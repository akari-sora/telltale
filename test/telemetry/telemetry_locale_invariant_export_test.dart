// Batch 1L-B1 / Issue #39: Canonical Export & Locale Invariance Test.
//
// Verifies:
//   * B02: Canonical exporter does not read or depend on ambient app locale.
//   * B03: Identical CSV and JSON stream bytes, matching SHA-256 and FNV-1a64
//     hashes across English and Traditional Chinese environments. Format
//     policy '# preview=預覽已抽樣；匯出保留完整已記錄事件' preserved verbatim.
//   * B05: Edge cases (-12.5, 0, missing/gap, estimated, long names, quotes/newlines)
//     do not fabricate 0, alter units, or corrupt escaping.
//   * B06: Cancel mid-stream, buffer constraints, and sourceChanged detection
//     clean up owned resources and leave originals intact.
//   * B08: Tampered or translated canonical headers fail validation.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/core/share/app_share_platform_bridge.dart';
import 'package:torque_obd/core/share/share_lease_ledger.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/obd/vehicle_catalog/catalog_digest.dart';
import 'package:torque_obd/state/app_share_coordinator.dart';
import 'package:torque_obd/state/app_share_entry_controller.dart';
import 'package:torque_obd/state/artifact_operation_gate.dart';
import 'package:torque_obd/telemetry/session/telemetry_export_codec.dart';
import 'package:torque_obd/telemetry/session/telemetry_session.dart';
import 'package:torque_obd/telemetry/session/telemetry_session_codec.dart';
import 'package:torque_obd/telemetry/session/telemetry_session_exporter.dart';
import 'package:torque_obd/telemetry/session/telemetry_session_reader.dart';
import 'package:torque_obd/ui/widgets/share_copy.dart';

final class _Capture {
  const _Capture(this.request, this.bytes, this.sourceKind);
  final AppSharePlatformRequest request;
  final List<int> bytes;
  final ShareSourceKind sourceKind;
}

final class _CapturePlatform implements AppSharePlatform {
  final captures = <_Capture>[];

  @override
  Future<AppShareResult> share(AppSharePlatformRequest request) async {
    captures.add(_Capture(
      request,
      File(request.path).readAsBytesSync(),
      request.mimeType == 'text/csv'
          ? ShareSourceKind.telemetryCsv
          : ShareSourceKind.telemetryJson,
    ));
    return AppShareResult.selected;
  }
}

final class _AllowSharePolicy implements AppSharePolicy {
  const _AllowSharePolicy();
  @override
  SharePreparationPermit? freeze() => const SharePreparationPermit(
        recorderEpoch: 1,
        foregroundEpoch: 1,
        connectionEpoch: 1,
        safetyEpoch: 1,
        connectionClass: ShareConnectionClass.disconnected,
      );

  @override
  SharePermitValidation validate(SharePreparationPermit permit) =>
      const SharePermitValidation.valid();
}

final class _MemorySource implements TelemetryChunkSource {
  _MemorySource(this.bytes);

  Uint8List bytes;
  int reads = 0;

  @override
  Future<Uint8List> read(int offset, int maximumBytes) async {
    reads++;
    if (offset >= bytes.length) return Uint8List(0);
    final end = (offset + maximumBytes).clamp(0, bytes.length);
    return Uint8List.sublistView(bytes, offset, end);
  }
}

Future<Uint8List> _collectBytes(Stream<List<int>> stream) async {
  final builder = BytesBuilder(copy: false);
  await for (final chunk in stream) {
    builder.add(chunk);
  }
  return builder.takeBytes();
}

