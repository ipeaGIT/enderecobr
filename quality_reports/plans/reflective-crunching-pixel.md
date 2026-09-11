# Fix CRAN install failure on Fedora (fedora-clang / fedora-gcc) — enderecobr 0.6.1

**Status:** COMPLETED (local verification done; CI + R-hub pending push) · **Date:** 2026-09-11 · **Branch:** `fix/fedora-lR` (from `main`)

## Context

CRAN's check page shows enderecobr 0.6.0 with **ERROR** on `r-devel-linux-x86_64-fedora-clang`
and `r-devel-linux-x86_64-fedora-gcc` ("Installation failed"); every other flavor is OK.
Roger Bivand reproduced it on his own Fedora box (issue #70, comment 5631694008) and hinted
at the cause: his R has no `libR.so` (built without `--enable-R-shlib`).

### Root cause (established from the CRAN and Bivand install logs)

`src/Makevars.in` (and `.win.in`) run **two** cargo invocations at install time:

1. `cargo build --lib --release ...` → `libenderecobr.a` (static lib, no linking). **Succeeds.**
2. `cargo run --bin document ...` → builds and runs the `document` *binary*
   (`src/rust/document.rs`), which regenerates `R/extendr-wrappers.R`. A binary must be
   **linked**, and extendr-ffi emits `-lR`. On CRAN's Fedora machines R is not built as a
   shared library, so there is no `libR.so` anywhere and `ld` fails:
   `cannot find -lR: No such file or directory` → `ERROR: compilation failed`.

Notes that shape the fix:

- This is **not** a missing `-L` path: `src/vendor/extendr-ffi/build.rs:212` already emits
  `rustc-link-search=$R_HOME/lib`. The library simply does not exist there. Adding
  `-L$(R_HOME)/lib` would not help.
- Step 2 is pointless at install time anyway: `R/extendr-wrappers.R` is committed and in
  sync with `src/rust/src/lib.rs`. The step also recompiles every crate a second time in the
  *debug* profile (no `--release`, different `RUSTFLAGS`), doubling install time.
- The step came from the **rextendr 0.5.0** scaffold (`Config/rextendr/version: 0.5.0`),
  adopted in commit `4296f87`. rextendr's dev branch has since (a) gated wrapper generation
  behind `if [ -n "$ROXYGEN_PKG" ]` so it runs only during `devtools::document()`, never on
  plain install, and (b) replaced `document.rs` with a tiny C driver (`document.c`) that
  calls `write__make_<pkg>_wrappers`.
- We **cannot** adopt (b): that symbol exists only on extendr git `main`; the vendored
  `extendr-api 0.9.0` (newest on crates.io) does not export it (verified by grep in
  `src/vendor/extendr-macros/src/extendr_module.rs`). The `src/rust/document.c` already in
  the repo is therefore dead code that ships in the tarball for nothing.
- roxygen2 8.1.0 sets `ROXYGEN_PKG` in `roxygen_setup()`; the env var is inherited by the
  `make` that `pkgbuild::compile_dll()` spawns, so gating on it is reliable (same mechanism
  the upstream template relies on).

### Intended outcome

`R CMD INSTALL` never builds or links a Rust binary → installs on any R, shared-lib or not.
Developers keep automatic wrapper regeneration through `devtools::document()`. Ship as
**0.6.1**, a patch release, and resubmit to CRAN.

## Changes

### 1. `src/Makevars.in` — gate the wrapper-generation step (the actual fix)

Replace the unconditional second block

```make
	export CARGO_HOME=$(CARGOTMP) && \
	export PATH="$(PATH):$(HOME)/.cargo/bin" && \
	cargo run @CRAN_FLAGS@ --bin document --manifest-path=./rust/Cargo.toml --target-dir $(TARGET_DIR) @TARGET@
```

with a block that (i) runs only when `ROXYGEN_PKG` is set and (ii) passes the **same**
`RUSTFLAGS` / `@PANIC_EXPORTS@` / `@PROFILE@` as the lib build so cargo reuses the
fingerprints instead of recompiling everything:

```make
	# Regenerate R/extendr-wrappers.R only during devtools::document()
	# (roxygen2 sets ROXYGEN_PKG). Never at install time: the `document`
	# binary links against libR, which does not exist on R builds without
	# --enable-R-shlib (e.g. CRAN's Fedora flavors).
	if [ -n "$$ROXYGEN_PKG" ]; then \
		export CARGO_HOME=$(CARGOTMP) && \
		export PATH="$(PATH):$(HOME)/.cargo/bin" && \
		@PANIC_EXPORTS@RUSTFLAGS="$(RUSTFLAGS) --print=native-static-libs" cargo run @CRAN_FLAGS@ --bin document @PROFILE@ --manifest-path=./rust/Cargo.toml --target-dir $(TARGET_DIR) @TARGET@; \
	fi
```

`$(STATLIB)` stays `.PHONY`, `rust_clean` / `clean` unchanged.

### 2. `src/Makevars.win.in` — same gating

Wrap the existing "Generate wrappers" block (which already passes `--target $(TARGET)`,
`RUSTFLAGS`, `@PROFILE@`, `LIBRARY_PATH` and the `@CARGO_LINKER_VAR@` export) in the same
`if [ -n "$$ROXYGEN_PKG" ]; then ...; fi`. Windows is not failing on CRAN, but the step is
equally useless at install time and the two templates should stay symmetric.
`tools/config.R` needs no change (`@CARGO_LINKER_VAR@` / `.windows_target` logic stays).

### 3. Remove dead `src/rust/document.c`

Delete it (`git rm`). It references `write__make_enderecobr_wrappers`, which no released
extendr exports; it is not referenced by `Cargo.toml`, `Makevars*`, or `entrypoint.c`.
Keep `src/rust/document.rs` and the `[[bin]] document` entry in `src/rust/Cargo.toml`:
cargo errors if a declared bin path is missing, and `cargo build --lib` never compiles it.

### 4. Release metadata

- `DESCRIPTION`: `Version: 0.6.1`.
- `NEWS.md`: new top section (Portuguese, matching house style):

  ```md
  # enderecobr 0.6.1

  ## Notas

  - Corrigida falha de instalação nas plataformas Fedora do CRAN
    (`r-devel-linux-x86_64-fedora-clang` e `-gcc`): o gerador de wrappers do
    extendr (binário `document`) era compilado e executado durante a instalação
    e precisava linkar com a `libR.so`, inexistente em builds do R sem
    `--enable-R-shlib`. A geração de wrappers agora ocorre apenas durante
    `devtools::document()` ([issue
    #70](https://github.com/ipea/enderecobr/issues/70)).
  ```

- `cran-comments.md`: rewrite for a patch resubmission — state that 0.6.1 fixes the
  installation failure flagged on the Fedora flavors, explain the cause in one sentence, and
  list the test environments actually run (local Windows, GitHub Actions matrix, win-builder,
  R-hub incl. a Fedora container — see Verification). Drop the pasted NEWS body.

### 5. Developer docs / memory

- `src/rust/README.md`: one paragraph — wrappers are regenerated only by
  `devtools::document()`; on an R without `libR.so` that step fails, and the fallback is
  `rextendr::register_extendr()` (still present in 0.5.0, calls
  `wrap__make_enderecobr_wrappers` from the already-built DLL) or editing the file by hand.
- `MEMORY.md`: two `[LEARN:enderecobr]` entries — (1) CRAN Fedora / any `--enable-R-shlib`-less
  R has no `libR.so`, so no cargo **binary** may be built at install time; only
  `cargo build --lib`. (2) rextendr-dev's `document.c` needs
  `write__make_<pkg>_wrappers`, which only extendr git main provides — do not adopt it until
  an extendr-api > 0.9.0 ships it.

### 6. Reply on issue #70 (user action, text drafted by me)

Thank Roger Bivand, confirm the diagnosis (no `libR.so` → the `document` bin cannot link),
say 0.6.1 removes the install-time generation, link the PR. Not automated; I will draft the
comment for you to post.

## Files touched

| File | Change |
|---|---|
| `src/Makevars.in` | gate `cargo run --bin document` on `ROXYGEN_PKG`; align flags |
| `src/Makevars.win.in` | same gating |
| `src/rust/document.c` | delete |
| `DESCRIPTION` | 0.6.1 |
| `NEWS.md` | 0.6.1 entry |
| `cran-comments.md` | resubmission notes |
| `src/rust/README.md` | dev-workflow note |
| `MEMORY.md` | two `[LEARN]` entries |
| `quality_reports/session_logs/2026-09-11_fedora-lR-fix.md` | session log (per global rules) |

No change to `Cargo.toml`, `Cargo.lock`, `vendor.tar.xz`, `R/`, `tests/`, `man/`.

## Verification

Local (Windows, R 4.6.0, rextendr 0.5.0, Rust 1.87 with `x86_64-pc-windows-gnu` target):

1. **Rendered Makevars is sane:** `Rscript tools/config.R` → inspect `src/Makevars.win`
   (gated block present, placeholders substituted). Then `Rscript -e 'source("cleanup")'`-style
   cleanup (`sh cleanup.win`).
2. **Install path no longer runs the bin:** `R CMD build .` then
   `R CMD INSTALL --preclean enderecobr_0.6.1.tar.gz 2>&1 | tee install.log`; assert
   `grep -c "cargo run" install.log` = 0 and exactly one `cargo build --lib`. Also
   `tar tzf enderecobr_0.6.1.tar.gz | grep document` shows only `document.rs`.
3. **Dev path still regenerates wrappers:** `Rscript -e 'devtools::document()'` (sets
   `ROXYGEN_PKG`) → `git diff --exit-code R/extendr-wrappers.R NAMESPACE man/` is clean
   (regenerated output byte-identical to committed). Confirm the `cargo run --bin document`
   line appears in that build's output and that it does **not** recompile the dependency
   crates (fingerprint reuse).
4. **Suite + CRAN gate:** `devtools::test()`; then `devtools::check(args = "--as-cran")` run
   in the background — must be 0 errors / 0 warnings / 0 notes.
5. **Rust gate:** from `src/`, `tar xf rust/vendor.tar.xz` then
   `cargo build --locked --offline --lib --manifest-path rust/Cargo.toml` (per MEMORY.md, the
   R build wipes `src/vendor/`).

Fedora reproduction (the one thing Windows cannot prove):

6. Dispatch the existing `.github/workflows/rhub.yaml` (`gh workflow run R-hub -f config=...`
   or `rhub::rhub_check()`) on the fix branch with Fedora-based containers `gcc16`
   (Fedora 44, GCC 16 — same Fedora/GCC as the CRAN log) and `atlas` or `nosuggests`
   (Fedora 42), plus `ubuntu-release` as a control. All must install and check clean.
   Optionally dispatch the same on current `main` first to see whether the R-hub Fedora image
   reproduces the `-lR` failure (it will only if that image's R also lacks `libR.so`; if it
   does not reproduce, the CRAN/Bivand logs remain the evidence of the failure and step 2 the
   evidence of the fix).
7. Existing CI matrix (`check.yaml`: Windows x64 + ARM64, macOS, Ubuntu devel/release/oldrel)
   green on the PR.

Release (maintainer, manual, outside this plan): win-builder devel, then
`devtools::release()` / `submit_cran()` with the refreshed `cran-comments.md`.

## Out of scope

- Upgrading to rextendr-dev's `document.c` mechanism (blocked on an extendr-api release).
- Any change to `enderecobr_rs` or the vendored crates.
- Updating the git remote from `ipeaGIT` to `ipea` (noted in CLAUDE.md, unrelated).
