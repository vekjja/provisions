Provisions Local/Remote Mac OsX, Linux and Windows
=====================================

## Mac and Linux Install
```powershell
curl -sL https://raw.githubusercontent.com/seemywingz/provisions/refs/heads/main/scripts/setup.sh | bash
```

The Script will install `git` and  `ansible`, clone the repo locally to `~/git/provisions` and run `ansible-playbook playbooks/local.yaml`

Alternatively you can clone the repo locally, make changes and then run the playbook.

## Windows Install
```powershell
iex ((Invoke-WebRequest -Uri "https://raw.githubusercontent.com/seemywingz/provisions/main/scripts/setup.ps1" -UseBasicParsing).Content)
```
This script will 
