[← Previous: Architecture](architecture.md) | [Table of Contents](README.md) | [Next: The Template →](template.md)

# Chapter 3: The CLI

> A command-by-command walkthrough of `bin/cep`. How each command works, what bash idioms it uses, and how to extend it. If you've written shell scripts before, this will feel familiar — but the specific patterns are worth understanding.

The entire CEP runtime is a single file: `bin/cep`. At the time of writing, it's under 300 lines of bash. There's no library directory being sourced, no compiled binary, no external dependencies beyond coreutils. The script handles argument parsing, file I/O, text transformation, and colored terminal output. That's the whole system.

## Script Setup

The script opens with three lines that set the tone for everything that follows:

```bash
#!/usr/bin/env bash
set -euo pipefail
```

The shebang (`#!/usr/bin/env bash`) uses `env` to find bash on the PATH rather than hardcoding `/bin/bash`. This is a portability convention — on some systems (notably FreeBSD and certain NixOS configurations), bash lives in a different location. Using `env` delegates the lookup to the system.

`set -euo pipefail` enables bash's strict mode. This is three flags packed together: `-e` exits immediately if any command returns a non-zero status, `-u` treats unset variables as errors (rather than silently expanding to empty strings), and `-o pipefail` makes a pipeline's return status the exit code of the last command that failed (rather than the last command in the pipe, which might succeed). If you've debugged a bash script where an error was silently swallowed five lines before the visible failure, you understand why these flags exist. They turn bash from a language that hides problems into one that surfaces them immediately.

After strict mode, the script resolves its own location:

```bash
CEP_DIR="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
CEP_VERSION="$(cat "$CEP_DIR/VERSION")"
```

`readlink -f "$0"` resolves the full path to the script, following symlinks. `dirname` strips the filename to get the directory (`bin/`). `cd ... && pwd` moves up one level and prints the absolute path. This gives `CEP_DIR` — the root of the CEP repository — regardless of where the script is called from or whether it's invoked through a symlink. This pattern is the standard way for a bash script to find "its own" files.

## Command Dispatch

At the bottom of the script, a `case` statement routes subcommands:

```bash
case "${1:-}" in
    init)    shift; cmd_init "$@" ;;
    status)  shift; cmd_status "$@" ;;
    list)    cmd_list ;;
    upgrade) shift; cmd_upgrade "$@" ;;
    diff)    shift; cmd_diff "$@" ;;
    -h|--help|"") usage ;;
    *)       echo -e "${RED}Unknown command: $1${NC}"; usage; exit 1 ;;
esac
```

The `${1:-}` syntax is a bash parameter expansion that means "the value of `$1`, or empty string if `$1` is unset." Without the `:-`, the strict mode flag `-u` would cause an error when the script is called with no arguments. The `shift` before each handler removes the subcommand name from the argument list, so `cmd_init` receives `$@` as `<project-path> <project-name>` rather than `init <project-path> <project-name>`.

This is the simplest possible command router. There's no argument parsing library, no flag handling beyond `--help`, no subcommand aliases. It's enough. When the CLI grows to need `--verbose` flags or `--format json` options, that's a signal that the bash version has reached its limits and the Go rewrite is due.

## `cep init`

The `cmd_init` function scaffolds a new project. It takes a path and a project name, then:

1. **Checks for existing `.cep/` directory.** If found, prompts for re-initialization confirmation. The prompt uses `read -rp` — the `-r` flag prevents backslash interpretation (a subtle bug source in bash), and `-p` supplies the prompt string. The response is pattern-matched with `[[ "$confirm" =~ ^[Yy]$ ]]` — a bash regex match that accepts `y` or `Y`.

2. **Creates the directory structure.** Six `mkdir -p` calls create the `.cep/` tree. The `-p` flag creates parent directories as needed and doesn't error if the directory already exists — making the command idempotent.

3. **Writes the version marker.** `echo "$CEP_VERSION" > "$project_path/.cep/version"` stamps which CEP version this project was initialized with. This is the version that `cep status` and `cep upgrade` compare against.

