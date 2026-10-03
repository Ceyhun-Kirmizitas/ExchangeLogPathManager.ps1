<#
.SYNOPSIS
Reviews, compares, and optionally applies supported Exchange Server transport log path settings.

.DESCRIPTION
ExchangeLogPathManager.ps1 is read-only by default.

Running the script without parameters reviews the current supported log path configuration on the local Exchange Mailbox server. It does not prompt for a destination path and it does not change Exchange configuration.

The script has three operating modes:

1. Configuration Review (default)
   - Reviews the local Exchange Mailbox server by default.
   - Use -Server to review one or more Exchange Mailbox servers.
   - Shows current paths, default paths, and Default/Custom/Null classification.
   - No Exchange configuration changes are made.

2. Log Root mode
   - Use -LogRootPath to build a Current -> Proposed plan for higher-growth transport logs.
   - The Exchange directory structure below V15 is preserved under the specified log root.
   - The following paths are included:
     - Message tracking
     - Receive protocol logs
     - Send protocol logs
     - Connectivity logs
   - Agent, Routing, DNS, pipeline tracing, mailbox delivery throttling, and other Reference-only settings are not moved by Log Root mode.
   - -LogRootPath must be a local absolute drive path such as E:\EXCLOG. UNC paths are not accepted.
   - Without -ApplyChanges, this mode is preview-only.

3. Reference mode
   - Use -SourceServer with -TargetServer.
   - The script compares supported log path settings with the source server and builds target proposals using install-path-aware translation.
   - Source default paths are translated to each target server's own Exchange install path.
   - Source custom paths below the source Exchange install path preserve their relative layout below the target Exchange install path.
   - Source custom paths outside the source Exchange install path are proposed literally when they are local absolute drive paths. They remain subject to normal canonical path, target drive existence, DriveType, capability, and policy validation before automatic Apply. Review Only policy items remain Review Only.
   - UNC/network paths and paths whose target drive cannot be verified are never applied automatically.
   - PipelineTracingPath is Review Only and is never changed automatically.
   - Without -ApplyChanges, this mode is read-only.

-ApplyChanges is the explicit change gate. Even when it is used, the script shows the proposal before applying supported changes. PowerShell -WhatIf and -Confirm are also supported.

-OutputFile always takes precedence over -ApplyChanges. When both are supplied the run is read-only and only a report is produced.

Before Apply, the script saves fresh JSON and TXT configuration snapshots under the script folder's ConfigBackups directory. Existing snapshot files are never overwritten. The JSON snapshot is written first and is mandatory.

Immediately before Apply, the script rebuilds the plan from freshly read Exchange values and compares it with the reviewed plan. If anything changed after the proposal was reviewed, no changes are applied.

If Apply fails part way through, the script still performs a fresh verification pass so partial changes are visible.

The script does not create log directories, restart Exchange services, generate rollback commands, or move mailbox databases, mailbox transaction logs, queue database files, queue transaction logs, IIS logs, HttpProxy logs, or diagnostic log folders that do not have a supported Exchange Set-* path property in this scope.

This version supports Exchange Server 2016, Exchange Server 2019, and Exchange Server Subscription Edition Mailbox role servers. Edge Transport is not supported by this script version.

.PARAMETER Server
One or more Exchange Mailbox servers to review or use with -LogRootPath.
If omitted, the local computer is used.

.PARAMETER LogRootPath
Local absolute root path for higher-growth transport logs, for example E:\EXCLOG.
The Exchange directory structure below V15 is preserved under this root.
UNC paths are not accepted.

.PARAMETER SourceServer
Reference Exchange Mailbox server. Valid in Reference mode.

.PARAMETER TargetServer
One or more Exchange Mailbox servers that receive the Reference-mode comparison/proposal.

.PARAMETER ApplyChanges
Explicitly allows the proposed supported changes to be applied.
Without this switch, all modes are read-only.

.PARAMETER OutputFile
Optional TXT report path.
In Configuration Review mode, exports the current configuration.
In Log Root or Reference mode, exports the proposal and planned Exchange PowerShell commands.
An existing file is never overwritten.
-OutputFile does not enable changes and takes precedence over -ApplyChanges.

.PARAMETER NoPaging
Disables console paging and prints continuously.
The startup ENTER confirmation remains enabled.

.PARAMETER Help
Displays a short usage guide and exits without initializing Exchange Management Shell or making changes.

.EXAMPLE
.\ExchangeLogPathManager.ps1
Reviews the supported log path configuration on the local Exchange Mailbox server. No changes are made.

.EXAMPLE
.\ExchangeLogPathManager.ps1 -Server EX01,EX02
Reviews the supported log path configuration on EX01 and EX02. No changes are made.

.EXAMPLE
.\ExchangeLogPathManager.ps1 -OutputFile C:\Temp\ExchangeLogPaths.txt
Reviews the local server and saves the current configuration to a TXT report.

.EXAMPLE
.\ExchangeLogPathManager.ps1 -LogRootPath E:\EXCLOG
Builds a Current -> Proposed plan for higher-growth logs on the local server. No changes are made.

.EXAMPLE
.\ExchangeLogPathManager.ps1 -Server EX01,EX02 -LogRootPath E:\EXCLOG
Builds a Current -> Proposed plan for higher-growth logs on EX01 and EX02. No changes are made.

.EXAMPLE
.\ExchangeLogPathManager.ps1 -Server EX01,EX02 -LogRootPath E:\EXCLOG -ApplyChanges
Shows the proposal and then allows supported changes to be applied to EX01 and EX02.

.EXAMPLE
.\ExchangeLogPathManager.ps1 -SourceServer EX01 -TargetServer EX02,EX03
Compares EX01 with EX02 and EX03 and shows the proposed target configuration. No changes are made.

.EXAMPLE
.\ExchangeLogPathManager.ps1 -SourceServer EX01 -TargetServer EX02,EX03 -ApplyChanges
Shows the Reference-mode proposal and then allows supported changes to be applied to EX02 and EX03.

.EXAMPLE
.\ExchangeLogPathManager.ps1 -SourceServer EX01 -TargetServer EX02 -OutputFile C:\Temp\ExchangeLogPath-Plan.txt
Exports the Reference-mode comparison, proposal, and planned commands. No changes are made.

.EXAMPLE
.\ExchangeLogPathManager.ps1 -NoPaging
Reviews the local server without console paging.

.NOTES
Author        : Ceyhun Kirmizitas
Version       : 1.0
Date          : 03/10/2026
Applies to    : Exchange Server Mailbox servers
Compatibility : Intended for Exchange Server 2016, Exchange Server 2019, and Exchange Server Subscription Edition.
Validated     : Live lab validation performed on Exchange build 15.2.1748.10 (Mailbox role) using Windows PowerShell 5.1.
                Multi-target Apply and partial Apply failure paths were not runtime-validated.
Version gate  : None; no hard Exchange-version gate is enforced.
Shell         : Windows PowerShell 5.1
Mode          : Read-only by default; changes only with -ApplyChanges
Website       : https://ceyhunkirmizitas.net
GitHub        : https://github.com/Ceyhun-Kirmizitas
LinkedIn      : https://www.linkedin.com/in/ceyhun-kirmizitas/

License
-------
MIT License
Copyright (c) 2026 Ceyhun Kirmizitas

Caution
-------
Use this script at your own risk. Review and test it in your environment before production use.
The author is not responsible for any issues, outages, or data loss resulting from its use.

Change Log
----------
1.0 - 03/10/2026
      Initial release of ExchangeLogPathManager.ps1.
      Read-only Configuration Review is the default mode.
      Log Root and Reference modes build a Current -> Proposed plan and change
      configuration only with explicit -ApplyChanges, after a complete Preview
      and confirmation.
      Mailbox-role validation, canonical path handling, and canonical Exchange
      server identity handling: short name, FQDN, and casing resolve to one
      server, so duplicates and source-as-target are blocked.
      Exchange cmdlet and parameter capability preflight per setting.
      Target drive existence, drive type, and free-space checks.
      Configuration Review continues per server when one server cannot be read.
      -OutputFile is read-only, never overwrites an existing report, and takes
      precedence over -ApplyChanges.
      Mandatory JSON pre-change snapshot with a TXT companion under ConfigBackups
      before Apply. Internal snapshot and report writes are not affected by
      -WhatIf or -Confirm, so a snapshot cannot be skipped by a prompt answer.
      Stale-plan drift protection compares the reviewed Set-* operations,
      including current values, with a fresh read and blocks Apply when anything
      changed; the BLOCKER names the changed settings.
      Verification always runs after Apply, also after a partial failure, and an
      Apply summary is shown.
      Console paging keeps headings with their content and grouped Set-* commands
      together. Startup layout, controlled BLOCKER presentation, completion
      wording, and the Feedback / Bugs footer follow ExchangeURLManager.ps1.

.LINK
https://ceyhunkirmizitas.net

.LINK
https://github.com/Ceyhun-Kirmizitas

.LINK
https://www.linkedin.com/in/ceyhun-kirmizitas/
#>

[CmdletBinding(DefaultParameterSetName = 'Review', SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $false, ParameterSetName = 'Review')]
    [Parameter(Mandatory = $false, ParameterSetName = 'LogRoot')]
    [ValidateNotNullOrEmpty()]
    [string[]]$Server,

    [Parameter(Mandatory = $true, ParameterSetName = 'LogRoot')]
    [ValidateNotNullOrEmpty()]
    [string]$LogRootPath,

    [Parameter(Mandatory = $true, ParameterSetName = 'Reference')]
    [ValidateNotNullOrEmpty()]
    [string]$SourceServer,

    [Parameter(Mandatory = $true, ParameterSetName = 'Reference')]
    [ValidateNotNullOrEmpty()]
    [string[]]$TargetServer,

    [Parameter(Mandatory = $false, ParameterSetName = 'LogRoot')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Reference')]
    [switch]$ApplyChanges,

    [Parameter(Mandatory = $false)]
    [string]$OutputFile,

    [Parameter(Mandatory = $false)]
    [switch]$NoPaging,

    [Parameter(Mandatory = $false)]
    [switch]$Help
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$script:ScriptBaseName = 'ExchangeLogPathManager'
$script:ScriptVersion = '1.0'

if ($Help) {
    @"
$($script:ScriptBaseName).ps1
Exchange Server log path configuration manager

COMMON USAGE
  Review the local server (default, read-only):
    .\$($script:ScriptBaseName).ps1

  Review selected servers:
    .\$($script:ScriptBaseName).ps1 -Server EX01,EX02

  Save a configuration review:
    .\$($script:ScriptBaseName).ps1 -OutputFile C:\Temp\ExchangeLogPaths.txt

  Preview a new log root:
    .\$($script:ScriptBaseName).ps1 -LogRootPath E:\EXCLOG

  Preview a new log root on selected servers:
    .\$($script:ScriptBaseName).ps1 -Server EX01,EX02 -LogRootPath E:\EXCLOG

  Apply a new log root:
    .\$($script:ScriptBaseName).ps1 -Server EX01,EX02 -LogRootPath E:\EXCLOG -ApplyChanges

  Compare a reference server with target servers:
    .\$($script:ScriptBaseName).ps1 -SourceServer EX01 -TargetServer EX02,EX03

  Apply a Reference-mode proposal:
    .\$($script:ScriptBaseName).ps1 -SourceServer EX01 -TargetServer EX02,EX03 -ApplyChanges

  Disable console paging:
    .\$($script:ScriptBaseName).ps1 -NoPaging

NOTES
  - Default mode is Configuration Review and makes no Exchange changes.
  - -LogRootPath without -ApplyChanges is preview-only.
  - Reference mode without -ApplyChanges is read-only.
  - Only -ApplyChanges can enable configuration changes.
  - -OutputFile always takes precedence over -ApplyChanges and keeps the run read-only.
  - -OutputFile never overwrites an existing file.
  - PowerShell -WhatIf and -Confirm are supported with -ApplyChanges.
  - -LogRootPath accepts local absolute drive paths only. UNC paths are rejected.
  - Source custom paths outside the source Exchange install path are proposed literally when they are local absolute drive paths. Normal path, drive, capability, and policy validation still applies before Apply.
  - This version supports Mailbox role servers only. Edge Transport is not supported.
  - Console output pauses about once per screen. Press ENTER to continue or Q to exit.
  - Use -NoPaging to print continuously. Paging is also disabled when -OutputFile is used.
  - This script does not create log directories.
  - Full help:
      Get-Help .\$($script:ScriptBaseName).ps1 -Full
"@ | Write-Host
    return
}

# ---------------------------------------------------------------------------
# Run-scoped state
# ---------------------------------------------------------------------------
$script:OutputFileRequested = $false
$script:ApplyIntent = $false

$script:ServerIdentityCache = @{}
$script:InstallPathCache = @{}
$script:DriveInfoCache = @{}
$script:CapabilityMap = @{}


# ---------------------------------------------------------------------------
# Supported log path map
# ---------------------------------------------------------------------------
# MoveInLogRootMode controls the intentionally small default relocation scope.
# Reference mode uses every entry so custom Agent/Routing layouts on an existing
# server can also be reproduced on replacement/new Exchange servers.
$script:LogPathMap = @(
    [PSCustomObject]@{ ServiceKey = 'Transport'; ServiceName = 'Transport Service'; GetCmd = 'Get-TransportService'; SetCmd = 'Set-TransportService'; Property = 'MessageTrackingLogPath'; DefaultKind = 'ExchangeRelative'; DefaultRelative = 'TransportRoles\Logs\MessageTracking'; Policy = 'Apply'; MoveInLogRootMode = $true; ReviewReason = $null },
    [PSCustomObject]@{ ServiceKey = 'Transport'; ServiceName = 'Transport Service'; GetCmd = 'Get-TransportService'; SetCmd = 'Set-TransportService'; Property = 'ConnectivityLogPath'; DefaultKind = 'ExchangeRelative'; DefaultRelative = 'TransportRoles\Logs\Hub\Connectivity'; Policy = 'Apply'; MoveInLogRootMode = $true; ReviewReason = $null },
    [PSCustomObject]@{ ServiceKey = 'Transport'; ServiceName = 'Transport Service'; GetCmd = 'Get-TransportService'; SetCmd = 'Set-TransportService'; Property = 'ReceiveProtocolLogPath'; DefaultKind = 'ExchangeRelative'; DefaultRelative = 'TransportRoles\Logs\Hub\ProtocolLog\SmtpReceive'; Policy = 'Apply'; MoveInLogRootMode = $true; ReviewReason = $null },
    [PSCustomObject]@{ ServiceKey = 'Transport'; ServiceName = 'Transport Service'; GetCmd = 'Get-TransportService'; SetCmd = 'Set-TransportService'; Property = 'SendProtocolLogPath'; DefaultKind = 'ExchangeRelative'; DefaultRelative = 'TransportRoles\Logs\Hub\ProtocolLog\SmtpSend'; Policy = 'Apply'; MoveInLogRootMode = $true; ReviewReason = $null },
    [PSCustomObject]@{ ServiceKey = 'Transport'; ServiceName = 'Transport Service'; GetCmd = 'Get-TransportService'; SetCmd = 'Set-TransportService'; Property = 'AgentLogPath'; DefaultKind = 'ExchangeRelative'; DefaultRelative = 'TransportRoles\Logs\Hub\AgentLog'; Policy = 'Apply'; MoveInLogRootMode = $false; ReviewReason = $null },
    [PSCustomObject]@{ ServiceKey = 'Transport'; ServiceName = 'Transport Service'; GetCmd = 'Get-TransportService'; SetCmd = 'Set-TransportService'; Property = 'RoutingTableLogPath'; DefaultKind = 'ExchangeRelative'; DefaultRelative = 'TransportRoles\Logs\Hub\Routing'; Policy = 'Apply'; MoveInLogRootMode = $false; ReviewReason = $null },
    [PSCustomObject]@{ ServiceKey = 'Transport'; ServiceName = 'Transport Service'; GetCmd = 'Get-TransportService'; SetCmd = 'Set-TransportService'; Property = 'DnsLogPath'; DefaultKind = 'Null'; DefaultRelative = $null; Policy = 'Apply'; MoveInLogRootMode = $false; ReviewReason = $null },
    [PSCustomObject]@{ ServiceKey = 'Transport'; ServiceName = 'Transport Service'; GetCmd = 'Get-TransportService'; SetCmd = 'Set-TransportService'; Property = 'PipelineTracingPath'; DefaultKind = 'ExchangeRelative'; DefaultRelative = 'TransportRoles\Logs\Hub\PipelineTracing'; Policy = 'ReviewOnly'; MoveInLogRootMode = $false; ReviewReason = 'Review Only. Pipeline tracing can capture message content, so this path is reported but is never changed automatically.' },

    [PSCustomObject]@{ ServiceKey = 'FrontEnd'; ServiceName = 'Front End Transport'; GetCmd = 'Get-FrontEndTransportService'; SetCmd = 'Set-FrontEndTransportService'; Property = 'ConnectivityLogPath'; DefaultKind = 'ExchangeRelative'; DefaultRelative = 'TransportRoles\Logs\FrontEnd\Connectivity'; Policy = 'Apply'; MoveInLogRootMode = $true; ReviewReason = $null },
    [PSCustomObject]@{ ServiceKey = 'FrontEnd'; ServiceName = 'Front End Transport'; GetCmd = 'Get-FrontEndTransportService'; SetCmd = 'Set-FrontEndTransportService'; Property = 'ReceiveProtocolLogPath'; DefaultKind = 'ExchangeRelative'; DefaultRelative = 'TransportRoles\Logs\FrontEnd\ProtocolLog\SmtpReceive'; Policy = 'Apply'; MoveInLogRootMode = $true; ReviewReason = $null },
    [PSCustomObject]@{ ServiceKey = 'FrontEnd'; ServiceName = 'Front End Transport'; GetCmd = 'Get-FrontEndTransportService'; SetCmd = 'Set-FrontEndTransportService'; Property = 'SendProtocolLogPath'; DefaultKind = 'ExchangeRelative'; DefaultRelative = 'TransportRoles\Logs\FrontEnd\ProtocolLog\SmtpSend'; Policy = 'Apply'; MoveInLogRootMode = $true; ReviewReason = $null },
    [PSCustomObject]@{ ServiceKey = 'FrontEnd'; ServiceName = 'Front End Transport'; GetCmd = 'Get-FrontEndTransportService'; SetCmd = 'Set-FrontEndTransportService'; Property = 'AgentLogPath'; DefaultKind = 'ExchangeRelative'; DefaultRelative = 'TransportRoles\Logs\FrontEnd\AgentLog'; Policy = 'Apply'; MoveInLogRootMode = $false; ReviewReason = $null },
    [PSCustomObject]@{ ServiceKey = 'FrontEnd'; ServiceName = 'Front End Transport'; GetCmd = 'Get-FrontEndTransportService'; SetCmd = 'Set-FrontEndTransportService'; Property = 'RoutingTableLogPath'; DefaultKind = 'ExchangeRelative'; DefaultRelative = 'TransportRoles\Logs\FrontEnd\Routing'; Policy = 'Apply'; MoveInLogRootMode = $false; ReviewReason = $null },
    [PSCustomObject]@{ ServiceKey = 'FrontEnd'; ServiceName = 'Front End Transport'; GetCmd = 'Get-FrontEndTransportService'; SetCmd = 'Set-FrontEndTransportService'; Property = 'DnsLogPath'; DefaultKind = 'Null'; DefaultRelative = $null; Policy = 'Apply'; MoveInLogRootMode = $false; ReviewReason = $null },

    [PSCustomObject]@{ ServiceKey = 'Mailbox'; ServiceName = 'Mailbox Transport'; GetCmd = 'Get-MailboxTransportService'; SetCmd = 'Set-MailboxTransportService'; Property = 'ConnectivityLogPath'; DefaultKind = 'ExchangeRelative'; DefaultRelative = 'TransportRoles\Logs\Mailbox\Connectivity'; Policy = 'Apply'; MoveInLogRootMode = $true; ReviewReason = $null },
    [PSCustomObject]@{ ServiceKey = 'Mailbox'; ServiceName = 'Mailbox Transport'; GetCmd = 'Get-MailboxTransportService'; SetCmd = 'Set-MailboxTransportService'; Property = 'ReceiveProtocolLogPath'; DefaultKind = 'ExchangeRelative'; DefaultRelative = 'TransportRoles\Logs\Mailbox\ProtocolLog\SmtpReceive'; Policy = 'Apply'; MoveInLogRootMode = $true; ReviewReason = $null },
    [PSCustomObject]@{ ServiceKey = 'Mailbox'; ServiceName = 'Mailbox Transport'; GetCmd = 'Get-MailboxTransportService'; SetCmd = 'Set-MailboxTransportService'; Property = 'SendProtocolLogPath'; DefaultKind = 'ExchangeRelative'; DefaultRelative = 'TransportRoles\Logs\Mailbox\ProtocolLog\SmtpSend'; Policy = 'Apply'; MoveInLogRootMode = $true; ReviewReason = $null },
    [PSCustomObject]@{ ServiceKey = 'Mailbox'; ServiceName = 'Mailbox Transport'; GetCmd = 'Get-MailboxTransportService'; SetCmd = 'Set-MailboxTransportService'; Property = 'MailboxDeliveryAgentLogPath'; DefaultKind = 'ExchangeRelative'; DefaultRelative = 'TransportRoles\Logs\Mailbox\AgentLog\Delivery'; Policy = 'Apply'; MoveInLogRootMode = $false; ReviewReason = $null },
    [PSCustomObject]@{ ServiceKey = 'Mailbox'; ServiceName = 'Mailbox Transport'; GetCmd = 'Get-MailboxTransportService'; SetCmd = 'Set-MailboxTransportService'; Property = 'MailboxSubmissionAgentLogPath'; DefaultKind = 'ExchangeRelative'; DefaultRelative = 'TransportRoles\Logs\Mailbox\AgentLog\Submission'; Policy = 'Apply'; MoveInLogRootMode = $false; ReviewReason = $null },
    [PSCustomObject]@{ ServiceKey = 'Mailbox'; ServiceName = 'Mailbox Transport'; GetCmd = 'Get-MailboxTransportService'; SetCmd = 'Set-MailboxTransportService'; Property = 'RoutingTableLogPath'; DefaultKind = 'ExchangeRelative'; DefaultRelative = 'TransportRoles\Logs\Mailbox\Routing'; Policy = 'Apply'; MoveInLogRootMode = $false; ReviewReason = $null },
    [PSCustomObject]@{ ServiceKey = 'Mailbox'; ServiceName = 'Mailbox Transport'; GetCmd = 'Get-MailboxTransportService'; SetCmd = 'Set-MailboxTransportService'; Property = 'MailboxDeliveryThrottlingLogPath'; DefaultKind = 'ExchangeRelative'; DefaultRelative = 'TransportRoles\Logs\Throttling\Delivery'; Policy = 'Apply'; MoveInLogRootMode = $false; ReviewReason = $null },
    [PSCustomObject]@{ ServiceKey = 'Mailbox'; ServiceName = 'Mailbox Transport'; GetCmd = 'Get-MailboxTransportService'; SetCmd = 'Set-MailboxTransportService'; Property = 'PipelineTracingPath'; DefaultKind = 'ExchangeRelative'; DefaultRelative = 'TransportRoles\Logs\Mailbox\PipelineTracing'; Policy = 'ReviewOnly'; MoveInLogRootMode = $false; ReviewReason = 'Review Only. Pipeline tracing can capture message content, so this path is reported but is never changed automatically.' }
)

# ---------------------------------------------------------------------------
# Generic helpers
# ---------------------------------------------------------------------------
# Set-StrictMode -Version 2.0 throws when a property does not exist, so every
# dynamic property read goes through this accessor.
function Get-ObjectPropertyValue {
    param(
        [Parameter(Mandatory = $true)][AllowNull()]$InputObject,
        [Parameter(Mandatory = $true)][string]$Name
    )


    if ($null -eq $InputObject) { return $null }

    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -eq $property) { return $null }
    return $property.Value
}