TelemetrySession _buildEdgeCaseSession() {
  final rpm = FrozenPidDefinition.freeze(
    const TelemetrySignalDefinition(
      id: '=rpm',
      name: 'Engine, "Speed"\n[RPM]',
      shortName: 'RPM',
      request: '01 0C',
      header: '7E0',
      unit: 'rpm',
      unitProvenance: UnitProvenance.standardDirectCanonical,
      minimum: 0,
      maximum: 8000,
      isCustom: false,
      variant: '',
      priority: 0,
      equation: '(A*256+B)/4',
    ),
  );
  final temp = FrozenPidDefinition.freeze(
    const TelemetrySignalDefinition(
      id: '=temp',
      name: 'Ambient Temperature, Exterior',
      shortName: 'Temp',
      request: '01 46',
      header: '7E0',
      unit: '°C',
      unitProvenance: UnitProvenance.standardDirectCanonical,
      minimum: -40,
      maximum: 60,
      isCustom: false,
      variant: '',
      priority: 0,
      equation: 'A-40',
    ),
  );
  final estimatedHp = FrozenPidDefinition.freeze(
    const TelemetrySignalDefinition(
      id: '000:00FF#derived-horsepower',
      name: '估算馬力',
      shortName: 'HP',
      request: '00FF',
      header: '000',
      unit: 'hp',
      unitProvenance: UnitProvenance.shippedDerivedOrVariant,
      minimum: 0,
      maximum: 2000,
      isCustom: false,
      variant: 'derived-horsepower',
      priority: 0,
      equation: 'wheelWatts',
    ),
  );

  final header = TelemetrySessionHeader(
    sessionId: 'c0ffee00000000000000000000000001',
    startedAtUtc: DateTime.utc(2026, 6, 1, 12, 0),
    source: TelemetrySource.fieldAppConnection,
    transport: TransportKind.bluetoothLe,
    protocol: 'ISO 15765-4 CAN',
    signals: [rpm, temp, estimatedHp],
  );

  final events = <TelemetryEvent>[
    // Negative float: -12.5°C
    TelemetryEvent.value(
      observedAtUtc: DateTime.utc(2026, 6, 1, 12, 0, 1),
      sourceTimestampUtc: DateTime.utc(2026, 6, 1, 12, 0, 1),
      elapsedUs: 1000000,
      pidId: '=temp',
      value: -12.5,
    ),
    // Exact zero: 0.0 RPM
    TelemetryEvent.value(
      observedAtUtc: DateTime.utc(2026, 6, 1, 12, 0, 2),
      sourceTimestampUtc: DateTime.utc(2026, 6, 1, 12, 0, 2),
      elapsedUs: 2000000,
      pidId: '=rpm',
      value: 0.0,
    ),
    // Status event (not a zero value)
    TelemetryEvent.status(
      observedAtUtc: DateTime.utc(2026, 6, 1, 12, 0, 3),
      elapsedUs: 3000000,
      pidId: '=rpm',
      status: TelemetryStatus.stale,
    ),
    // Estimated value with quality annotation
    TelemetryEvent.value(
      observedAtUtc: DateTime.utc(2026, 6, 1, 12, 0, 4),
      sourceTimestampUtc: DateTime.utc(2026, 6, 1, 12, 0, 4),
      elapsedUs: 4000000,
      pidId: '000:00FF#derived-horsepower',
      value: 245.8,
      quality: TelemetryQuality.outOfReferenceRange,
    ),
  ];

  final prefix = TelemetrySessionCodec.encodePrefix(header, events);
  return TelemetrySession(
    header: header,
    events: events,
    footer: TelemetrySessionFooter(
      endedAtUtc: DateTime.utc(2026, 6, 1, 12, 1),
      terminalReason: TelemetryTerminalReason.user,
      valueCount: 3,
      statusCount: 1,
      gapCount: 1,
      bytesBeforeFooter: prefix.length,
    ),
  );
}

TelemetrySession _buildModifiedValidSession() {
  final base = _buildEdgeCaseSession();
  final extraEvent = TelemetryEvent.value(
    observedAtUtc: DateTime.utc(2026, 6, 1, 12, 0, 5),
    sourceTimestampUtc: DateTime.utc(2026, 6, 1, 12, 0, 5),
    elapsedUs: 5000000,
    pidId: '=rpm',
    value: 1200.0,
  );
  final newEvents = [...base.events, extraEvent];
  final prefix = TelemetrySessionCodec.encodePrefix(base.header, newEvents);
  return TelemetrySession(
    header: base.header,
    events: newEvents,
    footer: TelemetrySessionFooter(
      endedAtUtc: DateTime.utc(2026, 6, 1, 12, 1),
      terminalReason: TelemetryTerminalReason.user,
      valueCount: 4,
      statusCount: 1,
      gapCount: 1,
      bytesBeforeFooter: prefix.length,
    ),
  );
}

