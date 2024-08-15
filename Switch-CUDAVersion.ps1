# Extended CUDA Version Switcher
# This script automates the process of switching between installed CUDA versions on Windows
# It can be run interactively or with command-line parameters

param(
    [string]$Version,
    [switch]$ListVersions,
    [switch]$GetCurrent
)

# Function to get all installed CUDA versions
function Get-InstalledCUDAVersions {
    $cudaPath = "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA"
    if (Test-Path $cudaPath) {
        return Get-ChildItem $cudaPath -Directory | ForEach-Object { $_.Name }
    }
    return @()
}

# Function to get current CUDA version
function Get-CurrentCUDAVersion {
    $cudaPath = [Environment]::GetEnvironmentVariable("CUDA_PATH", [EnvironmentVariableTarget]::Machine)
    if ($cudaPath) {
        return (Split-Path $cudaPath -Leaf).TrimStart('v')
    }
    return $null
}

# Function to update CUDA_PATH environment variable
function Set-CUDAPath($version) {
    [Environment]::SetEnvironmentVariable("CUDA_PATH", "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v$version", [EnvironmentVariableTarget]::Machine)
    [Environment]::SetEnvironmentVariable("CUDA_PATH_V$($version.Replace('.','_'))", "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v$version", [EnvironmentVariableTarget]::Machine)
}

# Function to update Path environment variable
function Update-PathVariable($version) {
    $path = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
    $newPaths = @(
        "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v$version\bin",
        "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v$version\libnvvp"
    )
    
    # Remove old CUDA paths
    $pathParts = $path -split ';' | Where-Object { $_ -notmatch 'NVIDIA GPU Computing Toolkit\\CUDA' }
    
    # Add new CUDA paths at the beginning
    $newPath = ($newPaths + $pathParts) -join ';'
    
    [Environment]::SetEnvironmentVariable("Path", $newPath, [EnvironmentVariableTarget]::Machine)
}

# Function to switch CUDA version
function Switch-CUDAVersion($version) {
    $installedVersions = Get-InstalledCUDAVersions
    if ($version -in $installedVersions) {
        Set-CUDAPath $version
        Update-PathVariable $version
        Write-Host "CUDA version switched to $version. Please restart your command prompt or applications for the changes to take effect."
    } else {
        Write-Host "Error: CUDA version $version is not installed."
        exit 1
    }
}

# Main script logic
$installedVersions = Get-InstalledCUDAVersions
if ($installedVersions.Count -eq 0) {
    Write-Host "No CUDA versions found. Please install CUDA Toolkit."
    exit 1
}

if ($ListVersions) {
    Write-Host "Installed CUDA versions:"
    $installedVersions | ForEach-Object { Write-Host $_ }
    exit 0
}

if ($GetCurrent) {
    $currentVersion = Get-CurrentCUDAVersion
    if ($currentVersion) {
        Write-Host "Current CUDA version: $currentVersion"
    } else {
        Write-Host "No CUDA version is currently set."
    }
    exit 0
}

if ($Version) {
    Switch-CUDAVersion $Version
} else {
    Write-Host "Available CUDA versions:"
    for ($i = 0; $i -lt $installedVersions.Count; $i++) {
        Write-Host "$($i + 1). $($installedVersions[$i])"
    }

    $selection = Read-Host "Enter the number of the CUDA version you want to switch to"
    $selectedVersion = $installedVersions[$selection - 1]

    if ($selectedVersion) {
        Switch-CUDAVersion $selectedVersion
    } else {
        Write-Host "Invalid selection. No changes made."
        exit 1
    }
}
