<#
.SYNOPSIS
A script to check for and install the tools we need to do nodejs dev work.

.DESCRIPTION
It will install the base applications we always want.
.EXAMPLE
nodeInstall

.NOTES
notes

#>
#Patrick Moon - 2024
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    # orginal: Start-Process -FilePath "powershell" -ArgumentList "-File .\coreSetup.ps1" -Verb RunAs
    # We are not running as administrator, so start a new process with 'RunAs'
    Start-Process powershell.exe "-File",($myinvocation.MyCommand.Definition) -Verb RunAs
    exit
}

# Define the packages to check
$packages = @("OpenJS.NodeJS", "jasongin.nvs")
$global:errors=0;

function Invoke-Sanity-Checks {
    # Check if the script is running in PowerShell
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-Output "This script must be run in PowerShell. Please open PowerShell and run the script again."
        exit
    }

    # Check if winget is installed
    try {
        $wingetCheck = Get-Command winget -ErrorAction Stop
        Write-Host "Winget is installed so we can continue." -ForegroundColor Green
    } catch {
        Write-Host "Winget is either not installed or had an error. This is complicated. Good luck! Hint: check if App Installer is updated in the windows store." -ForegroundColor Red
        exit
    }
}
function CheckWingetUpdate {
    Write-Host "We are going to check if winget is able to update its self".
    $output = & winget update 2>&1

    # Check if the output contains the error message
    if ($output -match "Failed in attempting to update the source: winget") {
        Write-Host "Error: Failed attempting to update winget! Try updating 'App Installer'" -ForegroundColor Red
        $global:errors++
    } else {
        Write-Host "Winget update executed successfully." -ForegroundColor Green
    }
}

function packageInstall {
    param (
        [Parameter(Mandatory=$true)]
        [string]$package
    )

    # Check if the package is installed
    $installed = winget list --id $package

    if ($installed -match "No installed package found matching input criteria.") {
        # If the package is not installed, install it
        Write-Output "$package is not installed. Installing now..."
        winget install --id $package
    } else {
        # If the package is installed, print a message
        Write-Output "$package is already installed."
    }
}

if($global:errors -gt 0) {
    Write-Host "We found an issue so we are stopping until the error is corrected!" -ForegroundColor Red
    exit    
}

foreach ($package in $packages) {
    packageInstall($package)
}
