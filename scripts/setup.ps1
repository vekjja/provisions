# Ensure the script is run as Administrator
$currentUser = [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script must be run as Administrator!" -ForegroundColor Red
    exit 1
}

# Ensure WSL is installed
if (!(Get-Command "wsl" -ErrorAction SilentlyContinue)) {
    Write-Host "WSL is not installed. Installing WSL with Debian..."
    wsl --install --distribution Debian
    Write-Host "WSL Debian installation initiated. Restart and run the script again." -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "WSL is installed."
}

# Check if Debian is installed correctly
$wslDistros = wsl.exe --list --quiet | ForEach-Object { $_.Trim() }
if ($wslDistros -contains "Debian") {
    Write-Host "Debian is already installed in WSL."
} else {
    Write-Host "Debian is not installed. Installing now..."
    wsl --install --distribution Debian
    Write-Host "Debian installation started. Restart and rerun this script."
    exit 1
}

# Ensure Debian is fully initialized
Write-Host "Checking if Debian is fully initialized..."
$debianCheck = wsl -d Debian -- bash -c "echo 'WSL Debian Ready'"
if ($debianCheck -notmatch "WSL Debian Ready") {
    Write-Host "Debian is installed but not fully initialized. Launching Debian..."
    wsl -d Debian
    Write-Host "Restart and rerun this script once Debian has fully initialized."
    exit 1
}

# Retrieve the Debian WSL IP Address
$wslIp = wsl -d Debian -- hostname -I | ForEach-Object { $_.Trim() }
if (-not $wslIp) {
    Write-Host "Failed to retrieve WSL Debian IP address!" -ForegroundColor Red
    exit 1
}
Write-Host "WSL Debian IP Address: $wslIp"

# Install Chocolatey (if not already installed)
if (!(Get-Command "choco" -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    refreshenv
} else {
    Write-Host "Chocolatey is already installed."
}

# Install Python and Pip
Write-Host "Installing Python and Pip via Chocolatey..."
choco install python -y

# Verify Python Installation
$pythonInstalled = Get-Command "python" -ErrorAction SilentlyContinue
if ($pythonInstalled) {
    Write-Host "Python installed successfully."
    python --version
} else {
    Write-Host "Python installation failed." -ForegroundColor Red
    exit 1
}

# Verify Pip Installation
$pipInstalled = Get-Command "pip" -ErrorAction SilentlyContinue
if ($pipInstalled) {
    Write-Host "Pip installed successfully."
    pip --version
} else {
    Write-Host "Pip installation failed." -ForegroundColor Red
    exit 1
}

# Enable and start WinRM service
$winrmStatus = Get-Service -Name WinRM -ErrorAction SilentlyContinue
if ($winrmStatus -eq $null -or $winrmStatus.Status -ne "Running") {
    Write-Host "Enabling WinRM..."
    winrm quickconfig -quiet
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to enable WinRM" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "WinRM is already running."
}

# Allow unencrypted connections (Required for Basic Auth)
Set-Item -Path WSMan:\localhost\Service\AllowUnencrypted -Value $true -ErrorAction Stop
Write-Host "Allowed unencrypted WinRM connections."

# Enable Basic Authentication (Required for Ansible)
Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value $true -ErrorAction Stop
Write-Host "Enabled Basic Authentication."

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
    Write-Host "HTTPS Listener is already configured."
} else {
    # Configure HTTPS Listener
    Write-Host "Configuring HTTPS Listener for WinRM..."
    $cert = New-SelfSignedCertificate -CertStoreLocation Cert:\LocalMachine\My -DnsName "$wslIp"
    $thumbprint = $cert.Thumbprint
    winrm create winrm/config/Listener?Address=*+Transport=HTTPS @{Hostname="$wslIp"; CertificateThumbprint="$thumbprint"}
    Write-Host "HTTPS Listener configured with certificate thumbprint $thumbprint."
}

# Restart WinRM service
Restart-Service WinRM -Force
Write-Host "Restarted WinRM service."

# Verify WinRM listener
$listener = winrm enumerate winrm/config/listener
if ($listener -match "Transport = HTTP" -and $listener -match "Transport = HTTPS" -and $listener -match "Enabled = true") {
    Write-Host "WinRM is properly configured with both HTTP and HTTPS listeners."
} else {
    Write-Host "WinRM configuration failed. Check settings manually." -ForegroundColor Red
    exit 1
}

# Configure Windows Firewall for WinRM
Write-Host "Configuring Windows Firewall for WinRM..."

# Open WinRM HTTP (port 5985)
if (!(Get-NetFirewallRule -DisplayName "Allow WinRM" -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -DisplayName "Allow WinRM" -Direction Inbound -Protocol TCP -LocalPort 5985 -Action Allow
    Write-Host "Opened port 5985 for WinRM HTTP"
} else {
    Write-Host "WinRM HTTP port is already allowed in the firewall."
}

# Open WinRM HTTPS (port 5986)
if (!(Get-NetFirewallRule -DisplayName "Allow WinRM Secure" -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -DisplayName "Allow WinRM Secure" -Direction Inbound -Protocol TCP -LocalPort 5986 -Action Allow
    Write-Host "Opened port 5986 for WinRM HTTPS"
} else {
    Write-Host "WinRM HTTPS port is already allowed in the firewall."
}

Write-Host "Current WinRM Listeners:"
winrm enumerate winrm/config/listener
Write-Host "Testing WinRM connection to WSL Debian..."
Test-WsMan $wslIp -Authentication Basic
if ($?) {
    Write-Host "Python, Pip, and WinRM setup completed successfully!" -ForegroundColor Green
} else {
    Write-Host "WinRM connection to WSL Debian failed." -ForegroundColor Red
}


