# Ensure the script is run as Administrator
$currentUser = [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script must be run as Administrator!" -ForegroundColor Red
    exit 1
}

# Ensure WSL is installed
$wslDistro = "Debian"
if (!(Get-Command "wsl" -ErrorAction SilentlyContinue)) {
    Write-Host "WSL is not installed. Installing WSL with $wslDistro..."
    wsl --install --distribution $wslDistro
    Write-Host "WSL $wslDistro installation initiated. Restart and run the script again." -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "WSL $wslDistro is installed."
}

# Check if Debian is installed correctly
$wslDistros = wsl.exe --list --quiet | ForEach-Object { $_.Trim() }
if ($wslDistros -contains $wslDistro) {
    Write-Host ""
} else {
    Write-Host "$wslDistro is not installed. Installing now..."
    wsl --install --distribution $wslDistro
    Write-Host "$wslDistro installation started. Restart and rerun this script."
    exit 1
}

# Set WSL working directory to a known location
$knownDir = "/mnt/c"
wsl -d $wslDistro --cd $knownDir -- bash -c "cd $knownDir"

# Ensure Debian is fully initialized
Write-Host "Checking if Debian is fully initialized..."
$debianCheck = wsl -d $wslDistro --cd $knownDir -- bash -c "echo 'WSL $wslDistro Ready'"
if ($debianCheck -notmatch "WSL $wslDistro Ready") {
    Write-Host "$wslDistro is installed but not fully initialized. Launching Debian..."
    wsl -d $wslDistro --cd ~
    Write-Host "Restart and rerun this script once $wslDistro has fully initialized."
    exit 1
}

# Install Chocolatey (if not already installed)
if (!(Get-Command "choco" -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    refreshenv
}

Write-Host ""
# Install Python and Pip
choco install python -y

# Verify Python Installation
$pythonInstalled = Get-Command "python" -ErrorAction SilentlyContinue
if ($pythonInstalled) {
    Write-Host ""
    Write-Host "Python installed successfully."
    python --version
} else {
    Write-Host "Python installation failed." -ForegroundColor Red
    exit 1
}

# Verify Pip Installation
$pipInstalled = Get-Command "pip" -ErrorAction SilentlyContinue
if ($pipInstalled) {
    Write-Host ""
    Write-Host "Pip installed successfully."
    pip --version
} else {
    Write-Host "Pip installation failed." -ForegroundColor Red
    exit 1
}

# Enable and start WinRM service
$winrmStatus = Get-Service -Name WinRM -ErrorAction SilentlyContinue
if ($winrmStatus -eq $null -or $winrmStatus.Status -ne "Running") {
    Write-Host ""
    Write-Host "Enabling WinRM..."
    winrm quickconfig -quiet
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to enable WinRM" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host ""
    Write-Host "WinRM is running."
}

# Allow unencrypted connections (Required for Basic Auth)
Write-Host ""
Write-Host "Unencrypted WinRM Connections Allowed."
Set-Item -Path WSMan:\localhost\Service\AllowUnencrypted -Value $true -ErrorAction Stop

# Enable Basic Authentication (Required for Ansible)
Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value $true -ErrorAction Stop
Write-Host "Basic Authentication Enabled."

# Retrieve the Debian WSL IP Address
$wslIp = wsl -d $wslDistro --cd $knownDir -- hostname -I | ForEach-Object { $_.Trim() }
if (-not $wslIp) {
    Write-Host "Failed to retrieve WSL $wslDistro IP address!" -ForegroundColor Red
    exit 1
}

# Configure TrustedHosts to include the Debian WSL IP
$currentTrusted = (Get-Item WSMan:\localhost\Client\TrustedHosts).Value
if ($currentTrusted -and $currentTrusted -ne '*') {
    Set-Item WSMan:\localhost\Client\TrustedHosts -Value "$currentTrusted,$wslIp" -Force -ErrorAction Stop
} else {
    Set-Item WSMan:\localhost\Client\TrustedHosts -Value "$wslIp" -Force -ErrorAction Stop
}
Write-Host "Added WSL Debian ($wslIp) to TrustedHosts."

# Check if HTTPS Listener Exists
$existingHttpsListener = winrm enumerate winrm/config/listener | Select-String "Transport = HTTPS"
if ($existingHttpsListener) {
    Write-Host ""
    Write-Host "HTTPS Listener configured."
} else {
    # Configure HTTPS Listener
    Write-Host ""
    Write-Host "Configuring HTTPS Listener for WinRM..."
    $cert = New-SelfSignedCertificate -CertStoreLocation Cert:\LocalMachine\My -DnsName "$wslIp"
    $thumbprint = $cert.Thumbprint
    winrm create winrm/config/Listener?Address=*+Transport=HTTPS @{Hostname="$wslIp"; CertificateThumbprint="$thumbprint"}
    Write-Host "HTTPS Listener configured with certificate thumbprint $thumbprint."
}

# Restart WinRM service
Restart-Service WinRM -Force
Write-Host "Restarted WinRM Service."

# Configure Windows Firewall for WinRM
Write-Host ""
Write-Host "Configuring Windows Firewall for WinRM..."

# Open WinRM HTTP (port 5985)
if (!(Get-NetFirewallRule -DisplayName "Allow WinRM" -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -DisplayName "Allow WinRM" -Direction Inbound -Protocol TCP -LocalPort 5985 -Action Allow
    Write-Host "Opened port 5985 for WinRM HTTP"
} else {
    Write-Host "WinRM HTTP port allowed in the firewall."
}

# Open WinRM HTTPS (port 5986)
if (!(Get-NetFirewallRule -DisplayName "Allow WinRM Secure" -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -DisplayName "Allow WinRM Secure" -Direction Inbound -Protocol TCP -LocalPort 5986 -Action Allow
    Write-Host "Opened port 5986 for WinRM HTTPS"
} else {
    Write-Host "WinRM HTTPS port allowed in the firewall."
}

# Verify WinRM listener
$listener = winrm enumerate winrm/config/listener
if ($listener -match "Transport = HTTP" -and $listener -match "Transport = HTTPS" -and $listener -match "Enabled = true") {
    Write-Host ""
    Write-Host "WinRM is properly configured with both HTTP and HTTPS listeners."
} else {
    Write-Host "WinRM configuration failed. Check settings manually." -ForegroundColor Red
    exit 1
}
Write-Host "Current WinRM Listeners:"
winrm enumerate winrm/config/listener
if ($?) {
    Write-Host "Setup completed successfully!" -ForegroundColor Green
} else {
    Write-Host "WinRM failed to list listeners." -ForegroundColor Red
}


