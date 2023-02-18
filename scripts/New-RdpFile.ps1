Param(
    [Parameter(Mandatory=$true)]
    [string]$Path,

    [Parameter(Mandatory=$true)]
    [string]$FullAddress,

    [Parameter(Mandatory=$true)]
    [string]$Username,

    [Parameter(Mandatory=$true)]
    [string]$Password,

    [Parameter()]
    [string]$DesktopWidth="1280",

    [Parameter()]
    [string]$DesktopHeight="800"
)

# credit:
# https://github.com/RedAndBlueEraser/rdp-file-password-encryptor
Add-Type -AssemblyName System.Security

[System.Text.UnicodeEncoding]$encoding = [System.Text.Encoding]::Unicode
[byte[]]$passwordAsBytes = $encoding.GetBytes($Password)
[byte[]]$passwordEncryptedAsBytes = [System.Security.Cryptography.ProtectedData]::Protect($passwordAsBytes, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
[string]$passwordEncryptedAsHex = -join ($passwordEncryptedAsBytes | ForEach-Object { $_.ToString("X2") })

$RDPFile=@"
full address:s:$FullAddress
username:s:$Username
password 51:b:$passwordEncryptedAsHex
screen mode id:i:1
use multimon:i:0
desktopwidth:i:$DesktopWidth
desktopheight:i:$DesktopHeight
session bpp:i:32
winposstr:s:0,3,0,0,800,600
compression:i:1
keyboardhook:i:2
audiocapturemode:i:0
videoplaybackmode:i:1
connection type:i:7
networkautodetect:i:1
bandwidthautodetect:i:1
displayconnectionbar:i:1
enableworkspacereconnect:i:0
disable wallpaper:i:0
allow font smoothing:i:0
allow desktop composition:i:0
disable full window drag:i:1
disable menu anims:i:1
disable themes:i:0
disable cursor setting:i:0
bitmapcachepersistenable:i:1
audiomode:i:0
redirectprinters:i:1
redirectcomports:i:0
redirectsmartcards:i:1
redirectclipboard:i:1
redirectposdevices:i:0
autoreconnection enabled:i:1
authentication level:i:2
prompt for credentials:i:0
negotiate security layer:i:1
remoteapplicationmode:i:0
alternate shell:s:
shell working directory:s:
gatewayhostname:s:
gatewayusagemethod:i:4
gatewaycredentialssource:i:4
gatewayprofileusagemethod:i:0
promptcredentialonce:i:0
gatewaybrokeringtype:i:0
use redirection server name:i:0
rdgiskdcproxy:i:0
kdcproxyname:s:
"@

Set-Content -Path $(Join-Path -Path $Path -ChildPath "win_vm.rdp") -Force -Value $RDPFile