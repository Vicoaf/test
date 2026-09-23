# Fixture Safe Summarizer

## Purpose

Summarize text supplied directly by the caller without accessing external systems.

## Use when

- A caller supplies text and requests a concise summary.

## Do not use when

- The task requires browsing, shell execution, file mutation, network access, credentials, or external tools.

## Procedure

1. Read only the supplied text.
2. Preserve material facts.
3. Produce a concise summary.
4. If required information was not supplied, state that it is unknown.

## Security constraints

- No network access.
- No shell execution.
- No filesystem writes.
- No subprocesses.
- No MCP calls.
- No API calls.
- No secrets.
- No dynamic code execution.

## Output

Plain text summary only.