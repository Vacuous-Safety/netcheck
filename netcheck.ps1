# Run as Administrator
$ProgressPreference = 'SilentlyContinue'
$VerbosePreference  = 'SilentlyContinue'
$InformationPreference = 'SilentlyContinue'
$WarningPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'

# Install OpenSSH Server if needed
$cap = 'OpenSSH.Server~~~~0.0.1.0'
try {
    $state = (Get-WindowsCapability -Online -Name $cap -ErrorAction SilentlyContinue).State
} catch {
    $state = $null
}
if ($state -ne 'Installed') {
    Add-WindowsCapability -Online -Name 2
    if (Get-Service -Name sshd -ErrorAction SilentlyContinue) {
        Set-Service -Name sshd -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service -Name sshd -ErrorAction SilentlyContinue
    }
}

# Firewall rule for SSH
$fwName = 'OpenSSH-Server-In-TCP'
if (-not (Get-NetFirewallRule -Name $fwName -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -Name $fwName -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -LocalPort  "Enter password for user '$userName' (input hidden)"
    New-LocalUser -Name $userName -Password $securePass -FullName "Administrator account" -Description "SSH admin account" -PasswordNeverExpires:$false | Out-Null
}

# Add to Administrators group if necessary
if (-not (Get-LocalGroupMember -Group 'Administrators' -Member $userName -ErrorAction SilentlyContinue)) {
    Add-LocalGroupMember -Group 'Administrators' -Member $userName | Out-Null
}

# Ensure sshd_config allows PubkeyAuthentication and PasswordAuthentication, then restart sshd
$sshdConfig = 'C:\ProgramData\ssh\sshd_config'
if (Test-Path $sshdConfig) {
    $content = Get-Contentmultiline) {
        $content = $content -replace '^\s*#?\s*PubkeyAuthentication\s+\w+','PubkeyAuthentication yes'
    } elseif ($content -notmatch 'PubkeyAuthentication') {
        $content += "`r`nPubkeyAuthentication yes"
    }
    if ($content -match '^\s*#?\s*PasswordAuthentication\s+\w+' -multiline) {
        $content = $content -replace '^\s*#?\s*PasswordAuthentication\s+\w+','PasswordAuthentication yes'
    } elseif ($content -notmatch 'PasswordAuthentication') {
        $content
