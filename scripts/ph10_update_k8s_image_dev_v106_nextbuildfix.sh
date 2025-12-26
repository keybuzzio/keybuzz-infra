#!/bin/bash
set -e
LOG_FILE=/opt/keybuzz/logs/ph10-ui/update-images-v106-nextbuildfix.log
mkdir -p /opt/keybuzz/logs/ph10-ui
echo === PH10 Update K8s DEV image to v1.0.6-dev === | tee -a 
echo Date: Mon Dec 22 09:20:40 PM UTC 2025 | tee -a 
echo " | tee -a 
cd /opt/keybuzz/keybuzz-infra
MANIFEST=k8s/keybuzz-admin-dev/deployment.yaml
echo Updating ... | tee -a 
sed -i s|ghcr.io/keybuzzio/keybuzz-admin:.*|ghcr.io/keybuzzio/keybuzz-admin:v1.0.6-dev|g 
echo Manifest updated | tee -a 
echo " | tee -a 
echo Committing changes... | tee -a 
git add 
git commit -m chore: bump keybuzz-admin dev image to v1.0.6-dev | tee -a 
echo " | tee -a 
echo Pushing to remote... | tee -a 
git push | tee -a 
echo " | tee -a 
echo Update completed successfully | tee -a 
