# aiSkills

A collection of Claude Code skills.

## Skills

| Skill | What it does |
|-------|--------------|
| [resumeVibing](resumeVibing/) | Creates/refreshes a per-project resume launcher (`resumeVibing.ps1` on Windows, `resumeVibing.sh` on Linux/macOS) that re-orients you and relaunches the exact Claude Code session via `claude --resume`. Works as an on-demand skill or an automatic `SessionStart` hook. |

## Installing a skill

Copy a skill's folder into your skills directory:

- **User scope (all projects):** `~/.claude/skills/<skill>/`
- **Project scope:** `<project>/.claude/skills/<skill>/`

Each skill folder contains a `SKILL.md` and its own `README.md` with details.
