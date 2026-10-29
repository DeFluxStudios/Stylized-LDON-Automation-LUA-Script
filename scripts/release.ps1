# Builds dist\LDON-Triune-v<version>-windows.zip, -linux.tar.gz and SHA256SUMS.txt.
# Run from anywhere: powershell -File scripts\release.ps1
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$script = Join-Path $root 'LDON_Triune.lua'

$match = Select-String -Path $script -Pattern "^local VERSION = '([^']+)'" | Select-Object -First 1
if (-not $match) { throw 'Could not read VERSION from LDON_Triune.lua.' }
$version = $match.Matches[0].Groups[1].Value

if (-not (Select-String -Path (Join-Path $root 'CHANGELOG.md') -Pattern "^## \[$([regex]::Escape($version))\]" -Quiet)) {
    throw "CHANGELOG.md has no entry for $version."
}

$name = "LDON-Triune-v$version"
$dist = Join-Path $root 'dist'
$stage = Join-Path $dist $name
if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
New-Item -ItemType Directory -Path $stage | Out-Null
New-Item -ItemType Directory -Path (Join-Path $stage 'artwork') | Out-Null

foreach ($file in 'LDON_Triune.lua', 'README.md', 'GETTING_STARTED.md', 'GUIDE.md', 'CHANGELOG.md') {
    Copy-Item (Join-Path $root $file) $stage
}
Copy-Item (Join-Path $root 'artwork\ldon-triune-banner.svg') (Join-Path $stage 'artwork')

$zip = Join-Path $dist "$name-windows.zip"
$tar = Join-Path $dist "$name-linux.tar.gz"
Remove-Item $zip, $tar -ErrorAction SilentlyContinue
Compress-Archive -Path $stage -DestinationPath $zip
tar -czf $tar -C $dist $name
if ($LASTEXITCODE -ne 0) { throw 'tar failed.' }

$sums = foreach ($archive in $zip, $tar) {
    '{0}  {1}' -f (Get-FileHash $archive -Algorithm SHA256).Hash.ToLower(), (Split-Path -Leaf $archive)
}
$sums | Set-Content (Join-Path $dist 'SHA256SUMS.txt')
$sums
