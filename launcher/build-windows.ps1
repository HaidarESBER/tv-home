# Windows port of build-and-install.sh: builds launcher/build/tvhome.apk with the bare SDK tools.
# Usage: powershell -File build-windows.ps1
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
$root = (Resolve-Path '..\..').Path
$jh = (Get-ChildItem 'C:\Program Files\Eclipse Adoptium\jdk-17*' | Select-Object -First 1).FullName
$env:JAVA_HOME = $jh; $env:PATH = "$jh\bin;$env:PATH"
$sdk = "$root\sdk"; $bt = "$sdk\build-tools\34.0.0"; $jar = "$sdk\platforms\android-34\android.jar"
$B = 'build'
if (Test-Path $B) { Remove-Item -Recurse -Force $B }
New-Item -ItemType Directory "$B\gen", "$B\classes", "$B\dex" | Out-Null
function Run($exe) { & $exe @args; if ($LASTEXITCODE) { throw "$exe failed" } }
Run "$bt\aapt2.exe" compile --dir res -o "$B\res.zip"
Run "$bt\aapt2.exe" link -o "$B\base.apk" -I $jar --manifest AndroidManifest.xml --java "$B\gen" -A assets --min-sdk-version 30 --target-sdk-version 30 "$B\res.zip"
$src = Get-ChildItem src, "$B\gen" -Recurse -Filter *.java | ForEach-Object FullName
Run javac -encoding UTF-8 -nowarn '-Xlint:-options' --release 11 -classpath $jar -d "$B\classes" @src
$cls = Get-ChildItem "$B\classes" -Recurse -Filter *.class | ForEach-Object FullName
Run "$bt\d8.bat" --min-api 30 --lib $jar --output "$B\dex" @cls
# aapt2 on Windows stores assets as wallpapers\01.jpg (backslash), which Android can't open. Fix the names.
$py = "$root\repo\tools\venv\Scripts\python.exe"
Run $py -I "$root\repo\tools\fix_apk_paths.py" "$B\base.apk" "$B\unsigned.apk" | Out-Null
# add classes.dex with the SDK's aapt (the equivalent of `zip -u`), run from the dex folder
Push-Location "$B\dex"
Run "$bt\aapt.exe" add "..\unsigned.apk" classes.dex | Out-Null
Pop-Location
Run "$bt\zipalign.exe" -f 4 "$B\unsigned.apk" "$B\aligned.apk"
if (-not (Test-Path debug.keystore)) {
  Run keytool -genkeypair -keystore debug.keystore -storepass android -keypass android -alias tvhome -keyalg RSA -keysize 2048 -validity 10000 -dname 'CN=tvhome'
}
Run "$bt\apksigner.bat" sign --ks debug.keystore --ks-pass pass:android --out "$B\tvhome.apk" "$B\aligned.apk"
"built $B\tvhome.apk ($((Get-Item "$B\tvhome.apk").Length) bytes)"
