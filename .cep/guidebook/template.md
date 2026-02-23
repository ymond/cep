[← Previous: The CLI](cli.md) | [Table of Contents](README.md) | [Next: Project Anatomy →](project-anatomy.md)

# Chapter 4: The Template

> The base template is the product. Everything else — the CLI, the directory structure, the registry — exists to deliver this file to projects. Here's what's in it, how it's organized, and why each section exists.

The file `templates/CLAUDE.md.base` is the most important file in the CEP repository. When assembled into a project's `CLAUDE.md`, it becomes the complete instruction set for an AI coding agent. Every convention, every documentation requirement, every workflow rule lives here. Editing this file is like editing a public API — changes propagate to every managed project on the next `cep upgrade`.

## The Placeholder System

The template contains five placeholders that get substituted during assembly:

| Placeholder | Replaced With | Substitution Method |
|---|---|---|
| `{{CEP_VERSION}}` | Contents of the `VERSION` file (e.g., `0.2.0`) | sed |
| `{{PROJECT_NAME}}` | Second argument to `cep init` | sed |
| `{{UPGRADE_DATE}}` | Today's date in `YYYY-MM-DD` format | sed |
| `{{NOTIFICATION_BLOCK}}` | Notification config (currently a default message) | sed |
| `{{PROJECT_SPECIFIC}}` | Entire contents of `.cep/CLAUDE.local.md` | awk |

The first four are simple string replacements — sed finds the token and substitutes the value. The fifth is different: it replaces a single line with a multiline document. This is why the assembly pipeline has two stages (see the Architecture chapter).

When editing the template, the placeholders are the fragile points. If you accidentally delete `{{PROJECT_SPECIFIC}}` or misspell it, the project-specific content won't be injected. The `cep diff` command is your safety net — always run it against a managed project after editing the template to verify the output looks right.

## Section-by-Section Guide

The template is structured as a series of sections that the agent reads top-to-bottom at session start. The ordering is deliberate — it moves from context (who Raymond is, how he works) to procedures (startup, shutdown) to standards (documentation, coding, testing). Here's what each section does and why it exists.

### "Who I Am"

This section gives the agent the human context it needs to make good decisions. Raymond works evenings and weekends, values deep understanding over just-working code, and needs visible progress in short sessions. This isn't filler — it directly shapes agent behavior. An agent that knows the user values understanding will explain decisions in session logs rather than just listing what it did. An agent that knows sessions are short will prefer small working increments over large incomplete features.

The hardware spec (Arch Linux, Framework 16, RTX 5070, Ryzen AI 9 HX 370) is here for future use — when CEP supports multi-machine task routing, agents will need to know what hardware is available for GPU-intensive tasks like embedding generation.

### "How I Work With You"

Five numbered rules that define the agent's operational philosophy. These are the rules that took iteration to get right:

**Rule 1 (no irreversible decisions silently)** prevents the agent from choosing a database, a protocol, or an architecture pattern without documenting it. The key word is "irreversible" — the agent should make easily-reversible decisions (naming, file organization) without stopping, but pause for things that would be painful to undo.

**Rule 2 (small working increments)** fights the agent's natural tendency toward large, ambitious commits. Every commit should leave the project runnable.

**Rule 3 (when blocked, move on)** prevents the agent from spinning on a problem. Log it, pick up another node from the Mikado tree.

**Rule 4 (keep going until done)** is the "stop too early" fix. Without this rule, agents tend to complete one logical section and then stop to ask "should I continue?" — even when there are clearly more nodes to work on. This rule makes continuation the default and lists the only valid reasons to stop.

