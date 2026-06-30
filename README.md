# aiSkills

A collection of Claude Code skills.

## Quick install (getVibes)

`getVibes` is a one-shot bootstrap that downloads **every** skill in this repo
(any top-level folder containing a `SKILL.md`) into `~/.claude/skills`. Use git if
present, otherwise it falls back to the GitHub branch archive.

**Windows:**
```powershell
# from a clone of this repo:
powershell -ExecutionPolicy Bypass -File .\getVibes.ps1

# or straight from GitHub, no clone needed:
powershell -ExecutionPolicy Bypass -Command "iwr -useb https://raw.githubusercontent.com/Biggoan1/aiSkills/main/getVibes.ps1 | iex"
```

**Linux / macOS:**
```bash
# from a clone of this repo:
./getVibes.sh

# or straight from GitHub, no clone needed:
curl -fsSL https://raw.githubusercontent.com/Biggoan1/aiSkills/main/getVibes.sh | bash
```

Override the target with `-SkillsDir <path>` (PowerShell) or `CLAUDE_SKILLS_DIR=<path>`
(shell). Restart Claude Code afterward to pick up the new skills.

## Skills

| Skill | What it does |
|-------|--------------|
| [resumeVibing](resumeVibing/) | Creates/refreshes a per-project resume launcher (`resumeVibing.ps1` on Windows, `resumeVibing.sh` on Linux/macOS) that re-orients you and relaunches the exact Claude Code session via `claude --resume`. Works as an on-demand skill or an automatic `SessionStart` hook. |

## Installing a skill

Copy a skill's folder into your skills directory:

- **User scope (all projects):** `~/.claude/skills/<skill>/`
- **Project scope:** `<project>/.claude/skills/<skill>/`

Each skill folder contains a `SKILL.md` and its own `README.md` with details.
