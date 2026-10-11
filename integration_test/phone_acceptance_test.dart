/// Runs the existing isolated Demo and localized feature journeys in one
/// device build. Use the rig flavor so field-app records remain untouched:
///
/// fvm flutter test integration_test/phone_acceptance_test.dart -d DEVICE_ID \
///   --flavor rig --dart-define=TELLTALE_TEST_RIG=true
library;

import 'demo_rig_test.dart' as demo;
import 'localization_disconnect_journey_test.dart' as disconnect;
import 'localization_dtc_journey_test.dart' as dtc;
import 'localization_export_journey_test.dart' as export_journey;
import 'localization_freeze_journey_test.dart' as freeze;
import 'localization_gauges_journey_test.dart' as gauges;
import 'localization_history_journey_test.dart' as history;
import 'localization_journey_test.dart' as navigation;
import 'localization_overflow_journey_test.dart' as overflow;
import 'localization_pid_journey_test.dart' as pids;
import 'localization_readiness_journey_test.dart' as readiness;
import 'localization_record_journey_test.dart' as record;
import 'localization_replay_journey_test.dart' as replay;
import 'localization_screenshot_journey_test.dart' as screenshot;
import 'localization_trends_journey_test.dart' as trends;

void main() {
  demo.main();
  navigation.main();
  gauges.main();
  pids.main();
  dtc.main();
  freeze.main();
  readiness.main();
  record.main();
  trends.main();
  history.main();
  replay.main();
  export_journey.main();
  disconnect.main();
  overflow.main();
  screenshot.main();
}
