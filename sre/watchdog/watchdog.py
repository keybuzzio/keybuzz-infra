#!/usr/bin/env python3
"""
KeyBuzz K8s Node Watchdog
=========================
Monitors Kubernetes nodes and performs automatic recovery via Hetzner Cloud API.

Author: KeyBuzz SRE
Version: 1.0.0
"""

import json
import os
import subprocess
import sys
import time
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional, Any

# Configuration paths
CONFIG_PATH = Path("/opt/keybuzz/sre/watchdog/config.yaml")
STATE_PATH = Path("/opt/keybuzz/state/sre/watchdog_state.json")
LOG_DIR = Path("/opt/keybuzz/logs/sre/watchdog")
CREDENTIALS_PATH = Path("/opt/keybuzz/credentials/hcloud.env")

# Default configuration
DEFAULT_CONFIG = {
    "check_interval_seconds": 60,
    "consecutive_failures_threshold": 3,
    "cooldown_minutes": 20,
    "max_attempts_per_24h": 3,
    "recovery_timeout_seconds": 180,
    "dry_run": False,
    "excluded_nodes": [],  # Nodes to never touch (e.g., masters in some cases)
    "notification_webhook": "",  # Placeholder for future webhook
}


def log_json(level: str, message: str, **kwargs) -> None:
    """Write a JSON log entry to the log file and stdout."""
    entry = {
        "time": datetime.utcnow().isoformat() + "Z",
        "level": level,
        "message": message,
        **kwargs
    }
    log_line = json.dumps(entry)
    print(log_line)
    
    # Also write to log file
    log_file = LOG_DIR / f"watchdog_{datetime.utcnow().strftime('%Y%m%d')}.jsonl"
    try:
        with open(log_file, "a") as f:
            f.write(log_line + "\n")
    except Exception as e:
        print(json.dumps({"time": datetime.utcnow().isoformat() + "Z", "level": "ERROR", "message": f"Failed to write log: {e}"}))


def load_config() -> Dict[str, Any]:
    """Load configuration from YAML file or use defaults."""
    config = DEFAULT_CONFIG.copy()
    
    if CONFIG_PATH.exists():
        try:
            import yaml
            with open(CONFIG_PATH) as f:
                user_config = yaml.safe_load(f) or {}
                config.update(user_config)
        except ImportError:
            # YAML not available, try JSON format
            pass
        except Exception as e:
            log_json("WARN", f"Failed to load config, using defaults: {e}")
    
    return config


def load_state() -> Dict[str, Any]:
    """Load watchdog state (cooldowns, attempts)."""
    if STATE_PATH.exists():
        try:
            with open(STATE_PATH) as f:
                return json.load(f)
        except Exception as e:
            log_json("WARN", f"Failed to load state: {e}")
    
    return {"nodes": {}, "last_run": None}


def save_state(state: Dict[str, Any]) -> None:
    """Save watchdog state."""
    state["last_run"] = datetime.utcnow().isoformat() + "Z"
    try:
        STATE_PATH.parent.mkdir(parents=True, exist_ok=True)
        with open(STATE_PATH, "w") as f:
            json.dump(state, f, indent=2)
    except Exception as e:
        log_json("ERROR", f"Failed to save state: {e}")


def save_last_status(status: Dict[str, Any]) -> None:
    """Save last status for quick debugging."""
    status_file = LOG_DIR / "watchdog_last_status.json"
    try:
        with open(status_file, "w") as f:
            json.dump(status, f, indent=2)
    except Exception as e:
        log_json("WARN", f"Failed to save last status: {e}")


def write_alert(alert: Dict[str, Any]) -> None:
    """Write alert to alerts file."""
    alerts_file = LOG_DIR / "alerts.jsonl"
    alert["time"] = datetime.utcnow().isoformat() + "Z"
    try:
        with open(alerts_file, "a") as f:
            f.write(json.dumps(alert) + "\n")
    except Exception as e:
        log_json("ERROR", f"Failed to write alert: {e}")


def run_command(cmd: List[str], timeout: int = 30) -> tuple[int, str, str]:
    """Run a command and return (returncode, stdout, stderr)."""
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout
        )
        return result.returncode, result.stdout, result.stderr
    except subprocess.TimeoutExpired:
        return -1, "", "Command timed out"
    except Exception as e:
        return -1, "", str(e)


