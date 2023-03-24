Import-Module -Scope Local .\pwsh__Utils\Utils.psm1


enum TaskbarStatuses {
    Reset = 0
    None = 0
    Progress = 1
    Error = 2
    Indeterminate = 3
    Loading = 3
    Warning = 4
}


# https://github.com/microsoft/terminal/issues/6700
# https://conemu.github.io/en/AnsiEscapeCodes.html#ConEmu_specific_OSC
function Set-TerminalTaskbarStatus(
    [Parameter(ParameterSetName = 'default', Position = 0)][TaskbarStatuses]
    $Status = [TaskbarStatuses]::Reset,
    [Parameter(ParameterSetName = 'default', Position = 1)][Alias('Progress')]
    [int] $Percentage = -1,
    [Parameter(ParameterSetName = 'reset')][Parameter(ParameterSetName = 'default', Position = 2)][Alias('Flash')]
    [switch] $Notify = $false,
    [Parameter(ParameterSetName = 'reset')]
    [switch] $Reset
) {
    # bell/flash notification
    if ($Notify) { Write-Host -NoNewline $global:CHAR_BELL }

    # taskbar
    $st = [int] $Status
    $pr = $Percentage
    switch ($Status) {
        { [TaskbarStatuses]::Progress -eq $_ } {
            #if ($pr -notin 0..100) { throw "percentage $pr is not valid with status $Status" }
        }
        { [TaskbarStatuses]::Error, [TaskbarStatuses]::Warning -eq $_ } {
            # "pr is optional" - meaning the status can be switched to Error or Indeterminate,
            #   without altering/knowing the current progress percentage. The same cannot be done when
            #   switching to status Progress (apparently)
            if (-1 -eq $pr) { $pr = '' }
        }
        { [TaskbarStatuses]::Reset, [TaskbarStatuses]::None, [TaskbarStatuses]::Indeterminate -eq $_ } {
            # expect the user to leave -Percentage unaltered...
            if (-1 -ne $pr) { Write-Warning "cannot use -Percentage with status $Status" }
            # but use a non-zero value anyway or else it doesn't work
            # https://github.com/microsoft/terminal/issues/6700#issuecomment-769969473
            $pr = 1
        }
    }
    Write-Host -NoNewline "${global:CHAR_ESCAPE}]9;4;$st;$pr${global:STR_CONEMU_ST}"
}


function Set-TerminalTitle ([string] $Title, [switch] $NoPowershell, [switch] $NoConEmuAnsiEscape) {
    # TODO check out posh-git/WindowTitle
    # powershell ways
    [Console]::Title = $Title
    $Host.UI.RawUI.WindowTitle = $Title
    # conemu compatible terminal way
    if (!$NoConEmuAnsiEscape) {
        # https://learn.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences#window-title
        Write-Host -NoNewline "${global:CHAR_ESCAPE}]0;${Title}${global:STR_CONEMU_ST}"
    }
}

$global:__LockedTerminalTitle = $null
function Lock-TerminalTitle () {
    $global:__LockedTerminalTitle = [Console]::Title
}
function UnLock-TerminalTitle () {
    $global:__LockedTerminalTitle = $null
}


Export-ModuleMember -Function *-*