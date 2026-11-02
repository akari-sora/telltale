import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/diagnostics/service_recipes/mode08_codec.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/ui/screens/workshop/service_recipes_screen.dart';

void main() {
  String describe(Locale locale) => resolveMalformedReasonDescription(
    lookupAppLocalizations(locale),
    Mode08MalformedReason.truncated,
  );

  test('Traditional Chinese bundles keep the Traditional wording', () {
    expect(describe(traditionalChineseLocale), '回應長度不足');
    expect(describe(const Locale('zh')), '回應長度不足');
  });

  test('Simplified Chinese never gets the Traditional wording', () {
    expect(describe(simplifiedChineseLocale), 'Truncated response');
    for (final reason in Mode08MalformedReason.values) {
      expect(
        resolveMalformedReasonDescription(
          lookupAppLocalizations(simplifiedChineseLocale),
          reason,
        ),
        resolveMalformedReasonDescription(
          lookupAppLocalizations(englishLocale),
          reason,
        ),
      );
    }
  });

  test('German keeps its own wording', () {
    expect(describe(germanLocale), 'Antwort unvollständig');
  });
}
