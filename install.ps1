$PSDefaultParameterValues['Stop-Process:ErrorAction'] = [System.Management.Automation.ActionPreference]::SilentlyContinue
function Get-File
{
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.Uri]
        $Uri,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.IO.FileInfo]
        $TargetFile,
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Int32]
        $BufferSize = 1,
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('KB, MB')]
        [String]
        $BufferUnit = 'MB',
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('KB, MB')]
        [Int32]
        $Timeout = 10000
    )

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $useBitTransfer = $null -ne (Get-Module -Name BitsTransfer -ListAvailable) -and ($PSVersionTable.PSVersion.Major -le 5)

    if ($useBitTransfer)
    {
        Write-Information -MessageData 'Verwendung einer Fallback-BitTransfer-Methode, da Sie Windows PowerShell ausfuehren'
        Start-BitsTransfer -Source $Uri -Destination "$($TargetFile.FullName)"
    }
    else
    {
        $request = [System.Net.HttpWebRequest]::Create($Uri)
        $request.set_Timeout($Timeout) #15 second timeout
        $response = $request.GetResponse()
        $totalLength = [System.Math]::Floor($response.get_ContentLength() / 1024)
        $responseStream = $response.GetResponseStream()
        $targetStream = New-Object -TypeName ([System.IO.FileStream]) -ArgumentList "$($TargetFile.FullName)", Create
        switch ($BufferUnit)
        {
            'KB' { $BufferSize = $BufferSize * 1024 }
            'MB' { $BufferSize = $BufferSize * 1024 * 1024 }
            Default { $BufferSize = 1024 * 1024 }
        }
        Write-Verbose -Message "Puffergroeße: $BufferSize B ($($BufferSize/("1$BufferUnit")) $BufferUnit)"
        $buffer = New-Object byte[] $BufferSize
        $count = $responseStream.Read($buffer, 0, $buffer.length)
        $downloadedBytes = $count
        $downloadedFileName = $Uri -split '/' | Select-Object -Last 1
        while ($count -gt 0)
        {
            $targetStream.Write($buffer, 0, $count)
            $count = $responseStream.Read($buffer, 0, $buffer.length)
            $downloadedBytes = $downloadedBytes + $count
            Write-Progress -Activity "Herunterladen der Datei '$downloadedFileName'" -Status "Heruntergeladen ($([System.Math]::Floor($downloadedBytes/1024))K of $($totalLength)K): " -PercentComplete ((([System.Math]::Floor($downloadedBytes / 1024)) / $totalLength) * 100)
        }

        Write-Progress -Activity "Beendetes Herunterladen der Datei '$downloadedFileName'"

        $targetStream.Flush()
        $targetStream.Close()
        $targetStream.Dispose()
        $responseStream.Dispose()
    }
}

write-host @'
###########################
Saoas' Auto Spotify Patcher
###########################
'@


$spotifyDirectory = Join-Path -Path $env:APPDATA -ChildPath 'Spotify'
$spotifyExecutable = Join-Path -Path $spotifyDirectory -ChildPath 'Spotify.exe'
$spotifyApps = Join-Path -Path $spotifyDirectory -ChildPath 'Apps'

Write-Host "Beende Spotify...`n"
Stop-Process -Name Spotify
Stop-Process -Name SpotifyWebHelper

if ($PSVersionTable.PSVersion.Major -ge 7)
{
  Import-Module Appx -UseWindowsPowerShell
}

if (Get-AppxPackage -Name SpotifyAB.SpotifyMusic)
{
  Write-Host "Die Microsoft Store-Version von Spotify wurde erkannt, die nicht unterstuetzt wird.`n"

  $ch = Read-Host -Prompt 'Spotify Windows Store Edition deinstallieren (Y/N)'
  if ($ch -eq 'y')
  {
    Write-Host "Spotify deinstallieren.`n"
    Get-AppxPackage -Name SpotifyAB.SpotifyMusic | Remove-AppxPackage
  }
  else
  {
    Read-Host "Beenden...`nDruecken Sie eine beliebige Taste zum Beenden..."
    exit
  }
}

Push-Location -LiteralPath $env:TEMP
try
{
  # Unique directory name based on time
  New-Item -Type Directory -Name "SpotifyCrack-$(Get-Date -UFormat '%Y-%m-%d_%H-%M-%S')" |
  Convert-Path |
  Set-Location
}
catch
{
  Write-Output $_
  Read-Host 'Druecken Sie eine beliebige Taste zum Beenden...'
  exit
}

