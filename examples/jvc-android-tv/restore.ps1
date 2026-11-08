# Undo the debloat: re-enable everything that was disabled, bring back the stock launcher and make it Home again.
# Usage:  powershell -ExecutionPolicy Bypass -File examples\jvc-android-tv\restore.ps1
# Needs the TV on and reachable (TV IP is saved in tools\.tv_host). Nothing was ever uninstalled.
# The uk.co.freeview.* apps were ALREADY disabled before the debloat, so they are left as they were
# (they were disabled at the factory).
$ErrorActionPreference = 'Stop'
Set-Location (Resolve-Path "$PSScriptRoot\..\..")  # repo root
$py = "tools\venv\Scripts\python.exe"

$packages = @(
  'tv.anoki.acr.anokiacroptin',
  'com.google.android.feedback',
  'com.google.android.partnersetup',
  'com.mstar.android.tv.disclaimercustomization',
  'com.cltv.fast',
  'com.google.android.play.games',
  'com.google.android.youtube.tvmusic',
  'com.google.android.backdrop',
  'fusion.android.tv.demo',
  'com.expressluck.tvhelpmanual',
  'com.google.android.katniss',
  'com.google.android.marvin.talkback',
  'com.mediatek.android.leanbacklauncher.partnercustomizer',
  # disabled by the launcher install
  'com.google.android.tvlauncher',
  'com.google.android.tvrecommendations',
  'com.google.android.tungsten.setupwraith'
)
$cmds = @()
foreach ($p in $packages) { $cmds += "pm enable $p" }
# Play Store background limits and animation speed (originals: window 1.0, transition 1.0, animator 0.6, bucket 5)
$cmds += 'cmd appops set com.android.vending RUN_ANY_IN_BACKGROUND allow'
$cmds += 'cmd appops set com.android.vending RUN_IN_BACKGROUND allow'
$cmds += 'am set-standby-bucket com.android.vending active'
$cmds += 'settings put global window_animation_scale 1.0'
$cmds += 'settings put global transition_animation_scale 1.0'
$cmds += 'settings put global animator_duration_scale 0.6'
# Private DNS (AdGuard ad blocking) was off originally: back to the router's DNS
$cmds += 'settings delete global private_dns_specifier'
$cmds += 'settings delete global private_dns_mode'
# NOTE: app data cleared with `pm clear` on the disabled apps cannot be restored (they were unused).
$cmds += 'cmd package set-home-activity --user 0 com.google.android.tvlauncher/.MainActivity'
$cmds += 'am force-stop com.mihir.tvhome'
$cmds += 'input keyevent KEYCODE_HOME'

$tmp = Join-Path $env:TEMP 'tv-restore-cmds.txt'
[IO.File]::WriteAllText($tmp, ($cmds -join "`n") + "`n", (New-Object Text.UTF8Encoding $false))
Get-Content $tmp -Raw | & $py -I tools\tv.py --batch
Remove-Item $tmp
"Restored. Press Home on the remote. (The custom launcher app is still installed but no longer Home.)"
"SmartTube (org.smarttube.stable) is also installed; remove it with:  $py -I tools\tv.py 'pm uninstall org.smarttube.stable'"
"To remove it completely:  $py -I tools\tv.py 'pm uninstall com.mihir.tvhome'"
