# Codex Windows Native Launcher v2

## Root cause repaired

The consumed Q-D packet failed because Windows PowerShell 5.1 was launched with -File against the npm codex.ps1 shim while a literal dash argument was appended.

Exact reproduced root cause:

POWERSHELL-5.1-FILE-LITERAL-DASH-WITH-NOPARAM-SCRIPT

## Corrected launcher

Use the native codex.exe Application directly through ProcessStartInfo.

Do not launch powershell.exe -File codex.ps1 for stdin-based Codex exec.

## Validated non-model interface

- native executable resolves and returns version successfully
- exec --help succeeds
- login status succeeds through ChatGPT authentication
- sandbox read-only flag exists
- output-schema flag exists
- output-last-message flag exists
- json flag exists
- working-directory flag exists
- stdin is documented by exec help

## Safety

No model call was performed in 1.2Q-F.

The generated wrapper is intentionally blocked and cannot launch Codex.

A fresh execution packet must be built later. The consumed Q-D packet remains immutable.