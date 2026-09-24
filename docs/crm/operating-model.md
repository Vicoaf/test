# PROXTEL CRM Operating Model

Use the CRM Orchestrator when a task depends on CRM-specific business semantics. Use Development directly when a task is purely technical and CRM domain interpretation is unnecessary.

For CRM software work, the normal path is:

`CRM discovery/design -> Development implementation/technical validation -> CRM domain QA -> release gate`

No new MCP or local Tool is added merely because the work belongs to CRM. Existing certified Development capabilities are reused first; a new capability requires a proven gap.
