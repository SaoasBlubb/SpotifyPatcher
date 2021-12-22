# Ignore errors from `Stop-Process`
$PSDefaultParameterValues['Stop-Process:ErrorAction'] = 'SilentlyContinue'

write-host @'
###########################
Saoas' Auto Spotify Patcher
###########################
'@


$SpotifyDirectory = "$env:APPDATA\Spotify"
$SpotifyExecutable = "$SpotifyDirectory\Spotify.exe"
$SpotifyApps = "$SpotifyDirectory\Apps"

Write-Host 'Beende Spotify...'`n
Stop-Process -Name Spotify
Stop-Process -Name SpotifyWebHelper

if ($PSVersionTable.PSVersion.Major -ge 7)
{
    Import-Module Appx -UseWindowsPowerShell
}

if (Get-AppxPackage -Name SpotifyAB.SpotifyMusic) {
  Write-Host @'
Die Microsoft Store-Version von Spotify wurde erkannt, die nicht unterstuetzt wird!
'@`n
  $ch = Read-Host -Prompt "Spotify Windows Store-Ausgabe deinstallieren (Y/N) "
  if ($ch -eq 'y'){
     Write-Host @'
Deinstalliere Spotify.
'@`n
     Get-AppxPackage -Name SpotifyAB.SpotifyMusic | Remove-AppxPackage
  } else{
     Write-Host @'
Beende...
'@`n
     Pause 
     exit
    }
}

Push-Location -LiteralPath $env:TEMP
try {
  # Unique directory name based on time
  New-Item -Type Directory -Name "SpotifyCrack-$(Get-Date -UFormat '%Y-%m-%d_%H-%M-%S')" `
  | Convert-Path `
  | Set-Location
} catch {
  Write-Output $_
  Pause
  exit
}

Write-Host 'Lade letzten patch herunter (chrome_elf.zip)...'`n
$webClient = New-Object -TypeName System.Net.WebClient
try {
  $webClient.DownloadFile(
    # Remote file URL
    'https://github.com/SaoasBlubb/SpotifyPatcher/raw/main/chrome_elf.zip',
    # Local file path
    "$PWD\chrome_elf.zip"
  )
} catch {
  Write-Output $_
  Sleep
}
<#
try {
  $webClient.DownloadFile(
    # Remote file URL
    'https://github.com/SaoasBlubb/SpotifyPatcher/raw/main/zlink.zip',
    # Local file path
    "$PWD\zlink.zip"
  )
} catch {
  Write-Output $_
  Sleep
}
try {
  $webClient.DownloadFile(
    # Remote file URL
    'https://github.com/SaoasBlubb/SpotifyPatcher/raw/main/xpui.zip',
    # Local file path
    "$PWD\xpui.zip"
  )
} catch {
  Write-Output $_
  Sleep
}
#>
Expand-Archive -Force -LiteralPath "$PWD\chrome_elf.zip" -DestinationPath $PWD
Remove-Item -LiteralPath "$PWD\chrome_elf.zip"
<#
Expand-Archive -Force -LiteralPath "$PWD\zlink.zip" -DestinationPath $PWD
Remove-Item -LiteralPath "$PWD\zlink.zip"
Expand-Archive -Force -LiteralPath "$PWD\xpui.zip" -DestinationPath $PWD
Remove-Item -LiteralPath "$PWD\xpui.zip"
#>
$spotifyInstalled = (Test-Path -LiteralPath $SpotifyExecutable)
$update = $false
if ($spotifyInstalled) {
  $ch = Read-Host -Prompt "Optional - Aktualisieren Sie Spotify auf die neueste Version. (Koennte bereits aktualisiert sein). (Y/N) "
  if ($ch -eq 'y') {
	$update = $true
  } else {
    Write-Host @'
Spotify wird nicht aktualisiert.
'@
  }
} else {
  Write-Host @'
Die Spotify-Installation wurde nicht erkannt.
'@
}
if (-not $spotifyInstalled -or $update) {
  Write-Host @'
Neueste Spotify-Vollversion wird heruntergeladen, bitte warten...
'@
  try {
    $webClient.DownloadFile(
      # Remote file URL
      'https://download.scdn.co/SpotifySetup.exe',
      # Local file path
      "$PWD\SpotifySetup.exe"
    )
  } catch {
    Write-Output $_
    Pause
    exit
  }
  mkdir $SpotifyDirectory >$null 2>&1
  Write-Host 'Starte installation...'
  Start-Process -FilePath "$PWD\SpotifySetup.exe"
  Write-Host 'Stoppe Spotify...Erneut'
  while ((Get-Process -name Spotify -ErrorAction SilentlyContinue) -eq $null){
     #waiting until installation complete
     }
  Stop-Process -Name Spotify >$null 2>&1
  Stop-Process -Name SpotifyWebHelper >$null 2>&1
  Stop-Process -Name SpotifyInstaller >$null 2>&1
}

if (!(test-path $SpotifyDirectory/chrome_elf_bak.dll)){
	move $SpotifyDirectory\chrome_elf.dll $SpotifyDirectory\chrome_elf_bak.dll >$null 2>&1
}

Write-Host 'Cracke Spotify...'
$patchFiles = "$PWD\chrome_elf.dll", "$PWD\config.ini"
<#
$remup = "$PWD\zlink.spa"
$uipat = "$PWD\xpui.spa"
#>
Copy-Item -LiteralPath $patchFiles -Destination "$SpotifyDirectory"
<#
$ch = Read-Host -Prompt "Optional - Upgrade-Taste entfernen. (Y/N) "
if ($ch -eq 'y'){
    move $SpotifyApps\zlink.spa $SpotifyApps\zlink.spa.bak >$null 2>&1
    Copy-Item -LiteralPath $remup -Destination "$SpotifyApps"
} else{
     Write-Host @'
Die Upgrade-Schaltflaeche laesst sich nicht entfernen.
'@`n
}

