[← Previous: The Template](template.md) | [Table of Contents](README.md) | [Next: Vision →](vision.md)

# Chapter 5: Project Anatomy

> How the CEP repository is organized, why each directory exists, and how to navigate the codebase. The "how do I start working here?" chapter.

If you've worked on projects in compiled languages (Go, Rust, Java), you're used to build systems that enforce directory conventions. Bash projects have no such enforcement — there's no `cargo.toml`, no `go.mod`, no `package.json`. The directory layout is entirely a human decision, and understanding *why* it's structured this way is more important than memorizing *what* goes where.

## Directory Layout

```
~/projects/cep/
├── bin/
│   └── cep                      # The CLI — the entire runtime
├── templates/
│   ├── CLAUDE.md.base           # The base template (the product)
│   └── PROJECT_KICKOFF.md       # Interactive planning guide for new projects
├── hooks/                       # (empty) Future: lifecycle hooks for cep commands
├── lib/                         # (empty) Future: shared bash functions extracted from bin/cep
├── .registry/
│   └── projects                 # Plain text list of managed project paths (gitignored)
├── .cep/                        # CEP managing itself (dogfooding)
│   ├── CLAUDE.local.md          # Project-specific context for CEP
│   ├── mikado.yaml              # Current goal decomposition
│   ├── sessions.yaml            # Session index
│   ├── version                  # Which CEP version this project runs
│   ├── logs/                    # Session logs
│   ├── blog/                    # Session blog posts
│   ├── guidebook/               # This guidebook
│   └── decisions/               # Architecture Decision Records
├── VERSION                      # Source of truth for CEP's version number
├── README.md                    # Project front door
├── ROADMAP.md                   # Planned work and ideas parking lot
├── CLAUDE.md                    # Assembled by `cep init` — do not edit directly
└── .gitignore                   # Ignores .registry/
```

## Why This Layout?

The `bin/` directory follows a Unix convention: executable scripts go in `bin/`. When you add `~/projects/cep/bin` to your `PATH`, the shell can find `cep` without you specifying the full path. This is the same convention used by system tools (`/usr/bin/`), local tools (`/usr/local/bin/`), and per-user tools (`~/.local/bin/`). The convention exists because the `PATH` environment variable is a colon-separated list of directories the shell searches when you type a command name.

The `templates/` directory separates the template files from the runtime. The CLI reads from this directory at runtime — there's no "build" step that copies templates into the binary. This means you can edit a template and immediately see the effect with `cep diff`. If the templates were embedded in the script (heredocs, for instance), editing them would mean editing the CLI itself, which is riskier and harder to review.

The `hooks/` and `lib/` directories are empty placeholders. They exist in the repository to signal planned architecture: `hooks/` for lifecycle hooks that run before/after commands (think git hooks but for cep), and `lib/` for bash functions extracted from `bin/cep` when the script grows too large. The directories are committed even though they're empty because git doesn't track empty directories — the directories contain a `.gitkeep` or are mentioned in documentation to establish the convention.

The `.registry/` directory is gitignored because the registry is machine-local. If you clone CEP on a different machine, you'd have different project paths. The registry is created lazily by `cep init` when the first project is registered.

## The `.cep/` Directory

Every managed project gets a `.cep/` directory. For CEP itself, this is the dogfooding instance — CEP managing its own development. The leading dot makes it a hidden directory on Unix systems, following the convention that tool-internal directories (`.git/`, `.vscode/`, `.idea/`) stay out of sight in normal `ls` listings.

Inside `.cep/`, the files break into two categories:

**CLI-managed files** are created or updated by the `cep` CLI:
- `version` — stamped by `cep init` and `cep upgrade`
- `CLAUDE.local.md` — created with starter content by `cep init` if it doesn't exist, never overwritten
- `mikado.yaml` — created with starter content by `cep init` if it doesn't exist, never overwritten

**Agent-managed files** are created and updated by the AI agent during sessions:
- `sessions.yaml` — session index, appended to each session
- `logs/*.md` — one file per session
- `blog/*.md` — one file per session
- `guidebook/*.md` — revised every session
- `decisions/*.md` — created when significant decisions are made

This split is important: the CLI and the agent never write to the same files (except `mikado.yaml`, which the CLI seeds and the agent updates). There's no conflict resolution needed.

## The Entry Point: How `cep` Gets Found

When you type `cep status` in your terminal, here's what happens:

1. **Shell PATH search.** Your shell (bash, zsh, fish) reads the `PATH` environment variable — a colon-separated list of directories. It searches each directory, left to right, for an executable file named `cep`. If you added `~/projects/cep/bin` to your PATH (as the README instructs), the shell finds `~/projects/cep/bin/cep`.

2. **Shebang interpretation.** The kernel reads the first line: `#!/usr/bin/env bash`. This tells the kernel to run `/usr/bin/env` with the argument `bash`, which finds bash on the PATH and executes the script with it. The `env` indirection is a portability convention — it works regardless of where bash is installed.

3. **Self-location.** The script resolves `CEP_DIR` — the root of the CEP repository — using `readlink -f "$0"` to follow symlinks and find the real script location. This means it doesn't matter whether you invoked `cep` directly, through a symlink, or from a different directory. The script always finds its templates and VERSION file.

4. **Command dispatch.** The `case` statement at the bottom routes to the appropriate handler function.

## VERSION: Why a Separate File?

The CEP version lives in a top-level `VERSION` file rather than inside the script. This is a common pattern in projects without a formal build system. The advantages:

- **Single source of truth.** The CLI reads `VERSION` at runtime. The template references `{{CEP_VERSION}}`. Both get the same value from the same file. No risk of the script version and template version diverging.
- **Easy to bump.** `echo "0.3.0" > VERSION` is simpler and less error-prone than editing a version string inside a script.
- **Machine-readable.** CI/CD, release scripts, and future tooling can read the version without parsing bash.

## The `.gitignore`

CEP's `.gitignore` is minimal: it ignores `.registry/` (machine-local data that shouldn't be committed). Everything else — including the assembled `CLAUDE.md` — is committed. The assembled CLAUDE.md is committed because it serves as documentation: anyone cloning the repo can read it to understand how CEP instructs agents, without needing to mentally assemble the template and local context themselves.

## Working in This Codebase

The day-to-day of working on CEP involves two activities:

**Editing the template** (`templates/CLAUDE.md.base`). This is the most common and most impactful change. The workflow is: edit, `cep diff ~/projects/cep` to preview, `cep upgrade ~/projects/cep` to apply, commit. Always consider whether the change warrants a version bump.

**Editing the CLI** (`bin/cep`). Less common, since the command set is stable. When adding a command, follow the existing pattern: write a `cmd_name()` function, add a case branch, update `usage()`. Run the command manually to test. Formal tests are a separate Mikado tree branch.

There's no build step, no compilation, no dependency installation. You edit files and they take effect immediately (for the CLI) or on the next `cep upgrade` (for the template). This immediate feedback loop is one of the advantages of the bash approach.

[← Previous: The Template](template.md) | [Table of Contents](README.md) | [Next: Vision →](vision.md)
