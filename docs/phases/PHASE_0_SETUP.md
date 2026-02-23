# Phase 0: Setup and Tooling

> **Status:** NOT STARTED
> **Depends on:** Nothing (this is the first phase)
> **Blocks:** Phase 1 (MVP Core Loop)

---

## 1. Objective

Set up the complete development environment and project scaffold so that Phase 1 can begin coding immediately. By the end of this phase, every tool is installed, every directory exists, Wally packages are downloaded, the Rojo project builds and serves cleanly, and the Rojo Studio plugin is connected.

---

## 2. Prerequisites

None. This is the first phase. The bare minimum already exists:

| Already Present | Version / Notes |
|---|---|
| Rojo | 7.7.0-rc.1 (installed via Aftman or standalone) |
| Aftman | 0.3.0 |
| Git | Initialized repo with initial commit |
| Node.js | Available on PATH |
| `default.project.json` | Template version from `rojo init` |
| `src/server/init.server.luau` | Hello-world placeholder |
| `src/client/init.client.luau` | Hello-world placeholder |
| `src/shared/Hello.luau` | Template file (to be deleted) |
| `.gitignore` | Partial (only covers .rbxlx, lock files, sourcemap) |

---

## 3. Files to Create/Modify

| # | File | Action | Purpose |
|---|---|---|---|
| 1 | `aftman.toml` | **CREATE** | Aftman toolchain manifest. Pins Rojo, Wally, Selene, and StyLua versions. |
| 2 | `wally.toml` | **CREATE** | Wally package manifest. Declares ProfileStore as a dependency. |
| 3 | `default.project.json` | **MODIFY** | Update Rojo project to add `Packages/` mapping and match ARCHITECTURE.md structure. |
| 4 | `.gitignore` | **MODIFY** | Add entries for `Packages/`, `wally.lock` backup, node_modules, etc. |
| 5 | `src/shared/Config/` | **CREATE DIR** | Empty directory for shared config modules (Phase 1 will populate). |
| 6 | `src/server/Services/` | **CREATE DIR** | Empty directory for server service modules. |
| 7 | `src/server/Remotes/` | **CREATE DIR** | Empty directory for the remotes registry module. |
| 8 | `src/client/Controllers/` | **CREATE DIR** | Empty directory for client UI controller modules. |
| 9 | `src/shared/Hello.luau` | **DELETE** | Remove the Rojo template placeholder file. |
| 10 | `docs/PROGRESS.md` | **CREATE** | Initialize the progress tracker (mark Phase 0 as IN PROGRESS). |

---

## 4. Detailed Spec Per File

### 4.1 `aftman.toml` (CREATE)

This file tells Aftman which tool binaries to install and at what versions. Running `aftman install` reads this file and places binaries in `~/.aftman/bin/`.

```toml
[tools]
rojo = "rojo-rbx/rojo@7.7.0-rc.1"
wally = "UpliftGames/wally@0.3.2"
selene = "Kampfkarren/selene@0.27.1"
stylua = "JohnnyMorganz/StyLua@2.0.2"
```

**Notes:**
- Rojo is pinned at 7.7.0-rc.1 to match what is already installed.
- Wally, Selene, and StyLua versions should use the latest stable releases available. The versions shown above are reference targets; the agent should use whatever `aftman add` resolves to.
- After creating this file, run `aftman install` to ensure all tools are present.

---

### 4.2 `wally.toml` (CREATE)

Wally package manifest. Declares the project identity and its single dependency: ProfileStore.

```toml
[package]
name = "maxgm/collect-brainrots"
version = "0.1.0"
registry = "https://github.com/UpliftGames/wally-index"
realm = "server"

[dependencies]
ProfileStore = "madstudioroblox/profilestore@1.2.2"
```

**Notes:**
- The `name` field follows Wally's `scope/name` convention. Use the developer's username as the scope.
- The `realm = "server"` indicates this is a server-side project root.
- ProfileStore is placed under `[dependencies]` (not `[server-dependencies]`) so it lands in `Packages/` and can be mapped into ReplicatedStorage for convenience, but it is only `require()`-d from server code.
- The exact version of ProfileStore should be whatever `wally` resolves as latest. The version above is a reference target.