def get_kubernetes_nodes() -> List[Dict[str, Any]]:
    """Get list of Kubernetes nodes with their status."""
    rc, stdout, stderr = run_command(["kubectl", "get", "nodes", "-o", "json"])
    
    if rc != 0:
        log_json("ERROR", "Failed to get K8s nodes", stderr=stderr)
        return []
    
    try:
        data = json.loads(stdout)
        nodes = []
        for item in data.get("items", []):
            name = item["metadata"]["name"]
            
            # Get Ready condition
            ready = False
            for condition in item.get("status", {}).get("conditions", []):
                if condition["type"] == "Ready":
                    ready = condition["status"] == "True"
                    break
            
            # Get internal IP
            internal_ip = ""
            for addr in item.get("status", {}).get("addresses", []):
                if addr["type"] == "InternalIP":
                    internal_ip = addr["address"]
                    break
            
            nodes.append({
                "name": name,
                "ready": ready,
                "internal_ip": internal_ip,
                "labels": item["metadata"].get("labels", {}),
            })
        
        return nodes
    except Exception as e:
        log_json("ERROR", f"Failed to parse K8s nodes: {e}")
        return []


def get_hetzner_servers() -> Dict[str, Dict[str, Any]]:
    """Get Hetzner servers mapped by name."""
    # Source the token
    if CREDENTIALS_PATH.exists():
        with open(CREDENTIALS_PATH) as f:
            for line in f:
                if line.startswith("export HCLOUD_TOKEN="):
                    os.environ["HCLOUD_TOKEN"] = line.split("=", 1)[1].strip().strip('"').strip("'")
                elif line.startswith("HCLOUD_TOKEN="):
                    os.environ["HCLOUD_TOKEN"] = line.split("=", 1)[1].strip().strip('"').strip("'")
    
    if not os.environ.get("HCLOUD_TOKEN"):
        log_json("ERROR", "HCLOUD_TOKEN not set")
        return {}
    
    rc, stdout, stderr = run_command(["hcloud", "server", "list", "-o", "json"])
    
    if rc != 0:
        log_json("ERROR", "Failed to get Hetzner servers", stderr=stderr)
        return {}
    
    try:
        servers = json.loads(stdout)
        return {s["name"]: s for s in servers if s["name"].startswith("k8s-")}
    except Exception as e:
        log_json("ERROR", f"Failed to parse Hetzner servers: {e}")
        return {}


def kubectl_cordon(node: str, dry_run: bool = False) -> bool:
    """Cordon a node (mark unschedulable)."""
    log_json("INFO", f"Cordoning node {node}", action="cordon", node=node, dry_run=dry_run)
    if dry_run:
        return True
    
    rc, _, stderr = run_command(["kubectl", "cordon", node])
    if rc != 0:
        log_json("WARN", f"Failed to cordon {node}", stderr=stderr)
        return False
    return True


def kubectl_drain(node: str, dry_run: bool = False) -> bool:
    """Drain a node (evict pods)."""
    log_json("INFO", f"Draining node {node}", action="drain", node=node, dry_run=dry_run)
    if dry_run:
        return True
    
    rc, _, stderr = run_command([
        "kubectl", "drain", node,
        "--ignore-daemonsets",
        "--delete-emptydir-data",
        "--force",
        "--timeout=60s"
    ], timeout=90)
    
    if rc != 0:
        log_json("WARN", f"Failed to drain {node}", stderr=stderr)
        return False
    return True


def kubectl_uncordon(node: str, dry_run: bool = False) -> bool:
    """Uncordon a node (mark schedulable)."""
    log_json("INFO", f"Uncordoning node {node}", action="uncordon", node=node, dry_run=dry_run)
    if dry_run:
        return True
    
    rc, _, stderr = run_command(["kubectl", "uncordon", node])
    if rc != 0:
        log_json("WARN", f"Failed to uncordon {node}", stderr=stderr)
        return False
    return True


def hetzner_poweroff(server_id: int, dry_run: bool = False) -> bool:
    """Power off a Hetzner server."""
    log_json("INFO", f"Powering off server {server_id}", action="poweroff", server_id=server_id, dry_run=dry_run)
    if dry_run:
        return True
    
    rc, _, stderr = run_command(["hcloud", "server", "poweroff", str(server_id)])
    if rc != 0:
        log_json("WARN", f"Failed to poweroff server {server_id}", stderr=stderr)
        return False
    return True


