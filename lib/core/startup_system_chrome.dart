import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const startupSystemChromeTimeout = Duration(milliseconds: 500);

typedef StartupOverlayStyleSetter = void Function(SystemUiOverlayStyle style);

/// Applies Activity-owned phone chrome without blocking a headless car start.
///
/// A projected Android Auto service can create the Flutter engine before an
/// Activity exists. In that state Flutter's Android platform channel accepts a
/// SystemChrome call but has no PlatformPlugin to answer it, so the returned
/// Future never completes. Keep this startup wait bounded so the app root and
/// the cold projection runtime are still created.
Future<void> configureStartupSystemChrome({
  Duration orientationTimeout = startupSystemChromeTimeout,
  StartupOverlayStyleSetter overlayStyleSetter =
      SystemChrome.setSystemUIOverlayStyle,
}) async {
  try {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]).timeout(orientationTimeout);
  } on TimeoutException {
    // A headless projected engine has no Activity-backed PlatformPlugin yet.
  } on MissingPluginException {
    // Startup remains valid on a host without the SystemChrome plugin.
  } on PlatformException {
    // A host that rejects orientation must not prevent the app root starting.
  }

  overlayStyleSetter(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
}
