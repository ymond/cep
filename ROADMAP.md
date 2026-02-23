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
