# cept Roadmap

## Current: v0.1.0
- [x] `cep init`, `status`, `list`, `upgrade`, `diff`
- [x] CLAUDE.md base template with startup/shutdown
- [x] Mikado tree (YAML) with MHC annotations
- [x] Session logs, ADRs, strict XP/TDD
- [x] PROJECT_KICKOFF.md for brainstorming new projects

## v0.2.0 — Keep Going + Better Docs
- [ ] Fix "stop too early" — clearer instructions to continue through entire Mikado tree
- [ ] Architecture documentation: auto-generated/maintained docs about system structure
- [ ] Sprinkled `.cept.md` files for localized documentation (kept up to date by agent)
- [ ] Engineering practices preference checklist (1-5 scale per practice)
- [ ] Rename CLI from `cep` to `cept`

## v0.3.0 — Git Workflow
- [ ] Branch-per-experiment strategy (agent creates branches for different approaches)
- [ ] PR-style documentation for posterity
- [ ] Better commit organization guidance

## v0.4.0 — Notifications
- [ ] Gotify integration for mobile notifications
- [ ] "Need your input" vs "just FYI" notification levels

## v0.5.0 — Context Window Management
- [ ] Conversation summary artifacts (.md) generated at end of planning sessions
- [ ] Auto-generate "fresh chat initialization prompt" from project state
- [ ] Clipboard integration for prompts (xclip/wl-clipboard/pbcopy)

## v0.6.0 — Multi-Machine
- [ ] Hardware auto-detection (replace hardcoded specs)
- [ ] Machine registry (centralized account with registered workhorses)
- [ ] Task routing to appropriate machine
- [ ] "Last Claude turns off the lights" coordination

## v0.7.0 — User Onboarding
- [ ] Interactive interview on first install (work style, preferences, goals)
- [ ] User profile generation from interview
- [ ] Genericized templates with user profile injection
- [ ] "Human qualities" configuration

## v1.0.0 — Go Rewrite
- [ ] Rewrite CLI in Go with Charm (bubbletea, lipgloss, huh)
- [ ] Mikado tree TUI browser (collapsible, like DOM inspector)
- [ ] Beautiful dashboards for session logs, progress, MHC distribution

## Ideas Parking Lot
- Agent suggests new features opened up by completed work (without implementing them)
- Self-hosting: develop cept using cept
- Filebrain integration: cept queries filebrain for project context
- Memory palace integration for learning review
