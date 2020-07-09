[![Build](https://github.com/uroesch/DrawIOPortable/workflows/build-package/badge.svg)](https://github.com/uroesch/DrawIOPortable/actions?query=workflow%3Abuild-package)
[![GitHub release (latest by date including pre-releases)](https://img.shields.io/github/v/release/uroesch/DrawIOPortable?include_prereleases)](https://github.com/uroesch/DrawIOPortable/releases)
[![Runs on](https://img.shields.io/badge/runs%20on-Win64-blue)](#runtime-dependencies)
![GitHub All Releases](https://img.shields.io/github/downloads/uroesch/DrawIOPortable/total?style=flat)

# draw.io Portable for PortableApps.com

<img src="App/AppInfo/appicon_128.png" align="left">

[draw.io Desktop](https://draw.io/) is designed to be 
completely isolated from the Internet. All JavaScript 
files are self-contained, the Content Security Policy 
forbids running remotely loaded JavaScript.

No diagram data is ever sent externally, nor do we send
any analytics about app usage externally. This means 
certain functionality for which we do not have a JavaScript
implementation do not work in the Desktop build, namely 
.vsd and Gliffy import.

## Runtime dependencies
* 64-bit version of Windows.

## Support matrix

| OS              | 32-bit             | 64-bit              | 
|-----------------|:------------------:|:-------------------:|
| Windows XP      | ![ns][ns]          | ![ns][ns]           | 
| Windows Vista   | ![ns][ns]          | ![ns][ns]           | 
| Windows 7       | ![ns][ns]          | ![ps][ps]           |  
| Windows 8       | ![ns][ns]          | ![ps][ps]           |  
| Windows 10      | ![ns][ns]          | ![fs][fs]           |

Legend: ![ns][ns] not supported;  ![nd][nd] no data; ![ps][ps] supported but not verified; ![fs][fs] verified;

## Status 
This PortableApps project is in beta stage.

## Todo
- [ ] Documentation

## Disclaimer
Draw.io is already Portable right from the bat. This is
only a convenience wrapper for the PortableApps platform.

## Build

### Prerequisites

* [PortableApps.com Launcher](https://portableapps.com/apps/development/portableapps.com_launcher)
* [PortableApps.com Installer](https://portableapps.com/apps/development/portableapps.com_installer)
* [Powershell](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-linux?view=powershell-7)
* [Wine (Linux / MacOS only)](https://www.winehq.org/)

### Build

To build the installer run the following command in the root of the git repository.

```
powershell Other/Update/Update.ps1
```

[nd]: Other/Icons/no_data.svg
[ns]: Other/Icons/no_support.svg
[ps]: Other/Icons/probably_supported.svg
[fs]: Other/Icons/full_support.svg
