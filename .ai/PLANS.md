# Autonomous Development Plan

## Operating Loop

1. Always read `AGENTS.md`, `.ai/ROADMAP.md`, and `.ai/TASKS.md` before coding.
2. Pick the first unchecked task in `.ai/TASKS.md`.
3. Implement only that task.
4. Mark the task done in `.ai/TASKS.md`.
5. Add follow-up tasks if implementation reveals necessary work.
6. Run the required checks from `AGENTS.md`.
7. Summarize files changed, checks run, and the next unchecked task.

## Phase Discipline

- Do not skip phases.
- Do not implement multiple large phases at once.
- Do not start feature implementation while Phase 1 architecture tasks remain.
- Keep changes scoped to the current task.
- Prefer small, verifiable increments over broad rewrites.

## Safety Rules

- Gemini must not write directly to Firestore.
- Gemini responses are drafts or suggestions only.
- AI-parsed data must be shown to the user for confirmation before saving.
- Do not provide diagnosis, treatment advice, or medical reassurance.
- Repositories mediate between Cubits/UI and Firebase/data sources.
- Widgets should render state and dispatch user intent, not contain business
  logic.

## Stop Conditions

Stop and ask for user input only when progress requires:

- Firebase console actions.
- Credentials, API keys, or account access.
- Product decisions not covered by the roadmap/spec.
- Platform signing, bundle ID, or release decisions.
- Destructive git or filesystem operations.

## MCP Configuration

Prefer the Dart/Flutter MCP server:

```toml
[mcp_servers.dart]
command = "dart"
args = ["mcp-server"]
```

Project-level config exists at `.codex/config.toml`. In this environment the
Dart MCP server is available, but the session does not expose whether it was
loaded from project config, global config, or session configuration. Treat the
project config as the preferred local declaration.

If a new Codex session does not expose Dart/Flutter MCP tools, add the same
block to the global Codex config, usually at:

```text
$CODEX_HOME/config.toml
```

or:

```text
~/.codex/config.toml
```

After updating global config, restart Codex from the project root and confirm
the Dart MCP tools are available before starting substantial Flutter work.