$ch = Read-Host -Prompt "aendern Sie Alpha UI zurueck zu Old UI. (BTS unterstuetzt nur die alte UI). (Y/N) "
if ($ch -eq 'y'){
    move $SpotifyApps\xpui.spa $SpotifyApps\xpui.spa.bak >$null 2>&1
    Copy-Item -LiteralPath $uipat -Destination "$SpotifyApps"
} else{
     Write-Host @'
Die Benutzeroberflaeche wird nicht geaendert.
'@`n
}
#>

$ch = Read-Host -Prompt "Optional - Anzeigenplatzhalter und Upgrade-Button entfernen. (Y/N) "
if ($ch -eq 'y') {
    $xpuiBundlePath = "$SpotifyApps\xpui.spa"
    $xpuiUnpackedPath = "$SpotifyApps\xpui\xpui.js"
    $fromZip = $false
    
    # Try to read xpui.js from xpui.spa for normal Spotify installations, or
    # directly from Apps/xpui/xpui.js in case Spicetify is installed.
    if (Test-Path $xpuiBundlePath) {
        Add-Type -Assembly 'System.IO.Compression.FileSystem'
        Copy-Item -Path $xpuiBundlePath -Destination "$xpuiBundlePath.bak"

        $zip = [System.IO.Compression.ZipFile]::Open($xpuiBundlePath, 'update')
        $entry = $zip.GetEntry('xpui.js')

        # Extract xpui.js from zip to memory
        $reader = New-Object System.IO.StreamReader($entry.Open())
        $xpuiContents = $reader.ReadToEnd()
        $reader.Close()

        $fromZip = $true
    } elseif (Test-Path $xpuiUnpackedPath) {
        Copy-Item -Path $xpuiUnpackedPath -Destination "$xpuiUnpackedPath.bak"
        $xpuiContents = Get-Content -Path $xpuiUnpackedPath -Raw

        Write-Host 'Spicetify erkannt - Moeglicherweise muessen Sie BTS neu installieren, nachdem Sie "spicetify apply" ausgefuehrt haben.';
    } else {
        Write-Host 'xpui.js konnte nicht gefunden werden, bitte oeffnen Sie einen Fehler im Saoas Repository.'
    }

    if ($xpuiContents) {
        # Replace ".ads.leaderboard.isEnabled" + separator - '}' or ')'
        # With ".ads.leaderboard.isEnabled&&false" + separator
        $xpuiContents = $xpuiContents -replace '(\.ads\.leaderboard\.isEnabled)(}|\))', '$1&&false$2'
    
        # Delete ".createElement(XX,{onClick:X,className:XX.X.UpgradeButton}),X()"
        $xpuiContents = $xpuiContents -replace '\.createElement\([^.,{]+,{onClick:[^.,]+,className:[^.]+\.[^.]+\.UpgradeButton}\),[^.(]+\(\)', ''
    
        if ($fromZip) {
            # Rewrite it to the zip
            $writer = New-Object System.IO.StreamWriter($entry.Open())
            $writer.BaseStream.SetLength(0)
            $writer.Write($xpuiContents)
            $writer.Close()

            $zip.Dispose()
        } else {
            Set-Content -Path $xpuiUnpackedPath -Value $xpuiContents
        }
    }
} else {
     Write-Host @'
Platzhalter fuer Werbung und Upgrade-Schaltflaeche wurden nicht entfernt.
'@`n
}

$tempDirectory = $PWD
Pop-Location

Remove-Item -Recurse -LiteralPath $tempDirectory  

Write-Host 'Cracken abgeschlossen, Spotify starten...'
Start-Process -WorkingDirectory $SpotifyDirectory -FilePath $SpotifyExecutable
Write-Host 'Fertig.'

write-host @'
#########################
Danke, und viel spass! :D
#########################
'@

exit
