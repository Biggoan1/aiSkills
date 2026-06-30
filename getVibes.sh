#!/usr/bin/env bash
# getVibes.sh - one-shot installer for your Claude Code skills.
#
# Pulls every skill from your aiSkills GitHub repo and installs it into
# ~/.claude/skills, so a fresh machine is one command away from all your skills.
#
# A "skill" is any top-level folder in the repo that contains a SKILL.md.
# Each installed skill folder is replaced wholesale (clean install).
#
# Usage:
#   ./getVibes.sh                       # defaults: Biggoan1/aiSkills @ main
#   ./getVibes.sh You/yourSkills main   # custom repo / branch
#   CLAUDE_SKILLS_DIR=/alt/skills ./getVibes.sh
#
# Uses git if it's on PATH, otherwise downloads the branch tarball from GitHub.
set -euo pipefail

REPO="${1:-Biggoan1/aiSkills}"
BRANCH="${2:-main}"
SKILLS_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"

echo ""
echo "==== getVibes: installing skills from $REPO ($BRANCH) ===="

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

mkdir -p "$SKILLS_DIR"

count=0
for d in "$src"/*/; do
  [ -f "${d}SKILL.md" ] || continue
  name="$(basename "$d")"
  rm -rf "${SKILLS_DIR:?}/$name"
  cp -R "$d" "$SKILLS_DIR/$name"
  echo "  [ok] $name"
  count=$((count + 1))
done

if [ "$count" -eq 0 ]; then
  echo "WARN: no skill folders (containing SKILL.md) found in $REPO." >&2
  exit 0
fi

echo ""
echo "Installed $count skill(s) to $SKILLS_DIR"
echo "Restart Claude Code (or start a new session) to pick them up."
