# XFS Role

Ansible role for setting up XFS filesystems on data disks.

## Purpose

This role automatically:
- Detects data disks (excludes root and swap)
- Formats disks with XFS filesystem
- Creates mount points under `/data/<role_v3>/`
- Mounts disks
- Adds entries to `/etc/fstab` for persistence
- Tests write operations

## Requirements

- Ansible 2.9+
- Target servers must have data disks attached
- Root access required

## Variables

- `role_v3`: The role of the server (used for mount point organization)

## Usage

```yaml
- hosts: db_postgres
  roles:
    - role: xfs
      vars:
        role_v3: "db_postgres"
```

## Idempotency

This role is idempotent - it will:
- Skip formatting if disk is already XFS
- Skip mounting if already mounted
- Skip fstab entries if already present

## Mount Points

Disks are mounted under `/data/<role_v3>/<disk_name>/`

Example:
- `/data/db_postgres/sdb/`
- `/data/k8s_worker/sdc/`