function Test-LocalServerName {
    param([AllowNull()][string]$Name)

    if ([string]::IsNullOrWhiteSpace($Name)) { return $false }

    $value = $Name.Trim()
    $localNames = New-Object System.Collections.ArrayList
    [void]$localNames.Add([string]$env:COMPUTERNAME)
    [void]$localNames.Add('localhost')
    [void]$localNames.Add('.')
    if (-not [string]::IsNullOrWhiteSpace($env:USERDNSDOMAIN)) {
        [void]$localNames.Add(("{0}.{1}" -f $env:COMPUTERNAME, $env:USERDNSDOMAIN))
    }

    foreach ($localName in @($localNames)) {
        if (-not [string]::IsNullOrWhiteSpace($localName) -and $localName -ieq $value) { return $true }
    }
    return $false
}

# ---------------------------------------------------------------------------
# Path helpers
# ---------------------------------------------------------------------------
# Path comparisons are canonical and case-insensitive because Windows paths may
# be returned with different casing, a trailing backslash, or relative segments
# even when they identify the same directory. These helpers deliberately do not
# require the path to exist. This script does not create log directories.

# Implementation reference: CK-ELPM-01
function Normalize-PathText {
    param([AllowNull()][string]$Path)


    if ([string]::IsNullOrWhiteSpace($Path)) { return $null }

    $value = $Path.Trim().Replace('/', '\')
    while ($value.Length -gt 3 -and $value.EndsWith('\')) {
        $value = $value.Substring(0, $value.Length - 1)
    }
    return $value
}

# Lexical canonicalization only. [System.IO.Path]::GetFullPath is deliberately
# not used here because it resolves relative input against the process working
# directory, which would silently invent a path on behalf of the operator.
function Resolve-CanonicalLocalPath {
    param(
        [AllowNull()][string]$Path,
        [string]$Label = 'The specified path'
    )

    $result = [PSCustomObject]@{
        IsValid = $false
        Path    = $null
        Drive   = $null
        Reason  = $null
    }

    $value = Normalize-PathText -Path $Path
    if ([string]::IsNullOrWhiteSpace($value)) {
        $result.Reason = "$Label is empty."
        return $result
    }

    if ($value.StartsWith('\\')) {
        $result.Reason = "$Label is a UNC/network path. Only local absolute drive paths are supported."
        return $result
    }

    if ($value -notmatch '^[A-Za-z]:\\') {
        $result.Reason = "$Label is not a local absolute drive path, for example E:\EXCLOG."
        return $result
    }

    $drive = $value.Substring(0, 1).ToUpperInvariant() + ':'
    $remainder = ''
    if ($value.Length -gt 3) { $remainder = $value.Substring(3) }

    if ($remainder -match '[:*?"<>|]') {
        $result.Reason = "$Label contains invalid path characters."
        return $result
    }

    $segments = New-Object System.Collections.ArrayList
    foreach ($segment in @($remainder -split '\\')) {
        $segmentText = [string]$segment
        if ($segmentText.Length -eq 0) { continue }
        if ($segmentText -eq '.') { continue }

        if ($segmentText -match '^\.{3,}$') {
            $result.Reason = "$Label contains an invalid path segment '$segmentText'."
            return $result
        }

        if ($segmentText -eq '..') {
            if ($segments.Count -eq 0) {
                $result.Reason = "$Label navigates above the drive root."
                return $result
            }
            $segments.RemoveAt($segments.Count - 1)
            continue
        }

        if ($segmentText.EndsWith('.') -or $segmentText.EndsWith(' ')) {
            $result.Reason = "$Label contains a path segment that ends with a dot or a space."
            return $result
        }

        [void]$segments.Add($segmentText)
    }

    if ($segments.Count -eq 0) {
        $result.Path = $drive + '\'
    }
    else {
        $result.Path = $drive + '\' + ((@($segments)) -join '\')
    }

    $result.IsValid = $true
    $result.Drive = $drive
    return $result
}

# Canonical form for local drive paths, normalized text for anything else so
# UNC values stay comparable without being treated as local paths.
function ConvertTo-ComparablePath {
    param([AllowNull()][string]$Path)


    $value = Normalize-PathText -Path $Path
    if ([string]::IsNullOrWhiteSpace($value)) { return $null }

    if ($value -match '^[A-Za-z]:\\') {
        $canonical = Resolve-CanonicalLocalPath -Path $value
        if ($canonical.IsValid) { return $canonical.Path }
    }
    return $value
}

# An empty or null relative segment returns the root itself instead of
# throwing, so a setting whose default sits directly on the root is handled.
function Join-PathText {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $false)][AllowNull()][AllowEmptyString()][string]$Relative
    )

    $left = Normalize-PathText -Path $Root
    if ([string]::IsNullOrWhiteSpace($left)) {
        throw 'A root path is required to build a full path.'
    }
    $left = $left.TrimEnd('\')

    $right = ''
    if (-not [string]::IsNullOrWhiteSpace($Relative)) {
        $right = $Relative.Trim().Replace('/', '\').Trim('\')
    }

    if ([string]::IsNullOrEmpty($right)) {
        if ($left.EndsWith(':')) { return ($left + '\') }
        return $left
    }

    if ($left.EndsWith(':')) { return ($left + '\' + $right) }
    return ($left + '\' + $right)
}

# Segment aware containment test. E:\EXCLOGS is never treated as being under
# E:\EXCLOG, and E:\EXCLOG\..\Other is never treated as being under E:\EXCLOG.
function Test-PathUnderRoot {
    param(
        [AllowNull()][string]$Path,
        [Parameter(Mandatory = $true)][string]$Root
    )

    $pathValue = ConvertTo-ComparablePath -Path $Path
    $rootValue = ConvertTo-ComparablePath -Path $Root
    if ([string]::IsNullOrWhiteSpace($pathValue) -or [string]::IsNullOrWhiteSpace($rootValue)) { return $false }

    if ($pathValue.Equals($rootValue, [System.StringComparison]::OrdinalIgnoreCase)) { return $true }

    $rootPrefix = $rootValue
    if (-not $rootPrefix.EndsWith('\')) { $rootPrefix = $rootPrefix + '\' }
    return $pathValue.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)
}

# Returns the portion of Path below Root. An exact match returns an empty
# string, which Join-PathText then resolves back to the target root itself.
function Get-RelativePathUnderRoot {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Root
    )


    $pathValue = ConvertTo-ComparablePath -Path $Path
    $rootValue = ConvertTo-ComparablePath -Path $Root
    if (-not (Test-PathUnderRoot -Path $pathValue -Root $rootValue)) {
        throw "Path '$Path' is not under root '$Root'."
    }

    if ($pathValue.Length -le $rootValue.Length) { return '' }
    return $pathValue.Substring($rootValue.Length).TrimStart('\')
}

# Canonical comparison. Casing, trailing separators, and relative segments
# never cause a false difference or a false match.
function Test-EquivalentPath {
    param(
        [AllowNull()][string]$Left,
        [AllowNull()][string]$Right
    )

    $leftValue = ConvertTo-ComparablePath -Path $Left
    $rightValue = ConvertTo-ComparablePath -Path $Right
    if ($null -eq $leftValue -and $null -eq $rightValue) { return $true }
    if ($null -eq $leftValue -or $null -eq $rightValue) { return $false }
    return $leftValue.Equals($rightValue, [System.StringComparison]::OrdinalIgnoreCase)
}

# Classify the CURRENT configured value against the default path calculated
# from that server's own Exchange install root. This is the key distinction
# that prevents C:-installed and D:-installed Exchange servers from being
# reported as different when both are actually using their defaults.
# Classifies a current value as Default, Custom, or Not configured relative to
# the server's own calculated default path.
function Get-PathClassification {
    param(
        [AllowNull()][string]$CurrentPath,
        [AllowNull()][string]$DefaultPath,
        [Parameter(Mandatory = $true)][ValidateSet('ExchangeRelative','Null')][string]$DefaultKind
    )

    if ($DefaultKind -eq 'Null') {
        if ([string]::IsNullOrWhiteSpace($CurrentPath)) { return 'Default/Null' }
        return 'Custom'
    }

    if ([string]::IsNullOrWhiteSpace($CurrentPath)) { return 'Disabled/Null' }
    if (Test-EquivalentPath -Left $CurrentPath -Right $DefaultPath) { return 'Default' }
    return 'Custom'
}

# A null or empty value is shown explicitly so an unset Exchange path is never
# confused with a blank line in a report.
function ConvertTo-DisplayPath {
    param([AllowNull()][string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) { return '<null>' }
    return $Path
}

function ConvertTo-DisplayProposal {
    param([AllowNull()][string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) { return '<no change proposed>' }
    return $Path
}

# Renders the managed-setting policy in the operator vocabulary used by the
# reports: Apply or Review Only.
function Get-PolicyDisplayText {
    param([AllowNull()][string]$Policy)

    if ([string]::IsNullOrWhiteSpace($Policy)) { return 'Unknown' }
    if ($Policy -eq 'ReviewOnly') { return 'Review Only' }
    return $Policy
}

function ConvertTo-CommandLiteral {
    param([AllowNull()]$Value)

    if ($null -eq $Value) { return '$null' }
    $text = [string]$Value
    return "'$($text.Replace("'", "''"))'"
}
# ---------------------------------------------------------------------------
# Display / paging helpers
# ---------------------------------------------------------------------------
$script:PagingEnabled = $false
$script:PagingInteractive = $false
$script:PagingLineCount = 0
$script:PagingPageHeight = 0
$script:PagingWindowWidth = 120
$script:DisplayStopped = $false

function Test-InteractiveHost {
    try {
        if (-not [Environment]::UserInteractive) { return $false }
        if ([Console]::IsInputRedirected) { return $false }
        return $true
    }
    catch {
        return $false
    }
}

function Initialize-ResultPaging {
    param(
        [switch]$Disabled,
        [switch]$Interactive
    )

    $script:PagingEnabled = $false
    $script:PagingLineCount = 0
    $script:PagingPageHeight = 0
    $script:PagingWindowWidth = 120
    $script:DisplayStopped = $false
    $script:PagingInteractive = [bool]$Interactive

    if ($Disabled -or -not $Interactive) { return }

    try {
        $windowSize = $Host.UI.RawUI.WindowSize
        $height = [int]$windowSize.Height
        $width = [int]$windowSize.Width

        if ($height -ge 10 -and $width -ge 20) {
            $script:PagingPageHeight = [Math]::Max(5, ($height - 3))
            $script:PagingWindowWidth = [Math]::Max(20, $width)
            $script:PagingEnabled = $true
        }
    }
    catch {
        $script:PagingEnabled = $false
    }
}

function Get-ResultDisplayLineCount {
    param([AllowNull()][string]$Text)

    if ([string]::IsNullOrEmpty($Text)) { return 1 }

    $width = [Math]::Max(20, [int]$script:PagingWindowWidth)
    $count = 0
    foreach ($line in @($Text -split "`r`n|`n|`r")) {
        $lineText = [string]$line
        $count += [Math]::Max(1, [int][Math]::Ceiling(($lineText.Length + 1) / [double]$width))
    }
    return $count
}

function New-ResultLine {
    param(
        [AllowNull()][string]$Text = '',
        [string]$Color
    )

    return [PSCustomObject]@{
        Text         = [string]$Text
        Color        = [string]$Color
        KeepWithNext = $false
    }
}

function Write-ConsoleLine {
    param([Parameter(Mandatory = $true)]$Line)

    $text = [string]$Line.Text
    $color = [string]$Line.Color
    if ([string]::IsNullOrEmpty($color)) {
        Write-Host $text
    }
    else {
        Write-Host $text -ForegroundColor $color
    }
}

function Invoke-ResultPagingPause {
    if (-not $script:PagingEnabled) { return }

    Write-Host ''
    $response = Read-Host 'Press ENTER to continue or Q to exit'
    $script:PagingLineCount = 0

    if ([string]$response -match '(?i)^\s*(q|quit|exit)\s*$') {
        $script:PagingEnabled = $false
        $script:DisplayStopped = $true
    }
}

# Logical blocks are measured and written atomically so a related group of
# lines is never split across a paging pause.
function Write-ResultBlock {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][array]$Lines,
        [int]$ReserveLines = 0
    )

    if ($script:DisplayStopped) { return }

    $blockLines = @($Lines | Where-Object { $null -ne $_ })
    if ($blockLines.Count -eq 0) { return }

    if ($script:PagingEnabled) {
        $required = 0
        foreach ($line in $blockLines) {
            $required += Get-ResultDisplayLineCount -Text ([string]$line.Text)
        }

        # ReserveLines keeps a heading on the same page as the block after it.
        # It is capped at one page so an oversized next block cannot loop.
        $reserve = [Math]::Max(0, [Math]::Min([int]$ReserveLines, ([int]$script:PagingPageHeight - $required)))
        if ($script:PagingLineCount -gt 0 -and (($script:PagingLineCount + $required + $reserve) -gt $script:PagingPageHeight)) {
            Invoke-ResultPagingPause
            if ($script:DisplayStopped) { return }
        }
        $script:PagingLineCount += $required
    }

    foreach ($line in $blockLines) {
        Write-ConsoleLine -Line $line
    }
}

function Write-ResultHost {
    param(
        [AllowNull()][string]$Text = '',
        [string]$ForegroundColor
    )

    Write-ResultBlock -Lines @((New-ResultLine -Text $Text -Color $ForegroundColor))
}

# Status, progress, and result messages are never suppressed by paging because
# the operator must always see what the script did.
function Write-StatusHost {
    param(
        [AllowNull()][string]$Text = '',
        [string]$ForegroundColor
    )

    if ([string]::IsNullOrEmpty($ForegroundColor)) {
        Write-Host ([string]$Text)
    }
    else {
        Write-Host ([string]$Text) -ForegroundColor $ForegroundColor
    }
    $script:PagingLineCount += Get-ResultDisplayLineCount -Text ([string]$Text)
}

# ---------------------------------------------------------------------------
# Startup summary and confirmation
# ---------------------------------------------------------------------------
function Get-ModeInfo {
    param(
        [Parameter(Mandatory = $true)][string]$ParameterSetName,
        [switch]$Apply
    )

    switch ($ParameterSetName) {
        'Review' {
            return [PSCustomObject]@{
                Mode         = 'Configuration Review'
                Changes      = 'NONE'
                Description1 = 'The script reads the supported transport log path configuration in this mode.'
                Description2 = 'No Exchange configuration changes will be made.'
            }
        }
        'LogRoot' {
            if ($Apply) {
                return [PSCustomObject]@{
                    Mode         = 'Apply Log Root Changes'
                    Changes      = 'ENABLED'
                    Description1 = 'The script builds a Current -> Proposed log path plan for the specified log root and shows a Preview.'
                    Description2 = 'Apply was explicitly enabled with -ApplyChanges and still requires confirmation and a successful pre-change snapshot.'
                }
            }
            return [PSCustomObject]@{
                Mode         = 'Log Root Preview'
                Changes      = 'NONE'
                Description1 = 'The script builds a Current -> Proposed log path plan for the specified log root.'
                Description2 = 'No Exchange configuration changes will be made. Use -ApplyChanges explicitly to enable Apply.'
            }
        }
        'Reference' {
            if ($Apply) {
                return [PSCustomObject]@{
                    Mode         = 'Apply Reference Changes'
                    Changes      = 'ENABLED'
                    Description1 = 'The script compares the source server with the target server(s) and shows a Preview.'
                    Description2 = 'Apply was explicitly enabled with -ApplyChanges and still requires confirmation and a successful pre-change snapshot.'
                }
            }
            return [PSCustomObject]@{
                Mode         = 'Reference Comparison'
                Changes      = 'NONE'
                Description1 = 'The script compares the source server with the target server(s) and shows the proposal.'
                Description2 = 'No Exchange configuration changes will be made. Use -ApplyChanges explicitly to enable Apply.'
            }
        }
        default {
            return [PSCustomObject]@{
                Mode         = 'Configuration Review'
                Changes      = 'NONE'
                Description1 = 'The script reads the supported transport log path configuration in this mode.'
                Description2 = 'No Exchange configuration changes will be made.'
            }
        }
    }
}

function Show-StartupBanner {
    param(
        [Parameter(Mandatory = $true)][string]$ParameterSetName,
        [switch]$Apply
    )

    $modeInfo = Get-ModeInfo -ParameterSetName $ParameterSetName -Apply:$Apply
    $changesColor = 'Green'
    if ($modeInfo.Changes -ne 'NONE') { $changesColor = 'Yellow' }

    Write-Host ''
    Write-Host ("{0}.ps1" -f $script:ScriptBaseName)
    Write-Host 'Exchange Server transport log path configuration review, comparison, and change manager' -ForegroundColor Cyan
    Write-Host ''
    Write-Host 'Author  : Ceyhun Kirmizitas' -ForegroundColor Cyan
    Write-Host ("Version : {0}" -f $script:ScriptVersion) -ForegroundColor Cyan
    Write-Host ("Mode    : {0}" -f $modeInfo.Mode) -ForegroundColor Cyan
    Write-Host ("Changes : {0}" -f $modeInfo.Changes) -ForegroundColor $changesColor
    Write-Host ''
    Write-Host $modeInfo.Description1
    Write-Host $modeInfo.Description2
    Write-Host ''
    Write-Host 'Compatibility note: Intended for Exchange Server 2016, Exchange Server 2019, and Exchange Server Subscription Edition.' -ForegroundColor Yellow
    Write-Host 'No hard Exchange-version gate is enforced.' -ForegroundColor Yellow
    Write-Host ''
}

function Read-StartupConfirmation {
    while ($true) {
        $response = Read-Host 'Press ENTER to start or Q to exit'
        $text = [string]$response

        if ([string]::IsNullOrWhiteSpace($text)) { return $true }
        if ($text -match '(?i)^\s*(q|quit|exit)\s*$') { return $false }

        Write-Warning 'Press ENTER to start or Q to exit.'
    }
}

# Always shown as the last visible block of a completed run, interactive or
# not, matching ExchangeURLManager.ps1. Not shown for -Help or a startup exit.
function Show-CompletionFooter {
    Write-Host ''
    Write-Host '############################################' -ForegroundColor Cyan
    Write-Host '# Feedback / Bugs' -ForegroundColor Cyan
    Write-Host '############################################' -ForegroundColor Cyan
    Write-Host 'For updates, feedback, bugs, and feature requests:'
    Write-Host 'https://github.com/Ceyhun-Kirmizitas' -ForegroundColor DarkGray
    Write-Host 'https://ceyhunkirmizitas.net' -ForegroundColor DarkGray
    Write-Host '############################################' -ForegroundColor Cyan
}

# ---------------------------------------------------------------------------
# Exchange Management Shell
# ---------------------------------------------------------------------------
# This function must be dot-sourced by the caller so the Microsoft bootstrap
# script is loaded into script scope. StrictMode is disabled only around the
# Microsoft bootstrap sequence and is restored immediately in finally.
# $ErrorActionPreference is deliberately left unchanged.
function Initialize-ExchangeShell {
    if (Get-Command -Name Get-ExchangeServer -ErrorAction SilentlyContinue) { return }

    if ([string]::IsNullOrWhiteSpace($env:ExchangeInstallPath)) {
        throw 'Exchange Management Shell commands were not found. Run this script from the Exchange Management Shell on an Exchange server.'
    }

    $emsBootstrapScript = Join-Path -Path $env:ExchangeInstallPath -ChildPath 'bin\RemoteExchange.ps1'
    if (-not (Test-Path -LiteralPath $emsBootstrapScript -PathType Leaf)) {
        throw 'Exchange Management Shell commands were not found. Run this script from the Exchange Management Shell on an Exchange server.'
    }

    try {
        Set-StrictMode -Off 
        . $emsBootstrapScript
        Connect-ExchangeServer -Auto -AllowClobber | Out-Null
    }
    finally {
        Set-StrictMode -Version 2.0
    }

    if (-not (Get-Command -Name Get-ExchangeServer -ErrorAction SilentlyContinue)) {
        throw 'Exchange Management Shell initialization completed but Get-ExchangeServer is still not available.'
    }
}

# ---------------------------------------------------------------------------
# Exchange cmdlet / parameter capability preflight
# ---------------------------------------------------------------------------
function Resolve-CommandInfo {
    param([Parameter(Mandatory = $true)][string]$Name)

    $found = @(Get-Command -Name $Name -ErrorAction SilentlyContinue)
    if ($found.Count -eq 0) { return $null }

    $resolved = $found[0]
    $guard = 0
    while ($null -ne $resolved -and "$($resolved.CommandType)" -eq 'Alias' -and $guard -lt 10) {
        $next = Get-ObjectPropertyValue -InputObject $resolved -Name 'ResolvedCommand'
        if ($null -eq $next) { break }
        $resolved = $next
        $guard++
    }
    return $resolved
}

function Initialize-ExchangeCapability {
    param([Parameter(Mandatory = $true)][AllowEmptyCollection()][array]$Map)

    $script:CapabilityMap = @{}

    foreach ($entry in $Map) {
        $serviceKey = [string]$entry.ServiceKey
        if ($script:CapabilityMap.ContainsKey($serviceKey)) { continue }

        $getCommand = Resolve-CommandInfo -Name ([string]$entry.GetCmd)
        $setCommand = Resolve-CommandInfo -Name ([string]$entry.SetCmd)

        $setParameters = @{}
        if ($null -ne $setCommand) {
            $parameters = Get-ObjectPropertyValue -InputObject $setCommand -Name 'Parameters'
            if ($null -ne $parameters) {
                foreach ($parameterName in @($parameters.Keys)) {
                    $setParameters[[string]$parameterName] = $true
                }
            }
        }

        $script:CapabilityMap[$serviceKey] = [PSCustomObject]@{
            ServiceKey    = $serviceKey
            ServiceName   = [string]$entry.ServiceName
            GetCmd        = [string]$entry.GetCmd
            SetCmd        = [string]$entry.SetCmd
            GetAvailable  = ($null -ne $getCommand)
            SetAvailable  = ($null -ne $setCommand)
            SetParameters = $setParameters
        }
    }
}

function Test-ServiceFamilyAvailable {
    param([Parameter(Mandatory = $true)][string]$ServiceKey)

    if (-not $script:CapabilityMap.ContainsKey($ServiceKey)) { return $false }
    return [bool]$script:CapabilityMap[$ServiceKey].GetAvailable
}

function Get-ServiceFamilyGetCmd {
    param([Parameter(Mandatory = $true)][string]$ServiceKey)

    if (-not $script:CapabilityMap.ContainsKey($ServiceKey)) { return $ServiceKey }
    return [string]$script:CapabilityMap[$ServiceKey].GetCmd
}

# A missing Set-* cmdlet or a missing parameter downgrades that single setting
# to Review Only. It never aborts the whole run, so Review stays usable on any
# supported Exchange version.
function Test-SettingApplyCapability {
    param(
        [Parameter(Mandatory = $true)][string]$ServiceKey,
        [Parameter(Mandatory = $true)][string]$Property
    )

    if (-not $script:CapabilityMap.ContainsKey($ServiceKey)) {
        return [PSCustomObject]@{
            Supported = $false
            Reason    = 'Exchange cmdlet capability could not be determined for this service. Automatic apply is blocked.'
        }
    }

    $capability = $script:CapabilityMap[$ServiceKey]
    if (-not $capability.SetAvailable) {
        return [PSCustomObject]@{
            Supported = $false
            Reason    = ("{0} is not available in this Exchange Management Shell session. Automatic apply is blocked." -f $capability.SetCmd)
        }
    }

    if (-not $capability.SetParameters.ContainsKey($Property)) {
        return [PSCustomObject]@{
            Supported = $false
            Reason    = ("{0} does not expose a -{1} parameter in this Exchange Management Shell session. Automatic apply is blocked." -f $capability.SetCmd, $Property)
        }
    }

    return [PSCustomObject]@{ Supported = $true; Reason = $null }
}

function Test-CapabilitySupportsConfirm {
    param([Parameter(Mandatory = $true)][string]$ServiceKey)

    if (-not $script:CapabilityMap.ContainsKey($ServiceKey)) { return $false }
    return [bool]$script:CapabilityMap[$ServiceKey].SetParameters.ContainsKey('Confirm')
}

# ---------------------------------------------------------------------------
# Canonical Exchange server identity
# ---------------------------------------------------------------------------
# Short name, FQDN, and alternate casing must all resolve to one canonical
# Exchange server object so the same server is never processed twice and a
# source server can never be silently included in the target list.
function Resolve-ExchangeServerIdentity {
    param([Parameter(Mandatory = $true)][string]$Name)

    $requested = $Name.Trim()
    if ([string]::IsNullOrWhiteSpace($requested)) { throw 'An Exchange server name is required.' }

    $cacheKey = $requested.ToUpperInvariant()
    if ($script:ServerIdentityCache.ContainsKey($cacheKey)) {
        return $script:ServerIdentityCache[$cacheKey]
    }

    $found = $null
    try {
        $found = @(Get-ExchangeServer -Identity $requested -ErrorAction Stop)
    }
    catch {
        throw ("Exchange server '{0}' could not be resolved. {1}" -f $requested, $_.Exception.Message)
    }

    if ($found.Count -ne 1) {
        throw ("Exchange server name '{0}' did not resolve to exactly one Exchange server object." -f $requested)
    }

    $serverObject = $found[0]
    $resolvedName = [string](Get-ObjectPropertyValue -InputObject $serverObject -Name 'Name')
    $fqdn = [string](Get-ObjectPropertyValue -InputObject $serverObject -Name 'Fqdn')
    $distinguishedName = [string](Get-ObjectPropertyValue -InputObject $serverObject -Name 'DistinguishedName')
    $serverRole = [string](Get-ObjectPropertyValue -InputObject $serverObject -Name 'ServerRole')
    $adminDisplayVersion = [string](Get-ObjectPropertyValue -InputObject $serverObject -Name 'AdminDisplayVersion')

    if ([string]::IsNullOrWhiteSpace($resolvedName)) {
        throw ("Exchange server '{0}' did not return a server name." -f $requested)
    }

    $identityKey = $resolvedName.ToUpperInvariant()
    if (-not [string]::IsNullOrWhiteSpace($distinguishedName)) {
        $identityKey = $distinguishedName.ToUpperInvariant()
    }

    # Remote CIM/WMI calls use the FQDN when Exchange knows it, so the lookup
    # does not depend on the DNS suffix search order of the admin host.
    $connectionName = $resolvedName
    if (-not [string]::IsNullOrWhiteSpace($fqdn)) { $connectionName = $fqdn }

    $identity = [PSCustomObject]@{
        InputName           = $requested
        Name                = $resolvedName
        Fqdn                = $fqdn
        DistinguishedName   = $distinguishedName
        ServerRole          = $serverRole
        AdminDisplayVersion = $adminDisplayVersion
        Key                 = $identityKey
        ConnectionName      = $connectionName
        ServerObject        = $serverObject
    }

    $script:ServerIdentityCache[$cacheKey] = $identity

    $nameKey = $resolvedName.ToUpperInvariant()
    if (-not $script:ServerIdentityCache.ContainsKey($nameKey)) {
        $script:ServerIdentityCache[$nameKey] = $identity
    }

    if (-not [string]::IsNullOrWhiteSpace($fqdn)) {
        $fqdnKey = $fqdn.ToUpperInvariant()
        if (-not $script:ServerIdentityCache.ContainsKey($fqdnKey)) {
            $script:ServerIdentityCache[$fqdnKey] = $identity
        }
    }

    return $identity
}

function Assert-MailboxRoleServer {
    param([Parameter(Mandatory = $true)][string]$Server)

    $identity = Resolve-ExchangeServerIdentity -Name $Server
    if ($identity.ServerRole -notmatch '(?i)Mailbox') {
        throw ("Exchange server '{0}' is not a Mailbox role server. Detected role: {1}. This version of {2}.ps1 supports Mailbox role servers only." -f $identity.Name, $identity.ServerRole, $script:ScriptBaseName)
    }
    return $identity
}

function Get-RequestedServerName {
    param([Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]]$Servers)

    $result = New-Object System.Collections.ArrayList
    foreach ($candidate in $Servers) {
        $value = ([string]$candidate).Trim()
        if ([string]::IsNullOrWhiteSpace($value)) { continue }
        [void]$result.Add($value)
    }

    if ($result.Count -eq 0) { throw 'At least one Exchange server name is required.' }
    return @($result)
}

function Get-DuplicateName {
    param([Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]]$Names)

    $seen = @{}
    foreach ($candidate in $Names) {
        $key = ([string]$candidate).ToUpperInvariant()
        if ($seen.ContainsKey($key)) { return [string]$candidate }
        $seen[$key] = $true
    }
    return $null
}

# Never assume C:\Program Files\Microsoft\Exchange Server\V15.
# Exchange can be installed on another drive/path, so read msExchInstallPath
# from the Exchange server object in Active Directory for every server.
function Get-ExchangeInstallPath {
    param([Parameter(Mandatory = $true)]$Identity)

    $cacheKey = [string]$Identity.Key
    if ($script:InstallPathCache.ContainsKey($cacheKey)) { return $script:InstallPathCache[$cacheKey] }

    $distinguishedName = [string]$Identity.DistinguishedName
    if ([string]::IsNullOrWhiteSpace($distinguishedName)) {
        throw ("Unable to determine the Active Directory object for Exchange server '{0}'." -f $Identity.Name)
    }

    $installPath = $null
    try {
        $adsi = [ADSI]("LDAP://{0}" -f $distinguishedName)
        $installPath = [string]$adsi.Properties['msExchInstallPath'].Value
    }
    catch {
        throw ("Unable to read msExchInstallPath for '{0}'. {1}" -f $Identity.Name, $_.Exception.Message)
    }

    if ([string]::IsNullOrWhiteSpace($installPath)) {
        # Local fallback is useful if AD replication has not yet populated the attribute.
        if ((Test-LocalServerName -Name $Identity.Name) -and -not [string]::IsNullOrWhiteSpace($env:ExchangeInstallPath)) {
            $installPath = $env:ExchangeInstallPath
        }
        else {
            throw ("msExchInstallPath is empty for Exchange server '{0}'." -f $Identity.Name)
        }
    }

    $canonical = Resolve-CanonicalLocalPath -Path $installPath -Label ("The Exchange install path for '{0}'" -f $Identity.Name)
    if (-not $canonical.IsValid) {
        throw ("{0} Value: '{1}'." -f $canonical.Reason, $installPath)
    }

    $script:InstallPathCache[$cacheKey] = $canonical.Path
    return $canonical.Path
}

# ---------------------------------------------------------------------------
# Target drive validation
# ---------------------------------------------------------------------------
function New-DriveInfo {
    param(
        [Parameter(Mandatory = $true)][string]$Status,
        [AllowNull()][string]$Drive,
        [AllowNull()]$FreeSpaceGB,
        [AllowNull()]$SizeGB,
        [AllowNull()][string]$Method,
        [AllowNull()]$DriveType
    )

    return [PSCustomObject]@{
        Status      = $Status
        Drive       = $Drive
        FreeSpaceGB = $FreeSpaceGB
        SizeGB      = $SizeGB
        Method      = $Method
        DriveType   = $DriveType
    }
}

# Results are cached for the whole run, keyed by server and drive letter, so
# the pre-Apply drift rebuild reuses the Preview-time result instead of
# producing a false drift blocker because of a transient remoting failure.
function Get-TargetDriveInfo {
    param(
        [Parameter(Mandatory = $true)][string]$Server,
        [AllowNull()][string]$Path,
        [AllowNull()][string]$ConnectionName
    )

    $canonical = Resolve-CanonicalLocalPath -Path $Path
    if (-not $canonical.IsValid) {
        return New-DriveInfo -Status 'NotApplicable' -Drive $null -FreeSpaceGB $null -SizeGB $null -Method $null -DriveType $null
    }

    $drive = [string]$canonical.Drive
    $cacheKey = ("{0}|{1}" -f $Server.ToUpperInvariant(), $drive)
    if ($script:DriveInfoCache.ContainsKey($cacheKey)) { return $script:DriveInfoCache[$cacheKey] }

    $disk = $null
    $method = $null

    # Remote calls prefer the canonical connection name (FQDN when known).
    $remoteName = $Server
    if (-not [string]::IsNullOrWhiteSpace($ConnectionName)) { $remoteName = $ConnectionName.Trim() }
    $isLocal = ((Test-LocalServerName -Name $Server) -or (Test-LocalServerName -Name $remoteName))

    try {
        if ($isLocal) {
            $disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='$drive'" -ErrorAction Stop
            $method = 'Local CIM'
        }
        else {
            $disk = Invoke-Command -ComputerName $remoteName -ArgumentList $drive -ScriptBlock {
                param($RequestedDrive)
                Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='$RequestedDrive'" -ErrorAction Stop
            } -ErrorAction Stop
            $method = 'PowerShell Remoting / CIM'
        }
    }
    catch {
        try {
            $disk = Get-WmiObject -Class Win32_LogicalDisk -ComputerName $remoteName -Filter "DeviceID='$drive'" -ErrorAction Stop
            $method = 'WMI fallback'
        }
        catch {
            $unknown = New-DriveInfo -Status 'Unknown' -Drive $drive -FreeSpaceGB $null -SizeGB $null -Method 'Unavailable' -DriveType $null
            $script:DriveInfoCache[$cacheKey] = $unknown
            return $unknown
        }
    }

    $diskList = @($disk | Where-Object { $null -ne $_ })
    if ($diskList.Count -eq 0) {
        $missing = New-DriveInfo -Status 'Missing' -Drive $drive -FreeSpaceGB $null -SizeGB $null -Method $method -DriveType $null
        $script:DriveInfoCache[$cacheKey] = $missing
        return $missing
    }

    $diskObject = $diskList[0]
    $rawDriveType = Get-ObjectPropertyValue -InputObject $diskObject -Name 'DriveType'
    $rawFreeSpace = Get-ObjectPropertyValue -InputObject $diskObject -Name 'FreeSpace'
    $rawSize = Get-ObjectPropertyValue -InputObject $diskObject -Name 'Size'

    $freeSpaceGB = $null
    if ($null -ne $rawFreeSpace) { $freeSpaceGB = [Math]::Round(([double]$rawFreeSpace / 1GB), 1) }

    $sizeGB = $null
    if ($null -ne $rawSize) { $sizeGB = [Math]::Round(([double]$rawSize / 1GB), 1) }

    $driveType = $null
    if ($null -ne $rawDriveType) { $driveType = [int]$rawDriveType }

    # Win32_LogicalDisk DriveType 3 is a local fixed disk. Anything else is
    # removable, network, optical, or RAM and is never a safe log target.
    $status = 'Available'
    if ($null -ne $driveType -and $driveType -ne 3) { $status = 'NotFixedDisk' }

    $result = New-DriveInfo -Status $status -Drive $drive -FreeSpaceGB $freeSpaceGB -SizeGB $sizeGB -Method $method -DriveType $driveType
    $script:DriveInfoCache[$cacheKey] = $result
    return $result
}

function Get-DriveBlockReason {
    param([Parameter(Mandatory = $true)]$DriveInfo)

    switch ([string]$DriveInfo.Status) {
        'Missing'       { return ("Target drive {0} was not found on the target server. Automatic apply is blocked." -f $DriveInfo.Drive) }
        'Unknown'       { return ("Target drive {0} could not be verified on the target server. Automatic apply is blocked." -f $DriveInfo.Drive) }
        'NotFixedDisk'  { return ("Target drive {0} is not a local fixed disk (DriveType {1}). Automatic apply is blocked." -f $DriveInfo.Drive, $DriveInfo.DriveType) }
        'NotApplicable' { return 'The proposed path is not a local absolute drive path. Automatic apply is blocked.' }
        default         { return $null }
    }
}

function Get-DriveDisplayText {
    param([Parameter(Mandatory = $true)]$Item)

    $status = [string]$Item.DriveStatus
    if ($status -eq 'NotChecked' -or $status -eq 'NotApplicable' -or [string]::IsNullOrWhiteSpace($status)) {
        return $null
    }

    if ($status -eq 'Available') {
        return ("{0} Available, Free {1} GB / {2} GB ({3})" -f $Item.Drive, $Item.FreeSpaceGB, $Item.SizeGB, $Item.DriveCheckMethod)
    }

    return ("{0} {1} ({2})" -f $Item.Drive, $status, $Item.DriveCheckMethod)
}
# ---------------------------------------------------------------------------
# Configuration snapshot
# ---------------------------------------------------------------------------
# A single unreadable service family never aborts the run. The affected
# settings are reported as Unavailable and are excluded from Apply.
function Get-ServerSnapshot {
    param([Parameter(Mandatory = $true)]$Identity)

    $installPath = Get-ExchangeInstallPath -Identity $Identity
    $serverName = [string]$Identity.Name
    $serviceCache = @{}
    $serviceFailure = @{}
    $items = New-Object System.Collections.ArrayList

    foreach ($entry in $script:LogPathMap) {
        $serviceKey = [string]$entry.ServiceKey
        $available = $true
        $unavailableReason = $null
        $serviceObject = $null

        if (-not (Test-ServiceFamilyAvailable -ServiceKey $serviceKey)) {
            $available = $false
            $unavailableReason = ("{0} is not available in this Exchange Management Shell session." -f (Get-ServiceFamilyGetCmd -ServiceKey $serviceKey))
        }
        elseif ($serviceFailure.ContainsKey($serviceKey)) {
            $available = $false
            $unavailableReason = [string]$serviceFailure[$serviceKey]
        }
        else {
            if (-not $serviceCache.ContainsKey($serviceKey)) {
                try {
                    $serviceCache[$serviceKey] = & $entry.GetCmd -Identity $serverName -ErrorAction Stop
                }
                catch {
                    $serviceFailure[$serviceKey] = ("{0} could not be read on '{1}'. {2}" -f $entry.GetCmd, $serverName, $_.Exception.Message)
                    $available = $false
                    $unavailableReason = [string]$serviceFailure[$serviceKey]
                }
            }

            if ($available) { $serviceObject = $serviceCache[$serviceKey] }
        }

        $currentPath = $null
        if ($available -and $null -ne $serviceObject) {
            $propertyInfo = $serviceObject.PSObject.Properties[$entry.Property]
            if ($null -eq $propertyInfo) {
                $available = $false
                $unavailableReason = ("Property '{0}' was not returned by {1} on '{2}'." -f $entry.Property, $entry.GetCmd, $serverName)
            }
            else {
                $rawValue = $propertyInfo.Value
                if ($null -ne $rawValue) {
                    $currentPath = Normalize-PathText -Path ([string]$rawValue)
                }
            }
        }

        $defaultPath = $null
        if ($entry.DefaultKind -ne 'Null') {
            $defaultPath = Join-PathText -Root $installPath -Relative $entry.DefaultRelative
        }

        $classification = 'Unavailable'
        if ($available) {
            $classification = Get-PathClassification -CurrentPath $currentPath -DefaultPath $defaultPath -DefaultKind $entry.DefaultKind
        }

        [void]$items.Add([PSCustomObject]@{
            SettingId         = ("{0}.{1}" -f $entry.ServiceKey, $entry.Property)
            ServiceKey        = $entry.ServiceKey
            ServiceName       = $entry.ServiceName
            GetCmd            = $entry.GetCmd
            SetCmd            = $entry.SetCmd
            Property          = $entry.Property
            DefaultKind       = $entry.DefaultKind
            DefaultRelative   = $entry.DefaultRelative
            Policy            = $entry.Policy
            ReviewReason      = $entry.ReviewReason
            MoveInLogRootMode = $entry.MoveInLogRootMode
            CurrentPath       = $currentPath
            DefaultPath       = $defaultPath
            Classification    = $classification
            Available         = $available
            UnavailableReason = $unavailableReason
        })
    }

    return [PSCustomObject]@{
        Server      = $serverName
        Key         = [string]$Identity.Key
        Identity    = $Identity
        InstallPath = $installPath
        Items       = @($items)
    }
}

function Get-SnapshotItem {
    param(
        [Parameter(Mandatory = $true)]$Snapshot,
        [Parameter(Mandatory = $true)][string]$SettingId
    )

    $item = @($Snapshot.Items | Where-Object { $_.SettingId -eq $SettingId })
    if ($item.Count -ne 1) { throw ("Unable to resolve setting '{0}' on '{1}'." -f $SettingId, $Snapshot.Server) }
    return $item[0]
}

# ---------------------------------------------------------------------------
# Pre-change configuration snapshots
# ---------------------------------------------------------------------------
function Get-SnapshotRootPath {
    $root = $null
    if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) { $root = $PSScriptRoot }
    else { $root = (Get-Location).Path }

    return (Join-Path -Path $root -ChildPath 'ConfigBackups')
}

# The file name is reserved atomically with CreateNew so a parallel run on the
# same server can never overwrite another operator's snapshot.
function New-SnapshotFilePath {
    param(
        [Parameter(Mandatory = $true)][string]$Directory,
        [Parameter(Mandatory = $true)][string]$BaseName,
        [Parameter(Mandatory = $true)][string]$Extension
    )

    if (-not (Test-Path -LiteralPath $Directory -PathType Container)) {
        New-Item -Path $Directory -ItemType Directory -Force -WhatIf:$false -Confirm:$false -ErrorAction Stop | Out-Null
    }

    $suffix = 0
    while ($suffix -lt 50) {
        $candidateName = "$BaseName$Extension"
        if ($suffix -gt 0) { $candidateName = "{0}_{1}{2}" -f $BaseName, $suffix, $Extension }
        $candidate = Join-Path -Path $Directory -ChildPath $candidateName

        $stream = $null
        try {
            $stream = [System.IO.File]::Open($candidate, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
            $stream.Close()
            return [System.IO.Path]::GetFullPath($candidate)
        }
        catch [System.IO.IOException] {
            if ($null -ne $stream) { $stream.Dispose() }
            $suffix++
        }
    }

    throw ("Unable to reserve a unique pre-change snapshot file name in '{0}'." -f $Directory)
}

function Add-LogPathSnapshotLines {
    param(
        [Parameter(Mandatory = $true)][System.Collections.ArrayList]$Lines,
        [Parameter(Mandatory = $true)]$Snapshot,
        [Parameter(Mandatory = $true)][string]$Role
    )

    [void]$Lines.Add(("=== {0}: {1} ===" -f $Role, $Snapshot.Server))
    [void]$Lines.Add(("ExchangeInstallPath = {0}" -f (ConvertTo-DisplayPath -Path $Snapshot.InstallPath)))
    [void]$Lines.Add('')

    foreach ($item in @($Snapshot.Items)) {
        [void]$Lines.Add(("[{0} - {1}]" -f $item.ServiceName, $item.Property))
        [void]$Lines.Add(("Current        = {0}" -f (ConvertTo-DisplayPath -Path $item.CurrentPath)))
        [void]$Lines.Add(("Classification = {0}" -f $item.Classification))
        [void]$Lines.Add(("Default        = {0}" -f (ConvertTo-DisplayPath -Path $item.DefaultPath)))
        [void]$Lines.Add(("Policy         = {0}" -f (Get-PolicyDisplayText -Policy $item.Policy)))
        [void]$Lines.Add(("Readable       = {0}" -f $item.Available))
        if (-not [string]::IsNullOrWhiteSpace($item.UnavailableReason)) {
            [void]$Lines.Add(("Note           = {0}" -f $item.UnavailableReason))
        }
        [void]$Lines.Add('')
    }
}

# Exchange is queried once. Both snapshot files are produced from the same
# in-memory data so the TXT and JSON files can never disagree.
function Get-PreChangeState {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][array]$TargetIdentities,
        [AllowNull()]$SourceIdentity
    )

    $state = New-Object System.Collections.ArrayList

    if ($null -ne $SourceIdentity) {
        [void]$state.Add([PSCustomObject]@{
            Role     = 'SOURCE'
            Snapshot = (Get-ServerSnapshot -Identity $SourceIdentity)
        })
    }

    foreach ($identity in $TargetIdentities) {
        [void]$state.Add([PSCustomObject]@{
            Role     = 'TARGET'
            Snapshot = (Get-ServerSnapshot -Identity $identity)
        })
    }

    return @($state)
}

# The JSON snapshot is mandatory and is written first. The TXT companion is a
# convenience view, so a TXT failure warns but does not block Apply.
function Export-PreChangeSnapshot {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][array]$State,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]]$Targets,
        [AllowNull()][string]$SourceServerName
    )

    $directory = Get-SnapshotRootPath
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $runId = [Guid]::NewGuid().ToString('N').Substring(0, 8)
    $baseName = "{0}_{1}_{2}" -f $script:ScriptBaseName, $timestamp, $runId

    $jsonPath = New-SnapshotFilePath -Directory $directory -BaseName $baseName -Extension '.json'
    $jsonBaseName = [System.IO.Path]::GetFileNameWithoutExtension($jsonPath)

    $snapshotObjects = New-Object System.Collections.ArrayList
    foreach ($entry in $State) {
        [void]$snapshotObjects.Add([PSCustomObject]@{
            Role        = $entry.Role
            Server      = $entry.Snapshot.Server
            InstallPath = $entry.Snapshot.InstallPath
            Items       = @($entry.Snapshot.Items)
        })
    }

    $jsonPayload = [PSCustomObject]@{
        Script       = ("{0}.ps1" -f $script:ScriptBaseName)
        Version      = $script:ScriptVersion
        SnapshotTime = (Get-Date).ToString('o')
        Operator     = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        SourceServer = $SourceServerName
        Targets      = @($Targets)
        Snapshots    = @($snapshotObjects)
    }
    $jsonPayload | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $jsonPath -Encoding UTF8 -WhatIf:$false -Confirm:$false -ErrorAction Stop

    $txtPath = $null
    $txtError = $null
    try {
        $txtPath = New-SnapshotFilePath -Directory $directory -BaseName $jsonBaseName -Extension '.txt'

        $lines = New-Object System.Collections.ArrayList
        [void]$lines.Add('Exchange log path pre-change snapshot')
        [void]$lines.Add(("Script        : {0}.ps1" -f $script:ScriptBaseName))
        [void]$lines.Add(("Version       : {0}" -f $script:ScriptVersion))
        [void]$lines.Add(("Snapshot Time : {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')))
        [void]$lines.Add(("Operator      : {0}" -f [System.Security.Principal.WindowsIdentity]::GetCurrent().Name))
        [void]$lines.Add('Purpose       : Current configuration captured immediately before ApplyChanges')
        [void]$lines.Add(("JSON snapshot : {0}" -f $jsonPath))
        [void]$lines.Add('')

        foreach ($entry in $State) {
            Add-LogPathSnapshotLines -Lines $lines -Snapshot $entry.Snapshot -Role ([string]$entry.Role)
        }

        Set-Content -LiteralPath $txtPath -Value @($lines) -Encoding UTF8 -WhatIf:$false -Confirm:$false -ErrorAction Stop
    }
    catch {
        $txtError = $_.Exception.Message
        $txtPath = $null
    }

    return [PSCustomObject]@{
        JsonPath = $jsonPath
        TxtPath  = $txtPath
        TxtError = $txtError
    }
}

# ---------------------------------------------------------------------------
# Desired configuration
# ---------------------------------------------------------------------------
# Reference mode is semantic, not a literal clone:
#   1. Source Default -> calculate the target's own default path.
#   2. Source Custom inside the source Exchange install path -> preserve the
#      relative layout and rebuild it below the target Exchange install path.
#   3. Source Custom outside the source Exchange install path -> propose the
#      literal source path when it is a local absolute drive path. Canonical
#      path, target drive existence, DriveType, capability, and policy
#      validation still apply before automatic Apply; Review Only policy
#      items remain Review Only.
function Get-ReferenceDesiredPath {
    param(
        [AllowNull()][string]$SourcePath,
        [Parameter(Mandatory = $true)][string]$SourceClassification,
        [Parameter(Mandatory = $true)][string]$SourceInstallPath,
        [Parameter(Mandatory = $true)][string]$TargetInstallPath,
        [Parameter(Mandatory = $true)][ValidateSet('ExchangeRelative','Null')][string]$DefaultKind,
        [AllowNull()][string]$DefaultRelative
    )

    # A null source path is recorded and compared but is never pushed. This is
    # especially important for settings such as DnsLogPath whose product
    # default is $null and whose enabled state is a separate property.
    if ([string]::IsNullOrWhiteSpace($SourcePath)) {
        return [PSCustomObject]@{
            DesiredPath = $null
            Mapping     = 'Not proposed - the source path is null or default-disabled'
            Manage      = $false
            Reason      = 'The source value is null, so no path is proposed for the target.'
        }
    }

    if ($SourceClassification -eq 'Default' -and $DefaultKind -eq 'ExchangeRelative') {
        return [PSCustomObject]@{
            DesiredPath = (Join-PathText -Root $TargetInstallPath -Relative $DefaultRelative)
            Mapping     = 'Source default translated to the target Exchange install path'
            Manage      = $true
            Reason      = $null
        }
    }

    if (Test-PathUnderRoot -Path $SourcePath -Root $SourceInstallPath) {
        $relative = Get-RelativePathUnderRoot -Path $SourcePath -Root $SourceInstallPath
        return [PSCustomObject]@{
            DesiredPath = (Join-PathText -Root $TargetInstallPath -Relative $relative)
            Mapping     = 'Source custom path under the source Exchange install path rebuilt under the target Exchange install path'
            Manage      = $true
            Reason      = $null
        }
    }

    return [PSCustomObject]@{
        DesiredPath = (ConvertTo-ComparablePath -Path $SourcePath)
        Mapping     = 'Literal custom path preserved from source'
        Manage      = $true
        Reason      = $null
    }
}

function New-DesiredItem {
    param(
        [Parameter(Mandatory = $true)]$SettingTemplate,
        [Parameter(Mandatory = $true)]$TargetIdentity,
        [AllowNull()][string]$SourcePath,
        [AllowNull()][string]$SourceClassification,
        [AllowNull()][string]$TargetCurrentPath,
        [AllowNull()][string]$TargetClassification,
        [AllowNull()][string]$DesiredPath,
        [Parameter(Mandatory = $true)][string]$Mapping,
        [Parameter(Mandatory = $true)][bool]$Manage,
        [Parameter(Mandatory = $true)][bool]$Available,
        [AllowNull()][string]$ReviewNote,
        [AllowNull()][string]$TargetPathNote,
        [Parameter(Mandatory = $true)]$DriveInfo
    )

    return [PSCustomObject]@{
        SettingId            = $SettingTemplate.SettingId
        ServiceKey           = $SettingTemplate.ServiceKey
        ServiceName          = $SettingTemplate.ServiceName
        SetCmd               = $SettingTemplate.SetCmd
        Property             = $SettingTemplate.Property
        Policy               = $SettingTemplate.Policy
        TargetIdentity       = $TargetIdentity
        SourcePath           = $SourcePath
        SourceClassification = $SourceClassification
        TargetCurrentPath    = $TargetCurrentPath
        TargetClassification = $TargetClassification
        DesiredPath          = $DesiredPath
        Mapping              = $Mapping
        DriveStatus          = $DriveInfo.Status
        Drive                = $DriveInfo.Drive
        FreeSpaceGB          = $DriveInfo.FreeSpaceGB
        SizeGB               = $DriveInfo.SizeGB
        DriveType            = $DriveInfo.DriveType
        DriveCheckMethod     = $DriveInfo.Method
        Manage               = $Manage
        Available            = $Available
        ReviewNote           = $ReviewNote
        TargetPathNote       = $TargetPathNote
    }
}

# ReviewNote carries the policy/mapping reason and TargetPathNote carries the
# path and drive validation reason. They are kept separate so a drive message
# can never overwrite the reason a setting is Review Only.
function New-ReferenceDesiredConfiguration {
    param(
        [Parameter(Mandatory = $true)]$SourceSnapshot,
        [Parameter(Mandatory = $true)]$TargetSnapshot
    )

    $desiredItems = New-Object System.Collections.ArrayList

    foreach ($sourceItem in $SourceSnapshot.Items) {
        $targetItem = Get-SnapshotItem -Snapshot $TargetSnapshot -SettingId $sourceItem.SettingId

        $available = ([bool]$sourceItem.Available -and [bool]$targetItem.Available)
        $mapping = [PSCustomObject]@{
            DesiredPath = $null
            Mapping     = 'Not evaluated'
            Manage      = $false
            Reason      = $null
        }

        if ($available) {
            $mapping = Get-ReferenceDesiredPath `
                -SourcePath $sourceItem.CurrentPath `
                -SourceClassification $sourceItem.Classification `
                -SourceInstallPath $SourceSnapshot.InstallPath `
                -TargetInstallPath $TargetSnapshot.InstallPath `
                -DefaultKind $sourceItem.DefaultKind `
                -DefaultRelative $sourceItem.DefaultRelative
        }

        $manage = [bool]$mapping.Manage
        $reviewNote = [string]$mapping.Reason
        $targetPathNote = $null
        $driveInfo = New-DriveInfo -Status 'NotChecked' -Drive $null -FreeSpaceGB $null -SizeGB $null -Method $null -DriveType $null

        if (-not [bool]$sourceItem.Available) {
            $manage = $false
            $reviewNote = ("Source value unavailable. {0}" -f $sourceItem.UnavailableReason)
        }
        elseif (-not [bool]$targetItem.Available) {
            $manage = $false
            $reviewNote = ("Target value unavailable. {0}" -f $targetItem.UnavailableReason)
        }
        elseif ($sourceItem.Policy -ne 'Apply') {
            $manage = $false
            if (-not [string]::IsNullOrWhiteSpace($sourceItem.ReviewReason)) {
                $reviewNote = [string]$sourceItem.ReviewReason
            }
            else {
                $reviewNote = 'Review Only. This setting is reported but is never changed automatically.'
            }
        }

        if ($manage) {
            $capability = Test-SettingApplyCapability -ServiceKey $sourceItem.ServiceKey -Property $sourceItem.Property
            if (-not $capability.Supported) {
                $manage = $false
                $reviewNote = [string]$capability.Reason
            }
        }

        $desiredPath = [string]$mapping.DesiredPath
        if (-not [string]::IsNullOrWhiteSpace($desiredPath)) {
            $canonical = Resolve-CanonicalLocalPath -Path $desiredPath -Label 'The proposed path'
            if ($canonical.IsValid) {
                $desiredPath = [string]$canonical.Path
                $driveInfo = Get-TargetDriveInfo -Server $TargetSnapshot.Server -Path $desiredPath -ConnectionName ([string]$TargetSnapshot.Identity.ConnectionName)
                $driveNote = Get-DriveBlockReason -DriveInfo $driveInfo
                if ($null -ne $driveNote) {
                    $manage = $false
                    $targetPathNote = $driveNote
                }
            }
            else {
                $manage = $false
                $targetPathNote = [string]$canonical.Reason
            }
        }

        [void]$desiredItems.Add((New-DesiredItem `
            -SettingTemplate $sourceItem `
            -TargetIdentity $TargetSnapshot.Identity `
            -SourcePath $sourceItem.CurrentPath `
            -SourceClassification $sourceItem.Classification `
            -TargetCurrentPath $targetItem.CurrentPath `
            -TargetClassification $targetItem.Classification `
            -DesiredPath $desiredPath `
            -Mapping ([string]$mapping.Mapping) `
            -Manage $manage `
            -Available $available `
            -ReviewNote $reviewNote `
            -TargetPathNote $targetPathNote `
            -DriveInfo $driveInfo))
    }

    return [PSCustomObject]@{
        Target         = $TargetSnapshot.Server
        TargetIdentity = $TargetSnapshot.Identity
        Items          = @($desiredItems)
    }
}

# LogRoot mode intentionally relocates only entries marked MoveInLogRootMode.
# A root such as E:\EXCLOG becomes:
#   E:\EXCLOG\TransportRoles\Logs\...
function New-LogRootDesiredConfiguration {
    param(
        [Parameter(Mandatory = $true)]$TargetSnapshot,
        [Parameter(Mandatory = $true)][string]$Root
    )

    $desiredItems = New-Object System.Collections.ArrayList

    foreach ($targetItem in @($TargetSnapshot.Items | Where-Object { $_.MoveInLogRootMode })) {
        $available = [bool]$targetItem.Available
        $manage = $available
        $reviewNote = $null
        $targetPathNote = $null
        $desiredPath = $null
        $driveInfo = New-DriveInfo -Status 'NotChecked' -Drive $null -FreeSpaceGB $null -SizeGB $null -Method $null -DriveType $null

        if (-not $available) {
            $manage = $false
            $reviewNote = ("Target value unavailable. {0}" -f $targetItem.UnavailableReason)
        }
        elseif ($targetItem.Policy -ne 'Apply') {
            $manage = $false
            if (-not [string]::IsNullOrWhiteSpace($targetItem.ReviewReason)) {
                $reviewNote = [string]$targetItem.ReviewReason
            }
            else {
                $reviewNote = 'Review Only. This setting is reported but is never changed automatically.'
            }
        }
        elseif ([string]::IsNullOrWhiteSpace($targetItem.DefaultRelative)) {
            $manage = $false
            $reviewNote = 'This setting has no Exchange-relative default layout, so Log Root mode cannot place it automatically.'
        }
        else {
            $desiredPath = Join-PathText -Root $Root -Relative $targetItem.DefaultRelative
        }

        if ($manage) {
            $capability = Test-SettingApplyCapability -ServiceKey $targetItem.ServiceKey -Property $targetItem.Property
            if (-not $capability.Supported) {
                $manage = $false
                $reviewNote = [string]$capability.Reason
            }
        }

        if (-not [string]::IsNullOrWhiteSpace($desiredPath)) {
            $canonical = Resolve-CanonicalLocalPath -Path $desiredPath -Label 'The proposed path'
            if ($canonical.IsValid) {
                $desiredPath = [string]$canonical.Path
                $driveInfo = Get-TargetDriveInfo -Server $TargetSnapshot.Server -Path $desiredPath -ConnectionName ([string]$TargetSnapshot.Identity.ConnectionName)
                $driveNote = Get-DriveBlockReason -DriveInfo $driveInfo
                if ($null -ne $driveNote) {
                    $manage = $false
                    $targetPathNote = $driveNote
                }
            }
            else {
                $manage = $false
                $targetPathNote = [string]$canonical.Reason
            }
        }

        [void]$desiredItems.Add((New-DesiredItem `
            -SettingTemplate $targetItem `
            -TargetIdentity $TargetSnapshot.Identity `
            -SourcePath $null `
            -SourceClassification $null `
            -TargetCurrentPath $targetItem.CurrentPath `
            -TargetClassification $targetItem.Classification `
            -DesiredPath $desiredPath `
            -Mapping 'LogRootPath replaces the Exchange install root through V15; the relative structure is preserved' `
            -Manage $manage `
            -Available $available `
            -ReviewNote $reviewNote `
            -TargetPathNote $targetPathNote `
            -DriveInfo $driveInfo))
    }

    return [PSCustomObject]@{
        Target         = $TargetSnapshot.Server
        TargetIdentity = $TargetSnapshot.Identity
        Items          = @($desiredItems)
    }
}

# ---------------------------------------------------------------------------
# Compare and change plans
# ---------------------------------------------------------------------------
function New-ComparisonPlan {
    param([Parameter(Mandatory = $true)]$DesiredConfiguration)

    $result = New-Object System.Collections.ArrayList

    foreach ($item in $DesiredConfiguration.Items) {
        $status = 'Review Only'
        if (-not $item.Available) {
            $status = 'Unavailable'
        }
        elseif (Test-EquivalentPath -Left $item.TargetCurrentPath -Right $item.DesiredPath) {
            $status = 'Same'
        }
        elseif ($item.Manage) {
            $status = 'Different'
        }

        [void]$result.Add([PSCustomObject]@{
            Target                = $DesiredConfiguration.Target
            ServiceKey            = $item.ServiceKey
            ServiceName           = $item.ServiceName
            Property              = $item.Property
            Policy                = $item.Policy
            SourcePath            = $item.SourcePath
            SourceClassification  = $item.SourceClassification
            CurrentPath           = $item.TargetCurrentPath
            CurrentClassification = $item.TargetClassification
            ProposedPath          = $item.DesiredPath
            Mapping               = $item.Mapping
            DriveStatus           = $item.DriveStatus
            Drive                 = $item.Drive
            FreeSpaceGB           = $item.FreeSpaceGB
            SizeGB                = $item.SizeGB
            DriveType             = $item.DriveType
            DriveCheckMethod      = $item.DriveCheckMethod
            ReviewNote            = $item.ReviewNote
            TargetPathNote        = $item.TargetPathNote
            Status                = $status
        })
    }

    return @($result)
}

function New-ChangePlan {
    param([Parameter(Mandatory = $true)]$DesiredConfiguration)

    $result = New-Object System.Collections.ArrayList

    foreach ($item in $DesiredConfiguration.Items) {
        if (-not $item.Available) { continue }
        if (-not $item.Manage) { continue }
        if (Test-EquivalentPath -Left $item.TargetCurrentPath -Right $item.DesiredPath) { continue }

        [void]$result.Add([PSCustomObject]@{
            Target                = $DesiredConfiguration.Target
            ServiceKey            = $item.ServiceKey
            ServiceName           = $item.ServiceName
            SetCmd                = $item.SetCmd
            Property              = $item.Property
            Policy                = $item.Policy
            SourcePath            = $item.SourcePath
            SourceClassification  = $item.SourceClassification
            CurrentPath           = $item.TargetCurrentPath
            CurrentClassification = $item.TargetClassification
            NewValue              = $item.DesiredPath
            Mapping               = $item.Mapping
            DriveStatus           = $item.DriveStatus
            Drive                 = $item.Drive
            FreeSpaceGB           = $item.FreeSpaceGB
            SizeGB                = $item.SizeGB
            DriveType             = $item.DriveType
            DriveCheckMethod      = $item.DriveCheckMethod
            ReviewNote            = $item.ReviewNote
            TargetPathNote        = $item.TargetPathNote
        })
    }

    return @($result)
}

function New-TargetOperations {
    param(
        [Parameter(Mandatory = $true)][string]$Target,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][array]$Changes
    )

    $operations = New-Object System.Collections.ArrayList
    $changeList = @($Changes)
    if ($changeList.Count -eq 0) { return @($operations) }

    foreach ($serviceKey in @($changeList | ForEach-Object { $_.ServiceKey } | Select-Object -Unique)) {
        $serviceChanges = @($changeList | Where-Object { $_.ServiceKey -eq $serviceKey })
        if ($serviceChanges.Count -eq 0) { continue }

        $params = [ordered]@{ Identity = $Target }
        foreach ($change in $serviceChanges) {
            $params[[string]$change.Property] = $change.NewValue
        }

        [void]$operations.Add([PSCustomObject]@{
            Target      = $Target
            ServiceKey  = $serviceKey
            ServiceName = $serviceChanges[0].ServiceName
            SetCmd      = $serviceChanges[0].SetCmd
            Parameters  = $params
            Changes     = $serviceChanges
        })
    }

    return @($operations)
}

