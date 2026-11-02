#!/usr/bin/env python3
"""Exercise F-Droid locale sync with isolated store fixtures."""
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
LOCALES = ('en-US', 'zh-TW', 'de-DE')
SHOTS = ('01-connect.png', '02-dashboard.png', '03-dtc-freeze.png',
         '05-performance.png', '06-skins.png')


class StoreLocaleSyncTest(unittest.TestCase):
    def test_future_changelogs_and_screenshot_order(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            script = root / 'tool/fdroid/sync_fastlane_from_store.sh'
            script.parent.mkdir(parents=True)
            shutil.copy2(REPO / 'tool/fdroid/sync_fastlane_from_store.sh', script)
            (root / 'store').mkdir()
            (root / 'store/icon-512.png').write_bytes(b'icon')
            for locale in LOCALES:
                meta = root / 'store/metadata' / locale
                (meta / 'changelogs').mkdir(parents=True)
                for name in ('title', 'short_description', 'full_description', 'video'):
                    (meta / f'{name}.txt').write_text(f'{locale}-{name}', encoding='utf-8')
                for code in (205, 209, 210):
                    (meta / f'changelogs/{code}.txt').write_text(f'{locale}-{code}', encoding='utf-8')
                images = root / 'store' / locale
                images.mkdir()
                for name in (*SHOTS, 'feature-1024x500.png'):
                    (images / name).write_bytes(f'{locale}-{name}'.encode())
            subprocess.run(['bash', str(script)], cwd=root, check=True, capture_output=True, text=True)
            for locale in LOCALES:
                fastlane = root / 'fastlane/metadata/android' / locale
                self.assertEqual((fastlane / 'title.txt').read_text(), f'{locale}-title')
                for code in (209, 210):
                    for suffix in ('', '1', '2', '3'):
                        self.assertEqual((fastlane / f'changelogs/{code}{suffix}.txt').read_text(), f'{locale}-{code}')
                self.assertFalse((fastlane / 'changelogs/2051.txt').exists())
                for i, name in enumerate(SHOTS, 1):
                    self.assertEqual((fastlane / f'images/phoneScreenshots/{i}.png').read_bytes(), (root / 'store' / locale / name).read_bytes())


if __name__ == '__main__':
    unittest.main()
