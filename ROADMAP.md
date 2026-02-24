# CEP Roadmap

## Current: v0.2.0 — Keep Going + Better Docs

Building on the v0.1.0 foundation (`cep init`, `status`, `list`, `upgrade`, `diff`,
CLAUDE.md template, Mikado trees, session logs, ADRs, PROJECT_KICKOFF.md).

- [ ] Fix "stop too early" — clearer instructions to continue through entire Mikado tree
- [ ] Architecture documentation: auto-generated/maintained guidebook about system structure
- [ ] Blog posts: narrative teaching documents generated after each session
- [ ] Dogfooding: CEP manages its own development (bootstrapping in progress)

## Planned — Not Yet Sequenced

These are themed groups of ideas that have emerged from real usage. Version numbers,
ordering, and scope will be decided in a dedicated roadmap planning session.

### `cep work` — Launch Command
- `cep work` as a wrapper around `claude --dangerously-skip-permissions`
- Preamble warning that permissions are being skipped, with options: "yes", "no", "yes, and don't ask again"
- "Don't ask again" preference stored per-project or globally (TBD)
- Pre-flight checks before launch: verify CLAUDE.md exists, show active Mikado node so you know what the agent is about to work on
- Potential future: `cep work --resume` to pass a session UUID for continuation

### Session Archival
- `sessions.yaml` grows monotonically and will eventually consume meaningful context
  budget during Claude Code's startup procedure
- Archive sessions older than N recent sessions into `sessions.archive.yaml`
- Alternative threshold: archive by top-level Mikado task completion — keep sessions
  from the current and previous top-level task, archive the rest
- Deliberately NOT time-based (no "older than M days") — a project on hiatus for
  months should still have full context when resumed. Archival must be activity-based,
  not calendar-based, so that resuming a dormant project gives Claude the same context
  richness as an actively developed one
- Startup procedure reads only `sessions.yaml` (recent); archive is available for
  search but not loaded into context
- Simple implementation: during shutdown, if `sessions.yaml` exceeds N entries, move
  oldest entries to `sessions.archive.yaml`
- Future: a search tool can query the archive (see "Project Memory" theme below)

### Project Memory — RAG Over CEP Artifacts
- Filebrain indexes `.cep/` directories: logs, blog posts, decisions, guidebook pages
- Claude Code queries filebrain during sessions to find precedent: "have we dealt
  with this before?"
- Enables searching across session history, blog posts, ADRs, and guidebook without
  loading everything into context
- Bridges CEP and filebrain without creating a hard dependency — CEP works without
  it, filebrain enhances it
- Depends on filebrain having a queryable CLI or API that Claude Code can invoke
- Could also power a `cep search` command for Raymond to query project history from
  the terminal

### Session Timeline and Heartbeat
- Heartbeat mechanism: agent writes a `heartbeat` timestamp to `sessions.yaml` every N seconds during a session
- If Claude crashes, the heartbeat stops — last heartbeat gives accurate "worked until" time rather than relying on a graceful `ended` timestamp
- Multi-range session tracking: a session can have multiple active time ranges (e.g., initial run + resurrection), each with start/end/heartbeat data
- Reason field per range: "crashed" (heartbeat stopped, no graceful shutdown), "completed" (normal shutdown), "continued" (resurrected to finish specific tasks)
- `cep status` could show total active time per session, time since last heartbeat, and whether the session ended cleanly
- Note: this level of structured data may push sessions.yaml toward SQLite or a more schema-friendly format — evaluate when building

### Git Workflow
- Branch-per-experiment strategy (agent creates branches for different approaches)
- PR-style documentation for posterity
- Better commit organization guidance

### Notifications
- Gotify integration for mobile notifications
- "Need your input" vs "just FYI" notification levels

### Context Window Management
- Conversation summary artifacts (.md) generated at end of planning sessions
- Auto-generate "fresh chat initialization prompt" from project state
- Clipboard integration for prompts (xclip/wl-clipboard/pbcopy)

### Multi-Machine
- Hardware auto-detection (replace hardcoded specs)
- Machine registry (centralized account with registered workhorses)
- Task routing to appropriate machine
- "Last Claude turns off the lights" coordination

### User Onboarding (Genericization)
- Interactive interview on first install (work style, preferences, goals)
- User profile generation from interview
- Genericized templates with user profile injection

### Go Rewrite
- Rewrite CLI in Go with Charm (bubbletea, lipgloss, huh)
- Mikado tree TUI browser (collapsible, like DOM inspector)
- Beautiful dashboards for session logs, progress, MHC distribution

## Ideas Parking Lot

Ideas worth capturing but not yet shaped into concrete plans.

- Localized documentation: sprinkled `.cep.md` files near code for workarounds and non-obvious decisions, kept up to date by the agent — OR achieve the same goal via literate programming techniques (inline comments where code doesn't read like pseudocode). Needs a thinking session to decide which approach.
- Engineering practices preference checklist (1-5 scale per practice) — letting users configure how strictly to follow TDD, pair programming conventions, etc.
- `cep publish`: converter that transforms guidebook markdown into other formats (HTML, PDF, epub) — walk the README.md for chapter ordering, run through pandoc or similar
- Filebrain integration: CEP queries filebrain for project context during sessions
- Filebrain self-indexing dogfood: filebrain indexes its own `.cep/guidebook/` so you can query the guidebook about the system the guidebook describes
- Usage docs vs. contributor guidebook: convention for `docs/` (user-facing) vs `.cep/guidebook/` (contributor-facing) — not every project needs both, but projects with external consumers would benefit from the separation
- Memory palace integration for learning review
- Agent suggests new features opened up by completed work (without implementing them)
- Parallel Claude Code agents: multiple agents working on independent Mikado branches simultaneously, with task locking so two agents don't edit the same files. Raises questions about storage backend — YAML doesn't support concurrent writes well. Would need a service (SQLite with WAL, or a lightweight task queue) to coordinate. Also unclear whether this is a CEP concern (task coordination) or a Claude Code wrapper concern (agent orchestration). Capture the idea but don't build until the pain of sequential-only work is actually felt.
- Storage backend evolution for sessions: sessions.yaml is document-shaped (natural fit for document DB), but parallel agents need row-level locking and independent task updates, which pushes toward relational (SQLite) or a service. The right answer depends on whether parallel agents materialize — YAML is fine for single-agent sequential work, and premature migration adds complexity without benefit. Revisit when archival or parallel agents create real friction.