function Get-PlanOperations {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][array]$Changes,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]]$Targets
    )

    $operations = New-Object System.Collections.ArrayList
    foreach ($target in $Targets) {
        $targetChanges = @($Changes | Where-Object { $_.Target -eq $target })
        if ($targetChanges.Count -eq 0) { continue }

        foreach ($operation in @(New-TargetOperations -Target $target -Changes $targetChanges)) {
            [void]$operations.Add($operation)
        }
    }

    return @($operations)
}

# Deterministic signature of exactly what would be executed. It is compared
# immediately before Apply so a plan that went stale after review is blocked.
function Get-OperationSignature {
    param([Parameter(Mandatory = $true)][AllowEmptyCollection()][array]$Operations)

    $entries = New-Object System.Collections.ArrayList

    foreach ($operation in $Operations) {
        $parts = New-Object System.Collections.ArrayList
        [void]$parts.Add(("TARGET={0}" -f ([string]$operation.Target).ToUpperInvariant()))
        [void]$parts.Add(("SERVICE={0}" -f ([string]$operation.ServiceKey).ToUpperInvariant()))
        [void]$parts.Add(("CMD={0}" -f ([string]$operation.SetCmd).ToUpperInvariant()))

        foreach ($key in @($operation.Parameters.Keys | Sort-Object)) {
            $value = $operation.Parameters[$key]
            $valueText = '<null>'
            if ($null -ne $value) { $valueText = ([string]$value).ToUpperInvariant() }
            [void]$parts.Add(("{0}={1}" -f ([string]$key).ToUpperInvariant(), $valueText))
        }

        # Current-state guard. The same Set-* operation with the same desired
        # values is still stale when the value configured on the target changed
        # after Preview, so the comparable current path of every property in the
        # operation is part of the signature as well. Casing and trailing
        # separator differences stay equivalent through ConvertTo-ComparablePath.
        foreach ($change in @($operation.Changes | Sort-Object Property)) {
            $currentValue = ConvertTo-ComparablePath -Path $change.CurrentPath
            $currentText = '<null>'
            if (-not [string]::IsNullOrWhiteSpace($currentValue)) { $currentText = ([string]$currentValue).ToUpperInvariant() }
            [void]$parts.Add(("CURRENT.{0}={1}" -f ([string]$change.Property).ToUpperInvariant(), $currentText))
        }

        [void]$entries.Add((@($parts) -join '|'))
    }

    return ((@($entries) | Sort-Object) -join "`n")
}

