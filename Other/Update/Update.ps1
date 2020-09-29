#!/usr/bin/env powershell
# -----------------------------------------------------------------------------
# Description: Generic Update Script for PortableApps
# Author: Urs Roesch <github@bun.ch>
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Modules
# -----------------------------------------------------------------------------
Using module ".\PortableAppsCommon.psm1"

# -----------------------------------------------------------------------------
# Globals
# -----------------------------------------------------------------------------
$Version = "0.0.24-alpha"
$Debug   = $True

# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------
Function Which-7Zip() {
  $Locations = @(
    "$Env:ProgramFiles\7-Zip",
    "$Env:ProgramFiles(x86)\7-Zip",
    "$AppRoot\..\7-ZipPortable\App\7-Zip"
  )
  Switch (Test-Unix) {
    $True {
      $Prefix = 'wine'
      $Binary = '7z'
      break
    }
    default {
      $Prefix = ''
      $Binary = '7z.exe'
    }
  }
  Try {
    $Path = $(Get-Command $Binary).Source.ToString()
  }
  Catch {
    Foreach ($Location in $Locations) {
      If (Test-Path "$Location\$Binary") {
        $Path = "$Prefix $Location\$Binary"
      }
    }
  }
  Finally {
    If (!($Path)) {
      Debug fatal "Could not locate $Binary"
      Exit 76
    }
  }
  return $Path
}

# -----------------------------------------------------------------------------
Function Check-Sum {
  param(
    [object] $Download
  )
  Return Compare-Checksum `
    -Checksum $Download.Checksum `
    -Path $Download.OutFile()
}