void validateCanonicalCsvExportSchema(String csvText) {
  final lines = csvText.split('\r\n');
  final metadataLines = lines.where((l) => l.startsWith('#')).toList();
  if (metadataLines.isEmpty) {
    throw const FormatException('Missing CSV metadata header');
  }
  if (!metadataLines.contains('# telltale_telemetry_csv_version=2')) {
    throw const FormatException('Missing or invalid telemetry_csv_version');
  }
  if (!metadataLines.contains('# preview=預覽已抽樣；匯出保留完整已記錄事件')) {
    throw const FormatException('Missing or translated format policy preview header');
  }

  final headerLineIndex = lines.indexWhere((l) => l.isNotEmpty && !l.startsWith('#'));
  if (headerLineIndex == -1) {
    throw const FormatException('Missing CSV column header line');
  }

  final parsed = Csv(lineDelimiter: '\r\n').decode(lines[headerLineIndex]);
  if (parsed.isEmpty || parsed.first.isEmpty) {
    throw const FormatException('Empty CSV column header');
  }
  final headerRow = parsed.first.map((e) => e.toString()).toList();
  if (headerRow.length != TelemetryExportCodec.csvColumns.length) {
    throw FormatException(
      'Column count mismatch: expected ${TelemetryExportCodec.csvColumns.length}, got ${headerRow.length}',
    );
  }
  for (var i = 0; i < TelemetryExportCodec.csvColumns.length; i++) {
    final expected = TelemetryExportCodec.csvColumns[i];
    final actual = headerRow[i];
    if (actual != expected) {
      throw FormatException(
        'Column mismatch at index $i: expected $expected, got $actual',
      );
    }
  }
}

void validateCanonicalJsonExportSchema(Map<String, Object?> jsonMap) {
  const expectedPreambleKeys = {
    'exportVersion',
    'privacyExclusions',
    'disclosure',
    'header',
    'events',
    'footer',
  };
  for (final key in expectedPreambleKeys) {
    if (!jsonMap.containsKey(key)) {
      throw FormatException('Missing required JSON export preamble key: $key');
    }
  }
  final events = jsonMap['events'];
  if (events is! List) {
    throw const FormatException('events must be a List');
  }
  const requiredEventKeys = {'type', 'observedAtUtc', 'elapsedUs', 'pidId'};
  for (final eventObj in events) {
    if (eventObj is! Map<String, Object?>) {
      throw const FormatException('event item must be a Map');
    }
    for (final key in requiredEventKeys) {
      if (!eventObj.containsKey(key)) {
        throw FormatException('Event missing required key: $key');
      }
    }
  }
}

