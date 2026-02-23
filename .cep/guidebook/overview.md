[← Table of Contents](README.md) | [Next: Architecture →](architecture.md)

# Chapter 1: Overview

> What CEP is, what problem it solves, how to get started in five minutes, and a map of the moving parts. Read this first.

CEP — the Context Engineering Program — is a personal developer platform that structures how AI coding agents work on your projects. It is not a framework, not a library, and not an IDE plugin. It is a set of conventions, encoded in a template, distributed by a CLI, that ensures every project gets the same documentation discipline, decision-tracking rigor, and learning-oriented output regardless of which agent session touches it.

The core problem CEP solves is *amnesia*. You start a project with an AI agent. The agent writes code, makes architectural decisions, and moves fast. You come back the next evening and the code is there, but the reasoning is gone. Why did it pick this database? What alternatives did it consider? How does the ingestion pipeline connect to the query layer? You can read the code, but code doesn't explain itself at the system level. CEP fixes this by making the agent produce structured documentation as a first-class output of every session — not as an afterthought, but as part of the defined workflow.

## How It Works

CEP operates through a single mechanism: **template assembly**. A base template (`templates/CLAUDE.md.base`) defines all the conventions an agent should follow — how to start a session, how to log decisions, how to write a guidebook, how to decompose goals. When you run `cep init` on a project directory, the CLI takes that template, substitutes a few project-specific variables (name, version, date), and injects the contents of `.cep/CLAUDE.local.md` (your project-specific context) into the appropriate location. The result is a `CLAUDE.md` file in the project root — the single file the agent reads at the start of every session.

When you improve the template — say, by adding clearer instructions for blog posts — you run `cep upgrade` on each managed project and the new conventions propagate. Your project-specific content is preserved; only the base template portions change. This is the **one template, many projects** principle at work.

## Core Components

| Component | What It Does | Where It Lives |
|---|---|---|
| **CLI** (`cep`) | Scaffolds projects, assembles CLAUDE.md, manages upgrades, shows status | `bin/cep` |
| **Base Template** | Defines all agent conventions — the product itself | `templates/CLAUDE.md.base` |
| **Kickoff Guide** | Interactive planning template for brainstorming new projects | `templates/PROJECT_KICKOFF.md` |
| **Project Registry** | Plain text list of managed project paths | `.registry/projects` |
| **Version Marker** | Single-line version string, source of truth for CEP version | `VERSION` |

Within each managed project, CEP creates a `.cep/` directory containing:

| Artifact | Purpose |
|---|---|
| `CLAUDE.local.md` | Project-specific context injected into the assembled CLAUDE.md |
| `mikado.yaml` | Goal decomposition tree with MHC (cognitive complexity) annotations |
| `sessions.yaml` | Index of all sessions with timestamps, commits, and ADR references |
| `logs/` | Per-session structured logs: summary, decisions, progress, open questions |
| `blog/` | Per-session narrative teaching posts for a generalist programmer audience |
| `guidebook/` | Living reference book about the system, revised every session |
| `decisions/` | Architecture Decision Records (ADRs) for significant technical choices |
| `version` | Which CEP version this project was last upgraded to |

## Quick Start

```bash
# Install: add the CLI to your PATH
export PATH="$HOME/projects/cep/bin:$PATH"

# Create a new project
cep init ~/projects/my-project my-project

# Edit your project context and first goal
nano ~/projects/my-project/.cep/CLAUDE.local.md
nano ~/projects/my-project/.cep/mikado.yaml

# Start your agent
cd ~/projects/my-project && claude
```

The agent reads `CLAUDE.md`, initializes a session, picks up the active Mikado node, and starts working — logging decisions, writing tests first, and updating the guidebook as it goes.

## Tech Stack

CEP is deliberately minimal. The entire runtime is a single bash script plus a Markdown template.

| Technology | Role | Why This Choice |
|---|---|---|
| **Bash** | CLI implementation | Zero dependencies, runs on any Linux box, no build step. The feature set is simple enough that bash is the right tool — the Go rewrite is planned for when complexity demands it. |
| **sed + awk** | Template assembly | Standard coreutils. sed handles single-line placeholder substitution; awk handles the multiline injection of CLAUDE.local.md content. |
| **YAML** | Mikado trees, session index | Supports arbitrary nesting depth (critical for goal decomposition), is human-readable, and is machine-parseable for future tooling like a TUI tree browser. |
| **Markdown** | Everything else | Session logs, blog posts, guidebook pages, ADRs, README. Markdown is the lingua franca of developer documentation — it renders on GitHub, in editors, and in the terminal. |
| **Git** | Version control | Every CEP-managed project is assumed to be a git repo. The CLI stores a version marker but doesn't manage git operations directly. |

## What CEP Is Not

CEP is not a code generator. It doesn't write your application — your AI agent does that. CEP tells the agent *how to work*: how to decompose goals, how to document decisions, how to write tests, how to communicate what it did. Think of it as a management layer for the agent's workflow, not for the agent's output.

CEP is also not generic (yet). The template currently hardcodes Raymond's context, preferences, and hardware. Genericization — user profiles, interactive interviews, configurable conventions — is on the roadmap but intentionally deferred. The tool works for one user right now, and that's enough to validate the approach before scaling it.

[← Table of Contents](README.md) | [Next: Architecture →](architecture.md)
