/// Typed ELM327 CAN addressing helpers: `ATCEA`, `ATCP`, and `ATCRA`.
///
/// Vehicle profiles cannot supply AT text. There is no API here that accepts
/// an arbitrary command string. Apply and restore go through the client's
/// single-owner `_commandChain`.
///
/// Compact spellings match the rest of this ELM path (`ATCEA07`, `ATCP17`,
/// `ATCRA607`) — no spaces. Datasheet restore forms are pinned in tests:
/// `ATCEA` (clear), `ATCP18` (default priority), `ATCRA` (clear filter).
library;

import 'addressing.dart';
import 'transport/obd_transport.dart';

// ---------------------------------------------------------------------------
// Extended addressing (ATCEA)
// ---------------------------------------------------------------------------

/// Adapter extended-addressing programming this client currently believes.
sealed class ElmExtendedAddressingState {
  const ElmExtendedAddressingState();
}

final class ElmExtendedAddressingOff extends ElmExtendedAddressingState {
  const ElmExtendedAddressingOff();
}

final class ElmExtendedAddressingOn extends ElmExtendedAddressingState {
  const ElmExtendedAddressingOn(this.addressByte);
  final int addressByte;
}

final class ElmExtendedAddressingUnknown extends ElmExtendedAddressingState {
  const ElmExtendedAddressingUnknown();
}

enum ElmExtendedAddressingResult {
  applied,
  restored,
  rejectedUnknownCommand,
  restoreRejected,
  timedOut,
  unconfirmedWrite,
  disconnected,
  budgetExceeded,
  restoreFailed,
}

final class ElmExtendedAddressingOutcome {
  const ElmExtendedAddressingOutcome({
    required this.result,
    required this.state,
  });

  final ElmExtendedAddressingResult result;
  final ElmExtendedAddressingState state;

  bool get producedMeasurement =>
      result == ElmExtendedAddressingResult.applied;

  TransportIssue? get refusalIssue => switch (result) {
        ElmExtendedAddressingResult.rejectedUnknownCommand ||
        ElmExtendedAddressingResult.restoreFailed =>
          TransportIssue.extendedAddressingUnavailable,
        _ => null,
      };
}

/// Bounds and datasheet spellings for `ATCEA`.
abstract final class ElmExtendedAddressingConfig {
  static const restoreCommand = 'ATCEA';
  static const maxApplyCommands = 1;
  static const maxRestoreCommands = 1;
  static const maxResponseBytes = 256;
  static const defaultBudget = Duration(seconds: 8);

  /// Builds `ATCEAhh` for a single target address byte (0–255).
  static String applyCommand(int addressByte) {
    _requireByte(addressByte, 'addressByte');
    return 'ATCEA${_hexByte(addressByte)}';
  }
}

abstract final class ElmExtendedAddressingMessages {
  static const unavailable =
      'Extended addressing is not available on this ELM327 path.';
  static const restoreFailed =
      'The adapter refused to clear extended addressing (ATCEA), so polling is stopped until you reconnect.';
}

// ---------------------------------------------------------------------------
// CAN priority (ATCP) — 29-bit only
// ---------------------------------------------------------------------------

sealed class ElmCanPriorityState {
  const ElmCanPriorityState();
}

final class ElmCanPriorityDefault extends ElmCanPriorityState {
  const ElmCanPriorityDefault();
}

final class ElmCanPriorityCustom extends ElmCanPriorityState {
  const ElmCanPriorityCustom(this.priorityByte);
  final int priorityByte;
}

final class ElmCanPriorityUnknown extends ElmCanPriorityState {
  const ElmCanPriorityUnknown();
}

enum ElmCanPriorityResult {
  applied,
  restored,
  rejectedUnknownCommand,
  restoreRejected,
  timedOut,
  unconfirmedWrite,
  disconnected,
  budgetExceeded,
  restoreFailed,
}

final class ElmCanPriorityOutcome {
  const ElmCanPriorityOutcome({
    required this.result,
    required this.state,
  });

  final ElmCanPriorityResult result;
  final ElmCanPriorityState state;

  bool get producedMeasurement => result == ElmCanPriorityResult.applied;

  TransportIssue? get refusalIssue => switch (result) {
        ElmCanPriorityResult.rejectedUnknownCommand ||
        ElmCanPriorityResult.restoreFailed =>
          TransportIssue.canPriorityUnavailable,
        _ => null,
      };
}

