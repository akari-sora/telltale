/// Hash-checked loader for the bundled powertrain battery research catalog.
library;

import 'dart:convert';

import 'package:flutter/services.dart';

import '../vehicle_catalog/catalog_digest.dart' as catalog_digest;
import 'powertrain_battery_profile.dart';
import 'profile_catalog_validator.dart';

final class PowertrainBatteryCatalogAsset {
  static const String catalogAsset =
      'assets/powertrain_battery/powertrain_battery_catalog.json';
  static const String manifestAsset =
      'assets/powertrain_battery/powertrain_battery_catalog.manifest.json';

  const PowertrainBatteryCatalogAsset._();

  static Future<PowertrainBatteryCatalogSnapshot> load([
    AssetBundle? bundle,
  ]) async {
    final assets = bundle ?? rootBundle;
    try {
      final values = await Future.wait([
        assets.loadString(manifestAsset),
        assets.loadString(catalogAsset),
      ]);
      return fromStrings(manifestJson: values[0], catalogJson: values[1]);
    } on PowertrainBatteryCatalogAssetException {
      rethrow;
    } catch (error) {
      throw PowertrainBatteryCatalogAssetException(
        'cannot load bundled powertrain battery catalog: $error',
      );
    }
  }

  /// The digest [fromStrings] checks the catalog bytes against.
  ///
  /// Public so a test fixture can build a self-consistent manifest for an
  /// in-memory catalog instead of pinning hashes that rot on every edit.
  static String sha256Hex(List<int> bytes) => catalog_digest.sha256Hex(bytes);

