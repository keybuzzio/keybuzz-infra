#!/bin/bash
set -e
LOG_FILE=/opt/keybuzz/logs/ph10-ui/update-images-v105-bundle-081011.log
IMAGE_TAG=v1.0.5-dev
DEPLOYMENT_FILE=/opt/keybuzz/keybuzz-infra/k8s/keybuzz-admin-dev/deployment.yaml
cd /opt/keybuzz/keybuzz-infra
echo === PH10 Update K8s Image Dev v1.0.5-dev Bundle 08/09/10/11 === | tee -a 
echo Date: Mon Dec 22 07:14:31 PM UTC 2025 | tee -a 
echo Image Tag:  | tee -a 
echo " | tee -a 
if [ ! -f  ]; then
  echo Error:  not found | tee -a 
  exit 1
fi
echo Updating deployment file... | tee -a 
sed -i s|ghcr.io/keybuzzio/keybuzz-admin:v[0-9.]*-dev|ghcr.io/keybuzzio/keybuzz-admin:|g 
echo " | tee -a 
echo Verifying change... | tee -a 
grep   | tee -a 
echo " | tee -a 
echo Committing changes... | tee -a 
git add  | tee -a 
git commit -m chore: bump keybuzz-admin dev image to v1.0.5-dev | tee -a 
echo " | tee -a 
echo Pushing to remote... | tee -a 
git push origin main | tee -a 
echo " | tee -a 
echo K8s manifest updated successfully | tee -a 
