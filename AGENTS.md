# Repository Guidelines

<!-- 🤖 AI-authored by Claude (Anthropic, claude-fable-5), run from Markus's harness. -->

## Project Overview

pdfjam is a command-line tool for joining, rotating, cropping, and rearranging PDF pages — a shell wrapper around the LaTeX `pdfpages` package. The shipped product is a single self-contained POSIX sh script; all Lua in the repo is build-time only (l3build config + doc generation).

## Architecture & Data Flow

Runtime pipeline inside `pdfjam` (~1090 lines, `#!/bin/sh`):

```
cli args → pre-scan (--quiet/--batch/--vanilla/--version)
  → source config files (eval, comments stripped via sed)
  → paper size resolution (libpaper2 `paper` / libpaper1 `paperconf` / a4 fallback)
  → argument loop → fileSpec (newline-delimited path|ext|pagespec triples)
  → system checks ($latex executable, pdfpages.sty via kpsewhich)
  → mktemp -d (umask 077); --batch re-execs $0 per file (PDFJAM_CALL_NUMBER)
  → symlink/copy inputs; optional pdfinfo+iconv metadata (--keepinfo)
  → write a.tex (\documentclass + \includepdfmerge[$miscOptions]{...})
  → run $latex × $runs → copy a.pdf to $outFile → trap-based cleanup
```

Unknown `--key value` options pass through verbatim to `\includepdfmerge` — pdfjam's option surface is largely pdfpages' surface.

Build-time pipeline: `doc/opts.lua` (single source of truth for every CLI option) → `doc/run.lua` (texlua) generates `README.md` (via pandoc), `_pdfjam` zsh completion, `options.tex`, example Makefile, and `pdfjam.pdf` (via latexmk). The man page `doc/pdfjam.1` is hand-authored troff, NOT generated — version `N.NN` and `$repository` tokens are sed-substituted by `utils/build.sh`.

## Key Directories

- `/` — `pdfjam` (the product), `build.lua` (main l3build config), `check-tex.lua` / `completion.lua` (l3build sub-configs)
- `doc/` — option table (`opts.lua`), doc generator (`run.lua`), templates (`README.in.md`, `zsh-completion.in.sh`, `Makefile.in`), man page, sample `pdfjam.conf`
- `testfiles/` — l3build tests: `*.jam`/`*.jamref`, `*.sh`/`*.shref`, `*.tlg`, plus `support/` (fixture PDFs, mock `paper`/`paperconf` binaries, engine wrappers)
- `utils/` — `build.sh` (assembly, invoked by l3build bundleunpack), `sandbox.sh` (PATH isolation for tests), `code-check.sh` (local replay of static-analysis CI), `check-tex.sh`, `github.sh` (release packaging), `man-date.sh`

## Development Commands

```sh
l3build check               # main tests (jam+sh) across sh, bash, ksh, zsh
l3build check -ccompletion  # zsh completion tests
l3build check -ccheck-tex   # TeX log tests (pdftex/xetex/luatex) — unstable, disabled in CI; or utils/check-tex.sh
l3build save <name>         # regenerate a test's reference (.jamref/.shref/.tlg)
l3build doc                 # full doc build (runs doc/run.lua)
utils/build.sh N.NN         # assemble build/pdfjam/{bin,man,shell-completion}; MINIMAL_BUILD=1 unpack only, =2 +completion
utils/code-check.sh         # shellcheck + checkbashisms + groff/nroff/mandoc lint, locally
```

CI: `.github/workflows/ci.yml` (functional, `MINIMAL_BUILD=2`), `.github/workflows/code-check.yml` (static analysis).

## Code Conventions & Common Patterns

- **Strict POSIX sh**: no arrays (newline-delimited scalars + `IFS=$newline` loops, always restore `OIFS`), `printf` over `echo`, `test` over `[`, `command -v` over `which`, `$((...))` arithmetic. `checkbashisms` runs in CI.
- **Errors**: always `error_exit "message" $E_*` with BSD-sysexits constants (`E_USAGE=64`, `E_NOINPUT=66`, …); never bare `exit N`. Verbose output funnels through `prattle()`.
- **Quoting helpers**: `enquote()` (dispatches to `escape_chars`/`escape_quote`), `embrace()` for pdfpages `{key=value}` lists.
- **Function naming**: `snake_case` (`get_extension`, `is_valid_pagespec`, …).
- **shellcheck**: SC2015/SC2016/SC2018/SC2019/SC2064 intentionally disabled in `.shellcheckrc` — don't "fix" those patterns.
- **Formatting** (`.editorconfig`): tabs (width 4), LF, UTF-8, final newline; `*.yml`/`*.txt` use 2-space indent; man page max line 80.
- **Adding/changing a CLI option**: edit `doc/opts.lua` (drives README, zsh completion, TeX manual) AND the parsing loop in `pdfjam` AND `doc/pdfjam.1` by hand.
- **CHANGELOG.md**: `# Version X.Y` headings, prose bullets. The block under the newest heading becomes the release announcement / git tag message (`l3build tag`/`release` parse it) — keep it public-facing.

## Important Files

- `pdfjam` — sole runtime entry point
- `build.lua` — l3build config: test types (jam/sh/completion_zsh), engines, `tag`/`release`/`upload` targets, version from git tag
- `doc/opts.lua` — authoritative option table (name, short, flag `+/-/=/*`, argtype, completer, help, example)
- `doc/run.lua` — doc generation driver (texlua, lualibs + lpeg)
- `doc/pdfjam.conf` — sample config; sourced as sh by pdfjam. Lookup: `/etc`, `/usr/share/etc`, `/usr/local/{share,etc}`, `$XDG_CONFIG_HOME`, `~/.pdfjam.conf` (user overrides site); `--vanilla` skips all
- `utils/sandbox.sh` — builds a symlink forest in `build/bin/` so tests run on a controlled PATH

## Runtime/Tooling Preferences

- Runtime: any POSIX shell (tested on sh, bash, ksh, zsh); a TeX distribution with `pdfpages` and a `$latex` engine (pdflatex default; xelatex/lualatex/tectonic supported); `poppler-utils` (pdfinfo), `iconv`, optionally libpaper.
- Build/test: `l3build` (TeX Live), `texlua`, `pandoc`, `latexmk`, `ghostscript`, `pdfcrop`.
- README.md is generated — edit `doc/README.in.md` / `doc/opts.lua`, never README.md directly.

## Testing & QA

- Framework: l3build with custom test types (defined in `build.lua`).
- `*.jam` = shell fragment invoking `$pdfjam`; normalized output (`%%% a.tex` / `%%% call.txt` / `%%% messages.txt` sections, `$BUILDDIR`/version/engine normalized) diffed against `*.jamref`.
- `*.sh` = raw shell tests diffed verbatim against `*.shref` (e.g. `testfiles/papersizes.sh` exercises config precedence with mock libpaper binaries).
- `*.tlg` = TeX log references per engine (`name.xetex.tlg`; bare `.tlg` = pdftex); regenerate with `l3build save`.
- Every behavioral change needs a `.jam` or `.sh` test; update references with `l3build save <name>`, then verify with `l3build check`.
