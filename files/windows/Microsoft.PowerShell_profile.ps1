


# Path

# Theme
oh-my-posh init pwsh --config "X:\OneDrive\Documents\WindowsPowerShell\kev.omp.json" | Invoke-Expression


# System
Set-Alias -Name la -Value ls
Set-Alias -Name link-git -Value New-Item -Path 'Y:\git' -ItemType SymbolicLink -Value '\\wsl$\kali-linux\home\kali\git'


function .. { Set-Location .. }

# make symbolic link
function mklink ($target, $link) {
    # Check if running as administrator
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

    if (-not $isAdmin) {
        Write-Host "Re-running as Administrator..."
        Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        return
    }

    # Check if link already exists
    if (Test-Path $link) {
        Write-Host "Error: The link path already exists. Remove it first."
        return
    }

    # Create symbolic link
    try {
        New-Item -Path $link -ItemType SymbolicLink -Value $target -ErrorAction Stop
        Write-Host "Symbolic link created: $link -> $target"
    } catch {
        Write-Host "Error creating symbolic link: $_"
    }
}

# Git
function gpll { git pull }
function gs { git status }
function gc { git commit }
function gpa { 
    param (
        [string]$commitMessage = "Update"
    )

    git add .
    git commit -am "$commitMessage"
    git push
}