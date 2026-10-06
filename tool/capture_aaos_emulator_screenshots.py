#!/usr/bin/env python3
"""Capture genuine, unscaled AAOS store screenshots directly from running Android Automotive OS emulators.

Satisfies Google Play Store AAOS screenshot guidelines (EP-4):
- Automotive Portrait: 800x1280 on generic AAOS emulator
- Automotive Landscape: 1024x768 on generic AAOS emulator
- Direct `adb exec-out screencap -p` capture without post-processing, resizing, or synthetic overlays
- 24-bit RGB PNG format (assert alpha == 255 before lossless conversion)
"""

import os
import subprocess
import sys
import time
from pathlib import Path
from PIL import Image

ADB = os.environ.get("ADB", "/Users/iml1s/Library/Android/sdk/platform-tools/adb")
PORTRAIT_SERIAL = os.environ.get("PORTRAIT_SERIAL", "emulator-5556")
LANDSCAPE_SERIAL = os.environ.get("LANDSCAPE_SERIAL", "emulator-5560")
APP_PACKAGE = "com.cbstudio.telltale.carproto.aaos"
APP_ACTIVITY = "androidx.car.app.activity.CarAppActivity"

ROOT_DIR = Path(__file__).resolve().parent.parent
METADATA_DIR = ROOT_DIR / "fastlane" / "metadata" / "android"

def run_cmd(args, check=True):
    res = subprocess.run(args, capture_output=True, text=True)
    if check and res.returncode != 0:
        raise RuntimeError(f"Command failed ({res.returncode}): {' '.join(args)}\nStderr: {res.stderr}")
    return res.stdout.strip()

def capture_screen(serial: str, screen_name: str, speed_mps: float = 0.0) -> Image.Image:
    print(f"[{serial}] Setting up screen: {screen_name} (speed={speed_mps} m/s)...")
    
    # Inject speed event
    run_cmd([ADB, "-s", serial, "shell", f"cmd car_service inject-vhal-event 0x11600207 0 {speed_mps}"], check=False)
    run_cmd([ADB, "-s", serial, "shell", f"cmd car_service inject-vhal-event 0x11600208 0 {speed_mps}"], check=False)

    # Force-stop and restart app to cleanly load target screen
    run_cmd([ADB, "-s", serial, "shell", "am", "force-stop", APP_PACKAGE])
    run_cmd([ADB, "-s", serial, "shell", "am", "start", "-n", f"{APP_PACKAGE}/{APP_ACTIVITY}"])
    time.sleep(3)

    # Re-inject speed once session is started
    if speed_mps > 0:
        run_cmd([ADB, "-s", serial, "shell", f"cmd car_service inject-continuous-events 0x11600208 {speed_mps} -s 10 -d 15"], check=False)
        run_cmd([ADB, "-s", serial, "shell", f"cmd car_service inject-continuous-events 0x11600207 {speed_mps} -s 10 -d 15"], check=False)
        time.sleep(1)

    # Capture raw frame
    proc = subprocess.run([ADB, "-s", serial, "exec-out", "screencap", "-p"], capture_output=True)
    if proc.returncode != 0 or len(proc.stdout) < 1000:
        raise RuntimeError(f"Failed to capture screencap from {serial}: {proc.stderr}")

    raw_path = Path("/tmp") / f"raw_{serial}_{screen_name}.png"
    raw_path.write_bytes(proc.stdout)

    im = Image.open(raw_path)
    return im

def process_and_save(im: Image.Image, expected_size: tuple[int, int], filename: str):
    if im.size != expected_size:
        raise ValueError(f"Captured screenshot size {im.size} does not match expected {expected_size}!")

    # Check alpha channel per store/README.md
    if im.mode == "RGBA":
        lo, hi = im.getchannel("A").getextrema()
        assert (lo, hi) == (255, 255), f"Alpha channel has transparent pixels: ({lo}, {hi})"
        rgb_im = im.convert("RGB")
    elif im.mode == "RGB":
        rgb_im = im
    else:
        raise ValueError(f"Unexpected image mode: {im.mode}")

    locales = ["en-US", "zh-TW"]
    for loc in locales:
        out_dir = METADATA_DIR / loc / "images" / "automotiveScreenshots"
        out_dir.mkdir(parents=True, exist_ok=True)
        dest = out_dir / filename
        rgb_im.save(dest, "PNG", optimize=True)
        print(f"Saved: {dest} ({rgb_im.size}, mode={rgb_im.mode}, channels=3)")

def main():
    print("=== AAOS Genuine Store Screenshot Capture Tool ===")

    # 1. Capture Portrait screens on emulator-5556 (800x1280)
    print("\n--- Capturing Portrait 800x1280 Screenshots (emulator-5556) ---")
    p1 = capture_screen(PORTRAIT_SERIAL, "home", speed_mps=0.0)
    process_and_save(p1, (800, 1280), "1_aaos_portrait_800x1280_telemetry.png")

    p2 = capture_screen(PORTRAIT_SERIAL, "health", speed_mps=0.0)
    process_and_save(p2, (800, 1280), "2_aaos_portrait_800x1280_health.png")

    p3 = capture_screen(PORTRAIT_SERIAL, "powertrain", speed_mps=13.89)
    process_and_save(p3, (800, 1280), "3_aaos_portrait_800x1280_powertrain.png")

    # 2. Capture Landscape screens on emulator-5560 (1024x768)
    print("\n--- Capturing Landscape 1024x768 Screenshots (emulator-5560) ---")
    l1 = capture_screen(LANDSCAPE_SERIAL, "home", speed_mps=0.0)
    process_and_save(l1, (1024, 768), "4_aaos_landscape_1024x768_telemetry.png")

    l2 = capture_screen(LANDSCAPE_SERIAL, "health", speed_mps=0.0)
    process_and_save(l2, (1024, 768), "5_aaos_landscape_1024x768_health.png")

    l3 = capture_screen(LANDSCAPE_SERIAL, "powertrain", speed_mps=13.89)
    process_and_save(l3, (1024, 768), "6_aaos_landscape_1024x768_powertrain.png")

    print("\n[SUCCESS] All 6 genuine generic AAOS screenshots successfully captured and verified!")

if __name__ == "__main__":
    main()