/// Bounds and datasheet spellings for `ATCP`.
///
/// Datasheet default after reset is `18`. Restore always sends that value —
/// there is no empty clear form.
abstract final class ElmCanPriorityConfig {
  static const int defaultPriorityByte = 0x18;
  static const restoreCommand = 'ATCP18';
  static const maxApplyCommands = 1;
  static const maxRestoreCommands = 1;
  static const maxResponseBytes = 256;
  static const defaultBudget = Duration(seconds: 8);

  static String applyCommand(int priorityByte) {
    _requireByte(priorityByte, 'priorityByte');
    return 'ATCP${_hexByte(priorityByte)}';
  }
}

abstract final class ElmCanPriorityMessages {
  static const unavailable =
      'CAN priority programming is not available on this ELM327 path.';
  static const restoreFailed =
      'The adapter refused to restore default CAN priority (ATCP18), so polling is stopped until you reconnect.';
}

// ---------------------------------------------------------------------------
// CAN receive filter (ATCRA)
// ---------------------------------------------------------------------------

sealed class ElmCanReceiveFilterState {
  const ElmCanReceiveFilterState();
}

final class ElmCanReceiveFilterOff extends ElmCanReceiveFilterState {
  const ElmCanReceiveFilterOff();
}

final class ElmCanReceiveFilterOn extends ElmCanReceiveFilterState {
  const ElmCanReceiveFilterOn(this.address);
  final String address;
}

final class ElmCanReceiveFilterUnknown extends ElmCanReceiveFilterState {
  const ElmCanReceiveFilterUnknown();
}

enum ElmCanReceiveFilterResult {
  applied,
  restored,
  rejectedUnknownCommand,
  restoreRejected,
  timedOut,
  unconfirmedWrite,
  disconnected,
  budgetExceeded,
  restoreFailed,
}

final class ElmCanReceiveFilterOutcome {
  const ElmCanReceiveFilterOutcome({
    required this.result,
    required this.state,
  });

  final ElmCanReceiveFilterResult result;
  final ElmCanReceiveFilterState state;

  bool get producedMeasurement =>
      result == ElmCanReceiveFilterResult.applied;

  TransportIssue? get refusalIssue => switch (result) {
        ElmCanReceiveFilterResult.rejectedUnknownCommand ||
        ElmCanReceiveFilterResult.restoreFailed =>
          TransportIssue.canReceiveFilterUnavailable,
        _ => null,
      };
}

/// A reviewed receive-filter program. Construction throws on an invalid shape.
final class ElmCanReceiveFilterConfig {
  ElmCanReceiveFilterConfig._(this.address);

  /// [address] must be exactly 3 hex digits on 11-bit CAN or 8 on 29-bit CAN.
  factory ElmCanReceiveFilterConfig({
    required String address,
    required BusAddressing addressing,
  }) {
    if (!addressing.isCan) {
      throw ArgumentError(
        'CAN receive filter is defined only on 11-bit or 29-bit CAN',
      );
    }
    final normalised = BusAddressing.normaliseHeader(address);
    if (!RegExp(r'^[0-9A-F]+$').hasMatch(normalised)) {
      throw ArgumentError.value(
        address,
        'address',
        'must be hexadecimal',
      );
    }
    if (normalised.length != 3 && normalised.length != 8) {
      throw ArgumentError.value(
        address,
        'address',
        'must be exactly 3 or 8 hex digits',
      );
    }
    if (!addressing.acceptedReceiveWidths.contains(normalised.length)) {
      throw ArgumentError.value(
        address,
        'address',
        'receive-filter width must be an accepted CAN receive width on this bus',
      );
    }
    if (!BusAddressing.isLegalCanId(normalised)) {
      throw ArgumentError.value(
        address,
        'address',
        'not a legal CAN identifier at this width',
      );
    }
    return ElmCanReceiveFilterConfig._(normalised);
  }

