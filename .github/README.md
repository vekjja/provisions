Provisions Local/Remote Mac OS X, Linux and Windows
=====================================

## Mac and Linux Install
```powershell
curl -sL https://raw.githubusercontent.com/vekjja/provisions/refs/heads/main/scripts/setup.sh | bash
```

Add Custom Arguments
```shell
curl -sL https://raw.githubusercontent.com/vekjja/provisions/refs/heads/main/scripts/setup.sh | bash -s -- [ARGUMENTS]
```

The script will install `git` and `ansible`, clone the repo locally to `~/git/provisions` and run  
`ansible-playbook playbooks/local.yaml`

Alternatively, you can clone the repo locally, make changes, and then run the playbook.

## Windows Install
```powershell
iex ((Invoke-WebRequest -Uri "https://raw.githubusercontent.com/vekjja/provisions/main/scripts/setup.ps1" -UseBasicParsing).Content)
```
This script will install `wsl --distro Debian`, `Chocolatey` and `Python` on the Windows host.  
It will also configure _Windows Remote Management_ to allow connection from WSL.

Once setup succeeds on the Windows host, enter `wsl -d Debian` and run the Linux install script above.  
You may need to run `sudo apt update && sudo apt install curl -y` first.

Navigate to `~/git/provisions` and add the file `playbooks/group_vars/windows.yaml` with contents:
```
ansible_user: YOUR_WINDOWS_USER
ansible_password: YOUR_WINDOWS_PASSWORD
ansible_host: YOUR_WINDOWS_IP (e.g. 10.0.0.123)
```
Then run `ansible-playbook playbooks/remote.yml`