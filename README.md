# CEP — Context Engineering Package

A personal developer platform for working with AI coding agents like [Claude Code](https://docs.anthropic.com/en/docs/claude-code). CEP gives every project a consistent structure for how your AI agent makes decisions, documents its work, and communicates what it did so you can learn from it.

## The Problem

You start a project with an AI coding agent. It writes code. You come back later and have no idea *why* it made the choices it did, what alternatives it considered, or how the pieces fit together. You can read the code, but the reasoning is gone.

Multiply that across several projects and you're managing a collection of codebases you don't fully understand, built by an agent with no memory of what it learned.

CEP fixes this by giving every project:

- A **CLAUDE.md** that tells the agent how to behave, document, and communicate
- A **Mikado tree** (YAML) that decomposes goals into tasks with cognitive complexity annotations
- **Session logs** that capture not just what was done, but why and what was considered
- **Architecture Decision Records** for significant technical choices
- A **CLI tool** to manage all of this across every project you work on

## Quick Start

```bash
git clone https://github.com/YOUR_USERNAME/cep.git ~/projects/cep
cd ~/projects/cep
chmod +x setup-cep.sh
./setup-cep.sh
source ~/.bashrc  # or ~/.zshrc
```

Scaffold your first project:

```bash
mkdir -p ~/projects/my-project
cep init ~/projects/my-project my-project
```

This creates:

```
my-project/
├── CLAUDE.md                      # assembled from CEP template + project context
└── .cep/
    ├── version                    # tracks which CEP version this project uses
    ├── mikado.yaml                # goal decomposition tree
    ├── CLAUDE.local.md            # project-specific context (preserved on upgrade)
    ├── logs/                      # session logs (created by the agent)
    └── decisions/                 # architecture decision records
```

Edit your project-specific context:

```bash
nano ~/projects/my-project/.cep/CLAUDE.local.md
```

Then start your agent:

```bash
cd ~/projects/my-project
claude  # or however you launch Claude Code
```

The agent reads CLAUDE.md and follows the conventions defined there.

## CLI Reference

### `cep init <project-path> <project-name>`

Scaffolds a new CEP-managed project. Creates the `.cep/` directory, assembles CLAUDE.md from the latest template, and registers the project in the CEP registry.

Safe to re-run — it will ask before overwriting and preserves your project-specific content.

### `cep status [project-path]`

Shows CEP version info, session log count, and Mikado tree progress for a project. Defaults to the current directory if no path is given.

### `cep list`

Lists all CEP-managed projects and their version status.

### `cep upgrade <project-path>`

Upgrades a project to the latest CEP version. Regenerates CLAUDE.md from the current template while preserving everything in `.cep/CLAUDE.local.md`. The project-specific content is never touched.

### `cep diff <project-path>`

Shows what would change in CLAUDE.md if you ran `cep upgrade`. Useful for reviewing template changes before applying them.

## Customizing Your Setup

### Per-Project Context

Each project has a `.cep/CLAUDE.local.md` file. This is where you describe what the project is, its tech stack, and any conventions that are specific to this project. This content gets injected into the assembled CLAUDE.md below the `CEP:PROJECT_SPECIFIC_START` marker and is preserved across upgrades.

### Modifying the Base Template

The base template lives at `templates/CLAUDE.md.base`. When you edit it, bump the version in `VERSION`, commit, and then run `cep upgrade` on each project to propagate your changes.

```bash
# Edit the template
nano ~/projects/cep/templates/CLAUDE.md.base

# Bump version
echo "0.2.0" > ~/projects/cep/VERSION

# Commit
cd ~/projects/cep
git add -A
git commit -m "feat: description of what changed"

# Upgrade your projects
cep upgrade ~/projects/filebrain
cep upgrade ~/projects/other-project
```

### Re-installing After Changes

If you pull updates or manually edit files in the CEP repo, there's no separate install step. The CLI reads directly from `~/projects/cep/templates/` and `~/projects/cep/VERSION` at runtime. Just make sure `~/projects/cep/bin` is in your PATH (the setup script handles this).

If you need to re-run setup on a fresh machine:

```bash
cd ~/projects/cep
chmod +x setup-cep.sh
./setup-cep.sh
source ~/.bashrc
```

## What's in the CLAUDE.md Template

The base template defines conventions that apply to every project:

**Session Logs** — After every work session, the agent writes a structured log covering what was accomplished, what decisions were made (with alternatives and reasoning), Mikado tree progress, and explanations of interesting concepts for your review.

**Mikado Tree** — Goals are decomposed in a YAML tree with unlimited nesting depth. Every node is annotated with its level on the [Model of Hierarchical Complexity](https://en.wikipedia.org/wiki/Model_of_hierarchical_complexity) (MHC), which tracks *what kind of thinking* a task demands — not how deep it is in the tree. This builds awareness of when you're over-simplifying a complex decision or over-complicating a concrete one.

**Strict XP Testing** — The template enforces Test-Driven Development as described in Kent Beck's "Test Driven Development: By Example." Red-green-refactor with no exceptions. The agent never writes production code without a failing test first.

**Architecture Decision Records** — Significant technical choices get their own document with context, options considered, the decision, and its consequences.

**Coding Standards** — Clear, readable code. Atomic commits. Explicit error handling. Justified dependencies.

## Design Philosophy

**One template, many projects.** Fix a bug in how session logs work, upgrade all your projects with one command.

**Project-specific content is sacred.** Upgrades never touch your `.cep/CLAUDE.local.md` or anything below the `CEP:PROJECT_SPECIFIC_START` marker.

**Human learning is the priority.** The documentation conventions exist so that when you come back to a project after hours or days away, you can understand not just what happened but *why*, at whatever depth you want to explore.

**Start simple, rewrite later.** The CLI is bash. It works. When the feature set stabilizes, rewrite it in Go with a proper TUI.

## Starting a New Project

CEP includes a kickoff guide that turns a stream-of-consciousness idea into a fully
planned project with a `CLAUDE.local.md` and `mikado.yaml`.

### How to Use It

Open a new conversation in **Claude Desktop** (not Claude Code — the kickoff is a
conversation, not a coding task). Then either:

- Drag and drop `templates/PROJECT_KICKOFF.md` into the chat, or
- If you have the Filesystem MCP connector enabled, just tell Claude:
  "Read `~/projects/cep/templates/PROJECT_KICKOFF.md` and follow it"

Then start talking about your idea. Claude will interview you, push back on scope
creep, help you define a realistic v0.1, and decompose it into a Mikado tree. When
you're both happy with the plan, it writes the files to `~/Claude/<project-name>/`.

### After the Kickoff

```bash
mkdir -p ~/projects/<project-name>
cep init ~/projects/<project-name> <project-name>
cp ~/Claude/<project-name>/CLAUDE.local.md ~/projects/<project-name>/.cep/CLAUDE.local.md
cp ~/Claude/<project-name>/mikado.yaml ~/projects/<project-name>/.cep/mikado.yaml
cep init ~/projects/<project-name> <project-name>  # regenerate CLAUDE.md
cd ~/projects/<project-name>
claude --dangerously-skip-permissions
```

### Why Claude Desktop and Not Claude Code?

The kickoff is an open-ended brainstorming conversation — exploring ideas, getting
honest pushback, refining scope, making tradeoffs. Claude Desktop is designed for
that kind of back-and-forth. Claude Code is an execution tool that wants a clear
task and a codebase. Use Desktop to plan, Code to build.

### Keeping the Kickoff Guide Current

The `PROJECT_KICKOFF.md` template includes a list of your existing projects so Claude
can spot overlaps and dependencies. Update this list each time you start a new project:

```bash
nano ~/projects/cep/templates/PROJECT_KICKOFF.md
# Update the "My existing CEP-managed projects" list
cd ~/projects/cep
git add -A
git commit -m "docs: add <project-name> to kickoff project list"
```

## Roadmap

- **v0.1.0** — Current. `init`, `status`, `list`, `upgrade`, `diff`.
- **v0.2.0** — Notification support (Gotify integration for when the agent needs your input).
- **v0.3.0** — Mikado tree browser (collapsible TUI for exploring the decision tree).
- **v1.0.0** — Go rewrite with [Charm](https://charm.sh/) libraries.

## License

MIT — fork it, make it yours.