# Diagnostic helper for the drift BLOCKER message only. It names the settings
# whose reviewed current/desired values differ from the fresh read. Whether
# Apply may continue is decided by Get-OperationSignature, never by this list.
function Get-DriftChangedSettingName {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][array]$ReviewedChanges,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][array]$FreshChanges
    )

    $reviewed = @{}
    foreach ($change in $ReviewedChanges) {
        $key = "{0} {1}.{2}" -f $change.Target, $change.ServiceKey, $change.Property
        $reviewed[$key] = "{0}|{1}" -f (ConvertTo-DriftValueText -Path $change.CurrentPath), (ConvertTo-DriftValueText -Path $change.NewValue)
    }

    $fresh = @{}
    foreach ($change in $FreshChanges) {
        $key = "{0} {1}.{2}" -f $change.Target, $change.ServiceKey, $change.Property
        $fresh[$key] = "{0}|{1}" -f (ConvertTo-DriftValueText -Path $change.CurrentPath), (ConvertTo-DriftValueText -Path $change.NewValue)
    }

    $names = New-Object System.Collections.ArrayList
    foreach ($key in @(@($reviewed.Keys) + @($fresh.Keys) | Sort-Object -Unique)) {
        if (-not $reviewed.ContainsKey($key) -or -not $fresh.ContainsKey($key) -or $reviewed[$key] -ne $fresh[$key]) {
            [void]$names.Add([string]$key)
        }
    }

    return @($names)
}

