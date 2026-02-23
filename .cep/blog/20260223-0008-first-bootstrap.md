# First Bootstrap: CEP Gets Its Own Guidebook, Tests, and a Bug Fix

*Session 20260223-0008 — The session where CEP became self-documenting.*

---

When a tool manages its own development, the first real session is a rite of passage. This was that session for CEP: the first time the system's own Mikado tree got worked from top to bottom, producing a complete guidebook, a functional test suite, and — as a bonus — uncovering a lurking bug in the CLI.

## What Happened

The Mikado tree for CEP v0.2.0 had four branches: verify the bootstrap, write the guidebook, add tests, and audit the template. All four branches got completed in a single session. The whole tree went from `active` to `done`.

## The Guidebook: Writing a Book About a Book-Writing System

The most substantial work was writing six guidebook chapters. The guidebook is CEP's reference documentation — not auto-generated API docs, but hand-written prose that explains how the system works and why it's built that way. Writing a guidebook *for the system that produces guidebooks* is naturally self-referential, but the experience validated the template's instructions: the voice guidelines ("warm, peer-to-peer, explain the why before the what") were specific enough to produce consistent output across all six chapters without mid-session correction.

The chapter structure follows a deliberate reading order `[convention]`: start with orientation (Overview), zoom into system design (Architecture), go deep on individual components (CLI, Template, Project Anatomy), and end with forward-looking context (Vision). Each chapter has prev/next navigation links — a pattern borrowed from GitBook-style documentation `[convention]` — so the guidebook reads linearly like a book but supports random access through the table of contents.

One thing worth noting about the guidebook voice: it's explicitly designed for a reader who "has seen everything before but needs explicit reminders." This means when explaining something like `set -euo pipefail` in the CLI chapter, the guidebook doesn't assume the reader knows what each flag does — but it also doesn't talk down. It explains the flags, then immediately connects them to a debugging scenario the reader has probably experienced. This "bridge to experience" technique `[best practice]` is what makes the guidebook a teaching tool rather than a reference card.

## The Test Suite: TDD Catches a Real Bug

The testing work followed strict TDD `[XP principle]`. CEP is a bash CLI, so the test harness is bash: a ~150-line script providing `assert_equals`, `assert_file_exists`, `assert_file_contains`, `assert_exit_code`, automatic temp directory creation and cleanup, and a test runner with colored output. No external test framework — keeping with CEP's "bash-first, no dependencies" principle.

The test suite covers all five CLI commands with 30 tests total:
- **cep init:** 11 tests covering scaffolding, assembly, placeholder substitution, re-init preservation, registry management
- **cep upgrade:** 6 tests covering version bumping, reassembly, content preservation, early-exit, directory creation
- **cep diff:** 5 tests covering no-op detection, change display, non-modification guarantees
- **cep status/list:** 8 tests covering output content, version comparison, error handling

The interesting moment came in the upgrade tests. `test_upgrade_reassembles_claude_md` replaces a project's `CLAUDE.md` with junk content ("OLD CONTENT"), then runs `cep upgrade` and checks that the file is properly reassembled. The test failed. The upgrade command crashed silently.

### The Bug: `set -euo pipefail` Meets `grep`

Here's the pipeline that broke:

```bash
project_name="$(head -3 "$project_path/CLAUDE.md" | grep 'Project:' | sed 's/.*Project: //')"
[[ -z "$project_name" ]] && project_name="Unknown"
```

This code *looks* correct. If grep finds nothing, the pipeline produces empty output, the variable is empty, and the next line falls back to "Unknown." Except it doesn't work that way under `set -euo pipefail`.

The issue is a three-way interaction `[idiom]`:

1. **`grep` returns exit code 1** when it finds no matches. Not just an empty string — a non-zero exit code.
2. **`pipefail`** makes the pipeline's return code the exit code of the rightmost failing command. So `head | grep | sed` returns 1 (from grep), even though `head` and `sed` succeed.
3. **`set -e`** terminates the script on any non-zero exit code. The assignment `project_name="$(pipeline)"` inherits the pipeline's exit code 1, which triggers `set -e`, and the script exits before reaching the fallback.

There's an additional subtlety. In bash, `local var="$(failing_command)"` does NOT trigger `set -e` — the `local` keyword always returns 0, masking the command's exit code. The CEP CLI declares and assigns on separate lines:

```bash
local project_name                          # always returns 0
project_name="$(pipeline_that_returns_1)"   # returns 1 → script exits
```

The separated declaration is actually a `[best practice]` to *avoid* the `local` masking problem (otherwise you'd never know the assignment failed). But it means the exit code propagates, and the grep failure kills the script.

The fix is simple: add `|| true` to the pipeline:

```bash
project_name="$(head -3 ... | grep 'Project:' | sed '...' || true)"
```

The `|| true` means "if the pipeline fails, return 0 instead." The same bug existed in both `cmd_upgrade` and `cmd_diff` — both were fixed.

This is a classic bash gotcha, and it's the kind of thing that survives code review because the fallback handling *looks* correct. Only testing with edge-case input catches it. The TDD discipline `[XP principle]` — writing tests that exercise boundary conditions before trusting the code — caught a bug that visual inspection missed.

## The Template Audit: Everything Holds

The final branch was reviewing the template itself — specifically the "stop too early" problem, blog post instructions, and guidebook maintenance instructions. The verdict: all three are adequate. The stop-too-early fix (Rule 4: "Keep going until the Mikado tree is done") is explicit and has clear escape conditions. The blog instructions specify audience, voice, annotation labels, and connection to the larger system. The guidebook instructions are detailed enough to produce a complete 6-chapter book on first use.

No template changes were made, so no version bump was needed.

## Where This Fits in the Larger System

This session took CEP from "scaffolded but empty" to "self-documenting and tested." Before this session, CEP managed its own development in theory — it had a `.cep/` directory and a Mikado tree, but no session logs, no guidebook, no tests, and no evidence that the system actually works when put through its paces.

After this session, CEP has:
- A **guidebook** that any future session can read to understand the system
- A **test suite** that catches regressions in the CLI
- A **bug fix** that makes the upgrade/diff commands more robust
- A **session log** and **blog post** that demonstrate the documentation pipeline working

The v0.2.0 goal — "CEP manages its own development, self-hosted, tested, and fully documented" — is complete. The next work (defined in the ROADMAP) will be chosen by Raymond based on what feels most valuable.
