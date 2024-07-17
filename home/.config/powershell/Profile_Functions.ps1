# Install and Import given module
function LoadModule (${MODULE}) {
  if (Get-Module | Where-Object { $_.Name -eq ${MODULE} }) {
    # If module is already imported say nothing
  } elseif (Get-Module -ListAvailable | Where-Object { $_.Name -eq ${MODULE} }) {
    # If module is not imported, but available on disk then import
    Import-Module ${MODULE}
  } elseif (Find-Module -Name ${MODULE} | Where-Object { $_.Name -eq ${MODULE} }) {
    # If module is not imported, not available on disk, but is in an online gallery then install and import
    Write-Host "Module ${MODULE} will be installed"
    Install-Module -Name ${MODULE} -Force -Scope CurrentUser
    Import-Module ${MODULE}
  } else {
    # If the module is not imported, not available and not in an online gallery then abort
    Write-Host "Module ${MODULE} not imported, not available and not in an online gallery, exiting."
  }
}

function UpdateModule (${MODULE}) {
  if ((Get-Module | Where-Object { $_.Name -eq ${MODULE} }) -or (Get-Module -ListAvailable | Where-Object { $_.Name -eq ${MODULE} })) {
    if (NredfLastRun -CurrentFunction [string]$(Get-PSCallStack)[0].FunctionName + "_" + ${MODULE}) {
      Update-Module -Name ${MODULE}
    }
  }
}

function NredfLastRun {
  param (
    [Parameter(Mandatory=$false)]
    [string] $CurrentFunction,
    [Parameter(Mandatory=$false)]
    [bool] $Success = $false,
    [Parameter(Mandatory=$false)]
    [int] $NextRun = (Get-Date).AddHours(12).Ticks
  )

  if (-not [string]::IsNullOrEmpty($CurrentFunction)) {
    $CurrentFunction
  } elseif (Get-Command Get-PSCallStack -errorAction SilentlyContinue) {
    # Get caller function name (limited to PowerShell v5.1)
    $CurrentFunction = (Get-PSCallStack)[1].FunctionName
  } elseif (Get-Module | Where-Object { $_.Name -eq "PSReadLine"}) {
    $CurrentFunction = (Get-PSReadLineHistory -Count 1).PreviousInputObject.Split(' ')[-2]
  }

  # Create last run cache directory if it doesn't exist
  if (-not (Test-Path -Path ${ENV:NREDF_LRCACHE})) {
    New-Item -Path ${ENV:NREDF_LRCACHE} -ItemType Directory
  }

  # Define last run file path
  $LastRunFile = Join-Path -Path ${ENV:NREDF_LRCACHE} -ChildPath ("last_run_${CurrentFunction}.txt")

  # Get Last Run Time (default 0 if file doesn't exist)
  $LastRun = (Get-Content -Path $LastRunFile -ErrorAction SilentlyContinue | ConvertTo-Int32 -ErrorAction SilentlyContinue) -or 0

  # Check for previous run
  if ($LastRun -gt (Get-Date).Ticks) {
    return 0
  } elseif ($Success) {
    Set-Content -Path $LastRunFile -Value $NextRun
    return 0
  } else {
    return 1
  }
}

# Clear current command line but save in history
function SaveInHistory {
  $LINE = $null
  $CURSOR = $null
  [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]${LINE}, [ref]${CURSOR})
  [Microsoft.PowerShell.PSConsoleReadLine]::AddToHistory(${LINE})
  [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
}

# Compute file hashes - useful for checking successful downloads
function md5 { Get-FileHash -Algorithm MD5 $args }
function sha1 { Get-FileHash -Algorithm SHA1 $args }
function sha256 { Get-FileHash -Algorithm SHA256 $args }

# From https://github.com/Pscx/Pscx
function sudo() { Invoke-Elevated @args }

# Reload profile
function reload() { & ${PROFILE} }
