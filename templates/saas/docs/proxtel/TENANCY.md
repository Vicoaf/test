# SaaS Tenancy Baseline

Before implementing tenancy, choose and document the isolation model.

Minimum controls:

- tenant context resolved explicitly
- queries constrained to tenant scope
- authorization tested across tenant boundaries
- jobs carry tenant context
- caches and files are tenant-aware
- administration paths are separately authorized
- billing entitlements do not replace authorization