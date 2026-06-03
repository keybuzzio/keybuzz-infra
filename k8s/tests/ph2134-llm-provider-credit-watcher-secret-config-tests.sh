#!/usr/bin/env sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)"

python3 - "$ROOT" <<'PY'
from pathlib import Path
import re
import sys

try:
    import yaml
except Exception as exc:
    raise SystemExit(f"PyYAML required for PH-21.34 manifest tests: {type(exc).__name__}") from exc

root = Path(sys.argv[1])
secret_name = "monitoring-llm-provider-credit-token"
secret_key = "token"
remote_key = "secret/keybuzz/llm_provider_credit/dev/monitor_token"

api_external_secret = root / "k8s/keybuzz-api-dev/externalsecret-llm-provider-credit-monitor-token.yaml"
monitoring_external_secret = root / "k8s/monitoring-alerts/externalsecret-llm-provider-credit-token.yaml"
api_deployment = root / "k8s/keybuzz-api-dev/deployment.yaml"
monitoring_cronjob = root / "k8s/monitoring-alerts/cronjob.yaml"
state_configmap = root / "k8s/monitoring-alerts/configmap-state.yaml"


def load_single(path):
    with path.open("r", encoding="utf-8") as handle:
        docs = [doc for doc in yaml.safe_load_all(handle) if doc is not None]
    if len(docs) != 1:
        raise AssertionError(f"{path} must contain exactly one YAML document")
    return docs[0]


def assert_external_secret(path, namespace):
    doc = load_single(path)
    assert doc["apiVersion"] == "external-secrets.io/v1", path
    assert doc["kind"] == "ExternalSecret", path
    assert doc["metadata"]["name"] == secret_name, path
    assert doc["metadata"]["namespace"] == namespace, path
    assert doc["spec"]["secretStoreRef"]["name"] == "vault-backend", path
    assert doc["spec"]["secretStoreRef"]["kind"] == "ClusterSecretStore", path
    assert doc["spec"]["target"]["name"] == secret_name, path
    assert doc["spec"]["target"]["creationPolicy"] == "Owner", path
    data = doc["spec"]["data"]
    assert len(data) == 1, path
    item = data[0]
    assert item["secretKey"] == secret_key, path
    assert item["remoteRef"]["key"] == remote_key, path
    assert item["remoteRef"]["property"] == "value", path
    assert "data" not in doc and "stringData" not in doc, path


def assert_state_configmap(path):
    doc = load_single(path)
    assert doc["apiVersion"] == "v1", path
    assert doc["kind"] == "ConfigMap", path
    assert doc["metadata"]["name"] == "monitoring-alert-state", path
    assert doc["metadata"]["namespace"] == "vault-management", path
    assert doc.get("data", {}) == {}, path
    assert "stringData" not in doc, path


def containers_from_workload(path):
    doc = load_single(path)
    return doc["spec"]["template"]["spec"]["containers"]


def cron_containers(path):
    doc = load_single(path)
    return doc["spec"]["jobTemplate"]["spec"]["template"]["spec"]["containers"]


def env_map(containers):
    envs = {}
    for container in containers:
        for env in container.get("env", []):
            envs[env["name"]] = env
    return envs


def require_secret_env(envs, name, optional):
    env = envs.get(name)
    assert env is not None, name
    ref = env["valueFrom"]["secretKeyRef"]
    assert ref["name"] == secret_name, name
    assert ref["key"] == secret_key, name
    assert ref.get("optional", False) is optional, name


assert_external_secret(api_external_secret, "keybuzz-api-dev")
assert_external_secret(monitoring_external_secret, "vault-management")
assert_state_configmap(state_configmap)

api_envs = env_map(containers_from_workload(api_deployment))
require_secret_env(api_envs, "LLM_PROVIDER_CREDIT_MONITOR_TOKEN", True)

monitoring_envs = env_map(cron_containers(monitoring_cronjob))
require_secret_env(monitoring_envs, "LLM_PROVIDER_CREDIT_TOKEN", True)
assert monitoring_envs["LLM_PROVIDER_CREDIT_TARGET_ENV"]["value"] == "dev"
assert monitoring_envs["LLM_PROVIDER_CREDIT_DRY_RUN"]["value"] == "false"
assert monitoring_envs["LLM_PROVIDER_CREDIT_LOG_ONLY"]["value"] == "true"
assert monitoring_envs["LLM_PROVIDER_CREDIT_DEV_URL"]["value"].endswith("/internal/monitoring/llm-provider-credit")

for path in (api_external_secret, monitoring_external_secret):
    text = path.read_text(encoding="utf-8")
    assert "kind: Secret" not in text
    assert "stringData:" not in text
    assert re.search(r"^[ \t]*data:[ \t]*$", text, re.MULTILINE)
    assert "sk-" not in text.lower()
    assert "REPLACEME" not in text

for path in root.glob("k8s/keybuzz-api-prod/**/*.yaml"):
    text = path.read_text(encoding="utf-8")
    assert "LLM_PROVIDER_CREDIT_MONITOR_TOKEN" not in text
    assert secret_name not in text

print("PH21.34 manifest tests PASS")
PY
