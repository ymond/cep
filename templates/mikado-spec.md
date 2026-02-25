# Mikado Tree Specification

This document is the complete specification for the Mikado tree format used by CEP.
A fresh Claude session should be able to read this file alone and correctly create,
edit, and traverse any `mikado.yaml` file.

## Tree Format

Maintain a file at `.cep/mikado.yaml` that represents the current goal decomposition.
The tree uses YAML for arbitrary nesting depth, machine parseability, and future
tooling (a collapsible tree browser, like DOM inspection in browser dev tools).

Format:

```yaml
project: "{{PROJECT_NAME}}"
updated: "YYYY-MM-DD"
active_path: "goal > v0.2 > First task > Current step"  # breadcrumb to current focus

goal:
  title: "Top-level objective"
  status: active
  mhc: 12          # Model of Hierarchical Complexity level
  children:
    - title: "v0.1 — First milestone"
      status: done
      mhc: 11
      completed: "YYYY-MM-DD"
      children:
        - title: "Completed subtask"
          status: done
          mhc: 9
          completed: "YYYY-MM-DD"
    - title: "v0.2 — Current milestone"
      status: active
      mhc: 11
      children:
        - title: "First task (do this before second task)"
          status: active
          mhc: 10
          children:
            - title: "Atomic step"
              status: done
              mhc: 9
              completed: "YYYY-MM-DD"
            - title: "Current step"
              status: active  # <-- deepest pending/active leaf = work here
              mhc: 9
            - title: "Next step"
              status: pending
              mhc: 8
        - title: "Second task (depends on first being done)"
          status: pending
          mhc: 9
        - title: "Blocked task"
          status: blocked
          mhc: 10
          reason: "Waiting on upstream API docs"
        - title: "Deferred task"
          status: deferred
          mhc: 10
          reason: "Deferring past v0.2 — want feedback from playtesting first"
```

## Node Status Values

- **`done`** — Completed. Include `completed: "YYYY-MM-DD"` date.
- **`active`** — Currently being worked on. Only one leaf node should be active at a time.
- **`pending`** — Ready to work on, not yet started.
- **`blocked`** — Attempted but cannot proceed. Include `reason:` explaining why.
- **`deferred`** — Deliberately postponed. Include `reason:` explaining why.

`blocked` means "I *can't* do this without external input." `deferred` means
"we *chose* not to do this yet." Both require a `reason` field. The distinction
helps Raymond prioritize: blocked items may need his input, deferred items are
parked by design.

## Model of Hierarchical Complexity (MHC) Levels

Every node in the Mikado tree must be annotated with its MHC level. This is not
correlated with tree depth — a deep leaf node may require higher-order thinking
than its parent. The purpose is to make visible *what kind of thinking* each task
demands, so that when working on a node, you bring the right cognitive frame rather
than over-simplifying a complex decision or over-complicating a concrete one.

Reference levels most relevant to software work:

- **8  — Concrete operational:** Direct, tangible actions with clear outcomes.
  "Run this command." "Rename this variable." "Copy this file."
- **9  — Abstract:** Working with concepts that aren't directly visible.
  "Implement this interface." "Write a function that handles X."
  Single abstractions, one organizing principle at a time.
- **10 — Formal operational:** Reasoning about relationships between abstractions.
  "Design a module where components X and Y interact through Z."
  Requires holding multiple abstractions and their relationships simultaneously.
- **11 — Systematic:** Constructing whole systems from interrelated formal operations.
  "Architect the data pipeline so ingestion, embedding, storage, and query work
  together." Requires understanding how changing one part affects the whole.
- **12 — Metasystematic:** Comparing, evaluating, or integrating entire systems.
  "Choose between a RAG architecture and a fine-tuning approach by evaluating
  their systemic tradeoffs." Requires reasoning *about* systems, not just within them.
- **13 — Paradigmatic:** Creating new frameworks that integrate metasystematic insights.
  Rare in day-to-day work but relevant when inventing novel approaches.

When annotating a node:
- Ask: "What kind of thinking does this task *actually* require to do well?"
- A task that *sounds* simple might be high-MHC if the decision has systemic impact
- A task that *sounds* grand might be low-MHC if the action itself is concrete
- When you find yourself operating at the wrong level (e.g., debating architecture
  when the task is MHC 8), note this in the session log — it's a valuable
  self-awareness signal

## Traversal Algorithm

This is how you decide what to work on. Follow this algorithm exactly.

**Children within any node are ordered top-to-bottom by intended execution order.**
Position encodes priority and implicit dependencies. The first child should be done
before the second. If you reorder children, you are changing the execution plan.

1. **Scan** the top-level children of `goal` from top to bottom.
2. **Find** the first child whose status is `active` or `pending`. Skip `done`,
   `blocked`, and `deferred` nodes.
3. **Descend** into that child. At each level, pick the first child whose status
   is `active` or `pending` (depth-first, always picking the first eligible child).
4. **Work** when you reach the deepest `active` or `pending` leaf — that is your
   current task. If it needs further decomposition, add children, then recurse.
5. **After completing a leaf** (mark it `done`), check if its parent is now
   completable (all children `done`). If so, mark the parent `done` too. Then
   return to step 3 within the same branch to find the next eligible leaf.
6. **If blocked**, mark the node `blocked` with a `reason`, then return to step 3
   to find the next eligible leaf in the same branch. If the entire branch is
   blocked or done, return to step 2 to try the next top-level branch.
7. **Stop** when every reachable node is `done`, `blocked`, or `deferred`.

`active_path` is a convenience bookmark — update it whenever focus changes so that
resume is fast. But the algorithm above is the source of truth, not `active_path`.

## Additional Rules

- When you discover a new dependency, add it as a child before proceeding
- Never delete completed nodes — they are part of the learning record
- When starting a session, state which node you're working on, its MHC level,
  and what kind of thinking that implies
- If a `blocked` or `deferred` node is a dependency of a later node (the later
  node cannot proceed without it), mark the later node `blocked` as well with a
  `reason` referencing the dependency