---

### 4.3 `default.project.json` (MODIFY)

The existing file already has the correct base structure for `src/shared`, `src/server`, `src/client`, Workspace, Lighting, and SoundService. The only change is to **add the `Packages` mapping** under `ReplicatedStorage` so Wally dependencies are available to server and client code.

**Updated file (complete):**

```json
{
  "name": "Collect Brainrot's\ud83e\udd88",
  "tree": {
    "$className": "DataModel",

    "ReplicatedStorage": {
      "Shared": {
        "$path": "src/shared"
      },
      "Packages": {
        "$path": "Packages"
      }
    },

    "ServerScriptService": {
      "Server": {
        "$path": "src/server"
      }
    },

    "StarterPlayer": {
      "StarterPlayerScripts": {
        "Client": {
          "$path": "src/client"
        }
      }
    },

    "Workspace": {
      "$properties": {
        "FilteringEnabled": true
      },
      "Baseplate": {
        "$className": "Part",
        "$properties": {
          "Anchored": true,
          "Color": [
            0.38823,
            0.37254,
            0.38823
          ],
          "Locked": true,
          "Position": [
            0,
            -10,
            0
          ],
          "Size": [
            512,
            20,
            512
          ]
        }
      }
    },
    "Lighting": {
      "$properties": {
        "Ambient": [
          0,
          0,
          0
        ],
        "Brightness": 2,
        "GlobalShadows": true,
        "Outlines": false,
        "Technology": "Voxel"
      }
    },
    "SoundService": {
      "$properties": {
        "RespectFilteringEnabled": true
      }
    }
  }
}
```

**What changed from the original:**
- Added `"Packages": { "$path": "Packages" }` as a sibling of `"Shared"` inside `"ReplicatedStorage"`. This maps the Wally-generated `Packages/` directory into `ReplicatedStorage.Packages` in the DataModel, making all Wally packages accessible via `require(ReplicatedStorage.Packages.ProfileStore)`.

Everything else remains identical to the original template.

---

### 4.4 `.gitignore` (MODIFY)

The current `.gitignore` only covers the place file, lock files, and sourcemap. Update it to be comprehensive for a Rojo + Wally project.

**Updated file (complete):**

```gitignore
# Roblox place files
*.rbxlx
*.rbxl
*.rbxlx.lock
*.rbxl.lock

# Rojo
sourcemap.json

# Wally packages (auto-generated by `wally install`)
/Packages/

# Wally server packages (if realm splitting is used)
/ServerPackages/

# Node
node_modules/

# OS files
.DS_Store
Thumbs.db

# Editor
.vscode/settings.json

# Build artifacts
/build/
```

**What changed from the original:**
- Added wildcard `*.rbxl` pattern (covers binary place files too).
- Added `/Packages/` and `/ServerPackages/` for Wally output.
- Added `node_modules/`, OS junk files, `.vscode/settings.json`, and `/build/`.

---

### 4.5 Directory Structure (CREATE DIRS)

Create the following empty directories. Because Git does not track empty directories, place a `.gitkeep` file in each one so the structure is preserved in version control. These `.gitkeep` files will be deleted naturally as real files are added in Phase 1.

```
src/shared/Config/.gitkeep
src/server/Services/.gitkeep
src/server/Remotes/.gitkeep
src/client/Controllers/.gitkeep
```

---

### 4.6 `src/shared/Hello.luau` (DELETE)

Delete this file. It is a Rojo template placeholder with no purpose going forward. Its contents are:

```luau
return function()
    print("Hello, world!")
end
```

This file must be removed so it does not appear as a stray ModuleScript in `ReplicatedStorage.Shared.Hello` at runtime.

---

### 4.7 `docs/PROGRESS.md` (CREATE)

