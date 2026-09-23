# Codex Native Live Packet V3

## Purpose

Create a fresh one-call packet after the Q-D launcher failure was isolated and repaired.

## Lineage

- Q-D remains consumed and immutable.
- Q-D is not retried.
- Q-F established the direct native codex.exe launcher.
- Q-G builds a new packet using that corrected path.

## Authorization model

The user instructed the workflow to stop requesting per-step authorization and to advance after each validated stage.

Q-G records that standing instruction as a one-call authorization for the next live execution stage.

## Safety

- direct native executable
- no powershell.exe -File codex.ps1 path
- read-only sandbox
- provider-default model
- one provider start maximum
- no automatic retry
- ChatGPT route only
- known API environment variables stripped
- no production use

Q-G itself performs no provider model call.