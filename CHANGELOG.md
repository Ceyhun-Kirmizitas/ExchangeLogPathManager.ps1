# Changelog

All notable changes to **ExchangeLogPathManager.ps1** are documented here.

## 1.0 - 2026-10-03

- Initial release of ExchangeLogPathManager.ps1.
- Added read-only Configuration Review as the default mode.
- Added Log Root and Reference modes with Current -> Proposed planning and explicit `-ApplyChanges` opt-in.
- Added canonical path handling and canonical Exchange server identity handling so short names, FQDNs, casing differences, duplicate targets, and source-as-target aliases are handled safely.
- Added Exchange cmdlet and parameter capability preflight per setting.
- Added target drive existence, drive type, and free-space checks.
- Added resilient multi-server Configuration Review so remaining servers continue when one server cannot be read.
- Added read-only `-OutputFile` behavior with no overwrite and precedence over `-ApplyChanges`.
- Added mandatory pre-change JSON snapshots with TXT companions under `ConfigBackups` before Apply.
- Added protection so mandatory snapshot and report writes are not affected by `-WhatIf` or `-Confirm`.
- Added stale-plan drift protection that refreshes current values after confirmation and blocks Apply when the reviewed plan is no longer current.
- Added changed-setting details to drift BLOCKER output.
- Added post-Apply verification for every changed setting, including verification after a partial Apply failure.
- Added Apply summary output with target servers, Set-* command count, verification count, and pre-change snapshot path.
- Added logical console paging, built-in `-Help`, controlled BLOCKER presentation, and Feedback / Bugs footer behavior aligned with ExchangeURLManager.ps1.
- Validated version 1.0 in a live lab on Exchange build 15.2.1748.10 with Windows PowerShell 5.1, including successful Log Root Apply, Reference Apply, pre-change snapshot integrity, drift blocking, `-WhatIf`, `-Confirm`, `-OutputFile`, and post-Apply verification.
- Multi-target Apply and partial Apply failure paths were not runtime-validated.
