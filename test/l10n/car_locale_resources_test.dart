import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';

void main() {
  test('every supported app locale has both native car string bundles', () {
    for (final locale in supportedAppLocales) {
      final qualifier = locale.languageCode == 'en'
          ? ''
          : locale.languageCode == 'zh'
          ? '-zh-r${locale.scriptCode == 'Hans' ? 'CN' : 'TW'}'
          : '-${locale.languageCode}';
      for (final res in [
        'android/car-core/src/main/res',
        'android/app/src/carProto/res',
      ]) {
        final file = File('$res/values$qualifier/strings.xml');
        expect(
          file.existsSync(),
          isTrue,
          reason: '$locale is offered but ${file.path} is missing',
        );
      }
    }
  });
}
