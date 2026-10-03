# ExchangeLogPathManager.ps1

PowerShell tool for reviewing, comparing, and changing supported **Exchange Server transport log path** configuration.

The script is designed for moving higher-growth transport logs to a dedicated log drive, Exchange Server side-by-side deployments, replacement-server work, and day-to-day transport log path configuration review.

Intended for Exchange Server 2016, Exchange Server 2019, and Exchange Server Subscription Edition.

## Download

- [ExchangeLogPathManager.ps1](ExchangeLogPathManager.ps1)
- [Raw download](https://raw.githubusercontent.com/Ceyhun-Kirmizitas/ExchangeLogPathManager.ps1/main/ExchangeLogPathManager.ps1)

## Modes

| Mode | Start | Changes |
|---|---|---|
| Configuration Review | No parameters, or `-Review` | Never. Read-only. |
| Log Root | `-LogRootPath` | Only with `-ApplyChanges` |
| Clone | `-SourceServer` and `-TargetServer` | Only with `-ApplyChanges` |
| Interactive Configure | `-Interactive` | Only with `-ApplyChanges` |

The banner and the report show the mode and the run type, for example `Log Root / Preview`, `Clone / Apply`, or `Interactive Configure / Command Export`. Runs with `-OutputFile` are labeled `Command Export`.

### Configuration Review

Reads supported transport log path settings from one or more Exchange Mailbox servers.

Configuration Review is read-only and is the default mode. It runs when no parameters are supplied, or explicitly with `-Review`. Each setting shows the current path and a Default/Custom classification against that server's own Exchange install path. The default path is shown below a Custom value. If one server cannot be read, the remaining servers are still reviewed.

### Log Root

Builds a Current -> Proposed plan that moves higher-growth transport logs below a new local log root, for example `E:\EXCLOG`.

The Exchange directory structure below V15 is preserved under the log root. Log Root is preview-only unless `-ApplyChanges` is specified.

### Clone

Clone was named Reference in version 1.0. The parameters did not change.

Uses a live Exchange server as the source and compares supported log path settings with one or more target servers.

Source default paths are translated to each target server's own Exchange install path. Source custom paths below the source Exchange install path keep their relative layout below the target Exchange install path. Source custom paths outside the source Exchange install path are proposed literally when they are local absolute drive paths.

Clone is read-only by default. Use `-ApplyChanges` explicitly to enter the Apply path.

### Interactive Configure

Guided configuration with `-Interactive`. It uses the same log path scope, path validation, planner, and safety workflow as Log Root mode.

- Without `-Server`, the script asks for the server list. Every name goes through the same Exchange identity and Mailbox role checks as `-Server`. Unknown names, duplicates, and two names for the same server, for example a short name and an FQDN, are rejected and the question is asked again.
- After the current values are read, choose a configuration method:
  - **1. Common Log Root Path**: one log root for message tracking, connectivity, SMTP Receive, and SMTP Send logs of all three transport components. This is the same plan as `-LogRootPath`. After the Preview, the equivalent `-LogRootPath ... -ApplyChanges` command line is shown.
  - **2. Advanced per-component configuration**: shows the current values for every server, then asks for each component (Transport Service, Front End Transport, Mailbox Transport): `1. Set a new log root for <component>` or `2. Skip`. Skip is the default.
- The selection is made once. It is reused unchanged when the plan is checked again before Apply, so nothing is asked again after the Preview.
- If every component is skipped, the script ends without changes.
- Without `-ApplyChanges`, Interactive Configure is preview-only.
- Interactive Configure needs an interactive console. On a non-interactive host the run stops with a BLOCKER before the Exchange Management Shell is loaded.

## Report layout

Review, Log Root, Clone, and Interactive Configure output is grouped by component, then setting, then server:

```text
##############################################################################
# Transport Service
##############################################################################

MessageTrackingLogPath
  EX01       : C:\Program Files\Microsoft\Exchange Server\V15\TransportRoles\Logs\MessageTracking  (Default)
    Proposed : E:\EXCLOG\TransportRoles\Logs\MessageTracking
    Status   : Different
    Mapping  : LogRootPath replaces the Exchange install root through V15; the relative structure is preserved
    Drive    : E: Available, Free 89.1 GB / 90 GB (Local CIM)
```

A setting that already matches the proposal shows only `Status : Same`. A drive or target path warning on that row is still shown.

## Managed configuration

The supported scope includes 22 settings per server:

- Transport Service: MessageTrackingLogPath, ConnectivityLogPath, ReceiveProtocolLogPath, SendProtocolLogPath, AgentLogPath, RoutingTableLogPath, DnsLogPath, PipelineTracingPath
- Front End Transport: ConnectivityLogPath, ReceiveProtocolLogPath, SendProtocolLogPath, AgentLogPath, RoutingTableLogPath, DnsLogPath
- Mailbox Transport: ConnectivityLogPath, ReceiveProtocolLogPath, SendProtocolLogPath, MailboxDeliveryAgentLogPath, MailboxSubmissionAgentLogPath, RoutingTableLogPath, MailboxDeliveryThrottlingLogPath, PipelineTracingPath

Log Root mode and Interactive Configure move only the higher-growth logs: message tracking, connectivity, receive protocol, and send protocol logs. Clone mode evaluates all supported settings.

PipelineTracingPath remains Review Only because pipeline tracing can capture message content. Null or default-disabled source values, such as DnsLogPath, are reported but are not pushed to target servers.

## Safety behavior

- Configuration Review is read-only.
- Log Root, Clone, and Interactive Configure are read-only unless `-ApplyChanges` is specified.
- With `-ApplyChanges`, every change follows the same chain:

  ```text
  Preview -> Confirm -> JSON pre-change snapshot -> drift check -> Apply -> Verify
  ```

- Apply always shows a complete Preview first and requires confirmation. `-WhatIf` and `-Confirm` are supported. If the Preview is stopped before the end, Apply is cancelled.
- A fresh pre-change JSON snapshot, plus a TXT companion, is required under `ConfigBackups` before Apply starts. Internal snapshot and report writes are not affected by `-WhatIf` or `-Confirm`.
- Apply is blocked if the configuration changed after the Preview, including a changed current value. The BLOCKER names the changed settings.
- Post-Apply verification re-reads every changed setting and also runs after a partial Apply failure.
- `-OutputFile` writes a report and the planned `Set-*` commands only. It never applies Exchange configuration changes, never overwrites an existing file, and takes precedence over `-ApplyChanges`.
- `-LogRootPath` and the Interactive log root accept local absolute drive paths only. UNC, relative, and drive-relative paths, paths that navigate above the drive root, and invalid path segments are rejected.
- Target drive existence and drive type are checked. A missing drive or a drive that is not a local fixed disk blocks automatic Apply for the affected settings. Free space is reported.
- Exchange cmdlet and parameter availability is checked per setting. Settings that the current Exchange Management Shell cannot change remain Review Only.
- Short name and FQDN aliases are resolved so the source server cannot also be used as a target and duplicate targets cannot bypass validation.
- Mailbox role servers only. Edge Transport is not supported.

### Drive root as log root

A drive root such as `K:\` is a valid log root, but it places the transport logs directly on the drive root, for example `K:\TransportRoles\Logs\MessageTracking`. This is usually a typo, so it has its own safety gate:

| Run | Behavior |
|---|---|
| Interactive Configure (any run) | WARNING and `Use the drive root anyway? [y/N]`. Default is N; N asks for a different log root. |
| `-LogRootPath K:\` Preview, `-OutputFile`, or `-WhatIf` | WARNING only. Nothing is changed. |
| `-LogRootPath K:\ -ApplyChanges`, interactive console | WARNING and `Use the drive root anyway? [y/N]` before the Exchange Management Shell is loaded. Default is N; N exits without changes. |
| `-LogRootPath K:\ -ApplyChanges`, non-interactive host | Always BLOCKER. |

This confirmation is separate from PowerShell `-Confirm`. `-Confirm:$false` skips only the normal Apply confirmation; it does not skip the drive root question and it does not change the BLOCKER on a non-interactive host. There is no override parameter for an unattended Apply to a drive root.

## Parameters

| Parameter | Description |
|---|---|
| `-Review` | Selects read-only Configuration Review explicitly. Running the script without parameters starts the same mode. |
| `-Interactive` | Starts guided Interactive Configure mode. Preview-only unless `-ApplyChanges` is specified. Needs an interactive console. |
| `-Server` | One or more Exchange Mailbox servers for Configuration Review, Log Root, or Interactive Configure. The local server is used when omitted; Interactive Configure asks for the list instead. |
| `-LogRootPath` | Local absolute log root for Log Root mode, for example `E:\EXCLOG`. |
| `-SourceServer` | Live source Exchange server for Clone mode. |
| `-TargetServer` | One or more target Exchange servers for Clone mode. |
| `-ApplyChanges` | Explicitly enables the Apply path in Log Root, Clone, or Interactive Configure mode. |
| `-OutputFile` | Writes a TXT report, or a proposal with planned `Set-*` commands, without applying changes. |
| `-NoPaging` | Disables console paging. |
| `-WhatIf` / `-Confirm` | Standard PowerShell confirmation controls for the Apply path. |
| `-Help` | Displays the built-in usage guide. |

## Examples

Review the local server:

```powershell
.\ExchangeLogPathManager.ps1
```

Review multiple servers:

```powershell
.\ExchangeLogPathManager.ps1 -Review -Server EX01,EX02
```

Save a configuration review:

```powershell
.\ExchangeLogPathManager.ps1 -Review -OutputFile C:\Temp\ExchangeLogPaths.txt
```

Preview a new log root:

```powershell
.\ExchangeLogPathManager.ps1 -Server EX01,EX02 -LogRootPath E:\EXCLOG
```

Apply a new log root:

```powershell
.\ExchangeLogPathManager.ps1 -Server EX01,EX02 -LogRootPath E:\EXCLOG -ApplyChanges
```

Run the Apply path without changing anything:

```powershell
.\ExchangeLogPathManager.ps1 -LogRootPath E:\EXCLOG -ApplyChanges -WhatIf
```

Compare a source server with target servers (Clone Preview):

```powershell
.\ExchangeLogPathManager.ps1 -SourceServer EX01 -TargetServer EX02,EX03
```

Apply a reviewed Clone plan:

```powershell
.\ExchangeLogPathManager.ps1 -SourceServer EX01 -TargetServer EX02,EX03 -ApplyChanges
```

Export the proposal and planned commands without applying changes:

```powershell
.\ExchangeLogPathManager.ps1 -SourceServer EX01 -TargetServer EX02 -ApplyChanges `
    -OutputFile C:\Temp\ExchangeLogPath-Plan.txt
```

Guided configuration, preview only:

```powershell
.\ExchangeLogPathManager.ps1 -Interactive
```

Guided configuration with Apply:

```powershell
.\ExchangeLogPathManager.ps1 -Interactive -Server EX01,EX02 -ApplyChanges
```

Built-in help:

```powershell
.\ExchangeLogPathManager.ps1 -Help
```

Full PowerShell help:

```powershell
Get-Help .\ExchangeLogPathManager.ps1 -Full
```

## Requirements

- Exchange Server Mailbox server environment
- Windows PowerShell 5.1
- Exchange Management Shell / required Exchange administrative permissions
- PowerShell Remoting (WinRM) or WMI access to remote target servers for drive checks
- An interactive console for `-Interactive`, and for a real Log Root Apply to a drive root

## Notes

Version 1.1 was live-lab validated on Exchange build 15.2.1748.10 using Windows PowerShell 5.1.

Validation included:

- Parser, built-in Help, and `Get-Help -Full` checks, and parameter set conflicts for `-Review` and `-Interactive`.
- Configuration Review with multiple servers and invalid-server isolation, in the component, setting, and server layout.
- Log Root and Clone Preview, Command Export, and Apply with pre-change snapshots, drift check, and post-Apply verification.
- Interactive Configure: server prompt validation, Common Log Root Path (report identical to `-LogRootPath` except the Mode and Run time lines), Advanced per-component configuration with Skip and different roots, `-WhatIf`, `-ApplyChanges -OutputFile` precedence, and a real Apply that was not asked again during the drift check.
- Drive root safety: WARNING-only read-only runs, `[y/N]` default N, `-Confirm:$false` not skipping the question, and the non-interactive BLOCKER with and without `-Confirm:$false`.
- An offline check of the compact `Same` rows, including drive and target path warnings.

Real Apply was validated on one target server at a time. Multi-target Apply and partial Apply failure paths were not runtime-validated.

The script does not create log directories, restart Exchange services, generate rollback commands, or move mailbox databases, mailbox transaction logs, queue databases, queue transaction logs, IIS logs, HttpProxy logs, or other diagnostic log folders. Create and secure the target directories according to your own standards, and validate whether a service restart is needed in your environment.

Always review the Preview or exported report and test the script in your environment before production use.

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

## Feedback and issues

For bugs, feedback, or feature requests, use [GitHub Issues](https://github.com/Ceyhun-Kirmizitas/ExchangeLogPathManager.ps1/issues).

Website: [ceyhunkirmizitas.net](https://ceyhunkirmizitas.net/)

## License

MIT. See [LICENSE](LICENSE).