function ConvertTo-DriftValueText {
    param([AllowNull()][string]$Path)

    $value = ConvertTo-ComparablePath -Path $Path
    if ([string]::IsNullOrWhiteSpace($value)) { return '<null>' }
    return ([string]$value).ToUpperInvariant()
}
# ---------------------------------------------------------------------------
# Output file handling
# ---------------------------------------------------------------------------
# -OutputFile is strictly non-destructive. An existing file is never
# overwritten and never appended to.
function Resolve-OutputFilePath {
    param([Parameter(Mandatory = $true)][string]$Path)

    $requested = $Path.Trim()
    if ([string]::IsNullOrWhiteSpace($requested)) {
        throw 'BLOCKER: -OutputFile cannot be empty.'
    }

    # Only add .txt when the operator did not supply an extension.
    if ([string]::IsNullOrWhiteSpace([System.IO.Path]::GetExtension($requested))) {
        $requested = "$requested.txt"
    }

    if (-not [System.IO.Path]::IsPathRooted($requested)) {
        $requested = Join-Path -Path (Get-Location).Path -ChildPath $requested
    }

    $fullPath = $null
    try {
        $fullPath = [System.IO.Path]::GetFullPath($requested)
    }
    catch {
        throw ("BLOCKER: -OutputFile '{0}' is not a valid file path. {1}" -f $Path, $_.Exception.Message)
    }

    if (Test-Path -LiteralPath $fullPath -PathType Container) {
        throw ("BLOCKER: -OutputFile '{0}' is an existing directory. Specify a file path." -f $fullPath)
    }

    if (Test-Path -LiteralPath $fullPath -PathType Leaf) {
        throw ("BLOCKER: -OutputFile '{0}' already exists. {1}.ps1 never overwrites or appends to an existing report. Specify a new file name." -f $fullPath, $script:ScriptBaseName)
    }

    $parent = [System.IO.Path]::GetDirectoryName($fullPath)
    if ([string]::IsNullOrWhiteSpace($parent)) {
        throw ("BLOCKER: -OutputFile '{0}' does not resolve to a valid parent directory." -f $fullPath)
    }

    return [PSCustomObject]@{
        Path   = $fullPath
        Parent = $parent
    }
}

