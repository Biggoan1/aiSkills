#requires -Version 5.1
<#
    getVibes.ps1 - one-shot installer for your Claude Code / Qwen / Codex skills.

    Pulls every skill from your aiSkills GitHub repo and installs it into the
    skills directory of the LLM CLI(s) you choose, so a fresh machine is one
    command away from all your skills.

    A "skill" is any top-level folder in the repo that contains a SKILL.md.
    Each installed skill folder is replaced wholesale (clean install).

    Target LLMs map to the convention ~/.<tool>/skills :
        claude -> ~/.claude/skills
        qwen   -> ~/.qwen/skills
        codex  -> ~/.codex/skills
        <any>  -> ~/.<any>/skills   (unknown names fall back to this)

    Usage:
        powershell -ExecutionPolicy Bypass -File .\getVibes.ps1                      # claude (default)
        powershell -ExecutionPolicy Bypass -File .\getVibes.ps1 -Llm qwen
        powershell -ExecutionPolicy Bypass -File .\getVibes.ps1 -Llm claude,qwen,codex
        powershell -ExecutionPolicy Bypass -File .\getVibes.ps1 -Llm all
        powershell -ExecutionPolicy Bypass -File .\getVibes.ps1 -SkillsDir D:\alt\skills   # explicit, wins over -Llm
        powershell -ExecutionPolicy Bypass -File .\getVibes.ps1 -Repo You/yourSkills -Branch main

    Uses git if it's on PATH, otherwise downloads the branch zip from GitHub.
#>
[CmdletBinding()]
param(
    [string]$Repo      = 'Biggoan1/aiSkills',
    [string]$Branch    = 'main',
    [string[]]$Llm     = @('claude'),
    [string]$SkillsDir
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Known LLM CLI skill-dir conventions.
$KnownLlms = [ordered]@{
    claude = (Join-Path $HOME '.claude\skills')
    qwen   = (Join-Path $HOME '.qwen\skills')
    codex  = (Join-Path $HOME '.codex\skills')
}

function Resolve-Targets {
    if ($SkillsDir) { return @($SkillsDir) }
    # Allow both -Llm claude,qwen and -Llm "claude,qwen"
    $names = $Llm | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim().ToLower() } | Where-Object { $_ }
    if ($names -contains 'all') { $names = @($KnownLlms.Keys) }
    $dirs = foreach ($n in $names) {
        if ($KnownLlms.Contains($n)) { $KnownLlms[$n] } else { Join-Path $HOME (".{0}\skills" -f $n) }
    }
    return ($dirs | Select-Object -Unique)
}

function Install-SkillsToDir {
    param([string]$Src, [string]$Dest)
    if (-not (Test-Path $Dest)) { New-Item -ItemType Directory -Path $Dest -Force | Out-Null }
    $skillDirs = Get-ChildItem -Path $Src -Directory |
        Where-Object { Test-Path (Join-Path $_.FullName 'SKILL.md') }
    if (-not $skillDirs) { Write-Warning "No skill folders (containing SKILL.md) found in $Repo."; return 0 }
    $n = 0
    foreach ($d in $skillDirs) {
        $target = Join-Path $Dest $d.Name
        if (Test-Path $target) { Remove-Item -Path $target -Recurse -Force }
        Copy-Item -Path $d.FullName -Destination $target -Recurse -Force
        Write-Host ("  [ok] " + $d.Name) -ForegroundColor Green
        $n++
    }
    return $n
}

$targets = Resolve-Targets

Write-Host ''
Write-Host "==== getVibes: installing skills from $Repo ($Branch) ====" -ForegroundColor Cyan
Write-Host ("Targets: " + ($targets -join ', ')) -ForegroundColor DarkGray

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

    $total = 0
    foreach ($dest in $targets) {
        Write-Host ''
        Write-Host ("--> " + $dest) -ForegroundColor Cyan
        $total += (Install-SkillsToDir -Src $src -Dest $dest)
    }

    Write-Host ''
    Write-Host ("Installed {0} skill folder(s) across {1} target(s)." -f $total, $targets.Count) -ForegroundColor Cyan
    Write-Host 'Restart the LLM CLI (or start a new session) to pick them up.' -ForegroundColor DarkGray
}
finally {
    if (Test-Path $tmp) { Remove-Item -Path $tmp -Recurse -Force -ErrorAction SilentlyContinue }
}
