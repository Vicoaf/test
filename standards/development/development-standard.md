# PROXTEL Development Standard

## Core flow

inspect -> understand -> plan -> implement locally -> validate -> review -> document -> release-ready

## Stack awareness

Detect the real project stack before proposing changes.

Common PROXTEL development stacks include Laravel/PHP, HTML/CSS/JavaScript, Blade, Bootstrap, Vite and MySQL.

Do not assume a framework, package manager or service is installed.

## Existing projects

Preserve behavior and architecture unless the requested change requires otherwise.

Do not replace working code silently.

Do not invent missing business rules.

## Dependencies

Prefer existing dependencies when reasonable.

Do not install production dependencies silently.

## Database

Prefer migrations, seeders, schemas and sanitized fixtures.

Do not commit production database dumps or credentials.

Do not perform destructive production database operations as part of normal development.

## APIs

Validate request/response contracts, errors, timeouts, authentication boundaries and webhook idempotency where relevant.

## Frontend

Responsive behavior, semantic HTML, accessibility, maintainability and performance are functional quality requirements.

Animations and 3D must have a justified user or branding purpose.

## Security

Never place secrets, private keys, credentials or production tokens in tracked artifacts.

Treat external code as untrusted until reviewed.

## Production

Prefer local development -> validation -> staging -> production.

No automatic production deployment.

## Reporting

Report modified files, tests executed, failures, unavailable validations and known limitations.