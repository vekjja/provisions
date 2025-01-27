Provisions Local/Remote Mac OsX, Linux and Windows
=====================================

## Mac and Linux Install
```shell
curl -sL -H "Authorization: token $GITHUB_PAT" https://raw.githubusercontent.com/seemywingz/provisions/refs/heads/main/scripts/setup.sh | bash
```

## Windows Install
```powershell
iex ((Invoke-WebRequest -Uri "https://raw.githubusercontent.com/seemywingz/provisions/main/scripts/setup.ps1" -UseBasicParsing).Content)
```