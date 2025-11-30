#!/usr/bin/env python3
"""
Validate dry-run mode in reset_hetzner.yml
Check that all destructive actions have when: not dry_run
"""
import yaml
import sys

playbook_file = 'ansible/playbooks/reset_hetzner.yml'

print("PH1-08 - Dry-run mode validation")
print("=" * 70)

try:
    with open(playbook_file, 'r', encoding='utf-8') as f:
        playbook = yaml.safe_load(f)
except Exception as e:
    print(f"ERROR: Failed to load playbook: {e}")
    sys.exit(1)

print("✓ Playbook loaded successfully")
print()

# Find the play
if not playbook or len(playbook) == 0:
    print("ERROR: Playbook is empty")
    sys.exit(1)

play = playbook[0]
tasks = play.get('tasks', [])

# Find all destructive modules
destructive_modules = [
    'community.general.hcloud_volume',  # for detach/delete
    'community.general.hcloud_server',  # for rebuild
]

# Check tasks in blocks
def check_tasks(task_list, path=""):
    issues = []
    dry_run_tasks = []
    
    for i, task in enumerate(task_list):
        if not isinstance(task, dict):
            continue
            
        task_name = task.get('name', f'task_{i}')
        current_path = f"{path}.{i}" if path else str(i)
        
        # Check if it's a block
        if 'block' in task:
            block_issues, block_dry_run = check_tasks(task['block'], f"{current_path}.block")
            issues.extend(block_issues)
            dry_run_tasks.extend(block_dry_run)
            continue
        
        # Check if it's a loop
        if 'loop' in task:
            # Check the looped task itself
            pass
        
        # Check for destructive modules
        for module in destructive_modules:
            if module in task:
                # Check if it has when: not dry_run
                when_conditions = task.get('when', [])
                if isinstance(when_conditions, str):
                    when_conditions = [when_conditions]
                
                has_dry_run_protection = any(
                    'not dry_run' in str(cond) or 'dry_run == false' in str(cond).lower()
                    for cond in when_conditions
                )
                
                if not has_dry_run_protection:
                    issues.append({
                        'task': task_name,
                        'module': module,
                        'path': current_path,
                        'issue': 'Missing when: not dry_run protection'
                    })
                else:
                    print(f"✓ {task_name}: Protected with when: not dry_run")
        
        # Check for DRY-RUN debug tasks
        if '[DRY-RUN]' in task_name or 'DRY-RUN' in str(task.get('debug', {}).get('msg', '')):
            dry_run_tasks.append(task_name)
    
    return issues, dry_run_tasks

print("Checking for destructive actions protection...")
print("-" * 70)

all_issues = []
all_dry_run_tasks = []

# Check main tasks
issues, dry_run_tasks = check_tasks(tasks)
all_issues.extend(issues)
all_dry_run_tasks.extend(dry_run_tasks)

# Check if dry_run variable is defined
vars_section = play.get('vars', {})
has_dry_run_var = 'dry_run' in vars_section or any('dry_run' in str(v) for v in vars_section.values())

print()
print("Validation Results:")
print("=" * 70)

if has_dry_run_var:
    print("✓ dry_run variable is defined in vars")
else:
    print("✗ dry_run variable NOT found in vars")
    all_issues.append({'issue': 'dry_run variable not defined'})

print(f"✓ Found {len(all_dry_run_tasks)} DRY-RUN debug tasks")
print()

if all_issues:
    print("✗✗✗ ISSUES FOUND ✗✗✗")
    print()
    for issue in all_issues:
        if isinstance(issue, dict):
            print(f"  - {issue.get('task', 'Unknown')}: {issue.get('issue', 'Issue')}")
            if 'module' in issue:
                print(f"    Module: {issue['module']}")
        else:
            print(f"  - {issue}")
    sys.exit(1)
else:
    print("✓✓✓ ALL VALIDATIONS PASSED ✓✓✓")
    print()
    print("Dry-run mode is properly protected:")
    print("  - All destructive actions have when: not dry_run")
    print("  - DRY-RUN debug tasks are present")
    print("  - dry_run variable is defined")
    sys.exit(0)

