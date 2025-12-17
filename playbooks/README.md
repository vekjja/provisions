# 📚 Playbooks

This directory contains the **entrypoint playbooks** and their **vars** (`group_vars/`, `host_vars/`) used to provision:
- **🧑‍💻 Local workstations** (the `local` inventory group)
- **🛰️ Remote hosts** (the `remote` inventory group)

> Tip: You can run these playbooks directly with `ansible-playbook`, or use the bootstrap wrapper `./scripts/setup.sh` (recommended for fresh machines).

## 🗺️ What runs what

- **🧑‍💻 Local**: `provision-local.yml` → targets `hosts: local`
- **🛰️ Remote**: `provision.yml` → targets `hosts: remote`

Inventory groups live in `.ansible/hosts`.

## 🚀 Running playbooks (direct)

Run from the repo root (so `ansible.cfg` and relative paths resolve correctly):

### 🧑‍💻 Local workstation

```bash
ansible-playbook playbooks/provision-local.yml
```

Run only one role via tags:

```bash
ansible-playbook playbooks/provision-local.yml --tags packages
ansible-playbook playbooks/provision-local.yml --tags files
```

### 🛰️ Remote host

```bash
ansible-playbook playbooks/provision.yml
```

Limit to one host (recommended):

```bash
ansible-playbook playbooks/provision.yml --limit mini-cloud
```

Run only one remote role via tags:

```bash
ansible-playbook playbooks/provision.yml --limit mini-cloud --tags k3s
ansible-playbook playbooks/provision.yml --limit mini-cloud --tags wireguard
```

### 🧪 Safe/preview modes

Dry-run with diffs:

```bash
ansible-playbook playbooks/provision.yml --limit mini-cloud --check --diff
```

List what would run:

```bash
ansible-playbook playbooks/provision.yml --list-tasks
ansible-playbook playbooks/provision.yml --list-tags
```

## 🎛️ Running playbooks (via `setup.sh`)

`./scripts/setup.sh` defaults to **local** and supports:
- `-t <tag>`: run only tagged tasks
- `-e <tag>`: skip tag
- `-r`: remote mode

Examples:

```bash
./scripts/setup.sh
./scripts/setup.sh -t packages
./scripts/setup.sh -r -t k3s
```

## 🧩 Vars: `group_vars/` + `host_vars/`

This repo uses standard Ansible precedence:

1) **`group_vars/all.yml`** applies to **everyone** (shared defaults)
2) **`host_vars/<hostname>`** (or `.yml`) applies to one host and **overrides** group vars

### 📦 `group_vars/all.yml`

Use this for defaults that should apply across machines, e.g.
- `unix_packages`
- `unix_directories`
- `nerd_fonts`

### 🏷️ Group-specific vars (optional)

If you want defaults per group, add files like:
- `group_vars/local.yml` (applies to the `local` group)
- `group_vars/remote.yml` (applies to the `remote` group)

### 🖥️ `host_vars/`

Host var filenames match the inventory hostname.

Current examples:
- `host_vars/macbook` (local workstation)
- `host_vars/mini-cloud.yml` (remote server)

Typical host vars you’ll see in this repo:
- **`packages` / `casks`**: lists used by the `packages` role
- **`files`**: a list of `{ src, dest }` used by the `files` role
- **`static_ip`**, **`firewall_rules`**, **`wireguard`**, **`k3s`**, **`nfs_*`**, **`fs_mounts`**: remote-only features

## 📁 How `files:` works (important)

The `files` role expects `files:` entries like:

```yaml
files:
  - { src: "dotfiles/.zshrc-common", dest: "~/.zshrc-common" }
  - { src: "configs/ssh.config", dest: "~/.ssh/config" }
```

Where:
- **`src`** is **relative to `assets/`** (e.g. `assets/dotfiles/.zshrc-common`)
- **Local hosts** get **symlinks** into your working tree (easy to iterate)
- **Remote hosts** get the files **copied** over SSH


