# ExchangeLogPathManager.ps1

PowerShell tool for reviewing, comparing, and safely configuring supported **Exchange Server transport log path** settings.

The script is designed for moving selected transport logs to a dedicated log drive, Exchange Server side-by-side deployments, replacement-server work, and day-to-day transport log path configuration review.

Intended for Exchange Server 2016, Exchange Server 2019, and Exchange Server Subscription Edition.

## Download

- [ExchangeLogPathManager.ps1](ExchangeLogPathManager.ps1)
- [Raw download](https://raw.githubusercontent.com/Ceyhun-Kirmizitas/ExchangeLogPathManager.ps1/main/ExchangeLogPathManager.ps1)

## Modes

### Configuration Review

Reads supported transport log path settings from one or more Exchange Mailbox servers.

Configuration Review is read-only and is the default mode. Each setting shows the current path, the default path calculated from that server's own Exchange install path, a Default/Custom classification, and the policy. If one server cannot be read, the remaining servers are still reviewed.

### Log Root

Builds a Current -> Proposed plan that moves selected transport logs below a new local log root, for example `E:\EXCLOG`.

The Exchange directory structure below V15 is preserved under the log root. Log Root is preview-only unless `-ApplyChanges` is specified.

### Reference

Uses a live Exchange server as the source and compares supported log path settings with one or more target servers.

Source default paths are translated to each target server's own Exchange install path. Source custom paths below the source Exchange install path keep their relative layout below the target Exchange install path. Source custom paths outside the source Exchange install path are proposed literally when they are local absolute drive paths.

Reference is read-only by default. Use `-ApplyChanges` explicitly to enter the Apply path.

## Managed configuration

The supported scope includes 22 settings per server:

- Transport Service: MessageTrackingLogPath, ConnectivityLogPath, ReceiveProtocolLogPath, SendProtocolLogPath, AgentLogPath, RoutingTableLogPath, DnsLogPath, PipelineTracingPath
- Front End Transport: ConnectivityLogPath, ReceiveProtocolLogPath, SendProtocolLogPath, AgentLogPath, RoutingTableLogPath, DnsLogPath
- Mailbox Transport: ConnectivityLogPath, ReceiveProtocolLogPath, SendProtocolLogPath, MailboxDeliveryAgentLogPath, MailboxSubmissionAgentLogPath, RoutingTableLogPath, MailboxDeliveryThrottlingLogPath, PipelineTracingPath

Log Root mode moves only message tracking, connectivity, receive protocol, and send protocol logs. Reference mode evaluates all supported settings.

PipelineTracingPath remains Review Only because pipeline tracing can capture message content. Null or default-disabled source values, such as DnsLogPath, are reported but are not pushed to target servers.

## Safety behavior

- Configuration Review is read-only.
- Log Root and Reference are read-only unless `-ApplyChanges` is specified.
- Apply always shows a complete Preview first and uses the standard PowerShell confirmation path before changes are applied. `-WhatIf` and `-Confirm` are supported.
- If the Preview is stopped before the end, Apply is cancelled.
- A fresh pre-change JSON snapshot, plus a TXT companion, is required under `ConfigBackups` before Apply starts. Internal snapshot and report writes are not affected by `-WhatIf` or `-Confirm`.
- Apply is blocked if the configuration changed after the Preview, including a changed current value. The BLOCKER names the changed settings.
- `-LogRootPath` accepts local absolute drive paths only. UNC, relative, and drive-relative paths, paths that navigate above the drive root, and invalid path segments are rejected.
- Target drive existence and drive type are checked. A missing drive or a drive that is not a local fixed disk blocks automatic Apply for the affected settings. Free space is reported.
- Exchange cmdlet and parameter availability is checked per setting. Settings that the current Exchange Management Shell cannot change remain Review Only.
- Short name and FQDN aliases are resolved so the source server cannot also be used as a target and duplicate targets cannot bypass validation.
- `-OutputFile` writes a report and planned `Set-*` commands only. It never applies Exchange configuration changes, never overwrites an existing file, and takes precedence over `-ApplyChanges`.
- Post-Apply verification re-reads every changed setting and also runs after a partial Apply failure.
- Mailbox role servers only. Edge Transport is not supported.

## Parameters

| Parameter | Description |
|---|---|
| `-Server` | One or more Exchange Mailbox servers for Configuration Review or Log Root. The local server is used when omitted. |
| `-LogRootPath` | Local absolute log root for Log Root mode, for example `E:\EXCLOG`. |
| `-SourceServer` | Live source Exchange server for Reference mode. |
| `-TargetServer` | One or more target Exchange servers for Reference mode. |
| `-ApplyChanges` | Explicitly enables the Apply path in Log Root or Reference mode. |
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
.\ExchangeLogPathManager.ps1 -Server EX01,EX02
```

Save a configuration review:

```powershell
.\ExchangeLogPathManager.ps1 -OutputFile C:\Temp\ExchangeLogPaths.txt
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

Compare a source server with target servers:

```powershell
.\ExchangeLogPathManager.ps1 -SourceServer EX01 -TargetServer EX02,EX03
```

Apply a reviewed Reference plan:

```powershell
.\ExchangeLogPathManager.ps1 -SourceServer EX01 -TargetServer EX02,EX03 -ApplyChanges
```

Export the proposal and planned commands without applying changes:

```powershell
.\ExchangeLogPathManager.ps1 -SourceServer EX01 -TargetServer EX02 -ApplyChanges -OutputFile C:\Temp\ExchangeLogPath-Plan.txt
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

## Notes

Version 1.0 was live-lab validated on Exchange build 15.2.1748.10 using Windows PowerShell 5.1.

Validation included parser and built-in Help checks, Configuration Review with multiple servers and invalid-server isolation, Log Root and Reference Preview, path and drive validation, `-WhatIf`, `-OutputFile` precedence, Preview and confirmation cancellation, Log Root Apply and Reference Apply with pre-change snapshots and post-Apply verification, drift blocking, and `-Confirm` snapshot safety.

Multi-target Apply and partial Apply failure paths were not runtime-validated.

The script does not create log directories, restart Exchange services, generate rollback commands, or move mailbox databases, mailbox transaction logs, queue databases, queue transaction logs, IIS logs, HttpProxy logs, or other diagnostic log folders. Create and secure the target directories according to your own standards, and validate whether a service restart is needed in your environment.

Always review the Preview or exported report and test the script in your environment before production use.

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

## Feedback and issues

For bugs, feedback, or feature requests, use [GitHub Issues](https://github.com/Ceyhun-Kirmizitas/ExchangeLogPathManager.ps1/issues).

Website: [ceyhunkirmizitas.net](https://ceyhunkirmizitas.net/)

## License

MIT. See [LICENSE](LICENSE).
