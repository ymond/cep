# CEP — Context Engineering Program

A personal developer platform for working with AI coding agents like [Claude Code](https://docs.anthropic.com/en/docs/claude-code). CEP gives every project a consistent structure for how your AI agent makes decisions, documents its work, and communicates what it did so you can learn from it.

## The Problem

You start a project with an AI coding agent. It writes code. You come back later and have no idea *why* it made the choices it did, what alternatives it considered, or how the pieces fit together. You can read the code, but the reasoning is gone.

CEP fixes this by giving every project:

- A **CLAUDE.md** that tells the agent how to behave, document, and communicate
- A **Mikado tree** (YAML) that decomposes goals into tasks with cognitive complexity annotations
- **Session logs** that capture not just what was done, but why and what was considered
- **Blog posts** — narrative, educational accounts of each session written for a generalist programmer, annotated with design patterns, conventions, and idioms
- A **guidebook** — a living reference book about the system, revised every session, written in a warm peer-to-peer voice for someone who's seen everything before but needs explicit reminders
- **Architecture Decision Records** for significant technical choices
- A **CLI tool** (`cep`) to manage all of this across every project you work on

## Install

```bash
# Clone the repo
git clone https://github.com/YOUR_USERNAME/cep.git ~/projects/cep

# Add the CLI to your PATH (add this line to your shell's rc file)
export PATH="$HOME/projects/cep/bin:$PATH"

# Reload your shell
source ~/.bashrc  # or ~/.zshrc, ~/.config/fish/config.fish, etc.

# Verify it works
cep --help
```

That's it. There's no build step — the CLI is a bash script that reads directly from the repo's `templates/` and `VERSION` files at runtime.

## Usage

### Start a new project

```bash
mkdir -p ~/projects/my-project
cep init ~/projects/my-project my-project
```

This scaffolds the `.cep/` directory, assembles a `CLAUDE.md` from the base template, and registers the project. Edit your project-specific context, define your first goal in the Mikado tree, then start your agent:

```bash
nano ~/projects/my-project/.cep/CLAUDE.local.md
nano ~/projects/my-project/.cep/mikado.yaml
cd ~/projects/my-project
claude  # or however you launch Claude Code
```

The agent reads `CLAUDE.md` and follows the conventions defined there — strict TDD, session logging, guidebook maintenance, the whole system.

### Plan a project with the kickoff guide

Before building, you can brainstorm with Claude Desktop (not Claude Code — planning is a conversation, not a coding task). CEP includes a kickoff guide that interviews you, pushes back on scope, and generates the `CLAUDE.local.md` and `mikado.yaml` for you:

```bash
# In Claude Desktop, drop in the kickoff guide or tell Claude:
# "Read ~/projects/cep/templates/PROJECT_KICKOFF.md and follow it"
```

After the kickoff, copy the generated files into your project and re-run `cep init` to assemble the final `CLAUDE.md`.

### Manage your projects

```bash
cep list                           # List all CEP-managed projects and version status
cep status ~/projects/my-project   # Session log count, Mikado progress, version info
cep diff ~/projects/my-project     # Preview what would change on upgrade
cep upgrade ~/projects/my-project  # Upgrade to latest CEP template (preserves your content)
```

Run `cep --help` for the full command reference.

### What the agent produces

After each session, the agent creates or updates these artifacts in `.cep/`:

```
.cep/
├── logs/YYYYMMDD-HHMM.md       # Session log: what happened, decisions made, open questions
├── blog/YYYYMMDD-HHMM-title.md # Blog post: narrative teaching document about the session
├── guidebook/                   # Reference book: living documentation revised every session
│   ├── README.md                #   Table of contents with chapter links
│   ├── overview.md              #   "Orient me in 5 minutes"
│   ├── architecture.md          #   System design, patterns, data flow
│   ├── [component].md           #   Deep dives per subsystem
│   ├── project-anatomy.md       #   Language-specific project structure explained
│   └── vision.md                #   Roadmap and design philosophy
├── decisions/NNN-title.md       # Architecture Decision Records
├── mikado.yaml                  # Goal decomposition tree with MHC annotations
└── sessions.yaml                # Session index with timestamps and commit hashes
```

**The guidebook** is the crown jewel. It reads like a book — chapters with prev/next navigation, prose explanations of *why* things work the way they do, design patterns named and explained in context, and the "you've probably seen this before, here's how it works *here*" voice that makes it a genuine learning resource. Every session, the agent revises affected pages so the guidebook always reflects the current state of the system.

**The blog** is a linear teaching journal. Each post explains one session's work as if telling a skilled colleague about it over coffee, annotated with pattern labels like `[pattern: Strategy]`, `[convention]`, `[idiom]`, and `[DDIA concept]`.

**Session logs** are structured records: summary, decisions with alternatives and reasoning, Mikado tree progress, open questions, and a "What I Learned" section that explains interesting concepts at the level of someone who's skilled but encountering this specific thing for the first time.

### Customize the template

The base template lives at `templates/CLAUDE.md.base`. When you edit it:

```bash
nano ~/projects/cep/templates/CLAUDE.md.base   # Edit the template
echo "0.3.0" > ~/projects/cep/VERSION          # Bump version
cd ~/projects/cep && git add -A && git commit -m "feat: description"
cep upgrade ~/projects/my-project               # Propagate to projects
```

Per-project customization goes in `.cep/CLAUDE.local.md`, which is never touched by upgrades.

## Contributing

CEP is a personal tool, but its structure is designed to be forkable. If you want to understand how it works internally, adapt it for your own workflow, or contribute back:

### Set up a development environment

```bash
git clone https://github.com/YOUR_USERNAME/cep.git ~/projects/cep
cd ~/projects/cep
```

The CLI is a single bash script at `bin/cep`. The template is at `templates/CLAUDE.md.base`. The project kickoff guide is at `templates/PROJECT_KICKOFF.md`. There's no build system, no dependencies beyond bash and coreutils.

### Understand the design

Read [ROADMAP.md](ROADMAP.md) for where the project is heading. The template itself (`templates/CLAUDE.md.base`) is the most important file — it defines the conventions that every CEP-managed project follows, including the guidebook voice, the session log structure, and the Mikado tree format.

When CEP is self-hosted (managed by CEP itself), its own `.cep/guidebook/` will be the definitive reference for how the system works internally. Until then, this README and the template are the primary documentation.

## Design Philosophy

**One template, many projects.** Fix a problem in how session logs work, upgrade all your projects with one command.

**Project-specific content is sacred.** Upgrades never touch your `.cep/CLAUDE.local.md` or anything below the `CEP:PROJECT_SPECIFIC_START` marker.

**Human learning is the priority.** The documentation conventions — blogs, guidebooks, annotated session logs — exist so that when you come back to a project after hours or days, you understand not just what happened but *why*, and you become a better engineer in the process.

**Start simple, rewrite later.** The CLI is bash. It works. When the feature set stabilizes, [rewrite it in Go with Charm](ROADMAP.md).

## License

MIT — fork it, make it yours.