Initialize the progress tracking document. This file is read at the start of every agent session per `AGENT_WORKFLOW.md`.

```markdown
# Progress Tracker

> Last updated: [date of Phase 0 completion]

## Phase Summary

| Phase | Name | Status | Notes |
|---|---|---|---|
| 0 | Setup and Tooling | IN PROGRESS | |
| 1 | MVP Core Loop | NOT STARTED | |
| 2 | 3D Models and Visuals | NOT STARTED | |
| 3 | Map Building | NOT STARTED | |
| 4 | Sound and Animation | NOT STARTED | |
| 5 | Sell System | NOT STARTED | |
| 6 | Weather System | NOT STARTED | |
| 7 | Index, Gifting, Leaderboards | NOT STARTED | |
| 8 | Fusion, Tutorial, Personality | NOT STARTED | |
| 9 | Monetization (Gamepasses) | NOT STARTED | |

## Phase 0 Details

- [ ] Install Wally via Aftman
- [ ] Install Selene via Aftman (nice-to-have)
- [ ] Install StyLua via Aftman (nice-to-have)
- [ ] Install VS Code via winget (recommended)
- [ ] Create aftman.toml
- [ ] Create wally.toml
- [ ] Run wally install
- [ ] Update default.project.json (add Packages mapping)
- [ ] Create directory structure (Config, Services, Remotes, Controllers)
- [ ] Delete src/shared/Hello.luau
- [ ] Update .gitignore
- [ ] Verify rojo build succeeds
- [ ] Install Rojo plugin in Roblox Studio
- [ ] Verify rojo serve + Studio connection
- [ ] Git commit: "Phase 0: Project setup and tooling"
```

---

## 5. Module Contracts

N/A for this phase. No Luau code modules are created or modified (beyond deleting the placeholder). All module contracts begin in Phase 1.

---

## 6. Agent Task Breakdown

### Parallel Block A (Independent tool installations -- can run simultaneously)

These four tasks have no dependencies on each other and can be executed in parallel:

| Task | Command | Notes |
|---|---|---|
| A1. Install Wally via Aftman | `aftman add UpliftGames/wally` | Then run `aftman trust UpliftGames/wally` if prompted. Verify with `wally --version`. |
| A2. Install Selene via Aftman | `aftman add Kampfkarren/selene` | Nice-to-have linter. Verify with `selene --version`. |
| A3. Install StyLua via Aftman | `aftman add JohnnyMorganz/StyLua` | Nice-to-have formatter. Verify with `stylua --version`. |
| A4. Install VS Code via winget | `winget install Microsoft.VisualStudioCode` | Recommended editor. Skip if already installed. Verify with `code --version`. |

**After all parallel tasks complete, proceed to the sequential block.**

### Sequential Block B (Must execute in this exact order)