**Rule 5 (don't invent features)** constrains scope. The agent builds what's in the Mikado tree and nothing more. The "Possibilities" section at session end gives it a safe outlet for suggesting what the completed work enables.

### "Startup" and "Shutdown"

These are step-by-step procedures the agent executes at the beginning and end of every session. The startup procedure ensures the agent has full context: the Mikado tree, the most recent session log, relevant ADRs. The shutdown procedure ensures nothing is lost: session log written, blog post written, guidebook updated, Mikado tree marked up, commits made.

The shutdown includes an `espeak` notification and a `systemctl suspend` call. This is specific to Raymond's workflow — he starts the agent and walks away (or goes to sleep). The notification and auto-sleep mean the computer isn't running idle until morning.

### Documentation Requirements

The longest section of the template. It defines the format and voice for four documentation artifacts:

**Session logs** are structured records with mandatory sections: summary, decisions (with alternatives and reasoning), Mikado progress, "What I Learned" (educational), open questions, and possibilities. The structure ensures consistency across sessions and makes logs machine-parseable for future tooling.

**Blog posts** are narrative teaching documents. The template specifies that they should be written for a generalist programmer "over coffee," with inline annotations for patterns (`[pattern: Strategy]`), conventions (`[convention]`), idioms (`[idiom]`), and concepts from specific sources (`[DDIA concept]`, `[XP principle]`). The blog's purpose is education — over weeks of reading these, Raymond should absorb software design thinking.

**The guidebook** is the most elaborately specified artifact. The template defines the directory structure, the navigation convention (prev/next links), the voice (warm, peer-to-peer, "you've probably seen this before"), and specific requirements for each chapter type. The guidebook voice description is perhaps the most distinctive part of CEP — it's an explicit encoding of how technical documentation should read.

**ADRs** follow the standard Architecture Decision Record format: context, options considered with pros/cons, decision, and consequences.

### The Mikado Tree

The template defines the YAML format for goal decomposition and the MHC (Model of Hierarchical Complexity) annotation system. MHC levels range from 8 (concrete operational — "run this command") to 13 (paradigmatic — "create new frameworks"). The purpose is to make visible what kind of thinking each task demands, so the agent brings the right cognitive frame.

### Coding Standards and Testing

The template enforces strict XP-style TDD: Red (write a failing test), Green (minimal code to pass), Refactor (clean up with tests still passing). This is non-negotiable in the template. The section is detailed because TDD discipline breaks down in the specifics — agents will skip the Red phase if not explicitly told to watch the test fail, and they'll write more code than necessary in the Green phase if not told to write the minimum.

### "Project-Specific Context"

The final section is the injection point for `.cep/CLAUDE.local.md`. It's wrapped in HTML comments (`<!-- CEP:PROJECT_SPECIFIC_START -->` and `<!-- CEP:PROJECT_SPECIFIC_END -->`) that serve as visual markers in the assembled output. The `{{PROJECT_SPECIFIC}}` placeholder sits between them, replaced by awk during assembly.

## Editing the Template Safely

When you edit `templates/CLAUDE.md.base`:

1. Make the change.
2. Run `cep diff` on at least one managed project (e.g., `cep diff ~/projects/cep`).
3. Review the diff carefully — does the output look right? Did any placeholders break?
4. If the change affects agent behavior (not just wording), bump the version in `VERSION`.
5. Run `cep upgrade` on managed projects to propagate the change.

The self-referential nature of CEP means that template changes don't affect the current session. The agent is reading a snapshot of CLAUDE.md that was assembled *before* the session started. Template edits take effect on the next session after `cep upgrade`. This is the natural firewall described in the Architecture chapter.

## The Template as a Product

It's worth stepping back to appreciate what this file really is. The base template is not configuration. It's not documentation. It's the *product*. CEP's value proposition is that this template, when injected into a project, produces a consistent, high-quality workflow from any AI coding agent. The CLI exists to deliver this template to projects. The guidebook voice, the session log structure, the Mikado tree format, the blog post conventions — all of these are features of the product, iterated on and refined through dogfooding.

When you think about "what should CEP's next version include?", you're thinking about what should go in this template. Every improvement to the template improves every managed project simultaneously.

[← Previous: The CLI](cli.md) | [Table of Contents](README.md) | [Next: Project Anatomy →](project-anatomy.md)
