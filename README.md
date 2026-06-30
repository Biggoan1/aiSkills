# aiSkills

A collection of Claude Code skills.

## Quick install (getVibes)

`getVibes` is a one-shot bootstrap that downloads **every** skill in this repo
(any top-level folder containing a `SKILL.md`) into the skills directory of the LLM
CLI(s) you choose. Use git if present, otherwise it falls back to the GitHub branch
archive.

**Pick your target LLM(s)** — they map to the `~/.<tool>/skills` convention:

| Target | Installs to |
|--------|-------------|
| `claude` (default) | `~/.claude/skills` |
| `qwen` | `~/.qwen/skills` |
| `codex` | `~/.codex/skills` |
| `all` | all of the above |
| any other name | `~/.<name>/skills` |

**Windows:**
```powershell
# from a clone of this repo:
powershell -ExecutionPolicy Bypass -File .\getVibes.ps1                       # claude
powershell -ExecutionPolicy Bypass -File .\getVibes.ps1 -Llm qwen,codex
powershell -ExecutionPolicy Bypass -File .\getVibes.ps1 -Llm all

# or straight from GitHub, no clone needed (passing args through iex):
powershell -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create((iwr -useb https://raw.githubusercontent.com/Biggoan1/aiSkills/main/getVibes.ps1))) -Llm all"
```

**Linux / macOS:**
```bash
# from a clone of this repo:
./getVibes.sh                          # claude
./getVibes.sh --llm qwen,codex
./getVibes.sh --llm all

# or straight from GitHub, no clone needed:
curl -fsSL https://raw.githubusercontent.com/Biggoan1/aiSkills/main/getVibes.sh | bash -s -- --llm all
```

Override the destination explicitly with `-SkillsDir <path>` (PowerShell) or
`--skills-dir <path>` / `CLAUDE_SKILLS_DIR=<path>` (shell) — that wins over the LLM
mapping. Point at a different repo/branch with `-Repo`/`-Branch` (`--repo`/`--branch`).
Restart the LLM CLI afterward to pick up the new skills.

> Note: `~/.<tool>/skills` is the convention used here. If a CLI you use expects skills
> somewhere else, pass `--skills-dir` / `-SkillsDir` to target that path directly.

## Skills

| Skill | What it does |
|-------|--------------|
| [resumeVibing](resumeVibing/) | Creates/refreshes a per-project resume launcher (`resumeVibing.ps1` on Windows, `resumeVibing.sh` on Linux/macOS) that re-orients you and relaunches the exact Claude Code session via `claude --resume`. Works as an on-demand skill or an automatic `SessionStart` hook. |

## Installing a skill

Copy a skill's folder into your skills directory:

- **User scope (all projects):** `~/.claude/skills/<skill>/`
- **Project scope:** `<project>/.claude/skills/<skill>/`

Each skill folder contains a `SKILL.md` and its own `README.md` with details.
