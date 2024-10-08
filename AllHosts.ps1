$Global:psFormatsOptions.HumanizeDate = $true
$Global:psFormatsOptions.HumanizeSize = $true

$Global:GitPromptSettings.DefaultPromptSuffix = '`n$(''>'' * ($nestedPromptLevel + 1)) '
$Global:GitPromptSettings.DefaultPromptAbbreviateHomeDirectory = $true

if(-not (Test-Path $PSScriptRoot\Cache)) {
    New-Item $PSScriptRoot\Cache -ItemType Directory
}

function __UpdateCompletionCache {
    $COM = Get-CimInstance -ClassName Win32_ClassicCOMClassSetting -Filter 'VersionIndependentProgId IS NOT NULL' |
    foreach {
        $progid = $_.VersionIndependentProgId

        if($_.Caption) {
            $caption = $_.Caption
        } else {
            $caption = $progid
        }

        if($_.Description) {
            $description = $_.Description
        } else {
            $description = $progid
        }

        [pscustomobject]@{
            ProgId      = $progid
            Caption     = $caption
            Description = $description
        }
    }

    $Script:CompletionCache = [pscustomobject]@{
        COM = $COM
    }
    $Script:CompletionCache | Export-Clixml $PSScriptRoot\Cache\CompletionCache.ps1xml
}

if(-not (Test-Path $PSScriptRoot\Cache\CompletionCache.ps1xml)) {
    __UpdateCompletionCache
}

$Script:CompletionCache = Import-Clixml $PSScriptRoot\Cache\CompletionCache.ps1xml

Register-ArgumentCompleter -CommandName Register-ArgumentCompleter -ParameterName ParameterName -ScriptBlock {
    param(
        [string]$CommandName,
        [string]$ParameterName,
        [string]$WordToComplete,
        [System.Management.Automation.Language.CommandAst]$CommandAst,
        [System.Collections.IDictionary]$FakeBoundParameters
    )

    if(-not $FakeBoundParameters['CommandName']) {
        return
    }

    $cmd = Get-Command $FakeBoundParameters['CommandName']

    while($cmd.ResolvedCommand -ne $null) { $cmd = $cmd.ResolvedCommand }
    $cmd |
    foreach Parameters |
    foreach Keys |
    where { $_ -like "$WordToComplete*" } |
    foreach {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterName', $_)
    }
}

Register-ArgumentCompleter -CommandName New-Object -ParameterName ComObject -ScriptBlock {
    param(
        [string]$CommandName,
        [string]$ParameterName,
        [string]$WordToComplete,
        [System.Management.Automation.Language.CommandAst]$CommandAst,
        [System.Collections.IDictionary]$FakeBoundParameters
    )
    $Script:CompletionCache.COM |
    where ProgId -like "$WordToComplete*" |
    foreach {
        [System.Management.Automation.CompletionResult]::new($_.ProgId, $_.ProgId, 'Type', $_.Caption)
    }
}

Register-ArgumentCompleter -CommandName Get-Help -ParameterName Parameter -ScriptBlock {
    param(
        [string]$CommandName,
        [string]$ParameterName,
        [string]$WordToComplete,
        [System.Management.Automation.Language.CommandAst]$CommandAst,
        [System.Collections.IDictionary]$FakeBoundParameters
    )
    try {
        $cmd = Get-Command $FakeBoundParameters['Name']
        while($cmd.ResolvedCommand -ne $null) { $cmd = $cmd.ResolvedCommand }
    } catch [System.Management.Automation.CommandNotFoundException] {
        # Most likely the result of a non-command topic (i.e. about_*), just ignore it
        return
    }

    $commonParameters = [System.Management.Automation.Cmdlet]::CommonParameters + [System.Management.Automation.Cmdlet]::OptionalCommonParameters

    $cmd.Parameters.Keys |
    where { $_ -like "$WordToComplete*" -and $_ -notin $commonParameters } |
    foreach {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterName', $_)
    }
}

$Global:PSDefaultParameterValues["Out-File:Encoding"] = 'utf8NoBOM'
# Load rg completions
. "$env:ChocolateyInstall\lib\ripgrep\tools\ripgrep-*\complete\_rg.ps1"
if (Get-Command gh -ErrorAction SilentlyContinue) {
    gh completion -s powershell | Out-String | Invoke-Expression
}