function Initialize-OutputFileDirectory {
    param([Parameter(Mandatory = $true)]$OutputTarget)

    if (Test-Path -LiteralPath $OutputTarget.Parent -PathType Container) { return }

    New-Item -Path $OutputTarget.Parent -ItemType Directory -Force -WhatIf:$false -Confirm:$false -ErrorAction Stop | Out-Null
    Write-StatusHost -Text ("Created output directory: {0}" -f $OutputTarget.Parent) -ForegroundColor Yellow
}

function Export-TextReport {
    param(
        [Parameter(Mandatory = $true)]$OutputTarget,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][AllowEmptyString()][string[]]$Lines
    )

    # Defense in depth behind the explicit existence check. Set-Content has no
    # -NoClobber parameter in Windows PowerShell 5.1, so the report is created
    # with CreateNew and written through the same handle. An existing file is
    # never overwritten, and the output stays UTF-8 with BOM and CRLF endings.
    $stream = $null
    try {
        $stream = [System.IO.File]::Open([string]$OutputTarget.Path, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
    }
    catch {
        if (Test-Path -LiteralPath $OutputTarget.Path) {
            throw ("BLOCKER: -OutputFile '{0}' already exists. {1}.ps1 never overwrites or appends to an existing report. Specify a new file name." -f $OutputTarget.Path, $script:ScriptBaseName)
        }
        throw
    }

    try {
        $writer = New-Object System.IO.StreamWriter -ArgumentList @($stream, (New-Object System.Text.UTF8Encoding -ArgumentList $true))
        try {
            foreach ($line in @($Lines)) { $writer.WriteLine([string]$line) }
        }
        finally {
            $writer.Dispose()
        }
    }
    finally {
        $stream.Dispose()
    }
}

# ---------------------------------------------------------------------------
# Report block construction
# ---------------------------------------------------------------------------
# Reports are built once as ordered blocks. The same blocks feed the paged
# console view and the text report, so the console and the file can never
# disagree, and a related group of lines is never split by a paging pause.
function Add-ReportBlock {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][System.Collections.ArrayList]$Blocks,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][array]$Lines,
        [switch]$KeepWithNext
    )

    $blockLines = @($Lines | Where-Object { $null -ne $_ })
    if ($blockLines.Count -eq 0) { return }

    # A heading block is marked so the paged console view keeps it on the same
    # page as the block that follows it. The text report is not affected.
    if ($KeepWithNext) {
        Add-Member -InputObject $blockLines[$blockLines.Count - 1] -NotePropertyName 'KeepWithNext' -NotePropertyValue $true -Force
    }
    [void]$Blocks.Add($blockLines)
}

function Show-ReportBlocks {
    param([Parameter(Mandatory = $true)][AllowEmptyCollection()][array]$Blocks)

    $blockList = @($Blocks)
    for ($index = 0; $index -lt $blockList.Count; $index++) {
        if ($script:DisplayStopped) { return }

        # A chain of heading blocks reserves room for itself and the first
        # content block after it, so a target, server, or service heading is
        # not left alone at the end of a page.
        $reserve = 0
        $nextIndex = $index
        while ((Test-BlockKeepWithNext -Block $blockList[$nextIndex]) -and (($nextIndex + 1) -lt $blockList.Count)) {
            $nextIndex++
            $reserve += Get-BlockDisplayLineCount -Block $blockList[$nextIndex]
        }

        Write-ResultBlock -Lines @($blockList[$index]) -ReserveLines $reserve
    }
}

function Test-BlockKeepWithNext {
    param([AllowNull()]$Block)

    $blockLines = @($Block)
    if ($blockLines.Count -eq 0) { return $false }
    return [bool](Get-ObjectPropertyValue -InputObject $blockLines[$blockLines.Count - 1] -Name 'KeepWithNext')
}

function Get-BlockDisplayLineCount {
    param([AllowNull()]$Block)

    $count = 0
    foreach ($line in @($Block)) {
        if ($null -eq $line) { continue }
        $count += Get-ResultDisplayLineCount -Text ([string]$line.Text)
    }
    return $count
}

function ConvertTo-ReportTextLines {
    param([Parameter(Mandatory = $true)][AllowEmptyCollection()][array]$Blocks)

    $lines = New-Object System.Collections.ArrayList
    foreach ($block in $Blocks) {
        foreach ($line in @($block)) {
            [void]$lines.Add([string]$line.Text)
        }
    }
    return ,@($lines)
}

function Get-ClassificationColor {
    param([AllowNull()][string]$Classification)

    switch ([string]$Classification) {
        'Default'     { return 'Green' }
        'Custom'      { return 'Yellow' }
        'Unavailable' { return 'Red' }
        default       { return 'DarkGray' }
    }
}

function Get-StatusColor {
    param([AllowNull()][string]$Status)

    switch ([string]$Status) {
        'Same'        { return 'Green' }
        'Different'   { return 'Yellow' }
        'Review Only' { return 'Cyan' }
        'Unavailable' { return 'Red' }
        'Verified'    { return 'Green' }
        default       { return 'Red' }
    }
}

function Get-ReportSeparator {
    return ('-' * 78)
}

function Get-OperationCommandText {
    param([Parameter(Mandatory = $true)]$Operation)

    $text = [string]$Operation.SetCmd
    foreach ($key in @($Operation.Parameters.Keys)) {
        $value = $Operation.Parameters[$key]
        if ($null -eq $value) {
            $text = "{0} -{1} `$null" -f $text, $key
        }
        else {
            $text = "{0} -{1} '{2}'" -f $text, $key, (([string]$value).Replace("'", "''"))
        }
    }
    return $text
}

function Get-ReportHeaderBlock {
    param(
        [Parameter(Mandatory = $true)][string]$Title,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]]$Details
    )

    $lines = New-Object System.Collections.ArrayList
    [void]$lines.Add((New-ResultLine -Text ''))
    [void]$lines.Add((New-ResultLine -Text $Title -Color 'Yellow'))
    [void]$lines.Add((New-ResultLine -Text (Get-ReportSeparator) -Color 'DarkGray'))
    foreach ($detail in $Details) {
        if ([string]::IsNullOrWhiteSpace($detail)) { continue }
        [void]$lines.Add((New-ResultLine -Text $detail -Color 'DarkCyan'))
    }
    return ,@($lines)
}

function Get-SnapshotReportBlocks {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][array]$Snapshots,
        [Parameter(Mandatory = $true)][string]$Title
    )

    $blocks = New-Object System.Collections.ArrayList
    Add-ReportBlock -Blocks $blocks -KeepWithNext -Lines (Get-ReportHeaderBlock -Title $Title -Details @(
        ("Script  : {0}.ps1  Version {1}" -f $script:ScriptBaseName, $script:ScriptVersion),
        ("Run time: {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')),
        'Changes : NONE. This view only reads the current configuration.'
    ))

    foreach ($snapshot in $Snapshots) {
        $serverLines = New-Object System.Collections.ArrayList
        [void]$serverLines.Add((New-ResultLine -Text ''))
        [void]$serverLines.Add((New-ResultLine -Text ("Server                : {0}" -f $snapshot.Server) -Color 'Yellow'))
        [void]$serverLines.Add((New-ResultLine -Text ("Exchange install path : {0}" -f (ConvertTo-DisplayPath -Path $snapshot.InstallPath)) -Color 'DarkGray'))
        Add-ReportBlock -Blocks $blocks -Lines $serverLines -KeepWithNext

        foreach ($serviceName in @($snapshot.Items | ForEach-Object { $_.ServiceName } | Select-Object -Unique)) {
            $serviceLines = New-Object System.Collections.ArrayList
            [void]$serviceLines.Add((New-ResultLine -Text ''))
            [void]$serviceLines.Add((New-ResultLine -Text ("  {0}" -f $serviceName) -Color 'Cyan'))
            Add-ReportBlock -Blocks $blocks -Lines $serviceLines -KeepWithNext

            foreach ($item in @($snapshot.Items | Where-Object { $_.ServiceName -eq $serviceName })) {
                $itemLines = New-Object System.Collections.ArrayList
                [void]$itemLines.Add((New-ResultLine -Text ("    {0}" -f $item.Property)))
                [void]$itemLines.Add((New-ResultLine -Text ("      Current        : {0}" -f (ConvertTo-DisplayPath -Path $item.CurrentPath))))
                [void]$itemLines.Add((New-ResultLine -Text ("      Classification : {0}" -f $item.Classification) -Color (Get-ClassificationColor -Classification $item.Classification)))
                [void]$itemLines.Add((New-ResultLine -Text ("      Default        : {0}" -f (ConvertTo-DisplayPath -Path $item.DefaultPath)) -Color 'DarkGray'))
                [void]$itemLines.Add((New-ResultLine -Text ("      Policy         : {0}" -f (Get-PolicyDisplayText -Policy $item.Policy)) -Color 'DarkGray'))

                if ($item.Policy -ne 'Apply' -and -not [string]::IsNullOrWhiteSpace($item.ReviewReason)) {
                    # Policy already says Review Only, so the reason is shown without
                    # repeating that prefix.
                    $reviewText = [string]$item.ReviewReason
                    if ($reviewText.StartsWith('Review Only. ')) { $reviewText = $reviewText.Substring(13) }
                    [void]$itemLines.Add((New-ResultLine -Text ("      Review         : {0}" -f $reviewText) -Color 'Cyan'))
                }
                if (-not [string]::IsNullOrWhiteSpace($item.UnavailableReason)) {
                    [void]$itemLines.Add((New-ResultLine -Text ("      Unavailable    : {0}" -f $item.UnavailableReason) -Color 'Red'))
                }

                Add-ReportBlock -Blocks $blocks -Lines $itemLines
            }
        }
    }

    return ,@($blocks)
}

# Review-mode servers that could not be resolved or read are listed in their
# own block, so the console view and the text report both show them.
function Get-ReviewFailureReportBlocks {
    param([Parameter(Mandatory = $true)][AllowEmptyCollection()][array]$Failures)

    $blocks = New-Object System.Collections.ArrayList
    $failureList = @($Failures)
    if ($failureList.Count -eq 0) { return ,@($blocks) }

    $headerLines = New-Object System.Collections.ArrayList
    [void]$headerLines.Add((New-ResultLine -Text ''))
    [void]$headerLines.Add((New-ResultLine -Text ("Servers not reviewed ({0})" -f $failureList.Count) -Color 'Yellow'))
    [void]$headerLines.Add((New-ResultLine -Text (Get-ReportSeparator) -Color 'DarkGray'))
    Add-ReportBlock -Blocks $blocks -Lines $headerLines -KeepWithNext

    foreach ($failure in $failureList) {
        $failureLines = New-Object System.Collections.ArrayList
        [void]$failureLines.Add((New-ResultLine -Text ("  [{0}]" -f $failure.Server) -Color 'Red'))
        [void]$failureLines.Add((New-ResultLine -Text ("    {0}" -f $failure.Message) -Color 'Red'))
        Add-ReportBlock -Blocks $blocks -Lines $failureLines
    }

    return ,@($blocks)
}

