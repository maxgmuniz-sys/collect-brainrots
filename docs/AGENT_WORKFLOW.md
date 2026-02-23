# Agent Workflow Rulebook

This document is the definitive rulebook for any AI agent (Claude Code) working on the **Collect Brainrot's** Roblox game project. It ensures consistency, prevents wasted work, and enables crash recovery. Every agent session MUST follow these rules without exception.

---

## 1. Project Overview (for agent context)

- **Game:** "Collect Brainrot's" — a Roblox tycoon/idle game
- **Stack:** Rojo + Aftman + Wally + ProfileStore + Luau
- **Project path:** `C:\Users\maxgm\collect-brainrots`
- **Documentation:** The `docs/` folder contains all specs
- **Phases:** 10 phases (0 through 9), each with its own spec doc located in `docs/phases/`

---

## 2. Before Starting Any Work

Every agent session MUST begin with the following steps, in order:

1. **Read `docs/PROGRESS.md`** to understand the current state of the project — which phases are done, which are in progress, and any known blockers.
2. **Read the relevant `PHASE_X` doc** for the current phase (found in `docs/phases/`).
3. **Check `git status`** for any uncommitted changes from a previous session.
4. **DO NOT start a phase that has not been explicitly approved by the user.** If the next phase has not been approved, stop and ask.

---

## 3. Phase Execution Rules

- Phases are executed **one at a time**, in strict order: 0 -> 1 -> 2 -> ... -> 9.
- The user must **explicitly approve** starting each phase before work begins.
- **Never skip ahead** to a future phase, even if it seems straightforward.
- Each phase's spec doc (`docs/phases/PHASE_X.md`) contains the exact tasks to complete.
- Follow the agent task breakdown in the spec doc for guidance on parallel vs. sequential work.

---

## 4. Parallel vs Sequential Rules

### Can run in parallel (independent):

- Config modules that do not reference each other
- Client controllers that do not share state
- Documentation files

### Must run sequentially (dependencies):

- `Remotes/init.luau` BEFORE any service that uses remotes
- `DataService` BEFORE services that read/write player data
- Config modules BEFORE services that import them
- Server services BEFORE client controllers that call their remotes
- `Types.luau` BEFORE any module that uses the types

### General rule:

When in doubt, run sequentially. **Speed is less important than correctness.**

---

## 5. File Writing Rules

- Always read the `PHASE_X` doc before writing any file for that phase.
- Follow the public API (function signatures) defined in `ARCHITECTURE.md`.
- Use the types defined in `Types.luau`.
- Follow the RemoteEvent contracts in `ARCHITECTURE.md`.
- Every module must return a table with its public functions.
- Use descriptive variable names and add comments for non-obvious logic.
- **Do NOT add features beyond what the current phase specifies.** Stick to the spec.

---

## 6. Testing Protocol

After completing each phase:

1. Run `rojo build -o "collect-brainrots.rbxlx"` to verify there are no syntax errors.
2. Open in Roblox Studio, connect the Rojo plugin, and playtest.
3. Verify **ALL** testing criteria listed in the phase doc.
4. If any test fails, fix the issue before moving on.
5. Report results in `PROGRESS.md`.

---

## 7. Git Commit Strategy

- Commit after **each completed phase** (not after individual files).
- Commit message format: `Phase X: [brief description]`
- Example: `Phase 1: MVP core loop - food, brainrot spawning, earnings`
- **Never commit broken code.**
- Always run `rojo build` before committing to verify the build succeeds.

---

## 8. Crash Recovery Protocol

If a session crashes or disconnects:

1. The new session reads `docs/PROGRESS.md` first.
2. Check which phase was in progress.
3. Check `git log` for the last successful commit.
4. Read the phase doc for the incomplete phase.
5. Check which files exist and which are missing.
6. **Resume from where work stopped** — do not restart the phase from scratch.
7. Update `PROGRESS.md` with recovery notes.

---

## 9. PROGRESS.md Update Rules

Update `PROGRESS.md` at the following points:

- **When starting a phase:** Set status to `IN PROGRESS`.
- **When completing a task within a phase:** Check it off in the task list.
- **When completing a phase:** Set status to `DONE`, add completion notes.
- **When hitting a blocker:** Set status to `BLOCKED`, describe the issue.
- **After every significant piece of work** — do not wait until the end of the session.

---

## 10. Communication Rules

- Agents do **NOT** auto-proceed to next phases.
- After completing a phase, **report results and wait for user approval** before starting the next phase.
- If something is ambiguous in the spec, **ask the user** rather than guessing.
- If a design decision needs to be made that is not covered in the spec, **ask the user**.
- Document any decisions made during implementation in `PROGRESS.md`.

---

## 11. Code Style Guidelines (Luau)

- Use **PascalCase** for module names and types.
- Use **camelCase** for variables and functions.
- Use **UPPER_SNAKE_CASE** for constants.
- Each service module returns a table: `local ServiceName = {} ... return ServiceName`
- Use Luau type annotations where they add clarity.
- Keep functions short and focused (under 50 lines ideally).
- Comment **"why"** not **"what"** — explain reasoning, not mechanics.

---

## 12. Module Pattern

Every server service follows this template:

```luau
-- Services/ExampleService.luau
local ExampleService = {}

-- Dependencies
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config.Example)

function ExampleService.Init()
    -- Called once during boot
end

function ExampleService.SomePublicFunction(args)
    -- Public API
end

return ExampleService
```

Every client controller follows this template:

```luau
-- Controllers/ExampleUI.luau
local ExampleUI = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

function ExampleUI.Init()
    -- Set up UI, connect events
end

return ExampleUI
```