def hetzner_poweron(server_id: int, dry_run: bool = False) -> bool:
    """Power on a Hetzner server."""
    log_json("INFO", f"Powering on server {server_id}", action="poweron", server_id=server_id, dry_run=dry_run)
    if dry_run:
        return True
    
    rc, _, stderr = run_command(["hcloud", "server", "poweron", str(server_id)])
    if rc != 0:
        log_json("WARN", f"Failed to poweron server {server_id}", stderr=stderr)
        return False
    return True


def hetzner_reset(server_id: int, dry_run: bool = False) -> bool:
    """Hard reset a Hetzner server."""
    log_json("INFO", f"Resetting server {server_id}", action="reset", server_id=server_id, dry_run=dry_run)
    if dry_run:
        return True
    
    rc, _, stderr = run_command(["hcloud", "server", "reset", str(server_id)])
    if rc != 0:
        log_json("WARN", f"Failed to reset server {server_id}", stderr=stderr)
        return False
    return True


def is_in_cooldown(node_state: Dict[str, Any], cooldown_minutes: int) -> bool:
    """Check if a node is in cooldown period."""
    last_action = node_state.get("last_action_time")
    if not last_action:
        return False
    
    last_time = datetime.fromisoformat(last_action.replace("Z", "+00:00"))
    cooldown_end = last_time + timedelta(minutes=cooldown_minutes)
    return datetime.now(last_time.tzinfo) < cooldown_end


def get_attempts_last_24h(node_state: Dict[str, Any]) -> int:
    """Count recovery attempts in the last 24 hours."""
    attempts = node_state.get("attempts", [])
    cutoff = datetime.utcnow() - timedelta(hours=24)
    
    count = 0
    for attempt_time in attempts:
        try:
            t = datetime.fromisoformat(attempt_time.replace("Z", "+00:00"))
            if t.replace(tzinfo=None) > cutoff:
                count += 1
        except:
            pass
    
    return count


