# PowerShell script to apply the speech_to_text plugin patch

$ErrorActionPreference = "Stop"

# Get the path to the speech_to_text plugin
$pubCachePath = "$env:USERPROFILE\AppData\Local\Pub\Cache\hosted\pub.dev"
$speechToTextPath = "$pubCachePath\speech_to_text-6.6.2"
$pluginKotlinPath = "$speechToTextPath\android\src\main\kotlin\com\csdcorp\speech_to_text\SpeechToTextPlugin.kt"

# Check if the plugin exists
if (-not (Test-Path $speechToTextPath)) {
    Write-Error "Speech to text plugin not found at $speechToTextPath"
    exit 1
}

# Create the directory structure if it doesn't exist
$pluginDir = Split-Path -Parent $pluginKotlinPath
if (-not (Test-Path $pluginDir)) {
    New-Item -ItemType Directory -Path $pluginDir -Force | Out-Null
    Write-Host "Created directory: $pluginDir"
}

# Copy the patched file to the plugin
$patchFilePath = "$PSScriptRoot\speech_to_text_plugin_fix.kt"
if (-not (Test-Path $patchFilePath)) {
    Write-Error "Patch file not found at $patchFilePath"
    exit 1
}

Write-Host "Applying patch to $pluginKotlinPath"
Copy-Item -Path $patchFilePath -Destination $pluginKotlinPath -Force

Write-Host "Patch applied successfully!"
Write-Host "Now run 'flutter clean' and 'flutter pub get' before building again."