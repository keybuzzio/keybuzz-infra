# Guide de déploiement de la clé SSH sur install-v3

## Situation actuelle

- ✅ Clé SSH générée localement : `C:\Users\ludov\.ssh\id_rsa_keybuzz_v3`
- ❌ Clé publique non déployée sur install-v3
- ❌ Connexion SSH échoue : `Permission denied (publickey,password)`

## Méthode 1 : Déploiement manuel via Hetzner Console

### Option A : Via Hetzner Cloud Console (Web)

1. Connectez-vous à [Hetzner Cloud Console](https://console.hetzner.cloud)
2. Allez dans **Servers** → Trouvez **install-v3** (IP: 46.62.171.61)
3. Cliquez sur **Console** ou **VNC Console**
4. Connectez-vous avec les credentials root (mot de passe Hetzner)
5. Exécutez les commandes suivantes :

```bash
mkdir -p /root/.ssh
chmod 700 /root/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCbFlqZbjFvL3e9BzjJHZwbrnaKRDInjWMjRDewf4TAU0BjhU9dnmU48G/Zh965QzXNfeMjDTDS6kGe6fSaPGW/ORriZRJ1eZ6LWwQy0SSNTQ9upjul1b8ffjs6kN+sinVYUr4wwCaupTD7a/1dhJ+BOYKqHPJLm2JWhPnNTZj1wLwaUS91Rh2L3HiWELCSn0Nffe3if4ZKuZhcJcEChKDwTeVq5LwOgmDWV5XlRNWVH7QvOzFDSxuBy+lQQ7A8ICydUrTVrHN2foy9bviuB2OYKnTldC5YD8dXGYKRc2kiob1Vr+GvaRj4ywGANQsOdz3zZFz9cByHnxDeHilyLAI4s2aqwLSYLxYiiF6WmDVbihnjUCI+TGabWtRs2UpTtekONcqS5LoY09F34VHMXsF6oYhjRoL8ENDBNSfRkATRiiOCsJYYE3xyBaz5H1opuxscphkT5xgVi7UvmNS5oc1V8kXY8OGPih6q6g43CvGRy/VE5uxUfVqHGuwRe3KcpPOakYj36x3XKywlqVwDD4wVuu0FW9XljuZKeW8X3B3sKMu1vdh1sRBtzwEfeDc46Xe3chNqCPGPU1EmXj/hllont6i7duh7msJyuR33Y8a9IIfNVhgtEpZ0PhQQ6wkGG5iqn9WH5SG/PitJ7wuxAOBkzAFBt2t+PBXpIKRnOwn1vw== install-v3-keybuzz-v3" >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
```

### Option B : Via mot de passe SSH temporaire

Si vous avez le mot de passe root temporaire de Hetzner :

```bash
# Sur votre machine locale Windows (PowerShell)
$password = "VOTRE_MOT_DE_PASSE_HETZNER"
$publicKey = Get-Content C:\Users\ludov\.ssh\id_rsa_keybuzz_v3.pub

# Installer plink ou utiliser sshpass (si disponible)
# Ou utiliser PuTTY pour la première connexion
```

## Méthode 2 : Utiliser le script dédié

Une fois que vous avez un accès (même temporaire) à install-v3 :

1. Copiez le script `scripts/deploy-ssh-key-install-v3.sh` sur install-v3
2. Exécutez-le :

```bash
# Sur install-v3
bash /path/to/deploy-ssh-key-install-v3.sh
```

## Méthode 3 : Déploiement via Hetzner API

Si vous avez déjà configuré le token Hetzner, vous pouvez utiliser hcloud :

```bash
# Sur install-v3 (après avoir sourcé le token)
export HETZNER_API_TOKEN="..."
hcloud server ssh-key list
hcloud server ssh-key add install-v3-key --public-key-from-file ~/.ssh/id_rsa_keybuzz_v3.pub
hcloud server add-ssh-key install-v3 install-v3-key
```

## Vérification après déploiement

Après avoir déployé la clé, testez la connexion :

```powershell
# Sur votre machine locale
ssh -i C:\Users\ludov\.ssh\id_rsa_keybuzz_v3 root@46.62.171.61 "echo 'Connexion réussie'; hostname"
```

## Commandes complètes (copier-coller)

### Commande unique pour déployer la clé (à exécuter sur install-v3)

```bash
mkdir -p /root/.ssh && chmod 700 /root/.ssh && echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCbFlqZbjFvL3e9BzjJHZwbrnaKRDInjWMjRDewf4TAU0BjhU9dnmU48G/Zh965QzXNfeMjDTDS6kGe6fSaPGW/ORriZRJ1eZ6LWwQy0SSNTQ9upjul1b8ffjs6kN+sinVYUr4wwCaupTD7a/1dhJ+BOYKqHPJLm2JWhPnNTZj1wLwaUS91Rh2L3HiWELCSn0Nffe3if4ZKuZhcJcEChKDwTeVq5LwOgmDWV5XlRNWVH7QvOzFDSxuBy+lQQ7A8ICydUrTVrHN2foy9bviuB2OYKnTldC5YD8dXGYKRc2kiob1Vr+GvaRj4ywGANQsOdz3zZFz9cByHnxDeHilyLAI4s2aqwLSYLxYiiF6WmDVbihnjUCI+TGabWtRs2UpTtekONcqS5LoY09F34VHMXsF6oYhjRoL8ENDBNSfRkATRiiOCsJYYE3xyBaz5H1opuxscphkT5xgVi7UvmNS5oc1V8kXY8OGPih6q6g43CvGRy/VE5uxUfVqHGuwRe3KcpPOakYj36x3XKywlqVwDD4wVuu0FW9XljuZKeW8X3B3sKMu1vdh1sRBtzwEfeDc46Xe3chNqCPGPU1EmXj/hllont6i7duh7msJyuR33Y8a9IIfNVhgtEpZ0PhQQ6wkGG5iqn9WH5SG/PitJ7wuxAOBkzAFBt2t+PBXpIKRnOwn1vw== install-v3-keybuzz-v3" >> /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys && echo "✓ Clé SSH déployée avec succès"
```

## Informations de la clé

- **Clé privée** : `C:\Users\ludov\.ssh\id_rsa_keybuzz_v3`
- **Clé publique** : `C:\Users\ludov\.ssh\id_rsa_keybuzz_v3.pub`
- **Fingerprint** : `SHA256:UwRMbZvFjyUwxqxCvDgFJcLEroa/sjQ+mBHzsi2GTLI`
- **Type** : RSA 4096 bits
- **Commentaire** : install-v3-keybuzz-v3

