# Historical host-test output, not Android device evidence

The four files listed in SHA256SUMS are intentionally preserved byte-for-byte.
Their original generator at commit `edb66bba2489d57832f2743f5bf74d7962842db1`
was a host `flutter test` with `_SupplementSession` and a TCP receipt barrier.
It explicitly emitted strings labelled ActivityTaskManager/PowerManagerService,
expected RX payloads and numeric pause epochs. It did not call ADB, execute the
candidate APK, capture Android logcat or take screenshots. The constant APK hash
in its manifest is a reference, not a measured executed-binary identity.

These outputs can accompany a host session-retirement regression; they cannot
satisfy D05's installed-App HOME/screen-off/query/result correlation. The current
test retains meaningful host assertions without exporting synthetic OS events.
See ../../gate2_device_acceptance_report.md for the independently inspected result.
