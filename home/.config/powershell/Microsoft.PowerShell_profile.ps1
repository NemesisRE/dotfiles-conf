# Set Aliases (need to be first to make completion work)
Set-Alias k -Value kubectl
Set-Alias kns -Value Select-KubeNamespace
Set-Alias kctx -Value Select-KubeContext

Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted

# Set Profile Path
#${PROFILE_PATH} = Split-Path -Path ${PROFILE}
${SCRIPT_PATH} = Split-Path -Parent $MyInvocation.MyCommand.Definition
# Source functions
. "${SCRIPT_PATH}\Profile_Functions.ps1"
. "${SCRIPT_PATH}\Kubectl_Completion.ps1"

${MODULES} = New-Object System.Collections.ArrayList
[Void]${MODULES}.Add("PSReadLine")
[Void]${MODULES}.Add("posh-git")
[Void]${MODULES}.Add("PSFzf")
[Void]${MODULES}.Add("Recycle")
[Void]${MODULES}.Add("Terminal-Icons")
[Void]${MODULES}.Add("PSKubeContext")
[Void]${MODULES}.Add("ZLocation")
[Void]${MODULES}.Add("PoShLog")

if ( ${isWindows} ) {
  ${ENV:PATH} += ";${HOME}\.local\bin"
  ${ENV:NREDF_LRCACHE} = "${ENV:LOCALAPPDATA}\nredf\LRCache"
  [Void]${MODULES}.Add("GuiCompletion")
} elseif ( ${isLinux} ) {
  ${ENV:PATH} += ";${XDG_BIN_HOME}"
  ${ENV:POSH_THEMES_PATH} = "${ENV:XDG_CACHE_HOME}/oh-my-posh/themes"
  ${ENV:NREDF_LRCACHE} = "${ENV:XDG_CACHE_HOME}/nredf/LRCache"
}

if (Test-Path "${SCRIPT_PATH}\Local_Modules.ps1") {
  . "${SCRIPT_PATH}\Local_Modules.ps1"
}

# Load Modules and install if necessary
foreach (${MODULE} in ${MODULES}) {
  UpdateModule ${MODULE}
  LoadModule ${MODULE}
}

# Set Powershell Theme
if (Get-Command oh-my-posh -errorAction SilentlyContinue) {
  oh-my-posh init pwsh --config "${ENV:POSH_THEMES_PATH}\powerlevel10k_rainbow.omp.json" | Invoke-Expression
}

# Set PSReadLine options
Set-PSReadLineOption -PredictionSource History

# Set Keyhandlers
#Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
if ( ${isWindows} ) {
  Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-GuiCompletion }
} elseif ( ${isLinux} ) {
  Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion -CaseInsensitive }
}
Set-PSReadLineKeyHandler -Key Ctrl+d -Function ViExit
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key Alt+d -Function ShellKillWord
Set-PSReadLineKeyHandler -Key Alt+Backspace -Function ShellBackwardKillWord
Set-PSReadLineKeyHandler -Key Alt+q -ScriptBlock { SaveInHistory }

# Produce UTF-8 by default
# https://news.ycombinator.com/item?id=12991690
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

# https://technet.microsoft.com/en-us/magazine/hh241048.aspx
$MaximumHistoryCount = 10000;

# PSFzf settings
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'

# Register Completions
Register-PSKubeContextComplete