  static PowertrainBatteryCatalogSnapshot fromStrings({
    required String manifestJson,
    required String catalogJson,
  }) {
    try {
      final manifest = _PowertrainBatteryCatalogManifest.parse(manifestJson);
      final bytes = utf8.encode(catalogJson);
      if (sha256Hex(bytes) != manifest.sha256) {
        throw const PowertrainBatteryCatalogAssetException(
          'catalog SHA-256 does not match its manifest',
        );
      }
      if (bytes.length != manifest.sizeBytes) {
        throw const PowertrainBatteryCatalogAssetException(
          'catalog byte size does not match its manifest',
        );
      }

      final catalog = PowertrainBatteryCatalog.fromJsonString(catalogJson);
      const validator = PowertrainBatteryProfileCatalogValidator();
      final validation = validator.validateCatalog(catalog);
      if (!validation.isValid) {
        throw PowertrainBatteryCatalogAssetException(
          'catalog validation failed: ${validation.issues.first}',
        );
      }

      final profileCount = catalog.profiles.length;
      final signalCount = catalog.profiles.fold<int>(
        0,
        (total, profile) =>
            total +
            profile.commands.fold<int>(
              0,
              (commandTotal, command) => commandTotal + command.signals.length,
            ),
      );
      final countsByPowertrain = <String, int>{};
      for (final profile in catalog.profiles) {
        countsByPowertrain.update(
          profile.powertrain,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
      if (profileCount != manifest.profileCount ||
          signalCount != manifest.signalCount ||
          !_sameCounts(countsByPowertrain, manifest.countsByPowertrain)) {
        throw const PowertrainBatteryCatalogAssetException(
          'catalog statistics do not match its manifest',
        );
      }

      return PowertrainBatteryCatalogSnapshot._(
        catalog: catalog,
        catalogSha256: manifest.sha256,
        profileCount: profileCount,
        signalCount: signalCount,
        countsByPowertrain: countsByPowertrain,
      );
    } on PowertrainBatteryCatalogAssetException {
      rethrow;
    } on PowertrainBatteryProfileFormatException catch (error) {
      throw PowertrainBatteryCatalogAssetException(error.message);
    } on FormatException catch (error) {
      throw PowertrainBatteryCatalogAssetException(
        'manifest is not valid JSON: ${error.message}',
      );
    } catch (error) {
      throw PowertrainBatteryCatalogAssetException(
        'invalid bundled powertrain battery catalog: $error',
      );
    }
  }
}

final class PowertrainBatteryCatalogSnapshot {
  PowertrainBatteryCatalogSnapshot._({
    required this.catalog,
    required this.catalogSha256,
    required this.profileCount,
    required this.signalCount,
    required Map<String, int> countsByPowertrain,
  }) : countsByPowertrain = Map.unmodifiable(countsByPowertrain);

  final PowertrainBatteryCatalog catalog;
  final String catalogSha256;
  final int profileCount;
  final int signalCount;
  final Map<String, int> countsByPowertrain;
}

final class PowertrainBatteryCatalogAssetException implements Exception {
  const PowertrainBatteryCatalogAssetException(this.message);

  final String message;

  @override
  String toString() => 'PowertrainBatteryCatalogAssetException: $message';
}

final class _PowertrainBatteryCatalogManifest {
  const _PowertrainBatteryCatalogManifest({
    required this.sha256,
    required this.sizeBytes,
    required this.profileCount,
    required this.signalCount,
    required this.countsByPowertrain,
  });

  final String sha256;
  final int sizeBytes;
  final int profileCount;
  final int signalCount;
  final Map<String, int> countsByPowertrain;

  static _PowertrainBatteryCatalogManifest parse(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const PowertrainBatteryCatalogAssetException(
        'manifest must be a JSON object',
      );
    }
    final json = decoded.cast<String, Object?>();
    final schemaVersion = _integer(json['schema_version'], 'schema_version');
    if (schemaVersion != PowertrainBatteryCatalog.supportedSchemaVersion) {
      throw PowertrainBatteryCatalogAssetException(
        'unsupported manifest schema_version $schemaVersion',
      );
    }
    if (json['catalog_file'] != 'powertrain_battery_catalog.json') {
      throw const PowertrainBatteryCatalogAssetException(
        'manifest catalog_file is not the bundled catalog',
      );
    }
    final sha256 = _string(json['sha256'], 'sha256');
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(sha256)) {
      throw const PowertrainBatteryCatalogAssetException(
        'manifest sha256 is not a lowercase digest',
      );
    }
    final countsValue = json['counts_by_powertrain'];
    if (countsValue is! Map) {
      throw const PowertrainBatteryCatalogAssetException(
        'counts_by_powertrain must be an object',
      );
    }
    final counts = <String, int>{};
    for (final entry in countsValue.entries) {
      if (entry.key is! String ||
          entry.value is! int ||
          entry.value as int < 0) {
        throw const PowertrainBatteryCatalogAssetException(
          'counts_by_powertrain contains an invalid entry',
        );
      }
      counts[entry.key as String] = entry.value as int;
    }
    return _PowertrainBatteryCatalogManifest(
      sha256: sha256,
      sizeBytes: _nonNegativeInteger(json['size_bytes'], 'size_bytes'),
      profileCount: _nonNegativeInteger(json['profile_count'], 'profile_count'),
      signalCount: _nonNegativeInteger(json['signal_count'], 'signal_count'),
      countsByPowertrain: Map.unmodifiable(counts),
    );
  }
}

String _string(Object? value, String path) {
  if (value is! String || value.isEmpty) {
    throw PowertrainBatteryCatalogAssetException('$path must be a string');
  }
  return value;
}

int _integer(Object? value, String path) {
  if (value is! int) {
    throw PowertrainBatteryCatalogAssetException('$path must be an integer');
  }
  return value;
}

int _nonNegativeInteger(Object? value, String path) {
  final integer = _integer(value, path);
  if (integer < 0) {
    throw PowertrainBatteryCatalogAssetException('$path must be non-negative');
  }
  return integer;
}

bool _sameCounts(Map<String, int> left, Map<String, int> right) {
  if (left.length != right.length) return false;
  for (final entry in left.entries) {
    if (right[entry.key] != entry.value) return false;
  }
  return true;
}
