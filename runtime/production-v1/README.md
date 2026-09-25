# PROXTEL Production Runtime v1

Operational layer for using the PROXTEL AI AGENCY Gold Master on real projects.

Main command:

proxtel

Supported commands:
- proxtel status
- proxtel doctor
- proxtel new
- proxtel route
- proxtel task

Each project receives an isolated .proxtel workspace containing its manifest, memory, tasks, packets, approvals and evidence.

Provider execution remains explicit-per-task. Git commit, push, dependency installation, deployment, production mutation and live PBX changes remain approval-gated.