function Get-ProposalReportBlocks {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][array]$Comparisons,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][array]$Operations,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]]$Targets,
        [Parameter(Mandatory = $true)][string]$ModeName,
        [AllowNull()][string]$SourceServerName,
        [AllowNull()][string]$LogRootPathValue,
        [switch]$ApplyRequested,
        [switch]$ForExport
    )

    $blocks = New-Object System.Collections.ArrayList
    $changesText = 'NONE. This is a preview only.'
    if ($ApplyRequested) { $changesText = 'PENDING. Changes are applied only after the confirmation prompt below.' }

    $details = New-Object System.Collections.ArrayList
    [void]$details.Add(("Script  : {0}.ps1  Version {1}" -f $script:ScriptBaseName, $script:ScriptVersion))
    [void]$details.Add(("Run time: {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')))
    [void]$details.Add(("Mode    : {0}" -f $ModeName))
    if (-not [string]::IsNullOrWhiteSpace($SourceServerName)) {
        [void]$details.Add(("Source  : {0}" -f $SourceServerName))
    }
    if (-not [string]::IsNullOrWhiteSpace($LogRootPathValue)) {
        [void]$details.Add(("Log root: {0}" -f (ConvertTo-DisplayPath -Path $LogRootPathValue)))
    }
    [void]$details.Add(("Targets : {0}" -f ((@($Targets)) -join ', ')))
    [void]$details.Add(("Changes : {0}" -f $changesText))

    Add-ReportBlock -Blocks $blocks -KeepWithNext -Lines (Get-ReportHeaderBlock -Title 'Proposed log path configuration' -Details @($details))

    foreach ($target in $Targets) {
        $targetComparisons = @($Comparisons | Where-Object { $_.Target -eq $target })

        $targetLines = New-Object System.Collections.ArrayList
        [void]$targetLines.Add((New-ResultLine -Text ''))
        [void]$targetLines.Add((New-ResultLine -Text ("Target server : {0}" -f $target) -Color 'Yellow'))
        Add-ReportBlock -Blocks $blocks -Lines $targetLines -KeepWithNext

        if ($targetComparisons.Count -eq 0) {
            Add-ReportBlock -Blocks $blocks -Lines @((New-ResultLine -Text '  No managed settings were evaluated for this server.' -Color 'DarkGray'))
            continue
        }

        foreach ($comparison in $targetComparisons) {
            $itemLines = New-Object System.Collections.ArrayList
            [void]$itemLines.Add((New-ResultLine -Text ''))
            [void]$itemLines.Add((New-ResultLine -Text ("  [{0}] {1}" -f $comparison.ServiceName, $comparison.Property) -Color 'Cyan'))

            if (-not [string]::IsNullOrWhiteSpace($SourceServerName)) {
                [void]$itemLines.Add((New-ResultLine -Text ("    Source   : {0}  ({1})" -f (ConvertTo-DisplayPath -Path $comparison.SourcePath), $comparison.SourceClassification)))
            }

            [void]$itemLines.Add((New-ResultLine -Text ("    Current  : {0}  ({1})" -f (ConvertTo-DisplayPath -Path $comparison.CurrentPath), $comparison.CurrentClassification)))
            [void]$itemLines.Add((New-ResultLine -Text ("    Proposed : {0}" -f (ConvertTo-DisplayPath -Path $comparison.ProposedPath))))
            [void]$itemLines.Add((New-ResultLine -Text ("    Status   : {0}" -f $comparison.Status) -Color (Get-StatusColor -Status $comparison.Status)))
            [void]$itemLines.Add((New-ResultLine -Text ("    Mapping  : {0}" -f $comparison.Mapping) -Color 'DarkGray'))

            $driveText = Get-DriveDisplayText -Item $comparison
            if (-not [string]::IsNullOrWhiteSpace($driveText)) {
                $driveColor = 'DarkGray'
                if ($comparison.DriveStatus -ne 'Available') { $driveColor = 'Red' }
                [void]$itemLines.Add((New-ResultLine -Text ("    Drive    : {0}" -f $driveText) -Color $driveColor))
            }

            if (-not [string]::IsNullOrWhiteSpace($comparison.ReviewNote)) {
                [void]$itemLines.Add((New-ResultLine -Text ("    Note     : {0}" -f $comparison.ReviewNote) -Color 'Cyan'))
            }
            if (-not [string]::IsNullOrWhiteSpace($comparison.TargetPathNote)) {
                [void]$itemLines.Add((New-ResultLine -Text ("    Note     : {0}" -f $comparison.TargetPathNote) -Color 'Red'))
            }

            Add-ReportBlock -Blocks $blocks -Lines $itemLines
        }
    }

    $summaryLines = New-Object System.Collections.ArrayList
    [void]$summaryLines.Add((New-ResultLine -Text ''))
    [void]$summaryLines.Add((New-ResultLine -Text 'Summary' -Color 'Yellow'))
    [void]$summaryLines.Add((New-ResultLine -Text (Get-ReportSeparator) -Color 'DarkGray'))
    [void]$summaryLines.Add((New-ResultLine -Text ("  Different   : {0}" -f @($Comparisons | Where-Object { $_.Status -eq 'Different' }).Count) -Color 'Yellow'))
    [void]$summaryLines.Add((New-ResultLine -Text ("  Same        : {0}" -f @($Comparisons | Where-Object { $_.Status -eq 'Same' }).Count) -Color 'Green'))
    [void]$summaryLines.Add((New-ResultLine -Text ("  Review Only : {0}" -f @($Comparisons | Where-Object { $_.Status -eq 'Review Only' }).Count) -Color 'Cyan'))
    [void]$summaryLines.Add((New-ResultLine -Text ("  Unavailable : {0}" -f @($Comparisons | Where-Object { $_.Status -eq 'Unavailable' }).Count) -Color 'Red'))
    Add-ReportBlock -Blocks $blocks -Lines $summaryLines

    # The heading and all grouped Set-* commands form one block, so the command
    # list is not split across a paging pause when it fits on one page.
    $commandLines = New-Object System.Collections.ArrayList
    [void]$commandLines.Add((New-ResultLine -Text ''))
    [void]$commandLines.Add((New-ResultLine -Text 'Commands that would be executed' -Color 'Yellow'))
    [void]$commandLines.Add((New-ResultLine -Text (Get-ReportSeparator) -Color 'DarkGray'))

    $operationCount = @($Operations).Count
    if ($operationCount -eq 0) {
        [void]$commandLines.Add((New-ResultLine -Text '  None. No automatically applicable Exchange configuration changes are required.' -Color 'Green'))
    }
    else {
        foreach ($operation in $Operations) {
            [void]$commandLines.Add((New-ResultLine -Text ("  {0}" -f (Get-OperationCommandText -Operation $operation)) -Color 'Gray'))
        }
    }
    Add-ReportBlock -Blocks $blocks -Lines $commandLines

    # Console completion wording is written once by the main flow. The report
    # only adds the pre-confirmation note before an actionable Apply, or the
    # apply hint in an exported report that contains commands.
    $footerLines = New-Object System.Collections.ArrayList
    if ($operationCount -gt 0 -and $ApplyRequested) {
        [void]$footerLines.Add((New-ResultLine -Text ''))
        [void]$footerLines.Add((New-ResultLine -Text 'Review the proposal above. Nothing has been changed yet.' -Color 'Yellow'))
        [void]$footerLines.Add((New-ResultLine -Text ("{0}.ps1 does not create log directories. Create and secure the target directories according to your own standards." -f $script:ScriptBaseName) -Color 'DarkCyan'))
    }
    elseif ($operationCount -gt 0 -and $ForExport) {
        [void]$footerLines.Add((New-ResultLine -Text ''))
        [void]$footerLines.Add((New-ResultLine -Text 'No changes were made. To apply this proposal, run the same command with -ApplyChanges and without -OutputFile.' -Color 'Green'))
    }
    if ($footerLines.Count -gt 0) {
        Add-ReportBlock -Blocks $blocks -Lines $footerLines
    }

    return ,@($blocks)
}

# ---------------------------------------------------------------------------
# Apply and verification
# ---------------------------------------------------------------------------
# Defense in depth. Even if a future caller reaches this function directly,
# it refuses to run without an explicit apply intent, and it always refuses
# to run in the read-only -OutputFile reporting mode.
function Invoke-ConfigurationPlan {
    param([Parameter(Mandatory = $true)][AllowEmptyCollection()][array]$Operations)

    if (-not $script:ApplyIntent) {
        throw 'BLOCKER: An Exchange configuration change was requested without an explicit -ApplyChanges intent. No changes were made.'
    }
    if ($script:OutputFileRequested) {
        throw 'BLOCKER: -OutputFile is a read-only reporting mode and can never apply changes. No changes were made.'
    }

    foreach ($operation in $Operations) {
        $splat = [ordered]@{}
        foreach ($key in @($operation.Parameters.Keys)) {
            $splat[$key] = $operation.Parameters[$key]
        }
        $splat['ErrorAction'] = 'Stop'

        # Confirm is suppressed only where the cmdlet actually exposes it, and
        # only at invoke time, so the exported command text stays readable.
        if (Test-CapabilitySupportsConfirm -ServiceKey ([string]$operation.ServiceKey)) {
            $splat['Confirm'] = $false
        }

        Write-StatusHost -Text ("  {0}" -f (Get-OperationCommandText -Operation $operation)) -ForegroundColor Gray
        & $operation.SetCmd @splat
    }
}

# Verification must never mask an apply failure. A server or setting that
# cannot be re-read is reported as Verification Failed, not as success.
function Test-ConfigurationPlan {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][array]$Changes,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][array]$TargetIdentities
    )

    $results = New-Object System.Collections.ArrayList

    foreach ($identity in $TargetIdentities) {
        $targetName = [string]$identity.Name
        $targetChanges = @($Changes | Where-Object { $_.Target -eq $targetName })
        if ($targetChanges.Count -eq 0) { continue }

        $snapshot = $null
        $snapshotError = $null
        try {
            $snapshot = Get-ServerSnapshot -Identity $identity
        }
        catch {
            $snapshotError = $_.Exception.Message
        }

        foreach ($change in $targetChanges) {
            $status = 'Verification Failed'
            $actualPath = $null
            $detail = $snapshotError

            if ($null -ne $snapshot) {
                try {
                    $item = Get-SnapshotItem -Snapshot $snapshot -SettingId ("{0}.{1}" -f $change.ServiceKey, $change.Property)
                    if (-not $item.Available) {
                        $detail = [string]$item.UnavailableReason
                    }
                    else {
                        $actualPath = $item.CurrentPath
                        $detail = $null
                        if (Test-EquivalentPath -Left $actualPath -Right $change.NewValue) { $status = 'Verified' }
                        else {
                            $status = 'Mismatch'
                            $detail = 'The value read back from Exchange does not match the applied value.'
                        }
                    }
                }
                catch {
                    $detail = $_.Exception.Message
                }
            }

            [void]$results.Add([PSCustomObject]@{
                Target      = $targetName
                ServiceName = $change.ServiceName
                Property    = $change.Property
                Expected    = $change.NewValue
                Actual      = $actualPath
                Status      = $status
                Detail      = $detail
            })
        }
    }

    return ,@($results)
}

function Show-Verification {
    param([Parameter(Mandatory = $true)][AllowEmptyCollection()][array]$Results)

    Write-StatusHost -Text ''
    Write-StatusHost -Text 'Verification' -ForegroundColor Yellow
    Write-StatusHost -Text (Get-ReportSeparator) -ForegroundColor DarkGray

    $resultList = @($Results)
    if ($resultList.Count -eq 0) {
        Write-StatusHost -Text '  No applied change required verification.' -ForegroundColor DarkGray
        return $true
    }

    $allVerified = $true
    foreach ($result in $resultList) {
        if ($result.Status -ne 'Verified') { $allVerified = $false }

        Write-StatusHost -Text ("  [{0}] {1} - {2}" -f $result.Target, $result.ServiceName, $result.Property)
        Write-StatusHost -Text ("    Expected : {0}" -f (ConvertTo-DisplayPath -Path $result.Expected))
        Write-StatusHost -Text ("    Actual   : {0}" -f (ConvertTo-DisplayPath -Path $result.Actual))
        Write-StatusHost -Text ("    Status   : {0}" -f $result.Status) -ForegroundColor (Get-StatusColor -Status $result.Status)
        if (-not [string]::IsNullOrWhiteSpace($result.Detail)) {
            Write-StatusHost -Text ("    Detail   : {0}" -f $result.Detail) -ForegroundColor Red
        }
    }

    return $allVerified
}
# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
# Set before try. $interactive drives the startup prompt and paging;
# ApplyStarted lets the catch block decide whether the "no changes" line is
# accurate.
$interactive = Test-InteractiveHost
$script:ApplyStarted = $false

