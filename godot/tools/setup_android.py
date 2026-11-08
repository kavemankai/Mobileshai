#!/usr/bin/env python3
"""Sets up what Godot needs to export an Android APK, without Android Studio.

- Android command-line tools, then build-tools and platform-tools through sdkmanager, into ~/.cache/android-sdk
- a debug keystore (the standard android/android one), so a debug APK can be signed and sideloaded
- Godot editor settings pointing at the SDK, the JDK and the keystore

Needs a JDK 17 or newer on PATH. Run after setup_godot.py. Safe to run again.
"""
import os
import shutil
import subprocess
import urllib.request
import zipfile
from pathlib import Path

SDK = Path(os.environ.get("ANDROID_SDK_HOME", Path.home() / ".cache" / "android-sdk"))
CMDLINE = "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
BUILD_TOOLS = "35.0.0"
KEYSTORE = Path.home() / ".cache" / "godot-tools" / "debug.keystore"
## A fixed debug key kept in the repo, so every build (local or CI) is signed the same way and installs over the last
## one without losing the save. It is a debug key (password "android"), not a release key.
REPO_KEYSTORE = Path(__file__).resolve().parent / "debug.keystore"
SETTINGS = Path.home() / ".config" / "godot" / "editor_settings-4.6.tres"


def main() -> None:
    sdkmanager = SDK / "cmdline-tools" / "latest" / "bin" / "sdkmanager"
    if not sdkmanager.exists():
        SDK.mkdir(parents=True, exist_ok=True)
        z = SDK / "cmdline.zip"
        print("downloading Android command-line tools")
        urllib.request.urlretrieve(CMDLINE, z)
        with zipfile.ZipFile(z) as f:
            f.extractall(SDK / "tmp")
        (SDK / "cmdline-tools").mkdir(exist_ok=True)
        shutil.move(str(SDK / "tmp" / "cmdline-tools"), str(SDK / "cmdline-tools" / "latest"))
        shutil.rmtree(SDK / "tmp")
        z.unlink()
        for f in (SDK / "cmdline-tools" / "latest" / "bin").iterdir():
            f.chmod(0o755)
    if not (SDK / "build-tools" / BUILD_TOOLS / "apksigner").exists():
        print("installing build-tools and platform-tools")
        subprocess.run(f"yes | {sdkmanager} --sdk_root={SDK} --licenses > /dev/null", shell=True, check=False)
        subprocess.run([str(sdkmanager), f"--sdk_root={SDK}", f"build-tools;{BUILD_TOOLS}", "platform-tools"], check=True)
    if REPO_KEYSTORE.exists():
        KEYSTORE.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(REPO_KEYSTORE, KEYSTORE)
    if not KEYSTORE.exists():
        KEYSTORE.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run(["keytool", "-genkeypair", "-v", "-keystore", str(KEYSTORE), "-storepass", "android", "-alias",
                        "androiddebugkey", "-keypass", "android", "-keyalg", "RSA", "-keysize", "2048", "-validity", "10000",
                        "-dname", "CN=Android Debug,O=Android,C=US"], check=True, capture_output=True)
    java_home = Path(subprocess.run(["bash", "-c", "dirname $(dirname $(readlink -f $(which java)))"],
                                    capture_output=True, text=True).stdout.strip())
    SETTINGS.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        '[gd_resource type="EditorSettings" format=3]', "", "[resource]",
        f'export/android/android_sdk_path = "{SDK}"',
        f'export/android/java_sdk_path = "{java_home}"',
        f'export/android/debug_keystore = "{KEYSTORE}"',
        'export/android/debug_keystore_user = "androiddebugkey"',
        'export/android/debug_keystore_pass = "android"',
    ]
    if SETTINGS.exists():
        old = SETTINGS.read_text().splitlines()
        keep = [l for l in old if not l.startswith("export/android/")]
        if "[resource]" not in keep:
            keep = lines[:3]
        lines = keep + lines[3:]
    SETTINGS.write_text("\n".join(lines) + "\n")
    print(f"ANDROID_SDK={SDK}\nKEYSTORE={KEYSTORE}\nSETTINGS={SETTINGS}")


if __name__ == "__main__":
    main()
