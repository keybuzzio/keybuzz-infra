#!/usr/bin/env python3
"""Script pour initialiser le cluster PostgreSQL HA avec Patroni"""

import subprocess
import json
import time
import sys

POSTGRES_NODES = ["10.0.0.120", "10.0.0.121", "10.0.0.122"]
PATRONI_REST_API_PORT = 8008
SSH_KEY = "/root/.ssh/id_rsa_keybuzz_v3"

def run_ssh(ip, command):
    """Exécute une commande SSH sur un nœud"""
    ssh_cmd = f"ssh -i {SSH_KEY} -o StrictHostKeyChecking=no root@{ip}"
    result = subprocess.run(f"{ssh_cmd} '{command}'", shell=True, capture_output=True, text=True)
    return result.stdout.strip(), result.stderr.strip(), result.returncode

def get_cluster_status(ip):
    """Récupère le statut du cluster depuis l'API Patroni"""
    stdout, stderr, rc = run_ssh(ip, f"curl -s http://127.0.0.1:{PATRONI_REST_API_PORT}/cluster")
    if rc == 0:
        try:
            return json.loads(stdout)
        except:
            return None
    return None

def initialize_cluster(ip):
    """Initialise le cluster PostgreSQL sur un nœud"""
    print(f"Initialisation du cluster sur {ip}...")
    stdout, stderr, rc = run_ssh(ip, f"""curl -s -X POST http://127.0.0.1:{PATRONI_REST_API_PORT}/initialize -H 'Content-Type: application/json' -d '{{"initdb": []}}'""")
    if rc == 0:
        try:
            result = json.loads(stdout)
            if "message" in result:
                print(f"  ✅ {result['message']}")
                return True
            else:
                print(f"  ✅ Cluster initialisé")
                return True
        except:
            if "already initialized" in stdout.lower() or "already exists" in stdout.lower():
                print(f"  ⚠️  Cluster déjà initialisé")
                return True
            else:
                print(f"  ⚠️  Réponse: {stdout[:100]}")
                return False
    else:
        print(f"  ❌ Erreur: {stderr}")
        return False

def wait_for_leader(cluster_status):
    """Vérifie si un leader existe dans le cluster"""
    if cluster_status and "members" in cluster_status:
        for member in cluster_status["members"]:
            if member.get("role") == "leader" and member.get("state") == "running":
                return member
    return None

def main():
    print("=== PH7 - Initialisation Cluster PostgreSQL HA ===")
    print()
    
    # Vérifier le statut actuel
    print("1. Vérification du statut actuel du cluster...")
    cluster_status = get_cluster_status(POSTGRES_NODES[0])
    if cluster_status:
        leader = wait_for_leader(cluster_status)
        if leader:
            print(f"  ✅ Cluster déjà initialisé avec leader: {leader['name']}")
            print(f"     Leader: {leader['host']}:{leader['port']}")
            return 0
    
    # Initialiser le cluster
    print()
    print("2. Initialisation du cluster...")
    if not initialize_cluster(POSTGRES_NODES[0]):
        print("  ❌ Échec de l'initialisation")
        return 1
    
    # Attendre que le cluster soit prêt
    print()
    print("3. Attente de la formation du cluster...")
    for i in range(30):
        time.sleep(2)
        cluster_status = get_cluster_status(POSTGRES_NODES[0])
        if cluster_status:
            leader = wait_for_leader(cluster_status)
            if leader:
                print(f"  ✅ Cluster formé avec leader: {leader['name']}")
                print(f"     Leader: {leader['host']}:{leader['port']}")
                print(f"     État: {leader['state']}")
                
                # Afficher tous les membres
                print()
                print("4. Membres du cluster:")
                for member in cluster_status.get("members", []):
                    role_icon = "👑" if member.get("role") == "leader" else "📋"
                    print(f"   {role_icon} {member['name']}: {member['role']} ({member['state']})")
                
                return 0
    
    print("  ⚠️  Timeout - Le cluster n'a pas été formé dans les délais")
    return 1

if __name__ == "__main__":
    sys.exit(main())