| Step | Task | Command / Action | Why This Order |
|---|---|---|---|
| B1 | Verify Wally installed | `wally --version` | Must confirm Wally binary exists before creating wally.toml. |
| B2 | Create `aftman.toml` | Write file per Section 4.1 | Formalizes the toolchain manifest. If tools were added via `aftman add`, this file may already exist or be partially populated. Verify it matches the spec. |
| B3 | Run `aftman install` | `aftman install` | Ensures all tools listed in aftman.toml are installed at the pinned versions. |
| B4 | Create `wally.toml` | Write file per Section 4.2 | Wally must be installed (B1) before this file can be used. |
| B5 | Run `wally install` | `wally install` | Reads wally.toml, downloads ProfileStore into `Packages/`. Must run after wally.toml exists. |
| B6 | Verify Packages/ populated | `ls Packages/` | Confirm `ProfileStore` (or similar) directory exists inside `Packages/`. |
| B7 | Update `default.project.json` | Edit file per Section 4.3 | Must happen after `Packages/` exists so the Rojo path reference is valid. |
| B8 | Update `.gitignore` | Edit file per Section 4.4 | Must happen before the git commit so `Packages/` is excluded. |
| B9 | Create directory structure | `mkdir -p src/shared/Config src/server/Services src/server/Remotes src/client/Controllers` | Create all subdirectories. Add `.gitkeep` files. |
| B10 | Delete `src/shared/Hello.luau` | `rm src/shared/Hello.luau` | Remove template placeholder. |
| B11 | Create `docs/PROGRESS.md` | Write file per Section 4.7 | Initialize progress tracker. |
| B12 | Verify `rojo build` | `rojo build -o "collect-brainrots.rbxlx"` | Must succeed without errors. This confirms the project.json is valid and all paths resolve. |
| B13 | Verify `rojo serve` | `rojo serve` | Start the dev server. Confirm it prints "Rojo server listening" on the expected port (default 34872). Stop after confirming. |
| B14 | Install Rojo Studio plugin | Guide user to install from the Roblox Creator Marketplace, **or** run `rojo plugin install` to generate the `.rbxm` plugin file and instruct the user to place it in their Studio plugins folder. | Rojo plugin is required for live-sync. |
| B15 | Verify Studio connection | Open `collect-brainrots.rbxlx` in Studio, click "Connect" in the Rojo plugin toolbar. | Confirms end-to-end toolchain. |
| B16 | Git commit | `git add -A && git commit -m "Phase 0: Project setup and tooling"` | Clean commit with everything in place. |

### Task Dependency Diagram

```
Parallel Block A:
  A1 (Wally) ----+
  A2 (Selene) ---+---> All parallel tasks complete
  A3 (StyLua) ---+          |
  A4 (VS Code) --+          v
                      Sequential Block B:
                        B1 -> B2 -> B3 -> B4 -> B5 -> B6
                                                       |
                        B7 -> B8 -> B9 -> B10 -> B11 --+
                                                       |
                        B12 -> B13 -> B14 -> B15 -> B16
```

---

## 7. Data Structures

N/A for this phase. No data structures are defined until Phase 1 introduces `Types.luau`, `PlayerData`, and `BrainrotInstance`.

---

## 8. Testing Criteria

Every item below must pass before Phase 0 is considered complete.

| # | Test | How to Verify | Expected Result |
|---|---|---|---|
| T1 | Aftman installs all tools | `aftman install` | Exits with code 0, no errors printed. |
| T2 | Wally is available | `wally --version` | Prints a version string (e.g., `wally 0.3.2`). |
| T3 | Rojo is available | `rojo --version` | Prints `Rojo 7.7.0-rc.1`. |
| T4 | Selene is available (nice-to-have) | `selene --version` | Prints a version string. Not a blocker if missing. |
| T5 | StyLua is available (nice-to-have) | `stylua --version` | Prints a version string. Not a blocker if missing. |
| T6 | Wally packages downloaded | `ls Packages/` | `ProfileStore` directory (or equivalent) exists inside `Packages/`. |
| T7 | `rojo build` succeeds | `rojo build -o "collect-brainrots.rbxlx"` | Exits with code 0. Produces a `.rbxlx` file without errors. |
| T8 | `rojo serve` starts | `rojo serve` | Prints "Rojo server listening on ..." (default port 34872). |
| T9 | Studio connects via Rojo plugin | Open place in Studio, click Connect | Rojo plugin shows "Connected" status. Changes sync live. |
| T10 | Directory `src/shared/Config/` exists | `ls src/shared/Config/` | Directory exists (contains `.gitkeep`). |
| T11 | Directory `src/server/Services/` exists | `ls src/server/Services/` | Directory exists (contains `.gitkeep`). |
| T12 | Directory `src/server/Remotes/` exists | `ls src/server/Remotes/` | Directory exists (contains `.gitkeep`). |
| T13 | Directory `src/client/Controllers/` exists | `ls src/client/Controllers/` | Directory exists (contains `.gitkeep`). |
| T14 | `src/shared/Hello.luau` is gone | `ls src/shared/Hello.luau` | File not found. |
| T15 | `.gitignore` excludes Packages | `grep "Packages" .gitignore` | Line `/Packages/` is present. |
| T16 | `.gitignore` excludes .rbxlx | `grep "rbxlx" .gitignore` | Line `*.rbxlx` is present. |
| T17 | Rojo DataModel structure correct | Open built `.rbxlx` in Studio or inspect with `rojo sourcemap` | `ReplicatedStorage` contains both `Shared` and `Packages`. `ServerScriptService` contains `Server`. `StarterPlayer.StarterPlayerScripts` contains `Client`. |
| T18 | Git status is clean after commit | `git status` | "nothing to commit, working tree clean". |