Write-Host "Herunterladen des neuesten Patches (chrome_elf.zip)...`n"
$elfPath = Join-Path -Path $PWD -ChildPath 'chrome_elf.zip'
try
{
  $uri = 'https://github.com/SaoasBlubb/SpotifyPatcher/raw/main/chrome_elf.zip'
  Get-File -Uri $uri -TargetFile "$elfPath"
}
catch
{
  Write-Output $_
  Start-Sleep
}

Expand-Archive -Force -LiteralPath "$elfPath" -DestinationPath $PWD
Remove-Item -LiteralPath "$elfPath" -Force

$spotifyInstalled = Test-Path -LiteralPath $spotifyExecutable
$update = $false
if ($spotifyInstalled)
{
  $ch = Read-Host -Prompt 'Optional - Aktualisieren Sie Spotify auf die neueste Version. (Koennte bereits aktualisiert sein). (Y/N)'
  if ($ch -eq 'y')
  {
    $update = $true
  }
  else
  {
    Write-Host 'Versucht nicht, Spotify zu aktualisieren.'
  }
}
else
{
  Write-Host 'Die Spotify-Installation wurde nicht erkannt.'
}
if (-not $spotifyInstalled -or $update)
{
  Write-Host 'Ich lade die neueste Spotify Vollversion herunter, bitte warten...'
  $spotifySetupFilePath = Join-Path -Path $PWD -ChildPath 'SpotifyFullSetup.exe'
  try
  {
    $uri = 'https://download.scdn.co/SpotifyFullSetup.exe'
    Get-File -Uri $uri -TargetFile "$spotifySetupFilePath"
  }
  catch
  {
    Write-Output $_
    Read-Host 'Druecken Sie eine beliebige Taste zum Beenden...'
    exit
  }
  New-Item -Path $spotifyDirectory -ItemType:Directory -Force | Write-Verbose

  [System.Security.Principal.WindowsPrincipal] $principal = [System.Security.Principal.WindowsIdentity]::GetCurrent()
  $isUserAdmin = $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
  Write-Host 'Installation laeuft...'
  if ($isUserAdmin)
  {
    Write-Host
    Write-Host 'Geplante Aufgabe erstellen...'
    $apppath = 'powershell.exe'
    $taskname = 'Spotify Installation'
    $action = New-ScheduledTaskAction -Execute $apppath -Argument "-NoLogo -NoProfile -Command & `'$spotifySetupFilePath`'"
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date)
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -WakeToRun
    Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $taskname -Settings $settings -Force | Write-Verbose
    Write-Host 'Die Installationsaufgabe wurde geplant. Starte die Aufgabe...'
    Start-ScheduledTask -TaskName $taskname
    Start-Sleep -Seconds 2
    Write-Host 'Aufhebung der Registrierung der Aufgabe...'
    Unregister-ScheduledTask -TaskName $taskname -Confirm:$false
    Start-Sleep -Seconds 2
  }
  else
  {
    Start-Process -FilePath "$spotifySetupFilePath"
  }

  while ($null -eq (Get-Process -Name Spotify -ErrorAction SilentlyContinue))
  {
    Start-Sleep -Milliseconds 100
  }

  # Erstellen einer Verknuepfung zu Spotify in %APPDATA%\Microsoft\Windows\Start Menu\Programs und Desktop 
  # (ermoeglicht den Start des Programms ueber die Suche und den Desktop)
  $wshShell = New-Object -comObject WScript.Shell
  $desktopShortcut = $wshShell.CreateShortcut("$Home\Desktop\Spotify.lnk")
  $startMenuShortcut = $wshShell.CreateShortcut("$Home\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Spotify.lnk")
  $desktopShortcut.TargetPath = "$Home\AppData\Roaming\Spotify\Spotify.exe"
  $startMenuShortcut.TargetPath = "$Home\AppData\Roaming\Spotify\Spotify.exe"
  $desktopShortcut.Save()
  $startMenuShortcut.Save()

  Write-Host 'Spotify stoppen...erneut'

  Stop-Process -Name Spotify
  Stop-Process -Name SpotifyWebHelper
  Stop-Process -Name SpotifyFullSetup
}
$elfDllBackFilePath = Join-Path -Path $spotifyDirectory -ChildPath 'chrome_elf_bak.dll'
$elfBackFilePath = Join-Path -Path $spotifyDirectory -ChildPath 'chrome_elf.dll'
if ((Test-Path $elfDllBackFilePath) -eq $false)
{
  Move-Item -LiteralPath "$elfBackFilePath" -Destination "$elfDllBackFilePath" | Write-Verbose
}

