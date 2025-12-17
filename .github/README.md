# 🛠️ Provisions

Your personal “push-button” setup for **workstations** (local) and **servers** (remote) using **Ansible** — plus Helm values/scripts for a small homelab stack.

## 🚀 Quickstart

### 🍎 macOS / 🐧 Linux (one-liner)

This bootstrap will:
- Install **Ansible** (and Git where needed)
- Clone to `~/git/provisions`
- Run the **local** playbook (`playbooks/provision-local.yml`) by default

```bash
curl -fsSL https://raw.githubusercontent.com/vekjja/provisions/main/scripts/setup.sh | bash
```

### 🎛️ Custom arguments

Pass args through (examples):

```bash
curl -fsSL https://raw.githubusercontent.com/vekjja/provisions/main/scripts/setup.sh | bash -s -- -t packages
curl -fsSL https://raw.githubusercontent.com/vekjja/provisions/main/scripts/setup.sh | bash -s -- -e nerd-fonts
curl -fsSL https://raw.githubusercontent.com/vekjja/provisions/main/scripts/setup.sh | bash -s -- -r -t k3s
```

## 🧩 Tags (what you can run)

- **🧑‍💻 Workstation**: `packages`, `casks`, `nerd-fonts`, `system`, `files`, `go`
- **🧪 Homelab/remote**: `fstab`, `k3s`, `nfs`, `network`, `wireguard`

## 🛰️ Remote host provisioning

Remote mode runs `playbooks/provision.yml` against the `remote` inventory group:

```bash
./scripts/setup.sh -r
```

## 🗺️ Inventory + playbooks (quick map)

- **📒 Inventory**: `.ansible/hosts`
  - `[local]` (uses `ansible_connection=local`)
  - `[remote]` (SSH)
- **🧑‍💻 Local playbook**: `playbooks/provision-local.yml` (targets `hosts: local`)
- **🛰️ Remote playbook**: `playbooks/provision.yml` (targets `hosts: remote`)

## 🗂️ Repo layout

- **`playbooks/`**: entrypoints + `group_vars/` + `host_vars/`
- **`roles/`**: Ansible roles
- **`assets/`**: dotfiles/configs/themes/docs
- **`helm/`**: Helm charts/values used by the cluster
- **`scripts/`**: bootstrap + K3s helper scripts

## 📚 Docs (deeper dives)

- **Playbooks usage**: **[`playbooks/README.md`](../playbooks/README.md)**
- **Vars reference**: **[`playbooks/VARS.md`](../playbooks/VARS.md)**

## 🪟 Windows (bootstrap)

This sets up WSL + WinRM prerequisites; after it completes, open WSL (Debian) and run the Linux one-liner above.

```powershell
iex ((Invoke-WebRequest -Uri "https://raw.githubusercontent.com/vekjja/provisions/main/scripts/setup.ps1" -UseBasicParsing).Content)
```