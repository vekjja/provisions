# Provisions

Modern, repeatable **local** + **remote** provisioning with **Ansible**, plus Helm values/scripts for a small homelab stack.

## macOS / Linux (one-liner install)

This downloads and runs the bootstrap script which:
- Installs **Ansible** (and Git where needed)
- Clones this repo to `~/git/provisions`
- Runs the **local** playbook (`playbooks/provision-local.yml`) by default

```bash
curl -fsSL https://raw.githubusercontent.com/vekjja/provisions/main/scripts/setup.sh | bash
```

### Custom arguments

Pass args through to the script (examples):

```bash
curl -fsSL https://raw.githubusercontent.com/vekjja/provisions/main/scripts/setup.sh | bash -s -- -t packages
curl -fsSL https://raw.githubusercontent.com/vekjja/provisions/main/scripts/setup.sh | bash -s -- -e nerd-fonts
curl -fsSL https://raw.githubusercontent.com/vekjja/provisions/main/scripts/setup.sh | bash -s -- -r -t k3s
```

## Common tags

- **Workstation**: `packages`, `casks`, `nerd-fonts`, `system`, `files`, `go`
- **Homelab/remote**: `fstab`, `k3s`, `nfs`, `network`, `wireguard`

## Remote host provisioning

Remote mode runs `playbooks/provision.yml` against the `remote` inventory group:

```bash
./scripts/setup.sh -r
```

## Inventory + playbooks (quick map)

- **Inventory**: `.ansible/hosts`
  - `[local]` (uses `ansible_connection=local`)
  - `[remote]` (SSH)
- **Local playbook**: `playbooks/provision-local.yml` (targets `hosts: local`)
- **Remote playbook**: `playbooks/provision.yml` (targets `hosts: remote`)

## Repo layout

- **`playbooks/`**: Ansible entrypoints + `group_vars/` + `host_vars/`
- **`roles/`**: Ansible roles
- **`assets/`**: dotfiles/configs/themes/docs
- **`helm/`**: Helm charts/values used by the cluster
- **`scripts/`**: bootstrap + K3s helper scripts

## Windows (bootstrap)

This sets up WSL + WinRM prerequisites; after it completes, open WSL (Debian) and run the Linux install one-liner above.

```powershell
iex ((Invoke-WebRequest -Uri "https://raw.githubusercontent.com/vekjja/provisions/main/scripts/setup.ps1" -UseBasicParsing).Content)
```