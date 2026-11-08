# JVC Android TV (Expressluck "martin", Android 14, MediaTek, 1 GB RAM)

A worked example on a 32-bit, low-RAM set, driven from Windows.

| File | What it is |
|---|---|
| [debloat.txt](debloat.txt) | Packages disabled (never uninstalled) |
| [restore.ps1](restore.ps1) | Undoes everything below except cleared app data |

## What was done

- **Debloat:** ACR tracker (`tv.anoki.acr.anokiacroptin`), FAST channels, demo mode, voice search, TalkBack and
  other junk disabled. The stock launcher, TV recommendations and the Google setup wizard are disabled when the
  launcher is installed, so Home goes to the new launcher. The Freeview helper packages that Live TV depends on
  (`tifbridge`, `mdsclient`, `fvpconfigauth`) are kept.
- **Memory:** the Play Store is the biggest background process, so its background activity is denied
  (`cmd appops set com.android.vending RUN_ANY_IN_BACKGROUND deny`, standby bucket `restricted`). That also stops
  auto-updates; updates happen only when you open it. Animations are set to 0.5x.
- **Launcher:** dock, hidden apps and Live TV package are set in
  [`launcher/res/values/config.xml`](../../launcher/res/values/config.xml). A free-RAM pill (green above 250 MB,
  amber 150 to 250, red below) sits in the top-right row. Apps listed in `icon_apps` show their icon instead of a
  badly cropped banner.
- **Ad blocking:** Private DNS set to AdGuard DNS (`settings put global private_dns_mode hostname`,
  `private_dns_specifier dns.adguard-dns.com`). This blocks ad and tracker domains system-wide but cannot block
  YouTube video ads, which come from the same servers as the video.
- **YouTube without ads:** [SmartTube](https://github.com/yuliskov/SmartTube) (`org.smarttube.stable`), installed from
  its official GitHub release after checking the SHA-256 and signature. It is an unofficial client.

## Windows notes

- `tools/venv/Scripts/python.exe -I tools/tv.py ...` replaces the macOS paths. `launcher/build-windows.ps1` builds the APK
  with the Android SDK build-tools 34.0.0 and JDK 17.
- aapt2 on Windows stores assets with backslashes (`wallpapers\01.jpg`), which Android cannot open, so the wallpapers
  silently fail to load. `tools/fix_apk_paths.py` rewrites those names; the build script runs it.
- Git Bash rewrites arguments such as `/data/local/tmp/x.apk` into `C:/Program Files/Git/...`. Use PowerShell or set
  `MSYS_NO_PATHCONV=1` when calling `tv.py --push-b64`.
- Piping text from PowerShell to `tv.py --batch` can prepend a byte-order mark and break the first command; `tv.py` now
  strips it.
- On Android 14 the Wi-Fi name is hidden from apps while system location is off, so the launcher shows "Wi-Fi" and
  decides online/offline from `ConnectivityManager`.
