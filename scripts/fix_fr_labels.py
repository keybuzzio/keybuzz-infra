#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""PH28.26 - Fix FR labels for menu"""
import json

file_path = "/root/keybuzz-client/public/locales/fr/common.json"

with open(file_path, "r", encoding="utf-8") as f:
    data = json.load(f)

# Update nav labels per PH28.26 mapping
data["nav"]["dashboard"] = "Tableau de bord"
data["nav"]["inbox"] = "Messages"
data["nav"]["knowledge"] = "Base de réponses"
data["nav"]["playbooks"] = "Automatisation IA"

with open(file_path, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print("Labels updated successfully")
print("Nav section:")
for k, v in data["nav"].items():
    print(f"  {k}: {v}")
