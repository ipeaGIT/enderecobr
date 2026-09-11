<!-- Copy to quality_reports/merges/YYYY-MM-DD_[branch-name].md -->

# Quality Report — [branch-name] — YYYY-MM-DD

**Merged into:** main
**Scope:** [what this branch/PR changed]

## Release gate

| Check | Result |
|---|---|
| `R CMD check --as-cran` | E errors, W warnings, N notes (each justified below) |
| `cargo build` (`src/rust/`) | [clean / errors — against which `enderecobr_rs` version] |
| `devtools::test()` | P passed, F failed |
| Coverage (`covr`) | X% of exported functions; list any at 0% |
| roxygen completeness | [pass/fail — every exported fn has @param/@return/@examples] |

### NOTE justifications

- [NOTE text] → [why it's acceptable, or the `cran-comments.md` entry]

## r-package-reviewer findings

- Critical: [count] — [resolved / deferred]
- High: [count] — [resolved / deferred]

## Verdict

RELEASABLE / FIX-FIRST / POLICY-VIOLATION

## Follow-ups

- [anything deferred to a later PR]
