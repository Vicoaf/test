# PROXTEL Skill Auditor - Area 1.2 Closure V2

Status: CERTIFIED

## Why V2 exists

The historical Area 1.2 closure is preserved unchanged. A later read-only audit found that its six regression records reported exit code 0 but had empty captured stdout/stderr and no explicit regression-count evidence.

Closure V2 reruns the same six hash-locked regression runners with their real mandatory parameter contracts and preserves fresh execution evidence.

## Mandatory parameter contracts used

- Core contracts: Agency + TestsRoot
- Semantic policy: AuditorRoot + TestsRoot
- Behavioral V1 legacy: TestsRoot
- Behavioral V2: AuditorRoot + SuiteRoot
- Adapter contracts: Agency + TestsRoot
- Provider dry-run: HarnessRoot

All parameter roots are validated against the exact files or directories consumed by each runner before execution.

## Fresh offline regression

- Core contracts: 8/8
- Semantic policy: 20/20
- Behavioral V1 legacy: 16/16
- Behavioral V2: 4/4
- Adapter contracts: 9/9
- Provider dry-run: 3/3

Every runner:

- matched its certified SHA-256 before execution
- ran in a non-interactive child PowerShell process
- exited with code 0
- produced captured output
- produced no failure marker
- produced suite-count evidence

## Live smoke basis

- direct native Codex executable
- ChatGPT authentication route
- read-only sandbox
- provider-default model
- one provider process
- one model call
- no automatic retry
- behavioral evaluation 15/15
- provider input tokens 18880
- provider output tokens 397

## Historical evidence preserved

The historical closure V1 manifest and document remain untouched.

The Q-D packet remains consumed and was never retried. Its exact root cause remains POWERSHELL-5.1-FILE-LITERAL-DASH-WITH-NOPARAM-SCRIPT.

## Metadata

Observed skill lifecycle/status: @{state=candidate; version=0.2.0}

The Auditor source and lifecycle metadata are not silently rewritten by this closure rebuild.

## Result

Area 1.2 technical certification is supported by the certified live smoke, 15/15 behavioral evaluation, and six fresh hash-locked offline regression suites with captured evidence.