# Changelog

All notable changes to **ExchangeLogPathManager.ps1** are documented here.

## 1.1 - 2026-10-04

### Added

- Added `-Review` to select read-only Configuration Review explicitly. Running the script without parameters still starts Configuration Review.
- Added Interactive Configure (`-Interactive`), a guided mode that uses the Log Root planner and the same safety workflow:
  - Without `-Server`, the script asks for the server list and validates every name with the same identity and Mailbox role checks as `-Server`. Unknown names, duplicates, and two names for the same server are rejected and the question is asked again.
  - **Common Log Root Path**: one log root for all three transport components. It builds the same plan as `-LogRootPath`, and the equivalent `-LogRootPath ... -ApplyChanges` command line is shown after the Preview and in the exported report.
  - **Advanced per-component configuration**: shows the current values for every server, then offers `1. Set a new log root for <component>` or `2. Skip` (default) for Transport Service, Front End Transport, and Mailbox Transport.
  - The selection is made once and reused unchanged for the pre-Apply drift check; nothing is asked again after the Preview.
  - Preview-only unless `-ApplyChanges` is specified. `-OutputFile` produces an `Interactive Configure / Command Export` report and takes precedence over `-ApplyChanges`.
  - Needs an interactive console; a non-interactive host stops with a BLOCKER before the Exchange Management Shell is loaded.
- Added a drive root safety gate for the log root (for example `K:\`):
  - The drive root stays a valid log root, but a WARNING is shown instead of the 1.0 NOTICE.
  - Interactive Configure asks `Use the drive root anyway? [y/N]` (default N) when a drive root is entered; N asks for a different log root.
  - `-LogRootPath` with a drive root shows only the WARNING in Preview, `-OutputFile`, and `-WhatIf` runs.
  - A real `-LogRootPath` Apply with a drive root asks `[y/N]` (default N) on an interactive console before the Exchange Management Shell is loaded, and is always blocked on a non-interactive host.
  - The question is separate from PowerShell `-Confirm`: `-Confirm:$false` skips only the normal Apply confirmation, never the drive root question, and does not change the non-interactive BLOCKER. There is no override parameter.

### Changed

- Renamed Reference mode to Clone. The parameters (`-SourceServer`, `-TargetServer`) did not change.
- Mode labels follow the `<Mode> / Preview`, `<Mode> / Apply`, and `<Mode> / Command Export` pattern. Runs with `-OutputFile` are labeled Command Export.
- Startup banner description: "Exchange Server transport log path review and configuration manager".
- Review, Log Root, Clone, and Interactive Configure output is grouped by component, then setting, then server. In Review, the default path is shown below a Custom value only.
- A setting that already matches the proposal shows only `Status : Same`. A drive or target path warning on that row is still shown.
- Built-in `-Help` is organized in MODES, INTERACTIVE, SAFETY, and EXAMPLES sections. Comment-based help describes four operating modes.

### Validation

- Validated in a live lab on Exchange build 15.2.1748.10 with Windows PowerShell 5.1: Configuration Review, Log Root, Clone, and Interactive Configure in Preview, Command Export, `-WhatIf`, and real Apply runs, including drift check, post-Apply verification, and the drive root safety gate with and without `-Confirm:$false`.
- Real Apply was validated on one target server at a time. Multi-target Apply and partial Apply failure paths were not runtime-validated.

## 1.0 - 2026-10-03

- Initial release of ExchangeLogPathManager.ps1.
- Added read-only Configuration Review mode for 22 supported Exchange Server transport log path settings per server, with Default/Custom classification against each server's own Exchange install path.
- Added Log Root mode with Current -> Proposed Preview, confirmation, mandatory pre-change snapshot, Apply, and post-change verification.
- Added live server-to-server Reference comparison with read-only behavior by default and explicit `-ApplyChanges` opt-in.
- Added install-path-aware translation of default and Exchange-relative custom paths in Reference mode.
- Added local path validation for `-LogRootPath`, rejecting UNC, relative, drive-relative, above-root, and invalid path segments.
- Added target drive existence, drive type, and free-space checks, including remote checks through PowerShell Remoting with WMI fallback.
- Added runtime validation of Exchange `Set-*` cmdlets and parameters per setting; unsupported settings remain Review Only.
- Added canonical Exchange server identity validation to block source/target alias collisions and duplicate targets.
- Added mandatory pre-change JSON snapshot with a TXT companion under `ConfigBackups` before Apply begins. Internal snapshot and report writes are not affected by `-WhatIf` or `-Confirm`.
- Added drift detection before Apply; Apply is blocked when configuration changes after Preview, and the BLOCKER names the changed settings.
- Added post-Apply verification, also after a partial Apply failure, and an Apply summary.
- Added per-server isolation in Configuration Review so one unreadable server does not stop the review.
- Added read-only `-OutputFile` reporting that never overwrites an existing file and takes precedence over `-ApplyChanges`.
- Added built-in `-Help`, comment-based PowerShell help, console paging, `-WhatIf` and `-Confirm` support, and controlled BLOCKER presentation.
- Validated version 1.0 in a live lab on Exchange build 15.2.1748.10 with Windows PowerShell 5.1, including Log Root Apply, Reference Apply, drift blocking, and post-Apply verification.
- Multi-target Apply and partial Apply failure paths were not runtime-validated.
