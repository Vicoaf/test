# PROXTEL Development Quality Gates

## Gate 1 - Structural

- syntax/parse
- relevant static analysis
- schema/contract validation when applicable

## Gate 2 - Automated behavior

- related tests
- regression tests
- API/integration tests where applicable

## Gate 3 - Build

- lint when available
- Composer/npm checks when relevant
- Vite/build when relevant

## Gate 4 - Browser and responsive

For user-facing web changes:

- browser smoke
- responsive breakpoints
- navigation/forms
- console errors
- visual regression when useful

Playwright is preferred when the project supports it.

## Gate 5 - Accessibility

Use automated checks plus manual review proportional to the change.

Target WCAG 2.2 practices where applicable.

## Gate 6 - Performance

Use Lighthouse/Core Web Vitals or equivalent evidence when performance is material.

Track LCP, INP and CLS when applicable.

## Gate 7 - Security

Review secrets, inputs, auth, dependencies, unsafe output handling and risky configuration.

## Gate 8 - Independent review

Important or high-risk changes should receive independent validation by a reviewer different from the implementer when practical.

## Release rule

A failed applicable gate blocks READY unless explicitly accepted with documented limitations.