try {
    $script:OutputFileRequested = (-not [string]::IsNullOrWhiteSpace($OutputFile))
    $script:ApplyIntent = ([bool]$ApplyChanges -and -not $script:OutputFileRequested)

    $parameterSetName = [string]$PSCmdlet.ParameterSetName
    if ($parameterSetName -ne 'Review' -and $parameterSetName -ne 'LogRoot' -and $parameterSetName -ne 'Reference') {
        throw ("BLOCKER: Unsupported parameter combination (parameter set '{0}')." -f $parameterSetName)
    }

    Show-StartupBanner -ParameterSetName $parameterSetName -Apply:$script:ApplyIntent

    # -OutputFile always wins over -ApplyChanges. The operator is told clearly
    # that the run has become read-only.
    $outputTarget = $null
    if ($script:OutputFileRequested) {
        if ($ApplyChanges) {
            Write-StatusHost -Text 'NOTICE: -OutputFile takes precedence over -ApplyChanges.' -ForegroundColor Yellow
            Write-StatusHost -Text '        This run is read-only. No Exchange configuration change will be made.' -ForegroundColor Yellow
            Write-StatusHost -Text ''
        }
        $outputTarget = Resolve-OutputFilePath -Path $OutputFile
        Initialize-OutputFileDirectory -OutputTarget $outputTarget
    }

    # Reference mode takes its targets from -TargetServer. Review and Log Root
    # mode take them from -Server and fall back to the local computer.
    $requestedTargets = $null
    if ($parameterSetName -eq 'Reference') {
        $requestedTargets = Get-RequestedServerName -Servers $TargetServer
    }
    elseif ($null -ne $Server -and @($Server).Count -gt 0) {
        $requestedTargets = Get-RequestedServerName -Servers $Server
    }
    else {
        $requestedTargets = @([string]$env:COMPUTERNAME)
    }

    $duplicateRawName = Get-DuplicateName -Names $requestedTargets
    if ($null -ne $duplicateRawName) {
        if ($parameterSetName -eq 'Review') {
            Write-StatusHost -Text ("NOTICE: Duplicate target server entry '{0}' was ignored." -f $duplicateRawName) -ForegroundColor Yellow
        }
        else {
            throw ("BLOCKER: Target server '{0}' was specified more than once. Remove the duplicate entry before requesting a change." -f $duplicateRawName)
        }
    }

    if ($parameterSetName -eq 'Reference') {
        if ([string]::IsNullOrWhiteSpace($SourceServer)) {
            throw 'BLOCKER: -SourceServer is required when comparing against a reference server.'
        }

        $sourceRawName = $SourceServer.Trim()
        foreach ($requestedName in $requestedTargets) {
            if ($requestedName.ToUpperInvariant() -eq $sourceRawName.ToUpperInvariant()) {
                throw ("BLOCKER: The source server '{0}' also appears in the target list. A server can never be both source and target in the same run." -f $sourceRawName)
            }
        }
    }

    $logRootCanonicalPath = $null
    if ($parameterSetName -eq 'LogRoot') {
        if ([string]::IsNullOrWhiteSpace($LogRootPath)) {
            throw 'BLOCKER: -LogRootPath is required in log root mode.'
        }

        $canonicalRoot = Resolve-CanonicalLocalPath -Path $LogRootPath -Label 'The -LogRootPath value'
        if (-not $canonicalRoot.IsValid) {
            throw ("BLOCKER: {0} Value: '{1}'." -f $canonicalRoot.Reason, $LogRootPath)
        }

        $logRootCanonicalPath = [string]$canonicalRoot.Path
        if ($logRootCanonicalPath -match '^[A-Za-z]:\\?$') {
            Write-StatusHost -Text ("NOTICE: -LogRootPath '{0}' is a bare drive root. The proposed layout places the Exchange-relative log structure directly below the drive root, for example {1}." -f $logRootCanonicalPath, (Join-PathText -Root $logRootCanonicalPath -Relative 'TransportRoles\Logs\MessageTracking')) -ForegroundColor Yellow
        }
    }

    if ($interactive -and -not $script:OutputFileRequested) {
        if (-not (Read-StartupConfirmation)) {
            # Clean exit before the Exchange Management Shell is loaded.
            Write-Host ''
            Write-Host 'Exiting. No changes were made.' -ForegroundColor DarkCyan
            return
        }
    }

    Initialize-ResultPaging -Disabled:([bool]$NoPaging -or $script:OutputFileRequested) -Interactive:$interactive

    Write-StatusHost -Text ''
    Write-StatusHost -Text 'Connecting to the Exchange Management Shell...' -ForegroundColor DarkCyan
    . Initialize-ExchangeShell
    Initialize-ExchangeCapability -Map $script:LogPathMap

    Write-StatusHost -Text 'Reading current Exchange values... This may take a while. Please wait.' -ForegroundColor DarkCyan

    # Short name, FQDN, and alternate casing all collapse to one canonical
    # Exchange server identity before anything else happens.
    # Review mode is isolated per server: a server that cannot be resolved or
    # read is reported and skipped so the remaining servers are still reviewed.
    # Change modes keep failing fast, because a partial target list must never
    # lead to a partial Apply.
    $reviewFailures = New-Object System.Collections.ArrayList

    $targetIdentities = New-Object System.Collections.ArrayList
    $seenTargetKeys = @{}
    foreach ($requestedName in $requestedTargets) {
        $identity = $null
        try {
            $identity = Assert-MailboxRoleServer -Server $requestedName
        }
        catch {
            if ($parameterSetName -ne 'Review') { throw }
            [void]$reviewFailures.Add([PSCustomObject]@{ Server = $requestedName; Message = $_.Exception.Message })
            Write-StatusHost -Text ("WARNING: [{0}] Review skipped. {1}" -f $requestedName, $_.Exception.Message) -ForegroundColor Yellow
            continue
        }

        if ($seenTargetKeys.ContainsKey($identity.Key)) {
            if ($parameterSetName -eq 'Review') {
                Write-StatusHost -Text ("NOTICE: '{0}' resolves to Exchange server '{1}', which is already in the list. The duplicate was ignored." -f $requestedName, $identity.Name) -ForegroundColor Yellow
                continue
            }
            throw ("BLOCKER: Target '{0}' resolves to Exchange server '{1}', which is already in the target list. Remove the duplicate entry before requesting a change." -f $requestedName, $identity.Name)
        }

        $seenTargetKeys[$identity.Key] = $true
        [void]$targetIdentities.Add($identity)
    }

    $targetIdentityList = @($targetIdentities)
    $targetNames = @($targetIdentityList | ForEach-Object { [string]$_.Name })

    $sourceIdentity = $null
    $sourceName = $null
    if ($parameterSetName -eq 'Reference') {
        $sourceIdentity = Assert-MailboxRoleServer -Server $SourceServer
        $sourceName = [string]$sourceIdentity.Name

        if ($seenTargetKeys.ContainsKey($sourceIdentity.Key)) {
            throw ("BLOCKER: Source server '{0}' resolves to the same Exchange server as one of the targets. A server can never be both source and target in the same run." -f $sourceIdentity.Name)
        }
    }

    $sourceSnapshot = $null
    if ($null -ne $sourceIdentity) {
        $sourceSnapshot = Get-ServerSnapshot -Identity $sourceIdentity
    }

    $targetSnapshots = New-Object System.Collections.ArrayList
    foreach ($identity in $targetIdentityList) {
        try {
            [void]$targetSnapshots.Add((Get-ServerSnapshot -Identity $identity))
        }
        catch {
            if ($parameterSetName -ne 'Review') { throw }
            [void]$reviewFailures.Add([PSCustomObject]@{ Server = [string]$identity.Name; Message = $_.Exception.Message })
            Write-StatusHost -Text ("WARNING: [{0}] Review skipped. {1}" -f $identity.Name, $_.Exception.Message) -ForegroundColor Yellow
        }
    }
    $targetSnapshotList = @($targetSnapshots)
    $reviewFailureList = @($reviewFailures)

    # -----------------------------------------------------------------------
    # Review mode. Read-only end to end.
    # -----------------------------------------------------------------------
    if ($parameterSetName -eq 'Review') {
        if ($targetSnapshotList.Count -eq 0) {
            throw 'BLOCKER: Configuration Review could not read any of the requested Exchange servers. See the warnings above.'
        }

        # The report builders return the block array wrapped with the unary comma,
        # so the result is assigned directly. Wrapping the call in @() would nest it.
        $reviewBlocks = Get-SnapshotReportBlocks -Snapshots $targetSnapshotList -Title 'Current Exchange log path configuration'
        if ($reviewFailureList.Count -gt 0) {
            $reviewBlocks = @($reviewBlocks) + (Get-ReviewFailureReportBlocks -Failures $reviewFailureList)
        }

        if ($script:OutputFileRequested) {
            Export-TextReport -OutputTarget $outputTarget -Lines (ConvertTo-ReportTextLines -Blocks $reviewBlocks)
            Write-StatusHost -Text ''
            Write-StatusHost -Text ("Review report created: {0}" -f $outputTarget.Path) -ForegroundColor Green
        }
        else {
            Show-ReportBlocks -Blocks $reviewBlocks
        }

        Write-StatusHost -Text ''
        if ($reviewFailureList.Count -gt 0) {
            Write-StatusHost -Text ("Review completed with warnings. {0} server(s) could not be reviewed." -f $reviewFailureList.Count) -ForegroundColor Yellow
        }
        else {
            Write-StatusHost -Text 'Review completed.' -ForegroundColor Green
        }
        Write-StatusHost -Text 'No Exchange configuration changes were made.' -ForegroundColor DarkGray
        Show-CompletionFooter
        return
    }

    # -----------------------------------------------------------------------
    # Change modes. Build the desired state, compare, and preview.
    # -----------------------------------------------------------------------
    $desiredConfigurations = New-Object System.Collections.ArrayList
    foreach ($snapshot in $targetSnapshotList) {
        if ($parameterSetName -eq 'LogRoot') {
            [void]$desiredConfigurations.Add((New-LogRootDesiredConfiguration -TargetSnapshot $snapshot -Root $logRootCanonicalPath))
        }
        else {
            [void]$desiredConfigurations.Add((New-ReferenceDesiredConfiguration -SourceSnapshot $sourceSnapshot -TargetSnapshot $snapshot))
        }
    }

    $comparisons = New-Object System.Collections.ArrayList
    $changes = New-Object System.Collections.ArrayList
    foreach ($desired in @($desiredConfigurations)) {
        foreach ($comparisonRow in @(New-ComparisonPlan -DesiredConfiguration $desired)) {
            [void]$comparisons.Add($comparisonRow)
        }
        foreach ($changeRow in @(New-ChangePlan -DesiredConfiguration $desired)) {
            [void]$changes.Add($changeRow)
        }
    }

    $comparisonList = @($comparisons)
    $changeList = @($changes)
    $operations = @(Get-PlanOperations -Changes $changeList -Targets $targetNames)

    Write-StatusHost -Text 'Preparing Preview...' -ForegroundColor DarkCyan

    $modeInfo = Get-ModeInfo -ParameterSetName $parameterSetName -Apply:$script:ApplyIntent
    $proposalBlocks = Get-ProposalReportBlocks `
        -Comparisons $comparisonList `
        -Operations $operations `
        -Targets $targetNames `
        -ModeName ([string]$modeInfo.Mode) `
        -SourceServerName $sourceName `
        -LogRootPathValue $logRootCanonicalPath `
        -ApplyRequested:$script:ApplyIntent `
        -ForExport:$script:OutputFileRequested

    if ($script:OutputFileRequested) {
        Export-TextReport -OutputTarget $outputTarget -Lines (ConvertTo-ReportTextLines -Blocks $proposalBlocks)
        Write-StatusHost -Text ''
        Write-StatusHost -Text ("Proposal report created: {0}" -f $outputTarget.Path) -ForegroundColor Green
        Write-StatusHost -Text ''
        Write-StatusHost -Text 'Preview completed.' -ForegroundColor Green
        Write-StatusHost -Text 'No Exchange configuration changes were made.' -ForegroundColor DarkGray
        Show-CompletionFooter
        return
    }

    Show-ReportBlocks -Blocks $proposalBlocks

    # An incomplete preview can never lead to a confirmation prompt.
    if ($script:DisplayStopped) {
        Write-StatusHost -Text ''
        if ($script:ApplyIntent) {
            Write-StatusHost -Text 'The preview was stopped before the end, so the apply workflow was cancelled. No changes were made.' -ForegroundColor Yellow
            Write-StatusHost -Text 'Re-run the script and review the complete preview before applying.' -ForegroundColor Yellow
        }
        else {
            Write-StatusHost -Text 'Display stopped. No changes were made.' -ForegroundColor Yellow
        }
        Show-CompletionFooter
        return
    }

    if ($changeList.Count -eq 0) {
        $reviewOnlyCount = @($comparisonList | Where-Object { $_.Status -eq 'Review Only' }).Count
        $unavailableCount = @($comparisonList | Where-Object { $_.Status -eq 'Unavailable' }).Count

        Write-StatusHost -Text ''
        if ($reviewOnlyCount -gt 0 -or $unavailableCount -gt 0) {
            Write-StatusHost -Text 'No automatically applicable Exchange configuration changes are required.' -ForegroundColor Green
            Write-StatusHost -Text ("{0} setting(s) are Review Only and {1} setting(s) could not be read. They are reported above and were not changed." -f $reviewOnlyCount, $unavailableCount) -ForegroundColor Cyan
        }
        else {
            Write-StatusHost -Text 'All applicable managed log path settings already match the proposal. Nothing to change.' -ForegroundColor Green
        }

        Show-CompletionFooter
        return
    }

    if (-not $script:ApplyIntent) {
        Write-StatusHost -Text ''
        Write-StatusHost -Text 'Preview completed. To apply this proposal, re-run the same command with -ApplyChanges.' -ForegroundColor Green
        Write-StatusHost -Text 'No Exchange configuration changes were made.' -ForegroundColor DarkGray
        Show-CompletionFooter
        return
    }

    $shouldProcessTarget = (@($targetNames) -join ', ')
    $shouldProcessAction = ("Apply {0} Exchange log path change(s)" -f $changeList.Count)
    if (-not $PSCmdlet.ShouldProcess($shouldProcessTarget, $shouldProcessAction)) {
        Write-StatusHost -Text ''
        if ($WhatIfPreference) {
            Write-StatusHost -Text 'Apply was skipped because -WhatIf was specified. No changes were made.' -ForegroundColor DarkCyan
        }
        else {
            Write-StatusHost -Text 'Cancelled at the confirmation prompt. No changes were made.' -ForegroundColor Yellow
        }
        Show-CompletionFooter
        return
    }

    # -----------------------------------------------------------------------
    # Pre-change snapshot. Mandatory, and written before anything is changed.
    # -----------------------------------------------------------------------
    Write-StatusHost -Text ''
    Write-StatusHost -Text 'Creating pre-change backup(s) before Apply...' -ForegroundColor DarkCyan
    Write-StatusHost -Text 'Refreshing current Exchange values...' -ForegroundColor DarkCyan

    $preChangeState = Get-PreChangeState -TargetIdentities $targetIdentityList -SourceIdentity $sourceIdentity
    $snapshotFiles = Export-PreChangeSnapshot -State $preChangeState -Targets $targetNames -SourceServerName $sourceName

    Write-StatusHost -Text ("Pre-change JSON snapshot : {0}" -f $snapshotFiles.JsonPath) -ForegroundColor Green
    if ([string]::IsNullOrWhiteSpace($snapshotFiles.TxtPath)) {
        Write-Warning ("The human readable pre-change snapshot could not be written. The JSON snapshot was written successfully. {0}" -f $snapshotFiles.TxtError)
    }
    else {
        Write-StatusHost -Text ("Pre-change text snapshot : {0}" -f $snapshotFiles.TxtPath) -ForegroundColor Green
    }

    # -----------------------------------------------------------------------
    # Stale plan / drift protection.
    # The snapshot above is already a fresh read, so the plan is rebuilt from
    # it and compared with the plan the operator actually reviewed. Any
    # difference blocks the whole run. Drift is never partially applied.
    # -----------------------------------------------------------------------
    $driftTargetSnapshots = @($preChangeState | Where-Object { $_.Role -eq 'TARGET' } | ForEach-Object { $_.Snapshot })
    $driftSourceSnapshot = $null
    $driftSourceRows = @($preChangeState | Where-Object { $_.Role -eq 'SOURCE' })
    if ($driftSourceRows.Count -eq 1) { $driftSourceSnapshot = $driftSourceRows[0].Snapshot }

    $driftChanges = New-Object System.Collections.ArrayList
    foreach ($snapshot in $driftTargetSnapshots) {
        $driftDesired = $null
        if ($parameterSetName -eq 'LogRoot') {
            $driftDesired = New-LogRootDesiredConfiguration -TargetSnapshot $snapshot -Root $logRootCanonicalPath
        }
        else {
            $driftDesired = New-ReferenceDesiredConfiguration -SourceSnapshot $driftSourceSnapshot -TargetSnapshot $snapshot
        }

        foreach ($changeRow in @(New-ChangePlan -DesiredConfiguration $driftDesired)) {
            [void]$driftChanges.Add($changeRow)
        }
    }

    $driftOperations = @(Get-PlanOperations -Changes @($driftChanges) -Targets $targetNames)
    $reviewedSignature = Get-OperationSignature -Operations $operations
    $currentSignature = Get-OperationSignature -Operations $driftOperations

    if ($reviewedSignature -ne $currentSignature) {
        $changedSettings = @(Get-DriftChangedSettingName -ReviewedChanges $changeList -FreshChanges @($driftChanges))
        $changedText = ''
        if ($changedSettings.Count -gt 0) { $changedText = (" Changed after review: {0}." -f ($changedSettings -join ', ')) }
        throw ("BLOCKER: The Exchange configuration changed after the proposal was reviewed, so the reviewed plan is stale. No changes were made.{0} The pre-change snapshot was kept at '{1}'. Re-run the script and review a current proposal." -f $changedText, $snapshotFiles.JsonPath)
    }
    Write-StatusHost -Text 'Configuration drift check passed. Nothing changed since the reviewed Preview.' -ForegroundColor DarkCyan

    # -----------------------------------------------------------------------
    # Apply the plan that was actually reviewed, then always verify.
    # -----------------------------------------------------------------------
    $applyFailure = $null
    $verificationFailure = $null
    $verificationResults = @()
    $allVerified = $false
    try {
        Write-StatusHost -Text ''
        Write-StatusHost -Text 'Applying changes...' -ForegroundColor Yellow
        $script:ApplyStarted = $true
        Invoke-ConfigurationPlan -Operations $operations
    }
    catch {
        $applyFailure = $_
    }
    finally {
        # Verification always runs, even after a failed Apply, but it is isolated
        # so an error while reading back can never replace the Apply error.
        try {
            Write-StatusHost -Text ''
            Write-StatusHost -Text 'Verifying changes...' -ForegroundColor DarkCyan
            # Test-ConfigurationPlan returns its result array with the unary comma,
            # so it is assigned directly. Wrapping the call in @() would nest it.
            $verificationResults = Test-ConfigurationPlan -Changes $changeList -TargetIdentities $targetIdentityList
            $allVerified = Show-Verification -Results $verificationResults
        }
        catch {
            $verificationFailure = $_
        }
    }

    if ($null -ne $verificationFailure) {
        Write-StatusHost -Text ''
        Write-StatusHost -Text 'Verification' -ForegroundColor Yellow
        Write-StatusHost -Text (Get-ReportSeparator) -ForegroundColor DarkGray
        Write-StatusHost -Text ("  Verification could not be completed: {0}" -f $verificationFailure.Exception.Message) -ForegroundColor Red
    }

    $verifiedCount = @($verificationResults | Where-Object { $_.Status -eq 'Verified' }).Count
    $verifiedColor = 'Green'
    if ($verifiedCount -ne $changeList.Count) { $verifiedColor = 'Red' }

    Write-StatusHost -Text ''
    Write-StatusHost -Text 'Apply summary' -ForegroundColor Cyan
    Write-StatusHost -Text (Get-ReportSeparator) -ForegroundColor DarkGray
    Write-StatusHost -Text ("  Targets             : {0}" -f (@($targetNames) -join ', '))
    Write-StatusHost -Text ("  Set-* commands      : {0}" -f @($operations).Count)
    Write-StatusHost -Text ("  Settings verified   : {0} / {1}" -f $verifiedCount, $changeList.Count) -ForegroundColor $verifiedColor
    Write-StatusHost -Text ("  Pre-change snapshot : {0}" -f $snapshotFiles.JsonPath)
    Write-StatusHost -Text ''
    Write-StatusHost -Text ("{0}.ps1 does not create log directories. Create and secure the new target directories according to your own standards." -f $script:ScriptBaseName) -ForegroundColor Yellow
    Write-StatusHost -Text 'Whether a service restart is needed for a new log path to take effect must be validated in your own environment.' -ForegroundColor DarkCyan

    if ($null -ne $applyFailure) {
        Write-StatusHost -Text ''
        if ($null -eq $verificationFailure) {
            Write-StatusHost -Text 'The apply operation failed. The verification above shows the state that was read back afterwards.' -ForegroundColor Red
        }
        else {
            Write-StatusHost -Text 'The apply operation failed and the current state could not be read back afterwards. Compare the current Exchange configuration with the pre-change snapshot before retrying.' -ForegroundColor Red
        }
        throw $applyFailure
    }

    if ($null -ne $verificationFailure) {
        throw ("Apply completed, but the final verification could not be completed. Compare the current Exchange configuration with the pre-change snapshot before retrying. {0}" -f $verificationFailure.Exception.Message)
    }

    if (-not $allVerified) {
        throw 'One or more applied Exchange log path changes could not be verified. Review the verification detail above and the pre-change snapshot before retrying.'
    }

    # Result first, Feedback / Bugs footer last.
    Write-StatusHost -Text ''
    Write-StatusHost -Text 'All proposed changes were applied and verified.' -ForegroundColor Green
    Show-CompletionFooter
}
catch {
    # Controlled presentation: one clean BLOCKER or ERROR message, the "no
    # changes" line only when Apply had not started, and the footer. The same
    # exception is then re-thrown as a terminating error, so a calling script
    # can still catch it and $_.Exception.Message keeps the full text.
    # ErrorDetails only shortens the console rendering of that error.
    $failure = $_
    $failureMessage = [string]$failure.Exception.Message
    $isBlocker = $failureMessage.StartsWith('BLOCKER:')

    Write-Host ''
    if ($isBlocker) {
        Write-Host $failureMessage -ForegroundColor Red
    }
    else {
        Write-Host ("ERROR: {0}" -f $failureMessage) -ForegroundColor Red
    }
    if (-not $script:ApplyStarted) {
        Write-Host ''
        Write-Host 'No Exchange configuration changes were made.' -ForegroundColor DarkGray
    }
    Show-CompletionFooter

    $errorId = 'ExchangeLogPathManager.Error'
    $displayText = 'Stopped by an ERROR. See the message above.'
    if ($isBlocker) {
        $errorId = 'ExchangeLogPathManager.Blocker'
        $displayText = 'Stopped by a BLOCKER. See the message above.'
    }

    $record = [System.Management.Automation.ErrorRecord]::new(
        $failure.Exception,
        $errorId,
        [System.Management.Automation.ErrorCategory]::OperationStopped,
        $null)
    $record.ErrorDetails = [System.Management.Automation.ErrorDetails]::new($displayText)
    $PSCmdlet.ThrowTerminatingError($record)
}