# -----------------------------------------------------------------------------
Function Download-File {
  param(
    [object] $Download
  )
  # hide progress bar
  $Global:ProgressPreference = 'silentlyContinue'
  If (!(Test-Path $Download.DownloadDir)) {
    Debug info "Create directory $($Download.DownloadDir)"
    New-Item -Path $Download.DownloadDir -Type directory | Out-Null
  }
  If (!(Test-Path $Download.OutFile())) {
    Try {
      Debug info "Download URL $($Download.URL) to $($Download.OutFile()).part"
      Invoke-WebRequest `
        -Uri $Download.URL `
        -OutFile "$($Download.OutFile()).part"

      Debug info "Move file $($Download.OutFile()).part to $($Download.OutFile())"
      Move-Item -Path "$($Download.OutFile()).part" `
        -Destination $Download.OutFile()
    }
    Catch {
      Debug fatal "Failed to download URL $($Download.URL)"
      Exit 1
    }
  }
  If (!(Check-Sum -Download $Download)) {
    Debug fatal "Checksum for $($Download.OutFile()) " `
      "does not match '$($Donwload.Checksum)'"
    Exit 1
  }
  Debug info "Downloaded file '$($Download.OutFile())'"
}

# -----------------------------------------------------------------------------
Function Expand-Download {
  param(
    [object] $Download
  )
  If (!(Test-Path $Download.ExtractTo())) {
    Debug info "Create extract directory $($Download.ExtractTo())"
    New-Item -Path $Download.ExtractTo() -Type "directory" | Out-Null
  }
  Debug info "Extract $($Download.OutFile()) to $($Download.ExtractTo())"
  Expand-Archive -LiteralPath $Download.OutFile() `
    -DestinationPath $Download.ExtractTo() -Force
}

# -----------------------------------------------------------------------------
Function Expand-7Zip {
  param(
    [object] $Download
  )
  $7ZipExe = $(Which-7Zip)
  If (!(Test-Path $Download.ExtractTo())) {
    Debug info "Create extract directory $($Download.ExtractTo())"
    New-Item -Path $Download.ExtractTo() -Type "directory" | Out-Null
  }
  Debug info "Extract $($Download.OutFile()) to $($Download.ExtractTo())"
  $Command = "$7ZipExe x -r -y  " +
    " -o""$($Download.ExtractTo())"" " +
    " ""$($Download.OutFile())"""
  Debug info "Running command '$Command'"
  Invoke-Expression $Command | Out-Null
}

# -----------------------------------------------------------------------------
Function Update-Release {
  param(
    [object] $Download
  )
  Switch -regex ($Download.Basename()) {
    '\.[Zz][Ii][Pp]$' {
      Expand-Download -Download $Download
      break
    }
    '\.7[Zz]\.[Ee][Xx][Ee]$' {
      Expand-7Zip -Download $Download
      break
    }
  }
  If (Test-Path $Download.MoveTo()) {
    Debug info "Cleanup $($Download.MoveTo())"
    Remove-Item -Path $Download.MoveTo() `
      -Force `
      -Recurse
  }
  # Create destination Directory if not exist
  $MoveBaseDir = $Download.MoveTo() | Split-Path
  If (!(Test-Path $MoveBaseDir)) {
  Debug info "Create directory $MoveBaseDir prior to moving items"
    New-Item -Path $MoveBaseDir -Type "directory" | Out-Null
  }
  Debug info `
    "Move release from $($Download.MoveFrom()) to $($Download.MoveTo())"
  Move-Item -Path $Download.MoveFrom() `
    -Destination $Download.MoveTo() `
    -Force
}

# -----------------------------------------------------------------------------
Function Update-Appinfo-Item() {
  param(
    [string] $IniFile,
    [string] $Match,
    [string] $Replace
  )
  $IniFile = $(Switch-Path $IniFile)
  If (Test-Path $IniFile) {
    Debug info "Update INI File $IniFile with $Match -> $Replace"
    $Content = (Get-Content $IniFile)
    $Content -replace $Match, $Replace | `
      Out-File -Encoding UTF8 -FilePath $IniFile
  }
}

# -----------------------------------------------------------------------------
Function Update-Appinfo() {
  $Version = $Config.Section("Version")
  Update-Appinfo-Item `
    -IniFile $AppInfoIni `
    -Match '^PackageVersion\s*=.*' `
    -Replace "PackageVersion=$($Version['Package'])"
  Update-Appinfo-Item `
    -IniFile $AppInfoIni `
    -Match '^DisplayVersion\s*=.*' `
    -Replace "DisplayVersion=$($Version['Display'])"
}

# -----------------------------------------------------------------------------
Function Update-Application() {
  $Archive = $Config.Section('Archive')
  $Position = 1
  While ($True) {
    If (-Not ($Archive.ContainsKey("URL$Position"))) {
      Break
    }
    $Download  = [Download]::new(
      $Archive["URL$Position"],
      $Archive["ExtractName$Position"],
      $Archive["TargetName$Position"],
      $Archive["Checksum$Position"]
    )
    Download-File -Download $Download
    Update-Release -Download $Download
    $Position += 1
  }
}

# -----------------------------------------------------------------------------
Function Postinstall() {
  $Postinstall = "$PSScriptRoot\Postinstall.ps1"
  If (Test-Path $Postinstall) {
    . $Postinstall
  }
}

# -----------------------------------------------------------------------------
Function Create-Launcher() {
  Set-Location $AppRoot
  $AppPath  = (Get-Location)
  Try {
    Invoke-Helper -Command `
      "..\PortableApps.comLauncher\PortableApps.comLauncherGenerator.exe"
  }
  Catch {
    Debug fatal "Unable to create PortableApps Launcher"
    Exit 21
  }
}

# -----------------------------------------------------------------------------
Function Create-Installer() {
  Try {
    Invoke-Helper -Sleep 5 -Timeout 300 -Command `
      "..\PortableApps.comInstaller\PortableApps.comInstaller.exe"
  }
  Catch {
    Debug fatal "Unable to create installer for PortableApps"
    Debug fatal $_
    Exit 42
  }
}

# -----------------------------------------------------------------------------
Function Invoke-Helper() {
  param(
    [string] $Command,
    [int]    $Sleep   = $Null,
    [int]    $Timeout = 30
  )
  Set-Location $AppRoot
  $AppPath = (Get-Location)

  Switch (Test-Unix) {
    $True   {
      $Arguments = "$Command $(ConvertTo-WindowsPath $AppPath)"
      $Command   = "wine"
      break
    }
    default {
      $Arguments = ConvertTo-WindowsPath $AppPath
    }
  }

  #If ($Sleep) {
  #  Debug info "Waiting for filsystem cache to catch up"
  #  Start-Sleep $Sleep
  #}

  Debug info "Run PA $Command $Arguments"
  Start-Process $Command -ArgumentList $Arguments -NoNewWindow -Wait
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
$Config = Read-IniFile -IniFile $UpdateIni
Update-Application
Update-Appinfo
Postinstall
Create-Launcher
Create-Installer
