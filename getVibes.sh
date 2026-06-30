#!/usr/bin/env bash
# getVibes.sh - one-shot installer for your Claude Code / Qwen / Codex skills.
#
# Pulls every skill from your aiSkills GitHub repo and installs it into the
# skills directory of the LLM CLI(s) you choose, so a fresh machine is one
# command away from all your skills.
#
# A "skill" is any top-level folder in the repo that contains a SKILL.md.
# Each installed skill folder is replaced wholesale (clean install).
#
# Target LLMs map to the convention ~/.<tool>/skills :
#   claude -> ~/.claude/skills
#   qwen   -> ~/.qwen/skills
#   codex  -> ~/.codex/skills
#   <any>  -> ~/.<any>/skills   (unknown names fall back to this)
#
# Usage:
#   ./getVibes.sh                          # claude (default)
#   ./getVibes.sh --llm qwen
#   ./getVibes.sh --llm claude,qwen,codex
#   ./getVibes.sh --llm all
#   ./getVibes.sh --skills-dir /alt/skills # explicit, wins over --llm
#   ./getVibes.sh --repo You/yourSkills --branch main
#
# Uses git if it's on PATH, otherwise downloads the branch tarball from GitHub.
set -euo pipefail

REPO="Biggoan1/aiSkills"
BRANCH="main"
LLM="claude"
SKILLS_DIR="${CLAUDE_SKILLS_DIR:-}"

usage() { sed -n '2,27p' "$0" | sed 's/^# \{0,1\}//'; }

while [ $# -gt 0 ]; do
  case "$1" in
    --repo)       REPO="$2"; shift 2;;
    --branch)     BRANCH="$2"; shift 2;;
    --llm)        LLM="$2"; shift 2;;
    --skills-dir) SKILLS_DIR="$2"; shift 2;;
    -h|--help)    usage; exit 0;;
    *) echo "getVibes: unknown argument '$1' (try --help)" >&2; exit 1;;
  esac
done

llm_dir() {
  case "$1" in
    claude) echo "$HOME/.claude/skills";;
    qwen)   echo "$HOME/.qwen/skills";;
    codex)  echo "$HOME/.codex/skills";;
    *)      echo "$HOME/.$1/skills";;
  esac
}

# Resolve target skills dirs.
targets=()
if [ -n "$SKILLS_DIR" ]; then
  targets+=("$SKILLS_DIR")
else
  names="$LLM"
  [ "$LLM" = "all" ] && names="claude,qwen,codex"
  IFS=',' read -ra _arr <<< "$names"
  for n in "${_arr[@]}"; do
    n="$(echo "$n" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"
    [ -n "$n" ] && targets+=("$(llm_dir "$n")")
  done
fi

echo ""
echo "==== getVibes: installing skills from $REPO ($BRANCH) ===="
echo "Targets: ${targets[*]}"

tmp="$(mktemp -d)"
cleanup() { rm -rf "$tmp"; }
trap cleanup EXIT

src=""
if command -v git >/dev/null 2>&1; then
  echo "Cloning with git..."
  git clone --depth 1 --branch "$BRANCH" "https://github.com/$REPO.git" "$tmp/repo" >/dev/null 2>&1
  src="$tmp/repo"
else
  echo "git not found; downloading tarball..."
  repo_name="${REPO##*/}"
  url="https://codeload.github.com/$REPO/tar.gz/refs/heads/$BRANCH"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" | tar -xz -C "$tmp"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO- "$url" | tar -xz -C "$tmp"
  else
    echo "ERROR: need git, curl, or wget to download the repo." >&2
    exit 1
  fi
  src="$tmp/$repo_name-$BRANCH"
fi

[ -d "$src" ] || { echo "ERROR: could not locate downloaded repo at $src" >&2; exit 1; }

install_into() {
  local dest="$1" count=0 name
  mkdir -p "$dest"
  for d in "$src"/*/; do
    [ -f "${d}SKILL.md" ] || continue
    name="$(basename "$d")"
    rm -rf "${dest:?}/$name"
    cp -R "$d" "$dest/$name"
    echo "  [ok] $name"
    count=$((count + 1))
  done
  echo "  ($count skill(s) -> $dest)"
  TOTAL=$((TOTAL + count))
}

TOTAL=0
for dest in "${targets[@]}"; do
  echo ""
  echo "--> $dest"
  install_into "$dest"
done

if [ "$TOTAL" -eq 0 ]; then
  echo "WARN: no skill folders (containing SKILL.md) found in $REPO." >&2
  exit 0
fi

echo ""
echo "Installed $TOTAL skill folder(s) across ${#targets[@]} target(s)."
echo "Restart the LLM CLI (or start a new session) to pick them up."
