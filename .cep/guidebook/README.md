# CEP Guidebook

> The living reference for how CEP works right now. Read this when you're about to work on the codebase, when you need to understand a design decision, or when you want to know why something is the way it is. Start with the Overview if you're new; jump to a specific chapter if you know what you're looking for.

## About This Book

This guidebook is maintained by the AI agent during every work session. It's not auto-generated documentation — it's a hand-written (well, agent-written) reference book in prose, revised and updated as the system evolves. If something in the guidebook contradicts the code, the guidebook is stale and needs updating. File an issue or fix it in the next session.

The voice throughout is peer-to-peer: written for a skilled engineer who's seen most patterns before but needs the specifics of *this* system explained. Expect design patterns named and explained in context, analogies to systems you've probably worked with, and the "why" before the "what."

---

## Table of Contents

### Part I: The System

| Ch | Title | What You'll Find |
|----|-------|-----------------|
| 1 | [Overview](overview.md) | What CEP is, the core components, quick start, tech stack |
| 2 | [Architecture](architecture.md) | Template assembly pipeline, upgrade mechanism, data flow, component diagram |

### Part II: Deep Dives

| Ch | Title | What You'll Find |
|----|-------|-----------------|
| 3 | [The CLI](cli.md) | Command-by-command walkthrough of `bin/cep`, bash idioms explained |
| 4 | [The Template](template.md) | `CLAUDE.md.base` section by section — the product itself |
| 5 | [Project Anatomy](project-anatomy.md) | Directory layout, entry point tracing, how to work in this codebase |

### Part III: The Road Ahead

| Ch | Title | What You'll Find |
|----|-------|-----------------|
| 6 | [Vision](vision.md) | Design philosophy, roadmap, why the architecture supports the future |

---

## Quick Reference

### Common Commands

```bash
cep init <path> <name>     # Scaffold a new CEP-managed project
cep status [path]          # Show version and session info for a project
cep list                   # List all managed projects
cep diff <path>            # Preview what cep upgrade would change
cep upgrade <path>         # Upgrade project to latest CEP template
```

### Tech Stack

| Technology | Role |
|---|---|
| Bash | CLI implementation (single script, zero dependencies) |
| sed + awk | Template assembly (placeholder substitution + multiline injection) |
| YAML | Mikado trees, session index |
| Markdown | Session logs, blog posts, guidebook, ADRs, README |
| Git | Version control (assumed for all managed projects) |

### Key Files

| File | What It Is |
|---|---|
| `bin/cep` | The CLI — the entire runtime |
| `templates/CLAUDE.md.base` | The base template — the product |
| `templates/PROJECT_KICKOFF.md` | Interactive planning guide |
| `VERSION` | Source of truth for CEP version |
| `.registry/projects` | Machine-local list of managed project paths |

---

## Architecture Decision Records

*No ADRs have been created yet. As significant technical decisions are made, they'll be listed here with links to the full records in `.cep/decisions/`.*

---

## Reading Order

For a linear read-through, follow the chapters in order: Overview → Architecture → The CLI → The Template → Project Anatomy → Vision. Each chapter is self-contained enough to read alone, but they build on each other when read sequentially. The Overview orients you, the Architecture shows you the big picture, the deep dives go inside each component, and the Vision connects everything to where the project is heading.