Write-Host 'Spotify patchen...'
$patchFiles = (Join-Path -Path $PWD -ChildPath 'chrome_elf.dll'), (Join-Path -Path $PWD -ChildPath 'config.ini')

Copy-Item -LiteralPath $patchFiles -Destination "$spotifyDirectory"

$ch = Read-Host -Prompt 'Optional - Entfernen Sie den Anzeigenplatzhalter und die Upgrade-Schaltflaeche. (Y/N)'
if ($ch -eq 'y')
{
  $xpuiBundlePath = Join-Path -Path $spotifyApps -ChildPath 'xpui.spa'
  $xpuiUnpackedPath = Join-Path -Path (Join-Path -Path $spotifyApps -ChildPath 'xpui') -ChildPath 'xpui.js'
  $fromZip = $false

  # Versuchen Sie, xpui.js aus xpui.spa fuer normale Spotify-Installationen zu lesen, oder
  # direkt aus Apps/xpui/xpui.js, falls Spicetify installiert ist.
  if (Test-Path $xpuiBundlePath)
  {
    Add-Type -Assembly 'System.IO.Compression.FileSystem'
    Copy-Item -Path $xpuiBundlePath -Destination "$xpuiBundlePath.bak"

    $zip = [System.IO.Compression.ZipFile]::Open($xpuiBundlePath, 'update')
    $entry = $zip.GetEntry('xpui.js')

    # Extract xpui.js from zip to memory
    $reader = New-Object System.IO.StreamReader($entry.Open())
    $xpuiContents = $reader.ReadToEnd()
    $reader.Close()

    $fromZip = $true
  }
  elseif (Test-Path $xpuiUnpackedPath)
  {
    Copy-Item -LiteralPath $xpuiUnpackedPath -Destination "$xpuiUnpackedPath.bak"
    $xpuiContents = Get-Content -LiteralPath $xpuiUnpackedPath -Raw

    Write-Host 'Spicetify erkannt - Moeglicherweise muessen Sie BTS neu installieren, nachdem Sie "spicetify apply" ausgefuehrt haben.';
  }
  else
  {
    Write-Host 'xpui.js konnte nicht gefunden werden, bitte oeffnen Sie einen Fehler im SpotifyPatcher Repository.'
  }

  if ($xpuiContents)
  {
    # Ersetzen Sie ".ads.leaderboard.isEnabled" + separator - '}' oder  ')'
    # Mit ".ads.leaderboard.isEnabled&&false" + separator
    $xpuiContents = $xpuiContents -replace '(\.ads\.leaderboard\.isEnabled)(}|\))', '$1&&false$2'

    # Loeschen Sie ".createElement(XX,{onClick:X,className:XX.X.UpgradeButton}),X()"
    $xpuiContents = $xpuiContents -replace '\.createElement\([^.,{]+,{onClick:[^.,]+,className:[^.]+\.[^.]+\.UpgradeButton}\),[^.(]+\(\)', ''

    if ($fromZip)
    {
      $writer = New-Object System.IO.StreamWriter($entry.Open())
      $writer.BaseStream.SetLength(0)
      $writer.Write($xpuiContents)
      $writer.Close()

      $zip.Dispose()
    }
    else
    {
      Set-Content -LiteralPath $xpuiUnpackedPath -Value $xpuiContents
    }
  }
}
else
{
  Write-Host "Platzhalter fuer Werbung und Upgrade-Schaltflaeche werden nicht entfernt.`n"
}

$tempDirectory = $PWD
Pop-Location

Remove-Item -LiteralPath $tempDirectory -Recurse

Write-Host 'Patching abgeschlossen, Spotify gestartet...'

Start-Process -WorkingDirectory $spotifyDirectory -FilePath $spotifyExecutable
Write-Host 'Fertig.'

write-host @'
#########################
Danke, und viel spass! :D
#########################
'@

exit
