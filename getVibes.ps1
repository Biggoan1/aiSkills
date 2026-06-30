#requires -Version 5.1
<#
    getVibes.ps1 - one-shot installer for your Claude Code skills.

    Pulls every skill from your aiSkills GitHub repo and installs it into
    ~/.claude/skills, so a fresh machine is one command away from all your skills.

    A "skill" is any top-level folder in the repo that contains a SKILL.md.
    Each installed skill folder is replaced wholesale (clean install).

    Usage:
        powershell -ExecutionPolicy Bypass -File .\getVibes.ps1
        powershell -ExecutionPolicy Bypass -File .\getVibes.ps1 -Repo You/yourSkills -Branch main
        powershell -ExecutionPolicy Bypass -File .\getVibes.ps1 -SkillsDir D:\alt\skills

    Uses git if it's on PATH, otherwise downloads the branch zip from GitHub.
#>
[CmdletBinding()]
param(
    [string]$Repo      = 'Biggoan1/aiSkills',
    [string]$Branch    = 'main',
    [string]$SkillsDir = (Join-Path $HOME '.claude\skills')
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host ''
Write-Host "==== getVibes: installing skills from $Repo ($Branch) ====" -ForegroundColor Cyan

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("getVibes_" + [System.Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
$src = $null

try {
    if (Get-Command git -ErrorAction SilentlyContinue) {
        Write-Host "Cloning with git..." -ForegroundColor DarkGray
        # git writes progress to stderr; don't let that trip ErrorActionPreference=Stop.
        $prevEAP = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        git clone --depth 1 --branch $Branch "https://github.com/$Repo.git" (Join-Path $tmp 'repo') 2>&1 | Out-Null
        $code = $LASTEXITCODE
        $ErrorActionPreference = $prevEAP
        if ($code -ne 0) { throw "git clone failed (exit $code)." }
        $src = Join-Path $tmp 'repo'
    }
    else {
        Write-Host "git not found; downloading zip..." -ForegroundColor DarkGray
        $zip = Join-Path $tmp 'repo.zip'
        Invoke-WebRequest -Uri "https://codeload.github.com/$Repo/zip/refs/heads/$Branch" -OutFile $zip -UseBasicParsing
        Expand-Archive -Path $zip -DestinationPath $tmp -Force
        $repoName = ($Repo -split '/')[-1]
        $src = Join-Path $tmp "$repoName-$Branch"
    }

    if (-not (Test-Path $src)) { throw "Could not locate downloaded repo at $src" }

    if (-not (Test-Path $SkillsDir)) { New-Item -ItemType Directory -Path $SkillsDir -Force | Out-Null }

    $skillDirs = Get-ChildItem -Path $src -Directory |
        Where-Object { Test-Path (Join-Path $_.FullName 'SKILL.md') }

    if (-not $skillDirs) {
        Write-Warning "No skill folders (containing SKILL.md) found in $Repo."
        return
    }

    $installed = @()
    foreach ($d in $skillDirs) {
        $dest = Join-Path $SkillsDir $d.Name
        if (Test-Path $dest) { Remove-Item -Path $dest -Recurse -Force }
        Copy-Item -Path $d.FullName -Destination $dest -Recurse -Force
        $installed += $d.Name
        Write-Host ("  [ok] " + $d.Name) -ForegroundColor Green
    }

    Write-Host ''
    Write-Host ("Installed {0} skill(s) to {1}" -f $installed.Count, $SkillsDir) -ForegroundColor Cyan
    Write-Host 'Restart Claude Code (or start a new session) to pick them up.' -ForegroundColor DarkGray
}
finally {
    if (Test-Path $tmp) { Remove-Item -Path $tmp -Recurse -Force -ErrorAction SilentlyContinue }
}
