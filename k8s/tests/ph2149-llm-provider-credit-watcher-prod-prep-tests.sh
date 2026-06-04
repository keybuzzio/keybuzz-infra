#!/usr/bin/env sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)"

python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys

try:
    import yaml
except Exception as exc:
    raise SystemExit(f"PyYAML required for PH-21.49 manifest tests: {type(exc).__name__}") from exc

root = Path(sys.argv[1])
secret_name = "monitoring-llm-provider-credit-token-prod"
secret_key = "token"
remote_key = "secret/keybuzz/llm_provider_credit/prod/monitor_token"

api_external_secret = root / "k8s/keybuzz-api-prod/externalsecret-llm-provider-credit-monitor-token.yaml"
monitoring_external_secret = root / "k8s/monitoring-alerts/externalsecret-llm-provider-credit-token-prod.yaml"
api_deployment = root / "k8s/keybuzz-api-prod/deployment.yaml"
api_kustomization = root / "k8s/keybuzz-api-prod/kustomization.yaml"
monitoring_cronjob = root / "k8s/monitoring-alerts/cronjob.yaml"


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
    text = path.read_text(encoding="utf-8")
    assert "kind: Secret" not in text, path
    assert "stringData:" not in text, path
    assert "sk-" not in text.lower(), path


def env_map_from_deployment(path):
    doc = load_single(path)
    envs = {}
    for container in doc["spec"]["template"]["spec"]["containers"]:
        for env in container.get("env", []):
            envs[env["name"]] = env
    return envs


def env_map_from_cronjob(path):
    doc = load_single(path)
    envs = {}
    for container in doc["spec"]["jobTemplate"]["spec"]["template"]["spec"]["containers"]:
        for env in container.get("env", []):
            envs[env["name"]] = env
    return envs


def assert_secret_ref(env, secret_name):
    ref = env["valueFrom"]["secretKeyRef"]
    assert ref["name"] == secret_name, env
    assert ref["key"] == secret_key, env
    assert ref.get("optional", False) is True, env


assert_external_secret(api_external_secret, "keybuzz-api-prod")
assert_external_secret(monitoring_external_secret, "vault-management")

api_envs = env_map_from_deployment(api_deployment)
assert "LLM_PROVIDER_CREDIT_MONITOR_TOKEN" in api_envs
assert_secret_ref(api_envs["LLM_PROVIDER_CREDIT_MONITOR_TOKEN"], secret_name)

monitoring_envs = env_map_from_cronjob(monitoring_cronjob)
assert monitoring_envs["MONITORING_ALERTS_LOG_ONLY"]["value"] == "true"
assert monitoring_envs["ALERT_DELIVERY_MODE"]["value"] == "log-only"
assert monitoring_envs["LLM_PROVIDER_CREDIT_ENABLED"]["value"] == "true"
assert monitoring_envs["LLM_PROVIDER_CREDIT_TARGET_ENV"]["value"] == "prod"
assert monitoring_envs["LLM_PROVIDER_CREDIT_DRY_RUN"]["value"] == "false"
assert monitoring_envs["LLM_PROVIDER_CREDIT_LOG_ONLY"]["value"] == "true"
assert monitoring_envs["LLM_PROVIDER_CREDIT_PROD_URL"]["value"].endswith("/internal/monitoring/llm-provider-credit")
assert monitoring_envs["LLM_PROVIDER_CREDIT_PROD_WINDOW_SECONDS"]["value"] == "900"
assert monitoring_envs["LLM_PROVIDER_CREDIT_PROD_THRESHOLD"]["value"] == "1"
assert monitoring_envs["LLM_PROVIDER_CREDIT_PROD_DEBOUNCE_SECONDS"]["value"] == "3600"
assert_secret_ref(monitoring_envs["LLM_PROVIDER_CREDIT_TOKEN"], secret_name)

kustomization = load_single(api_kustomization)
assert "externalsecret-llm-provider-credit-monitor-token.yaml" in kustomization["resources"]

print("PH21.49 LLM provider credit watcher PROD prep tests PASS")
PY