def recover_node(
    node_name: str,
    hetzner_server: Dict[str, Any],
    config: Dict[str, Any],
    node_state: Dict[str, Any]
) -> str:
    """
    Attempt to recover a node.
    Returns: "recovered", "pending", "failed", "cooldown", "max_attempts"
    """
    dry_run = config.get("dry_run", False)
    server_id = hetzner_server["id"]
    server_status = hetzner_server["status"]
    
    # Check cooldown
    if is_in_cooldown(node_state, config["cooldown_minutes"]):
        log_json("INFO", f"Node {node_name} in cooldown, skipping", node=node_name)
        return "cooldown"
    
    # Check max attempts
    attempts_24h = get_attempts_last_24h(node_state)
    if attempts_24h >= config["max_attempts_per_24h"]:
        log_json("WARN", f"Node {node_name} exceeded max attempts ({attempts_24h}/{config['max_attempts_per_24h']})", node=node_name)
        write_alert({
            "type": "NEEDS_HUMAN",
            "node": node_name,
            "reason": f"Exceeded max recovery attempts ({attempts_24h})",
            "server_id": server_id
        })
        return "max_attempts"
    
    # Record attempt
    if "attempts" not in node_state:
        node_state["attempts"] = []
    node_state["attempts"].append(datetime.utcnow().isoformat() + "Z")
    node_state["last_action_time"] = datetime.utcnow().isoformat() + "Z"
    
    start_time = time.time()
    
    # Step 1: Kubernetes soft actions
    log_json("INFO", f"Starting recovery for {node_name}", node=node_name, server_status=server_status)
    
    kubectl_cordon(node_name, dry_run)
    kubectl_drain(node_name, dry_run)
    
    # Step 2: Hetzner power cycle
    if server_status == "running":
        hetzner_poweroff(server_id, dry_run)
        if not dry_run:
            time.sleep(10)  # Wait for poweroff
    
    hetzner_poweron(server_id, dry_run)
    
    # Step 3: Wait for recovery
    if not dry_run:
        timeout = config["recovery_timeout_seconds"]
        log_json("INFO", f"Waiting up to {timeout}s for {node_name} to recover", node=node_name)
        
        for _ in range(timeout // 10):
            time.sleep(10)
            nodes = get_kubernetes_nodes()
            for n in nodes:
                if n["name"] == node_name and n["ready"]:
                    duration_ms = int((time.time() - start_time) * 1000)
                    log_json("INFO", f"Node {node_name} recovered", node=node_name, duration_ms=duration_ms, action="recovered")
                    kubectl_uncordon(node_name, dry_run)
                    node_state["consecutive_failures"] = 0
                    return "recovered"
        
        # If still not ready, try hard reset
        log_json("WARN", f"Node {node_name} not ready after power cycle, trying reset", node=node_name)
        hetzner_reset(server_id, dry_run)
        
        # Wait a bit more
        for _ in range(60 // 10):
            time.sleep(10)
            nodes = get_kubernetes_nodes()
            for n in nodes:
                if n["name"] == node_name and n["ready"]:
                    duration_ms = int((time.time() - start_time) * 1000)
                    log_json("INFO", f"Node {node_name} recovered after reset", node=node_name, duration_ms=duration_ms, action="recovered")
                    kubectl_uncordon(node_name, dry_run)
                    node_state["consecutive_failures"] = 0
                    return "recovered"
    
    duration_ms = int((time.time() - start_time) * 1000)
    log_json("ERROR", f"Failed to recover node {node_name}", node=node_name, duration_ms=duration_ms)
    write_alert({
        "type": "RECOVERY_FAILED",
        "node": node_name,
        "server_id": server_id,
        "duration_ms": duration_ms
    })
    return "failed"


def main():
    """Main watchdog loop (single run)."""
    log_json("INFO", "Watchdog starting")
    
    # Load configuration
    config = load_config()
    state = load_state()
    
    # Ensure log directory exists
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    
    # Get current state
    k8s_nodes = get_kubernetes_nodes()
    hetzner_servers = get_hetzner_servers()
    
    if not k8s_nodes:
        log_json("ERROR", "No K8s nodes found or kubectl failed")
        save_state(state)
        return 1
    
    if not hetzner_servers:
        log_json("ERROR", "No Hetzner servers found or hcloud failed")
        save_state(state)
        return 1
    
    # Build status
    status = {
        "time": datetime.utcnow().isoformat() + "Z",
        "nodes": {},
        "issues": [],
        "actions_taken": []
    }
    
    excluded = set(config.get("excluded_nodes", []))
    threshold = config["consecutive_failures_threshold"]
    
    for node in k8s_nodes:
        node_name = node["name"]
        
        # Initialize node state if needed
        if node_name not in state["nodes"]:
            state["nodes"][node_name] = {"consecutive_failures": 0, "attempts": []}
        
        node_state = state["nodes"][node_name]
        
        status["nodes"][node_name] = {
            "ready": node["ready"],
            "consecutive_failures": node_state.get("consecutive_failures", 0),
            "in_cooldown": is_in_cooldown(node_state, config["cooldown_minutes"]),
            "attempts_24h": get_attempts_last_24h(node_state)
        }
        
        # Skip excluded nodes
        if node_name in excluded:
            log_json("DEBUG", f"Skipping excluded node {node_name}", node=node_name)
            continue
        
        # Check if node is healthy
        if node["ready"]:
            # Reset consecutive failures if node is ready
            if node_state.get("consecutive_failures", 0) > 0:
                log_json("INFO", f"Node {node_name} is now ready, resetting failure count", node=node_name)
            node_state["consecutive_failures"] = 0
            continue
        
        # Node is not ready
        node_state["consecutive_failures"] = node_state.get("consecutive_failures", 0) + 1
        failures = node_state["consecutive_failures"]
        
        log_json("WARN", f"Node {node_name} not ready ({failures}/{threshold} failures)", 
                 node=node_name, consecutive_failures=failures, threshold=threshold)
        
        status["issues"].append({
            "node": node_name,
            "type": "not_ready",
            "failures": failures
        })
        
        # Check if we should take action
        if failures >= threshold:
            # Find Hetzner server
            hetzner_server = hetzner_servers.get(node_name)
            if not hetzner_server:
                log_json("ERROR", f"No Hetzner server found for {node_name}", node=node_name)
                continue
            
            result = recover_node(node_name, hetzner_server, config, node_state)
            status["actions_taken"].append({
                "node": node_name,
                "result": result,
                "server_id": hetzner_server["id"]
            })
    
    # Save state and status
    save_state(state)
    save_last_status(status)
    
    log_json("INFO", "Watchdog completed", 
             nodes_checked=len(k8s_nodes),
             issues=len(status["issues"]),
             actions=len(status["actions_taken"]))
    
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as e:
        log_json("ERROR", f"Watchdog crashed: {e}", exception=str(e))
        sys.exit(1)
