---
name: resumeVibing
description: Create or refresh a "resumeVibing" launcher in the current project so you can re-orient and jump straight back into this exact Claude Code session after a reboot or closed terminal. Detects the OS and writes resumeVibing.ps1 (Windows) or resumeVibing.sh (Linux/macOS, chmod +x), each carrying a brief summary and the resume session GUID. Use when the user asks to set up / write / refresh resumeVibing, or wants a one-command way to resume their session later.
---

# resumeVibing

Generates a per-project **resume launcher** that, when run later, prints a quick
"where was I" orientation (git state + recently changed files) and then relaunches
the Claude Code session you were in via `claude --resume <session-guid>`.

- **Windows** -> `resumeVibing.ps1`
- **Linux / macOS** -> `resumeVibing.sh` (made executable with `chmod 755`)

Each generated file embeds:
1. A **brief summary** header (project name + what the script does).
2. The **resume session GUID** (so `claude --resume <guid>` is wired in).

A sidecar `.resume-session` file (just the GUID) is also written so the launcher
keeps working even if its embedded id goes stale.

## How to run it

This skill bundles `resumeVibing-gen.js`, the same cross-platform generator used by
the optional `SessionStart` hook (see README). It reads a small JSON payload on
stdin and writes the right file for the current OS.

1. **Find the current session GUID.** It is the active Claude Code session id. You
   can read it from the working session's transcript path (the session-id directory
   under the Claude projects/temp folder), or ask the user if it cannot be
   determined.

2. **Find the project directory** — normally the current working directory.

3. **Run the generator**, piping a payload built from those two values:

   ```bash
   # POSIX shell
   printf '{"session_id":"<GUID>","cwd":"<ABS_PROJECT_DIR>"}' \
     | node "<path-to>/resumeVibing-gen.js"
   ```

   ```powershell
   # PowerShell
   '{"session_id":"<GUID>","cwd":"<ABS_PROJECT_DIR>"}' | node "<path-to>\resumeVibing-gen.js"
   ```

   The generator picks `.ps1` vs `.sh` from `process.platform`, embeds the summary +
   GUID, writes `.resume-session`, and (on non-Windows) sets the executable bit.

4. **Confirm** to the user what was written and how to use it (below).

> Safety: a file this generator produced carries a `RESUME_VIBING_AUTOGEN` marker.
> If the launcher already exists **without** that marker (i.e. the user hand-edited
> it), the generator leaves it untouched and only refreshes `.resume-session`.

If `node` is unavailable, write the launcher directly using the templates inside
`resumeVibing-gen.js` (`renderPs1` / `renderSh`) as the reference, keeping the
summary header, the embedded GUID, and the same `-JustDoIt` / `--just-do-it`
behavior.

## Using the generated launcher

Windows:
```powershell
powershell -ExecutionPolicy Bypass -File .\resumeVibing.ps1            # orient + resume (normal prompts)
powershell -ExecutionPolicy Bypass -File .\resumeVibing.ps1 -JustDoIt  # resume, skip permission prompts
powershell -ExecutionPolicy Bypass -File .\resumeVibing.ps1 -NoLaunch  # just orient, don't launch
```

Linux / macOS:
```bash
./resumeVibing.sh               # orient + resume (normal prompts)
./resumeVibing.sh --just-do-it  # resume, skip permission prompts
./resumeVibing.sh --no-launch   # just orient, don't launch
```

## Automating it for every project

To have a launcher created/refreshed automatically on every session start, wire the
bundled generator as a Claude Code `SessionStart` hook. See `README.md` in this
folder for the exact `settings.json` snippet (Windows and Linux/macOS).