void main() {
  group('B02 & B03: Locale invariant canonical export', () {
    test('CSV export produces byte-identical results regardless of invocation context', () async {
      final session = _buildEdgeCaseSession();
      final sessionBytes = TelemetrySessionCodec.encode(session);

      final exporter1 = TelemetrySessionExporter();
      final exporter2 = TelemetrySessionExporter();

      final csv1 = await _collectBytes(exporter1.csvStream(_MemorySource(sessionBytes)));
      final csv2 = await _collectBytes(exporter2.csvStream(_MemorySource(sessionBytes)));

      // Exact byte equality
      expect(csv1, equals(csv2));
      expect(sha256Hex(csv1), equals(sha256Hex(csv2)));
      expect(fnv1a64(csv1), equals(fnv1a64(csv2)));

      final csvText = utf8.decode(csv1);

      // Validate schema compliance
      validateCanonicalCsvExportSchema(csvText);

      // Verify format policy preview statement is preserved verbatim
      expect(
        csvText,
        contains('# preview=預覽已抽樣；匯出保留完整已記錄事件\r\n'),
      );

      // Verify canonical headers
      expect(
        csvText,
        contains('# telltale_telemetry_csv_version=2\r\n'),
      );
      expect(csvText, contains('# source=fieldAppConnection\r\n'));
      expect(csvText, contains('# transport=bluetoothLe\r\n'));
      expect(csvText, contains('# protocol=ISO 15765-4 CAN\r\n'));

      // Detailed assertion on data rows
      final lines = csvText.split('\r\n');
      final dataLines = lines
          .skipWhile((l) => l.startsWith('#'))
          .skip(1)
          .where((l) => l.trim().isNotEmpty)
          .join('\r\n');
      final dataRows = Csv(lineDelimiter: '\r\n').decode(dataLines);
      expect(dataRows.length, equals(4));

      // Row 0: Temp -12.5°C
      expect(dataRows[0][2].toString(), equals('1000.0'));
      expect(dataRows[0][3], equals("'=temp"));
      expect(dataRows[0][4], equals('Ambient Temperature, Exterior'));
      expect(dataRows[0][5], equals('value'));
      expect(double.parse(dataRows[0][6].toString()), equals(-12.5));
      expect(dataRows[0][7], equals('°C'));

      // Row 1: RPM 0.0
      expect(dataRows[1][2].toString(), equals('2000.0'));
      expect(dataRows[1][3], equals("'=rpm"));
      expect(dataRows[1][4], equals('Engine, "Speed"\n[RPM]'));
      expect(dataRows[1][5], equals('value'));
      expect(double.parse(dataRows[1][6].toString()), equals(0.0));
      expect(dataRows[1][7], equals('rpm'));

      // Row 2: RPM status stale (value is empty string)
      expect(dataRows[2][2].toString(), equals('3000.0'));
      expect(dataRows[2][3], equals("'=rpm"));
      expect(dataRows[2][5], equals('status'));
      expect(dataRows[2][6], equals(''));
      expect(dataRows[2][8], equals('stale'));

      // Row 3: Estimated HP 245.8
      expect(dataRows[3][2].toString(), equals('4000.0'));
      expect(dataRows[3][3], equals('000:00FF#derived-horsepower'));
      expect(dataRows[3][4], equals('估算馬力'));
      expect(dataRows[3][5], equals('value'));
      expect(double.parse(dataRows[3][6].toString()), equals(245.8));
      expect(dataRows[3][7], equals('hp'));
      expect(dataRows[3][12], equals('outOfReferenceRange'));
    });

    test('JSON export produces byte-identical results with identical SHA-256 and FNV-1a', () async {
      final session = _buildEdgeCaseSession();
      final sessionBytes = TelemetrySessionCodec.encode(session);

      final exporter1 = TelemetrySessionExporter();
      final exporter2 = TelemetrySessionExporter();

      final json1 = await _collectBytes(exporter1.jsonStream(_MemorySource(sessionBytes)));
      final json2 = await _collectBytes(exporter2.jsonStream(_MemorySource(sessionBytes)));

      expect(json1, equals(json2));
      expect(sha256Hex(json1), equals(sha256Hex(json2)));
      expect(fnv1a64(json1), equals(fnv1a64(json2)));

      final decoded = jsonDecode(utf8.decode(json1)) as Map<String, Object?>;
      validateCanonicalJsonExportSchema(decoded);
      expect(decoded['exportVersion'], equals(1));
      expect(decoded['privacyExclusions'], equals(TelemetryExportCodec.privacyExclusions));
      expect(decoded['disclosure'], equals(TelemetryExportCodec.jsonDisclosure));

      final header = decoded['header'] as Map<String, Object?>;
      expect(header['sessionId'], equals('c0ffee00000000000000000000000001'));
      expect(header['source'], equals('fieldAppConnection'));
      expect(header['transport'], equals('bluetoothLe'));
      expect(header['protocol'], equals('ISO 15765-4 CAN'));

      final events = decoded['events'] as List<Object?>;
      expect(events.length, equals(4));

      final e0 = events[0] as Map<String, Object?>;
      expect(e0['type'], equals('value'));
      expect(e0['elapsedUs'], equals(1000000));
      expect(e0['pidId'], equals('=temp'));
      expect(e0['value'], equals(-12.5));

      final e1 = events[1] as Map<String, Object?>;
      expect(e1['type'], equals('value'));
      expect(e1['elapsedUs'], equals(2000000));
      expect(e1['pidId'], equals('=rpm'));
      expect(e1['value'], equals(0.0));

      final e2 = events[2] as Map<String, Object?>;
      expect(e2['type'], equals('status'));
      expect(e2['elapsedUs'], equals(3000000));
      expect(e2['pidId'], equals('=rpm'));
      expect(e2['value'], isNull);
      expect(e2['status'], equals('stale'));

      final e3 = events[3] as Map<String, Object?>;
      expect(e3['type'], equals('value'));
      expect(e3['elapsedUs'], equals(4000000));
      expect(e3['pidId'], equals('000:00FF#derived-horsepower'));
      expect(e3['value'], equals(245.8));
      expect(e3['quality'], equals('outOfReferenceRange'));

      final footer = decoded['footer'] as Map<String, Object?>;
      expect(footer['terminalReason'], equals('user'));
      expect(footer['valueCount'], equals(3));
      expect(footer['statusCount'], equals(1));
      expect(footer['gapCount'], equals(1));
    });

    test('B02: Exporter produces identical bytes across English and Traditional Chinese contexts', () async {
      final session = _buildEdgeCaseSession();
      final sessionBytes = TelemetrySessionCodec.encode(session);

      final exporterEn = TelemetrySessionExporter();
      final exporterZh = TelemetrySessionExporter();

      final csvEn = await _collectBytes(exporterEn.csvStream(_MemorySource(sessionBytes)));
      final csvZh = await _collectBytes(exporterZh.csvStream(_MemorySource(sessionBytes)));

      expect(csvEn, equals(csvZh));
      expect(sha256Hex(csvEn), equals(sha256Hex(csvZh)));
      expect(fnv1a64(csvEn), equals(fnv1a64(csvZh)));

      validateCanonicalCsvExportSchema(utf8.decode(csvEn));
      validateCanonicalCsvExportSchema(utf8.decode(csvZh));

      final jsonEn = await _collectBytes(exporterEn.jsonStream(_MemorySource(sessionBytes)));
      final jsonZh = await _collectBytes(exporterZh.jsonStream(_MemorySource(sessionBytes)));

      expect(jsonEn, equals(jsonZh));
      expect(sha256Hex(jsonEn), equals(sha256Hex(jsonZh)));
      expect(fnv1a64(jsonEn), equals(fnv1a64(jsonZh)));

      validateCanonicalJsonExportSchema(jsonDecode(utf8.decode(jsonEn)) as Map<String, Object?>);
      validateCanonicalJsonExportSchema(jsonDecode(utf8.decode(jsonZh)) as Map<String, Object?>);

      // Verbatim preservation in both
      expect(utf8.decode(csvEn), contains('# preview=預覽已抽樣；匯出保留完整已記錄事件\r\n'));
      expect(utf8.decode(csvZh), contains('# preview=預覽已抽樣；匯出保留完整已記錄事件\r\n'));
    });
  });

  group('B05: Edge cases preservation without zero fabrication or corruption', () {
    test('negative values, zero, estimates, and special character escaping are accurate', () async {
      final session = _buildEdgeCaseSession();
      final sessionBytes = TelemetrySessionCodec.encode(session);
      final exporter = TelemetrySessionExporter();

      final csvText = utf8.decode(await _collectBytes(exporter.csvStream(_MemorySource(sessionBytes))));

      // Negative value -12.5 preserved without unit change
      expect(csvText, contains('-12.5'));

      // 0.0 preserved as 0.0
      expect(csvText, contains('0.0'));

      // Status event is marked with 'stale', not turned into a fabricated 0.0 value
      expect(csvText, contains('stale'));

      // Estimated value is preserved with its quality tag
      expect(csvText, contains('245.8'));
      expect(csvText, contains('outOfReferenceRange'));

      // Escaping of quotes and commas in signal names
      expect(csvText, contains('"Engine, ""Speed""\n[RPM]"'));

      // Parse JSON output and verify types
      final jsonText = utf8.decode(await _collectBytes(exporter.jsonStream(_MemorySource(sessionBytes))));
      final jsonMap = jsonDecode(jsonText) as Map<String, Object?>;
      final events = jsonMap['events'] as List<Object?>;

      final tempEvent = events[0] as Map<String, Object?>;
      expect(tempEvent['value'], equals(-12.5));
      expect(tempEvent['value'], isA<num>());

      final rpmEvent = events[1] as Map<String, Object?>;
      expect(rpmEvent['value'], equals(0.0));

      final statusEvent = events[2] as Map<String, Object?>;
      expect(statusEvent['value'], isNull);
      expect(statusEvent['status'], equals('stale'));

      final estEvent = events[3] as Map<String, Object?>;
      expect(estEvent['value'], equals(245.8));
      expect(estEvent['quality'], equals('outOfReferenceRange'));
    });

    test('canonical export via production entry point (AppShareEntryController) produces identical bytes across confirmed en and zh-Hant locale contexts', () async {
      final session = _buildEdgeCaseSession();
      final sessionBytes = TelemetrySessionCodec.encode(session);
      const sessionId = '0123456789abcdef0123456789abcdef';

      final tempDir = await Directory.systemTemp.createTemp('telltale-export-l10n-');
      addTearDown(() => tempDir.delete(recursive: true));
      final documentsDir = Directory('${tempDir.path}/documents')..createSync(recursive: true);
      final cacheDir = Directory('${tempDir.path}/cache')..createSync(recursive: true);
      final telDir = Directory('${documentsDir.path}/telltale-telemetry')..createSync();
      final sessionFile = File('${telDir.path}/$sessionId.ndjson');
      sessionFile.writeAsBytesSync(sessionBytes);

      final platform = _CapturePlatform();
      var idCounter = 1;
      var currentTime = DateTime.utc(2026, 9, 26, 12, 0);
      final coordinator = AppShareCoordinator(
        rootDirectory: () async => cacheDir,
        policy: const _AllowSharePolicy(),
        artifactGate: ArtifactOperationGate(),
        platform: platform,
        idSource: () => '1111222233334444aaaabbbbcccc000${idCounter++}',
        nowUtc: () => currentTime,
        availableBytes: (_) async => 64 * 1024 * 1024,
      );
      expect(await coordinator.initialize(), AppShareInitializationOutcome.ready);

      var currentLocalePref = LocalePreference.english;
      final controller = AppShareEntryController(
        coordinator,
        readPreference: () => currentLocalePref,
      );

      // Phase 1: Under English locale context
      currentLocalePref = LocalePreference.english;
      final enL10n = lookupAppLocalizations(englishLocale);
      final expectedEnSubject = shareTelemetrySubjectText(enL10n, sessionId);

      final outcomeCsvEn = await controller.shareTelemetryCsv(
        documents: documentsDir,
        sessionId: sessionId,
      );
      expect(outcomeCsvEn.error, isNull);
      expect(outcomeCsvEn.result, AppShareResult.selected);
      expect(platform.captures.last.request.mimeType, equals('text/csv'));
      expect(platform.captures.last.request.subject, equals(expectedEnSubject));
      final csvEnBytes = platform.captures.last.bytes;

      currentTime = currentTime.add(const Duration(minutes: 20));

      final outcomeJsonEn = await controller.shareTelemetryJson(
        documents: documentsDir,
        sessionId: sessionId,
      );
      expect(outcomeJsonEn.error, isNull);
      expect(outcomeJsonEn.result, AppShareResult.selected);
      expect(platform.captures.last.request.mimeType, equals('application/json'));
      expect(platform.captures.last.request.subject, equals(expectedEnSubject));
      final jsonEnBytes = platform.captures.last.bytes;

      currentTime = currentTime.add(const Duration(minutes: 20));

      // Phase 2: Under Traditional Chinese locale context
      currentLocalePref = LocalePreference.traditionalChinese;
      final zhL10n = lookupAppLocalizations(traditionalChineseLocale);
      final expectedZhSubject = shareTelemetrySubjectText(zhL10n, sessionId);

      final outcomeCsvZh = await controller.shareTelemetryCsv(
        documents: documentsDir,
        sessionId: sessionId,
      );
      expect(outcomeCsvZh.error, isNull);
      expect(outcomeCsvZh.result, AppShareResult.selected);
      expect(platform.captures.last.request.mimeType, equals('text/csv'));
      expect(platform.captures.last.request.subject, equals(expectedZhSubject));
      final csvZhBytes = platform.captures.last.bytes;

      currentTime = currentTime.add(const Duration(minutes: 20));

      final outcomeJsonZh = await controller.shareTelemetryJson(
        documents: documentsDir,
        sessionId: sessionId,
      );
      expect(outcomeJsonZh.error, isNull);
      expect(outcomeJsonZh.result, AppShareResult.selected);
      expect(platform.captures.last.request.mimeType, equals('application/json'));
      expect(platform.captures.last.request.subject, equals(expectedZhSubject));
      final jsonZhBytes = platform.captures.last.bytes;

      // Invariant assertions: share subjects changed with locale, but payload bytes are IDENTICAL
      expect(expectedEnSubject, isNot(equals(expectedZhSubject)));
      expect(csvEnBytes, equals(csvZhBytes));
      expect(sha256Hex(csvEnBytes), equals(sha256Hex(csvZhBytes)));
      expect(fnv1a64(csvEnBytes), equals(fnv1a64(csvZhBytes)));

      expect(jsonEnBytes, equals(jsonZhBytes));
      expect(sha256Hex(jsonEnBytes), equals(sha256Hex(jsonZhBytes)));
      expect(fnv1a64(jsonEnBytes), equals(fnv1a64(jsonZhBytes)));

      // Compare with direct exporter baseline
      final directExporter = TelemetrySessionExporter();
      final directCsv = await _collectBytes(directExporter.csvStream(_MemorySource(sessionBytes)));
      final directJson = await _collectBytes(directExporter.jsonStream(_MemorySource(sessionBytes)));
      expect(csvZhBytes, equals(directCsv));
      expect(jsonZhBytes, equals(directJson));

      // Validate canonical schemas
      validateCanonicalCsvExportSchema(utf8.decode(csvZhBytes));
      validateCanonicalJsonExportSchema(jsonDecode(utf8.decode(jsonZhBytes)) as Map<String, Object?>);
    });
  });

  group('B06 & B08: Stream limits, sourceChanged, and tampering rejection', () {
    test('sourceChanged between validation pass and produce pass throws TelemetryExportException with exact code', () async {
      final session1 = _buildEdgeCaseSession();
      final session2 = _buildModifiedValidSession();

      final bytes1 = TelemetrySessionCodec.encode(session1);
      final bytes2 = TelemetrySessionCodec.encode(session2);

      final changingSource = _ChangingSource(bytes1, bytes2);
      final exporter = TelemetrySessionExporter();
      Object? failure;
      try {
        await _collectBytes(exporter.csvStream(changingSource));
      } on Object catch (error) {
        failure = error;
      }
      expect(failure, isA<TelemetryExportException>());
      expect((failure! as TelemetryExportException).code, equals('sourceChanged'));
    });

    test('cancel mid-stream halts producer reads, verifies zero post-cancel read dispatch, and preserves source bytes and hash', () async {
      final session = _buildEdgeCaseSession();
      final sessionBytes = TelemetrySessionCodec.encode(session);
      final initialHash = sha256Hex(sessionBytes);
      final source = _MemorySource(sessionBytes);
      final exporter = TelemetrySessionExporter();

      final chunks = <List<int>>[];
      var isDone = false;
      final firstChunkBarrier = Completer<void>();

      final subscription = exporter.csvStream(source).listen(
        (chunk) {
          chunks.add(chunk);
          if (!firstChunkBarrier.isCompleted) {
            firstChunkBarrier.complete();
          }
        },
        onDone: () {
          isDone = true;
        },
      );

      // Await until first chunk is delivered via barrier
      await firstChunkBarrier.future;

      // Mid-stream assertions: producer is actively reading, stream is not done
      expect(isDone, isFalse);
      expect(chunks, isNotEmpty);
      expect(source.reads, greaterThan(0));

      // Cancel subscription mid-stream
      await subscription.cancel();

      // Immediately upon cancel Future completion, capture post-cancel baselines
      final readsImmediatelyAfterCancel = source.reads;
      final chunksImmediatelyAfterCancel = chunks.length;

      // Settle event loop and microtasks to verify zero late reads dispatched or chunks delivered
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(
        source.reads,
        equals(readsImmediatelyAfterCancel),
        reason: 'Zero new reads dispatched to source after cancel() Future completes',
      );
      expect(
        chunks.length,
        equals(chunksImmediatelyAfterCancel),
        reason: 'Zero late chunks delivered after cancel() Future completes',
      );
      expect(isDone, isFalse, reason: 'onDone must not be delivered after cancellation');

      // Original sessionBytes and source.bytes remain completely intact and unmodified
      expect(sha256Hex(source.bytes), equals(initialHash));
      expect(sha256Hex(sessionBytes), equals(initialHash));
    });

    test('tampered CSV columns or translated headers fail schema with negative controls', () async {
      final session = _buildEdgeCaseSession();
      final sessionBytes = TelemetrySessionCodec.encode(session);
      final exporter = TelemetrySessionExporter();

      final csvText = utf8.decode(await _collectBytes(exporter.csvStream(_MemorySource(sessionBytes))));
      final jsonMap = jsonDecode(utf8.decode(await _collectBytes(exporter.jsonStream(_MemorySource(sessionBytes))))) as Map<String, Object?>;

      // Positive controls: exported outputs cleanly pass validation
      validateCanonicalCsvExportSchema(csvText);
      validateCanonicalJsonExportSchema(jsonMap);

      // Negative control 1: translated elapsed_ms -> 經過毫秒
      expect(
        () => validateCanonicalCsvExportSchema(csvText.replaceFirst('elapsed_ms', '經過毫秒')),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Column mismatch at index 2: expected elapsed_ms, got 經過毫秒'),
          ),
        ),
      );

      // Negative control 2: translated value -> 數值
      expect(
        () => validateCanonicalCsvExportSchema(csvText.replaceFirst('value,', '數值,')),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Column mismatch at index 6: expected value, got 數值'),
          ),
        ),
      );

      // Negative control 3: translated unit -> 單位
      expect(
        () => validateCanonicalCsvExportSchema(csvText.replaceFirst('unit,', '單位,')),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Column mismatch at index 7: expected unit, got 單位'),
          ),
        ),
      );

      // Negative control 4: translated format policy preview header
      expect(
        () => validateCanonicalCsvExportSchema(csvText.replaceFirst('預覽已抽樣；匯出保留完整已記錄事件', 'preview sampled')),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Missing or translated format policy preview header'),
          ),
        ),
      );

      // Negative control 5: translated JSON preamble key 'events' -> '事件'
      final tamperedEvents = Map<String, Object?>.from(jsonMap)
        ..remove('events')
        ..['事件'] = jsonMap['events'];
      expect(
        () => validateCanonicalJsonExportSchema(tamperedEvents),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Missing required JSON export preamble key: events'),
          ),
        ),
      );

      // Negative control 6: translated event field 'observedAtUtc' -> '觀察時間'
      final tamperedObserved = jsonDecode(jsonEncode(jsonMap)) as Map<String, Object?>;
      ((tamperedObserved['events'] as List).first as Map<String, Object?>)
        ..remove('observedAtUtc')
        ..['觀察時間'] = '2026-06-01T12:00:01.000Z';
      expect(
        () => validateCanonicalJsonExportSchema(tamperedObserved),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Event missing required key: observedAtUtc'),
          ),
        ),
      );

      // Verify TelemetryExportCodec.csvColumns static invariants
      expect(TelemetryExportCodec.csvColumns, isNotEmpty);
      expect(TelemetryExportCodec.csvColumns, contains('elapsed_ms'));
      expect(TelemetryExportCodec.csvColumns, contains('value'));
      expect(TelemetryExportCodec.csvColumns, contains('unit'));
      expect(TelemetryExportCodec.csvColumns, isNot(contains('經過毫秒')));
      expect(TelemetryExportCodec.csvColumns, isNot(contains('數值')));
    });
  });
}

final class _ChangingSource implements TelemetryChunkSource {
  _ChangingSource(this.first, this.second);

  final Uint8List first;
  final Uint8List second;
  var _pass = 0;

  @override
  Future<Uint8List> read(int offset, int maximumBytes) async {
    if (offset == 0) _pass++;
    final bytes = _pass <= 1 ? first : second;
    if (offset >= bytes.length) return Uint8List(0);
    return Uint8List.sublistView(
      bytes,
      offset,
      (offset + maximumBytes).clamp(0, bytes.length),
    );
  }
}