---

## 9. Acceptance Criteria

Phase 0 is **DONE** when ALL of the following are true:

1. **All required tools are installed and accessible on PATH:**
   - Rojo 7.7.0-rc.1 (`rojo --version`)
   - Wally (`wally --version`)
   - Aftman 0.3.0+ (`aftman --version`)

2. **Nice-to-have tools are installed (non-blocking if unavailable):**
   - VS Code (`code --version`)
   - Selene (`selene --version`)
   - StyLua (`stylua --version`)

3. **`aftman.toml` exists** at the repo root and lists Rojo, Wally, Selene, and StyLua with pinned versions.

4. **`wally.toml` exists** at the repo root with ProfileStore as a dependency.

5. **`wally install` has been run** and `Packages/` contains the downloaded ProfileStore package.

6. **`default.project.json` is updated** with the `Packages` mapping under `ReplicatedStorage`.

7. **`.gitignore` is updated** to exclude `Packages/`, `*.rbxlx`, `*.rbxl`, lock files, `sourcemap.json`, `node_modules/`, and OS junk files.

8. **All directories exist:**
   - `src/shared/Config/`
   - `src/server/Services/`
   - `src/server/Remotes/`
   - `src/client/Controllers/`

9. **`src/shared/Hello.luau` has been deleted.**

10. **`rojo build -o "collect-brainrots.rbxlx"` succeeds** without errors.

11. **`rojo serve` starts** and Roblox Studio can connect via the Rojo plugin.

12. **The Rojo plugin is installed in Roblox Studio** (from the Creator Marketplace or via `rojo plugin install`).

13. **`docs/PROGRESS.md` exists** and shows Phase 0 as IN PROGRESS (will be updated to DONE upon completion).

14. **A clean Git commit has been made** with the message: `Phase 0: Project setup and tooling`.

15. **The project structure matches ARCHITECTURE.md Section 2** (file tree) and Section 3 (Rojo mapping).

---

## Appendix: Troubleshooting

### Aftman trust issues

If `aftman add` or `aftman install` fails with a trust error:

```bash
aftman trust UpliftGames/wally
aftman trust Kampfkarren/selene
aftman trust JohnnyMorganz/StyLua
aftman trust rojo-rbx/rojo
```

Then retry `aftman install`.

### Wally registry errors

If `wally install` fails to resolve packages, ensure your internet connection is active and that the registry URL in `wally.toml` is correct:

```
registry = "https://github.com/UpliftGames/wally-index"
```

If the specific ProfileStore version is not found, remove the version pin and let Wally resolve the latest:

```toml
ProfileStore = "madstudioroblox/profilestore@*"
```

### Rojo build fails after adding Packages

If `rojo build` fails with a path error for `Packages/`, ensure:
1. `wally install` has been run (the `Packages/` directory must exist).
2. The `$path` value in `default.project.json` is `"Packages"` (no leading slash, no trailing slash).

If `Packages/` is empty (Wally downloaded nothing), the build may still succeed but the `ReplicatedStorage.Packages` container will be empty in the DataModel. This is acceptable for Phase 0.

### Rojo plugin not appearing in Studio

If `rojo plugin install` does not work or the plugin does not appear:
1. Search for "Rojo" in the Roblox Creator Marketplace (Toolbox > Plugins).
2. Install the official Rojo plugin by Lucien Greathouse.
3. Restart Studio after installation.
4. The Rojo toolbar should appear with "Connect" and "Settings" buttons.