  /// Derives the receive filter for a physical 11-bit CAN ECU request header
  /// (`7xx` -> `7xx + 0x08`, e.g. `7E4` -> `7EC`, `7E2` -> `7EA`, `744` -> `74C`,
  /// `770` -> `778`, `7A0` -> `7A8`, `7C6` -> `7CE`, `7D1` -> `7D9`, `7B3` -> `7BB`).
  factory ElmCanReceiveFilterConfig.forPhysical11Bit({
    required String requestHeader,
    required BusAddressing addressing,
    String? expectedResponseHeader,
  }) {
    final rx = expectedResponseHeader != null &&
            expectedResponseHeader.trim().isNotEmpty
        ? BusAddressing.normaliseHeader(expectedResponseHeader)
        : ElmPhysicalCanAddressing.responseFor11BitRequest(requestHeader);
    if (rx == null) {
      throw ArgumentError.value(
        requestHeader,
        'requestHeader',
        'does not map to a physical 11-bit CAN response identifier',
      );
    }
    return ElmCanReceiveFilterConfig(address: rx, addressing: addressing);
  }

  static const restoreCommand = 'ATCRA';
  static const maxApplyCommands = 1;
  static const maxRestoreCommands = 1;
  static const maxResponseBytes = 256;
  static const defaultBudget = Duration(seconds: 8);

  final String address;

  String toAtCommand() => 'ATCRA$address';

  @override
  bool operator ==(Object other) =>
      other is ElmCanReceiveFilterConfig && other.address == address;

  @override
  int get hashCode => address.hashCode;
}

/// Clean-room 11-bit CAN physical ECU request/response pairing (`+0x08`).
///
/// Covers standard ISO 15765-4 (`7E0`..`7E7` <-> `7E8`..`7EF`) as well as
/// manufacturer physical 11-bit CAN diagnostic pairs in the `0x700`..`0x7FF`
/// diagnostic window where bit 3 (`0x008`) separates request (`0`) from
/// response (`1`) and `7DF` is reserved for functional broadcast:
/// e.g. `7E4`->`7EC` (BMS), `7E2`->`7EA` (VCU), `744`->`74C` (ICCU/OBC),
/// `770`->`778` (IGPM), `7A0`->`7A8` (BCM/TPMS), `7C6`->`7CE` (CLU),
/// `7D1`->`7D9` (IEB), `7B3`->`7BB` (A/C).
abstract final class ElmPhysicalCanAddressing {
  /// Returns the 11-bit CAN response ID (`request + 0x08`) for a physical
  /// request header in `700`..`7F7` (excluding functional `7DF`), or null.
  static String? responseFor11BitRequest(String? requestHeader) {
    if (requestHeader == null) return null;
    final normalised = BusAddressing.normaliseHeader(requestHeader);
    if (normalised.length != 3 || normalised == '7DF') return null;
    final id = int.tryParse(normalised, radix: 16);
    if (id == null || id < 0x700 || id > 0x7F7) return null;
    if ((id & 0x008) != 0) return null;
    return (id + 0x008).toRadixString(16).toUpperCase().padLeft(3, '0');
  }

  /// Returns the 11-bit CAN physical request ID (`response - 0x08`) for a
  /// response header in `708`..`7FF` (excluding functional `7DF`), or null.
  static String? requestFor11BitResponse(String? responseHeader) {
    if (responseHeader == null) return null;
    final normalised = BusAddressing.normaliseHeader(responseHeader);
    if (normalised.length != 3 || normalised == '7DF') return null;
    final id = int.tryParse(normalised, radix: 16);
    if (id == null || id < 0x708 || id > 0x7FF) return null;
    if ((id & 0x008) == 0) return null;
    final req = id - 0x008;
    if (req == 0x7DF) return null;
    return req.toRadixString(16).toUpperCase().padLeft(3, '0');
  }

  /// Whether [requestHeader] is a physical 11-bit CAN diagnostic request ID.
  static bool isPhysical11BitRequest(String? requestHeader) =>
      responseFor11BitRequest(requestHeader) != null;

  /// Whether [responseHeader] is a physical 11-bit CAN diagnostic response ID.
  static bool isPhysical11BitResponse(String? responseHeader) =>
      requestFor11BitResponse(responseHeader) != null;
}

abstract final class ElmCanReceiveFilterMessages {
  static const unavailable =
      'CAN receive filtering is not available on this ELM327 path.';
  static const restoreFailed =
      'The adapter refused to clear the CAN receive filter (ATCRA), so polling is stopped until you reconnect.';
}

// ---------------------------------------------------------------------------
// shared hex helpers
// ---------------------------------------------------------------------------

void _requireByte(int value, String name) {
  if (value < 0 || value > 255) {
    throw ArgumentError.value(value, name, 'must be in 0..255');
  }
}

String _hexByte(int value) =>
    value.toRadixString(16).toUpperCase().padLeft(2, '0');
