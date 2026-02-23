[← Previous: Project Anatomy](project-anatomy.md) | [Table of Contents](README.md)

# Chapter 6: Vision

> Where CEP is going, what's been built so far, and the design philosophy that connects the present architecture to the future roadmap. This chapter helps you understand why certain abstractions exist and what they're designed to support.

## What's Built

CEP v0.2.0 has a working foundation:

A **CLI** that initializes projects, assembles CLAUDE.md files from a base template plus project-specific content, tracks managed projects in a registry, shows version status, previews upgrades with diff, and propagates template changes across the portfolio. Five commands, one script, zero dependencies.

A **base template** that defines a complete agent workflow: session startup/shutdown procedures, structured documentation requirements (logs, blogs, guidebook, ADRs), strict TDD practices, a Mikado tree goal decomposition format with cognitive complexity annotations, and a distinctive guidebook voice designed for human learning.

A **kickoff guide** that structures the initial planning conversation for new projects — interviewing the user, pushing back on scope, and generating the project-specific context files.

**Self-hosting** (dogfooding): CEP manages its own development. This guidebook, the session logs, and the Mikado tree you're reading exist because CEP follows its own conventions.

## The Design Philosophy

Three principles shape every decision about CEP's direction.

### Human Learning Is the Priority

CEP exists so that Raymond becomes a better engineer by reviewing AI agent work. This is not a secondary benefit — it's the primary product goal. The guidebook voice ("a generalist engineer who's seen everything before but needs explicit reminders"), the blog post annotations (`[pattern: Strategy]`, `[convention]`, `[DDIA concept]`), the session log "What I Learned" section, the Mikado tree MHC annotations — all of these exist to make the agent's output a learning resource, not just a work log.

This principle drives specific technical decisions. For example, the template requires session logs to include "Alternatives Considered" for every decision. An agent optimizing for speed would skip this. CEP requires it because understanding *what wasn't chosen and why* is how you learn to reason about architecture, not just memorize one solution.

### One Template, Many Projects

Every CEP-managed project gets its conventions from the same base template. When you improve the template — clearer guidebook voice instructions, better session log format, stricter TDD rules — the improvement propagates to every project via `cep upgrade`. This is the same principle behind package managers, but applied to agent conventions rather than code dependencies.

The project-specific context (`CLAUDE.local.md`) is the customization layer. It's injected into the template but never touched by upgrades. This separation means you get the benefits of centralized improvement without losing per-project flexibility. If you've worked with CSS frameworks that provide base styles you override per-component, the mental model is similar.

### Start Simple, Rewrite Later

The CLI is bash. The data store is flat files. The registry is one path per line. This isn't laziness — it's a deliberate choice to avoid premature abstraction. The feature set hasn't stabilized yet. Building an elegant Go CLI with a SQLite database and a TUI dashboard *now* would mean rebuilding it every time the feature set changes. Building it in bash means the entire runtime is 300 lines that take 10 minutes to understand and 30 seconds to modify.

The rewrite boundary is clear: when CEP needs structured data queries (filtering projects by tag, searching session logs), concurrent operations (parallel upgrades), or rich terminal UI (Mikado tree browser), bash won't be enough. The ROADMAP explicitly marks the Go rewrite for when these features arrive.

## What's Planned

The roadmap (`ROADMAP.md`) organizes planned work into themed groups. These aren't sequenced yet — they're clusters of related capabilities that will become versioned milestones during planning sessions.

### Git Workflow

Branch-per-experiment strategy, where the agent creates branches for different approaches and documents them PR-style. This adds a layer of review discipline that the current "commit to main" workflow doesn't have. It matters more as projects grow and experiments become riskier.

### Notifications

Gotify integration for mobile notifications. The template already has a `{{NOTIFICATION_BLOCK}}` placeholder that currently renders as "not yet configured." When notifications ship, this placeholder will expand to configuration instructions. The two-level notification system ("need your input" vs. "just FYI") matches Raymond's workflow: some things can wait until morning, others need a nudge.

### Context Window Management

As agent sessions get longer, the context window fills up. This cluster of features addresses that: conversation summary artifacts, auto-generated "fresh chat initialization" prompts, and clipboard integration for quickly starting new sessions with the right context. This is where the session logs and guidebook become inputs, not just outputs — the agent reads previous session summaries to pick up where it left off.

### Multi-Machine Support

Hardware auto-detection (replacing the hardcoded specs in the template), a machine registry, and task routing to appropriate hardware. This becomes relevant when Raymond has multiple machines — route GPU-heavy tasks to the machine with the best GPU, route long-running builds to a machine that's not being used interactively.

### User Onboarding

Genericization of the template. Currently, CEP hardcodes Raymond's context, preferences, and hardware. The planned interactive interview would collect this information from any user, generate a user profile, and inject it into the template. This is the step that makes CEP a tool for others, not just for Raymond. It's deliberately deferred — the conventions need to stabilize through dogfooding before they're generalized.

### The Go Rewrite

The bash CLI will be rewritten in Go using the Charm ecosystem (bubbletea for TUI, lipgloss for styling, huh for forms). The centerpiece feature is a Mikado tree TUI browser — a collapsible tree that works like a DOM inspector in browser dev tools. Combined with dashboards for session logs, progress visualization, and MHC distribution charts, this transforms CEP from a CLI that prints text into an interactive development dashboard.

The rewrite is explicitly deferred until the feature set stabilizes. There's no point building a polished UI for features that might change. The bash version is the prototype; the Go version is the product.

## How the Architecture Supports the Future

Several current design decisions exist because of where CEP is going, not just where it is:

**The placeholder system** (`{{NOTIFICATION_BLOCK}}`, etc.) is designed for extensibility. Adding a new configurable section to the template means adding a new placeholder and a new substitution in `assemble_claude_md()`. The current sed approach works for string replacements; the awk stage handles multiline content. If the number of multiline sections grows, the assembly pipeline might need rethinking — but for now, one multiline injection (project-specific content) is the only case.

**The YAML Mikado tree** is chosen over Markdown or JSON because future tooling needs to parse it. The TUI tree browser will read `mikado.yaml` and render it as a collapsible, interactive tree. YAML's indentation-based nesting maps naturally to visual tree depth. JSON would work functionally but is harder to hand-edit; Markdown would work for display but is harder to parse programmatically.

**The session index** (`sessions.yaml`) captures not just session metadata but commit hashes and ADR filenames. This enables future queries: "which session introduced this decision?", "what was the last session that touched this component?", "show me the git log for this session." None of these queries exist yet, but the data to answer them is being collected from day one.

**The guidebook structure** (README.md as table of contents, prev/next navigation, chapter-per-component) is designed for `cep publish` — a future command that converts the guidebook into HTML, PDF, or epub. The README provides the chapter ordering, the navigation links provide the reading flow, and the consistent voice provides editorial coherence. When `cep publish` ships, the guidebook is already structured for book-like output.

## The Dogfooding Feedback Loop

CEP's most powerful quality-assurance mechanism is that it manages its own development. Every session with CEP-the-project tests CEP-the-template. If the session log instructions are ambiguous, the agent produces a bad log and the problem is visible immediately. If the guidebook voice instructions are unclear, this guidebook suffers and the gap is apparent.

This feedback loop means that CEP's template gets battle-tested continuously, on a project where the stakes are high (the template itself). Improvements discovered during CEP development benefit every managed project. Bugs in the template surface where they're easiest to fix — in the project that owns the template.

The self-referential loop is not an accident. It's the design.

[← Previous: Project Anatomy](project-anatomy.md) | [Table of Contents](README.md)
