# Creates an isolated Godot 4.6.3 export workspace; never copies signing credentials.
[CmdletBinding()]
param(
    [string]$TemplateDirectory = "$env:APPDATA/Godot/export_templates/4.6.3.stable",
    # A new workspace preserves previous build evidence without deletion or reuse.
    [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9_-]{0,63}$')]
    [string]$WorkspaceName = 'release-smoke'
)

$ErrorActionPreference = 'Stop'
$repoDirectory = Split-Path $PSScriptRoot -Parent
$outputDirectory = Join-Path $repoDirectory "export/$WorkspaceName"
$projectDirectory = Join-Path $outputDirectory 'project'
$templateZip = Join-Path $TemplateDirectory 'android_source.zip'
if (!(Test-Path -LiteralPath $templateZip)) { throw 'Godot 4.6.3 android_source.zip is required.' }
if ((Get-Content -LiteralPath (Join-Path $TemplateDirectory 'version.txt') -Raw).Trim() -ne '4.6.3.stable') {
    throw 'Only matching Godot 4.6.3 stable export templates are supported.'
}
if (Test-Path -LiteralPath $projectDirectory) {
    throw 'Smoke workspace already exists. Preserve its evidence or move it before preparing another.'
}
if (Test-Path -LiteralPath (Join-Path $repoDirectory 'config/ad_ids.gd')) {
    throw 'Private ad configuration found: do not copy it into the smoke workspace.'
}
$projectSettings = Get-Content -LiteralPath (Join-Path $repoDirectory 'project.godot') -Raw
if ($projectSettings -notmatch 'ads/use_test_ads=true' -or $projectSettings -notmatch 'ads/android_rewarded_id=""') {
    throw 'Release smoke requires unchanged test ads and an empty production rewarded unit.'
}

New-Item -ItemType Directory -Path $projectDirectory -Force | Out-Null
[IO.File]::WriteAllText((Join-Path $outputDirectory '.gdignore'), '')
foreach ($directory in @('addons', 'assets', 'config', 'locale', 'resources', 'scenes', 'scripts', 'theme')) {
    Copy-Item -LiteralPath (Join-Path $repoDirectory $directory) -Destination $projectDirectory -Recurse
}
foreach ($file in @('project.godot', 'default_bus_layout.tres', 'export_presets.cfg', 'LICENSE')) {
    Copy-Item -LiteralPath (Join-Path $repoDirectory $file) -Destination $projectDirectory
}
$androidDirectory = Join-Path $projectDirectory 'android'
$buildDirectory = Join-Path $androidDirectory 'build'
New-Item -ItemType Directory -Path $buildDirectory -Force | Out-Null
# Match Godot's installer: generated Android assets must never be scanned as sources.
[IO.File]::WriteAllText((Join-Path $androidDirectory '.gdignore'), '')
Add-Type -AssemblyName System.IO.Compression.FileSystem
[IO.Compression.ZipFile]::ExtractToDirectory($templateZip, $buildDirectory)
[IO.File]::WriteAllText((Join-Path $androidDirectory '.build_version'), '4.6.3.stable')
# Verified with the Godot 4.6.3 release AAR and the installed AdMob/Billing plugins.
# Gradle 8.11.1 already satisfies AGP 8.9.1; preserve every other template version.
$configPath = Join-Path $buildDirectory 'config.gradle'
$config = [IO.File]::ReadAllText($configPath)
if (!$config.Contains("androidGradlePlugin: '8.6.1'")) { throw 'Unexpected Godot template AGP.' }
$config = $config.Replace("androidGradlePlugin: '8.6.1'", "androidGradlePlugin: '8.9.1'")
[IO.File]::WriteAllText($configPath, $config, [Text.UTF8Encoding]::new($false))
New-Item -ItemType Directory -Path (Join-Path $projectDirectory 'export') -Force | Out-Null
Write-Output "Prepared isolated project: $projectDirectory"
Write-Output 'Export Android Release AAB with --export-release; signing is disabled.'
Write-Output 'Release-only AGP 8.9.1; development Android template remains unchanged.'
