[← Previous: Overview](overview.md) | [Table of Contents](README.md) | [Next: The CLI →](cli.md)

# Chapter 2: Architecture

> How CEP's pieces fit together. The template assembly pipeline, the upgrade mechanism, the registry, and why a 300-line bash script is the right architecture for this stage of the project.

CEP's architecture is simple by design. There are no services, no databases, no background processes. The entire system is a CLI that reads files, transforms text, and writes files. If you've worked with static site generators like Jekyll or Hugo, the mental model is similar: there's a template, there's per-project content, and the CLI combines them into an output file. The difference is that CEP's output isn't HTML — it's a `CLAUDE.md` that tells an AI agent how to behave.

## Component Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        CEP Repository                        │
│                                                              │
│  VERSION ─────────┐                                          │
│                    │                                          │
│  templates/        │    bin/cep                               │
│  ├─ CLAUDE.md.base ├──► assemble_claude_md()                 │
│  └─ PROJECT_KICKOFF│         │                               │
│                    │         ▼                                │
│  .registry/        │    ┌─────────┐                          │
│  └─ projects ◄─────┘    │ sed/awk │                          │
│                          └────┬────┘                         │
└───────────────────────────────┼──────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                    Managed Project                            │
│                                                              │
│  CLAUDE.md ◄──── assembled output                            │
│                                                              │
│  .cep/                                                       │
│  ├─ CLAUDE.local.md ───► injected into CLAUDE.md             │
│  ├─ version ───────────► tracks which CEP version is active  │
│  ├─ mikado.yaml          (agent-maintained artifacts below)  │
│  ├─ sessions.yaml                                            │
│  ├─ logs/                                                    │
│  ├─ blog/                                                    │
│  ├─ guidebook/                                               │
│  └─ decisions/                                               │
└─────────────────────────────────────────────────────────────┘
```

The arrow direction matters: the CEP repository is the *source*, the managed project is the *target*. Information flows one way during assembly — from the template and the project's local context into the assembled CLAUDE.md. The agent-maintained artifacts (logs, blog, guidebook) are created and updated by the AI agent during sessions, not by the CLI.

## The Template Assembly Pipeline

This is the heart of CEP. When you run `cep init` or `cep upgrade`, the `assemble_claude_md()` function executes a two-stage text transformation. Understanding this pipeline is essential for anyone editing the template.

**Stage 1: sed substitution.** The base template contains placeholder tokens like `{{CEP_VERSION}}`, `{{PROJECT_NAME}}`, `{{UPGRADE_DATE}}`, and `{{NOTIFICATION_BLOCK}}`. The function reads the template file and uses `sed` to replace each token with its value. The result is written to a temporary file (`.cep/CLAUDE.md.assembled`).

The sed command uses `|` as the delimiter instead of the traditional `/` — this is a common bash idiom when your replacement values might contain forward slashes (like file paths). The `-e` flag chains multiple substitutions in a single pass.

**Stage 2: awk injection.** The template contains one placeholder that sed can't handle well: `{{PROJECT_SPECIFIC}}`. This placeholder needs to be replaced with the *entire contents* of `.cep/CLAUDE.local.md`, which is a multiline document — potentially hundreds of lines. sed's substitution command operates line-by-line, which makes multiline replacement awkward. awk handles this naturally: it reads the partially-assembled file line by line, and when it encounters the `{{PROJECT_SPECIFIC}}` pattern, it prints the contents of the local file instead. Everything else passes through unchanged.

The awk command uses the `-v` flag to pass the file contents as a variable. This is the **Template Method pattern** in miniature — the base template defines the overall structure with a "hook point" (the placeholder), and the project-specific content fills in that hook at assembly time.

**Stage 3: cleanup.** The temporary `.cep/CLAUDE.md.assembled` file is deleted. The final output lives at `CLAUDE.md` in the project root.

## The Upgrade Mechanism

Upgrading is reassembly. When you run `cep upgrade`, the CLI:

1. Checks the project's `.cep/version` against the global `VERSION`. If they match, exits early (already up to date).
2. Extracts the project name from the existing CLAUDE.md header line using `head` and `sed`.
3. Runs `assemble_claude_md()` — the same function used by `init`.
4. Writes the new CEP version to `.cep/version`.

The critical design decision here is that **project-specific content is never touched**. The template portions of CLAUDE.md are completely regenerated from the latest `CLAUDE.md.base`, but `.cep/CLAUDE.local.md` is only *read* (to inject its contents), never *written*. This means you can safely upgrade without worrying about losing your project context.

The `cep diff` command lets you preview what would change before upgrading. It runs the same assembly pipeline but writes to a temporary file and diffs it against the current CLAUDE.md. This is the **Dry Run pattern** — show the user the consequences of an action before taking it.

## The Registry

CEP tracks which projects it manages using a plain text file at `.registry/projects` — one absolute path per line. When you run `cep init`, the project path is appended to this file and then deduplicated with `sort -u`. The `cep list` command reads this file and checks each path for a `.cep/` directory, showing version status.

The registry is intentionally simple. There's no database, no JSON, no YAML — just paths. The file is gitignored because the registry is machine-local (different machines would have different project paths). This design trades queryability for simplicity: you can't ask "which projects are outdated?" without reading every project's version file, but the list is short enough that `cep list` does exactly that with a simple while-read loop.

## The Self-Referential Loop

CEP manages its own development. The CEP repository has its own `.cep/` directory with a Mikado tree, session logs, and this guidebook. This creates a loop that's worth understanding:

1. At session start, the agent reads `CLAUDE.md` (assembled from `templates/CLAUDE.md.base`).
2. During the session, the agent may edit `templates/CLAUDE.md.base` — the source of the template.
3. The edits don't affect the currently-loaded CLAUDE.md. It's a snapshot.
4. After the session, Raymond runs `cep upgrade ~/projects/cep` to regenerate CLAUDE.md.
5. The next session loads the new instructions.

This is safe because of a natural firewall between reading instructions and editing their source. If you've worked with config-driven systems (Nginx reading `nginx.conf`, for instance), it's the same principle: editing the config while the process is running doesn't change behavior until a reload. In CEP's case, the "reload" is `cep upgrade`.

## Data Flow Summary

There are two distinct data flows in CEP, and they never mix:

**Flow 1: Template → Project (CLI-driven).** The CLI reads the base template and project-local context, assembles CLAUDE.md, and writes it to the project. This happens during `init` and `upgrade`. The human triggers it.

**Flow 2: Agent → Documentation (session-driven).** The agent reads CLAUDE.md, works through the Mikado tree, and produces session logs, blog posts, guidebook updates, and ADRs. This happens during agent sessions. The agent triggers it.

The CLI never reads or writes session logs, blog posts, or guidebook pages. The agent never assembles CLAUDE.md. Each flow has a clear owner. This separation means there are no race conditions, no merge conflicts between CLI and agent outputs, and no confusion about who is responsible for what.

## Why Bash?

A 300-line bash script with no dependencies might seem like an odd choice for a developer tool. The reasoning is practical:

The feature set is small. Five commands, one text transformation, one flat-file registry. Bash handles all of this natively. Adding a build system, a package manager, and a runtime (Go, Python, Node) would add complexity without adding capability *at this stage*.

The deployment model is trivial. Clone the repo, add `bin/` to PATH, done. No `go install`, no `pip install`, no `npm install -g`. This matters when the tool runs on a single machine and the user wants to start working in 30 seconds.

The Go rewrite is planned for when the feature set demands it — likely when the Mikado tree TUI browser and Charm-based dashboards arrive. Until then, bash is the right tool because it's the simplest tool that works.

[← Previous: Overview](overview.md) | [Table of Contents](README.md) | [Next: The CLI →](cli.md)
