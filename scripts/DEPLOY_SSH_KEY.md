# Commande pour déployer la clé SSH install-v3

## Clé publique install-v3

```
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCV2fmXjdCv4R+T40Y0pjXPCymIbqToj549xRFTqerp3bK8p2Nc4o7YPe46lyd11wPpoP5TtNG28epyzOQKnSWqtsOheTaMUCUKr1YbqQChYcRupog6YWQkmqQhZh7F7uj6oVlgo990NpwyJKKLK0L2GlqzIIdL3m1onBtx5GvLgszbzZYEYIqryUhUaPdgtcvSFOGsPGbx4qUA18/u5akz0touuCpbbP8J5O9ikwSVmIg3ynp09yQ5RNHJIVoQFbJTez/Z86pnjnJJfcGQkXsVQDTPvZ/qxEMYZGyXU1CdhzSSqgNzOe5obOnxQVvGT4wadlaamyVvpYv236DT4TGrbSWQ3C+6P3ZXR6tb06wjLeIIdp0THkU9SWH0O7mJMWMgG4zt8idQKyzl7Bhoa2/toV9CTRgV2G2DJri2bSEbwLLMXDum4QPFT8OjCSM66tMY/H+wH+mOWOOf0hVQT+dIkkbaFTNqMkAyrsQfBUI097SWGlYJ46+9t58g+juwMZYCbcUrooHO93VN2LZFRrq5Z8Pvj+0Lnys029zyp73ZT8xzz5VAJZZ3iMnDtTq1LxadmXBPSEw8enBYSgo9KE5t7ZtvFjkH4DmihCRy6gtJcqztjaUrfNOq+3Gs9+wV4x/3PzDRaAe9SNjXQKSxvraYQ1elAfbWnjKH1FLplZhPLQ== install-v3-keybuzz-v3
```

## Commande à exécuter sur chaque serveur

**Serveurs concernés:**
- maria-01 (10.0.0.170)
- maria-02 (10.0.0.171)
- maria-03 (10.0.0.172)
- proxysql-01 (10.0.0.173)
- proxysql-02 (10.0.0.174)

**Commande à exécuter sur CHAQUE serveur:**

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCV2fmXjdCv4R+T40Y0pjXPCymIbqToj549xRFTqerp3bK8p2Nc4o7YPe46lyd11wPpoP5TtNG28epyzOQKnSWqtsOheTaMUCUKr1YbqQChYcRupog6YWQkmqQhZh7F7uj6oVlgo990NpwyJKKLK0L2GlqzIIdL3m1onBtx5GvLgszbzZYEYIqryUhUaPdgtcvSFOGsPGbx4qUA18/u5akz0touuCpbbP8J5O9ikwSVmIg3ynp09yQ5RNHJIVoQFbJTez/Z86pnjnJJfcGQkXsVQDTPvZ/qxEMYZGyXU1CdhzSSqgNzOe5obOnxQVvGT4wadlaamyVvpYv236DT4TGrbSWQ3C+6P3ZXR6tb06wjLeIIdp0THkU9SWH0O7mJMWMgG4zt8idQKyzl7Bhoa2/toV9CTRgV2G2DJri2bSEbwLLMXDum4QPFT8OjCSM66tMY/H+wH+mOWOOf0hVQT+dIkkbaFTNqMkAyrsQfBUI097SWGlYJ46+9t58g+juwMZYCbcUrooHO93VN2LZFRrq5Z8Pvj+0Lnys029zyp73ZT8xzz5VAJZZ3iMnDtTq1LxadmXBPSEw8enBYSgo9KE5t7ZtvFjkH4DmihCRy6gtJcqztjaUrfNOq+3Gs9+wV4x/3PzDRaAe9SNjXQKSxvraYQ1elAfbWnjKH1FLplZhPLQ== install-v3-keybuzz-v3" >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys
```

## Vérification

Après avoir exécuté la commande sur tous les serveurs, depuis install-v3:

```bash
cd /opt/keybuzz/keybuzz-infra
for ip in 10.0.0.170 10.0.0.171 10.0.0.172 10.0.0.173 10.0.0.174; do
    ssh -i /root/.ssh/id_rsa_keybuzz_v3 -o StrictHostKeyChecking=no root@$ip "echo 'SSH OK - $ip'"
done
```

