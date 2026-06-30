# resumeVibing

A Claude Code skill + hook that drops a **resume launcher** into a project so you can
re-orient and jump straight back into the exact Claude Code session you were in —
handy after a reboot or a closed terminal.

The launcher prints a quick "where was I" snapshot (git branch / last commit / working
tree + recently changed files), then runs `claude --resume <session-guid>`.

## What's in this folder

| File | Purpose |
|------|---------|
| `SKILL.md` | The skill definition (on-demand "create/refresh a resumeVibing launcher here"). |
| `resumeVibing-gen.js` | Cross-platform generator. Reads a SessionStart-style JSON payload on stdin and writes the right launcher for the current OS. Used by both the skill and the hook. |
| `README.md` | This file. |

## Cross-platform by design

The generator chooses the output by `process.platform`:

- **Windows** -> `resumeVibing.ps1`
- **Linux / macOS** -> `resumeVibing.sh`, then `chmod 755`

Each file embeds a brief summary header and the **resume session GUID**, and a sidecar
`.resume-session` (just the GUID) is always refreshed so the launcher survives a stale
embedded id.

## Use as a skill (on demand)

Drop this folder into your skills directory:

- **User scope (all projects):** `~/.claude/skills/resumeVibing/`
- **Project scope:** `<project>/.claude/skills/resumeVibing/`

Then ask Claude to "set up resumeVibing here" (or invoke `/resumeVibing`). See
`SKILL.md` for the exact run steps.

## Use as a hook (automatic, every session)

Install the generator and wire a `SessionStart` hook so a launcher is created/refreshed
automatically whenever a session starts in any project.

1. Copy `resumeVibing-gen.js` somewhere stable, e.g. `~/.claude/hooks/resumeVibing-gen.js`.

2. Add the hook to your `settings.json`.

   **Windows** (`%USERPROFILE%\.claude\settings.json`):
   ```json
   {
     "hooks": {
       "SessionStart": [
         {
           "hooks": [
             {
               "type": "command",
               "command": "node \"C:/Users/<you>/.claude/hooks/resumeVibing-gen.js\"",
               "statusMessage": "Refreshing resumeVibing launcher"
             }
           ]
         }
       ]
     }
   }
   ```

   **Linux / macOS** (`~/.claude/settings.json`):
   ```json
   {
     "hooks": {
       "SessionStart": [
         {
           "hooks": [
             {
               "type": "command",
               "command": "node \"$HOME/.claude/hooks/resumeVibing-gen.js\"",
               "statusMessage": "Refreshing resumeVibing launcher"
             }
           ]
         }
       ]
     }
   }
   ```

   (Forward slashes work on Windows in Node and avoid backslash-escaping headaches in
   both PowerShell and Git Bash hook shells.)

The hook receives `{ session_id, cwd, source, ... }` on stdin, which is exactly the
payload the generator expects. It writes nothing to stdout, so it won't clutter your
session context.

## Safety / not clobbering your edits

A generated launcher carries a `RESUME_VIBING_AUTOGEN` marker comment. If you edit the
launcher and remove that marker, the generator stops overwriting it (it still refreshes
`.resume-session`). It also never writes into your home directory itself — only real
project folders.

## Generated launcher usage

```bash
# Windows
powershell -ExecutionPolicy Bypass -File .\resumeVibing.ps1            # orient + resume
powershell -ExecutionPolicy Bypass -File .\resumeVibing.ps1 -JustDoIt  # + skip permission prompts
powershell -ExecutionPolicy Bypass -File .\resumeVibing.ps1 -NoLaunch  # just orient

# Linux / macOS
./resumeVibing.sh               # orient + resume
./resumeVibing.sh --just-do-it  # + skip permission prompts
./resumeVibing.sh --no-launch   # just orient
```

`-JustDoIt` / `--just-do-it` adds `--dangerously-skip-permissions` to the resume so you
land back in the session without approval prompts.