4. **Updates the registry.** Appends the project path to `.registry/projects` and deduplicates with `sort -u -o`. The `-o` flag writes output to the same file that was read — a `sort` feature that handles the "read and overwrite same file" problem that would break with shell redirection (`sort file > file` truncates the file before `sort` reads it).

5. **Creates default files if they don't exist.** `CLAUDE.local.md` and `mikado.yaml` get starter content via heredocs (`<< EOF ... EOF`). The `if [[ ! -f ... ]]` guard makes this non-destructive — re-initialization preserves your existing files. This is critical for the re-init use case: you want to regenerate CLAUDE.md from the latest template without losing your project context.

6. **Assembles CLAUDE.md.** Calls `assemble_claude_md()` — see the Architecture chapter for the full pipeline.

## `cep status`

The status command reports on a single project. It reads the project's `.cep/version`, compares it to the global `CEP_VERSION`, counts session logs with `find ... | wc -l`, and finds the most recent log with `ls -1 ... | sort | tail -1`.

The Mikado progress display uses `grep -c` to count lines matching `status:` (total nodes) and `status: done` (completed nodes). The `|| true` after each grep prevents the strict mode `-e` flag from killing the script when grep finds zero matches (grep returns exit code 1 for "no matches," which `-e` would treat as an error).

## `cep list`

The simplest command. It reads `.registry/projects` line by line with a `while IFS= read -r` loop — the standard idiom for reading a file line by line in bash without word splitting or backslash interpretation. For each path, it checks whether `.cep/` exists (marking missing projects as "gone" in red) and displays the version with color-coded status.

The `local` keyword before variable declarations inside the loop limits their scope to the function. Without it, variables in bash are global by default — a common surprise for developers coming from other languages.

## `cep upgrade`

The upgrade command is reassembly with guards. It:

1. Verifies the project is CEP-managed (has `.cep/` directory).
2. Compares versions. If already current, exits with a green "up to date" message.
3. Creates any new directories that newer CEP versions might require (`blog/`, `guidebook/`). This handles the case where a project was initialized with an older CEP version that didn't have these directories.
4. Extracts the project name from the existing CLAUDE.md header using `head -3 | grep 'Project:' | sed 's/.*Project: //'`. This is a fragile extraction — it depends on the header format staying consistent. The `[[ -z ... ]]` guard falls back to "Unknown" if extraction fails.
5. Runs `assemble_claude_md()` and updates the version marker.

## `cep diff`

The diff command is `cep upgrade` as a dry run. It assembles what the new CLAUDE.md *would* look like (writing to a `mktemp` temporary file), then runs `diff -u` between the current and proposed versions. The `|| true` after `diff` prevents the script from exiting when differences are found (diff returns exit code 1 when files differ).

The diff command duplicates the assembly logic from `assemble_claude_md()` rather than calling the function. This is a deliberate choice: the diff command writes to a temporary file and must not touch the actual `CLAUDE.md`. The duplication is a known code smell — it means template changes need to be made in two places. This is a candidate for refactoring when the CLI grows.

## Color Output

The script defines ANSI color codes as variables at the top: `RED`, `GREEN`, `YELLOW`, `BLUE`, and `NC` (No Color / reset). These are used with `echo -e` (which interprets escape sequences) throughout the script. The pattern is `echo -e "${GREEN}Success${NC}"` — print in green, then reset to default. This is the standard approach for colored terminal output in bash scripts. The codes are the same ones you'd use in a prompt string (`PS1`), just wrapped in variables for readability.

## Extending the CLI

To add a new command:

1. Write a `cmd_yourcommand()` function following the pattern of existing commands.
2. Add a case branch in the dispatch block.
3. Update the `usage()` function.

The function naming convention (`cmd_` prefix) is not enforced by anything — it's just a namespace convention to distinguish command handlers from utility functions like `assemble_claude_md()`.

When adding commands, keep the bash version's limitations in mind: no structured data (YAML parsing is done with grep, not a proper parser), no concurrent operations, no network calls. If a new command needs any of these, it's probably a signal that the Go rewrite should happen first.

[← Previous: Architecture](architecture.md) | [Table of Contents](README.md) | [Next: The Template →](template.md)
