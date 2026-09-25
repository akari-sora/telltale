/// Typed Negative Response Codes (NRC) for Unified Diagnostic Services (ISO 14229-1).
///
/// Ref: Issue #13 ([WS-09][P1]), ISO 14229-1:2020.
///
/// SAFETY CONTRACT:
/// - NRC 0x21 (busyRepeatRequest) and NRC 0x78 (responsePending) are represented
///   as typed status values only; Slice 1 performs no retry/resend.
/// - Unknown NRCs are preserved as raw codes with `isKnown == false`, and never
///   coerced to success, zero, or unsupported.
library;

/// Negative Response Code representation for ISO 14229-1 UDS.
final class UdsNrc {
  const UdsNrc._({
    required this.code,
    required this.name,
    required this.isKnown,
  });

  /// The raw 8-bit NRC value.
  final int code;

  /// The normative ISO 14229-1 name or a formatted unknown label.
  final String name;

  /// Whether this NRC is defined in the ISO 14229-1 standard dictionary.
  final bool isKnown;

  /// Whether this NRC is 0x78 (responsePending), signaling that the server has
  /// received the request correctly but needs more time to complete processing.
  bool get isResponsePending => code == 0x78;

  /// Whether this NRC is 0x21 (busyRepeatRequest), signaling that the server is
  /// temporarily busy and the client may repeat the request under an allowable budget.
  bool get isBusyRepeatRequest => code == 0x21;

  /// Whether this NRC is 0x22 (conditionsNotCorrect).
  bool get isConditionsNotCorrect => code == 0x22;

  /// Whether this NRC is 0x31 (requestOutOfRange).
  bool get isRequestOutOfRange => code == 0x31;

  /// Whether this NRC is 0x33 (securityAccessDenied).
  bool get isSecurityAccessDenied => code == 0x33;

  /// Whether this NRC is 0x11 (serviceNotSupported).
  bool get isServiceNotSupported => code == 0x11;

  /// Whether this NRC is 0x12 (subFunctionNotSupported).
  bool get isSubFunctionNotSupported => code == 0x12;

  /// Whether this NRC is 0x13 (incorrectMessageLengthOrInvalidFormat).
  bool get isIncorrectMessageLengthOrInvalidFormat => code == 0x13;

  /// Whether this NRC represents a terminal negative state (not pending or busy).
  bool get isTerminal => !isResponsePending && !isBusyRepeatRequest;

  /// Canonical two-digit uppercase hex representation (e.g., "0x31").
  String toHex() =>
      '0x${code.toRadixString(16).padLeft(2, '0').toUpperCase()}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is UdsNrc && other.code == code);

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => '$name (${toHex()})';

  // ---------------------------------------------------------------------------
  // Standard Factory & Registry
  // ---------------------------------------------------------------------------

  /// Look up or construct a typed [UdsNrc] from an 8-bit integer [code].
  factory UdsNrc.fromCode(int code) {
    if (code < 0 || code > 0xFF) {
      throw ArgumentError.value(
        code,
        'code',
        'NRC code must be an 8-bit byte (0x00..0xFF)',
      );
    }
    final known = _knownNrcs[code];
    if (known != null) return known;
    return UdsNrc._(
      code: code,
      name:
          'unknownNRC_0x${code.toRadixString(16).padLeft(2, '0').toUpperCase()}',
      isKnown: false,
    );
  }

  // Predefined standard NRC constants
  static const generalReject =
      UdsNrc._(code: 0x10, name: 'generalReject', isKnown: true);
  static const serviceNotSupported =
      UdsNrc._(code: 0x11, name: 'serviceNotSupported', isKnown: true);
  static const subFunctionNotSupported =
      UdsNrc._(code: 0x12, name: 'subFunctionNotSupported', isKnown: true);
  static const incorrectMessageLengthOrInvalidFormat = UdsNrc._(
    code: 0x13,
    name: 'incorrectMessageLengthOrInvalidFormat',
    isKnown: true,
  );
  static const responseTooLong =
      UdsNrc._(code: 0x14, name: 'responseTooLong', isKnown: true);
  static const busyRepeatRequest =
      UdsNrc._(code: 0x21, name: 'busyRepeatRequest', isKnown: true);
  static const conditionsNotCorrect =
      UdsNrc._(code: 0x22, name: 'conditionsNotCorrect', isKnown: true);
  static const requestSequenceError =
      UdsNrc._(code: 0x24, name: 'requestSequenceError', isKnown: true);
  static const noResponseFromSubnetComponent =
      UdsNrc._(code: 0x25, name: 'noResponseFromSubnetComponent', isKnown: true);
  static const failurePreventsExecutionOfRequestedAction = UdsNrc._(
    code: 0x26,
    name: 'failurePreventsExecutionOfRequestedAction',
    isKnown: true,
  );
  static const requestOutOfRange =
      UdsNrc._(code: 0x31, name: 'requestOutOfRange', isKnown: true);
  static const securityAccessDenied =
      UdsNrc._(code: 0x33, name: 'securityAccessDenied', isKnown: true);
  static const authenticationRequired =
      UdsNrc._(code: 0x34, name: 'authenticationRequired', isKnown: true);
  static const invalidKey =
      UdsNrc._(code: 0x35, name: 'invalidKey', isKnown: true);
  static const exceedNumberOfAttempts =
      UdsNrc._(code: 0x36, name: 'exceedNumberOfAttempts', isKnown: true);
  static const requiredTimeDelayNotExpired =
      UdsNrc._(code: 0x37, name: 'requiredTimeDelayNotExpired', isKnown: true);
  static const secureDataVerificationFailed =
      UdsNrc._(code: 0x38, name: 'secureDataVerificationFailed', isKnown: true);
  static const uploadDownloadNotAccepted =
      UdsNrc._(code: 0x70, name: 'uploadDownloadNotAccepted', isKnown: true);
  static const transferDataSuspended =
      UdsNrc._(code: 0x71, name: 'transferDataSuspended', isKnown: true);
  static const generalProgrammingFailure =
      UdsNrc._(code: 0x72, name: 'generalProgrammingFailure', isKnown: true);
  static const wrongBlockSequenceCounter =
      UdsNrc._(code: 0x73, name: 'wrongBlockSequenceCounter', isKnown: true);
  static const requestCorrectlyReceivedResponsePending =
      UdsNrc._(code: 0x78, name: 'responsePending', isKnown: true);
  static const subFunctionNotSupportedInActiveSession = UdsNrc._(
    code: 0x7E,
    name: 'subFunctionNotSupportedInActiveSession',
    isKnown: true,
  );
  static const serviceNotSupportedInActiveSession = UdsNrc._(
    code: 0x7F,
    name: 'serviceNotSupportedInActiveSession',
    isKnown: true,
  );
  static const rpmTooHigh =
      UdsNrc._(code: 0x81, name: 'rpmTooHigh', isKnown: true);
  static const rpmTooLow =
      UdsNrc._(code: 0x82, name: 'rpmTooLow', isKnown: true);
  static const engineIsRunning =
      UdsNrc._(code: 0x83, name: 'engineIsRunning', isKnown: true);
  static const engineIsNotRunning =
      UdsNrc._(code: 0x84, name: 'engineIsNotRunning', isKnown: true);
  static const engineRunTimeTooLow =
      UdsNrc._(code: 0x85, name: 'engineRunTimeTooLow', isKnown: true);
  static const temperatureTooHigh =
      UdsNrc._(code: 0x86, name: 'temperatureTooHigh', isKnown: true);
  static const temperatureTooLow =
      UdsNrc._(code: 0x87, name: 'temperatureTooLow', isKnown: true);
  static const vehicleSpeedTooHigh =
      UdsNrc._(code: 0x88, name: 'vehicleSpeedTooHigh', isKnown: true);
  static const vehicleSpeedTooLow =
      UdsNrc._(code: 0x89, name: 'vehicleSpeedTooLow', isKnown: true);
  static const throttlePedalTooHigh =
      UdsNrc._(code: 0x8A, name: 'throttlePedalTooHigh', isKnown: true);
  static const throttlePedalTooLow =
      UdsNrc._(code: 0x8B, name: 'throttlePedalTooLow', isKnown: true);
  static const transmissionRangeNotInNeutral = UdsNrc._(
    code: 0x8C,
    name: 'transmissionRangeNotInNeutral',
    isKnown: true,
  );
  static const transmissionRangeNotInGear = UdsNrc._(
    code: 0x8D,
    name: 'transmissionRangeNotInGear',
    isKnown: true,
  );
  static const brakeSwitchNotClosed =
      UdsNrc._(code: 0x8F, name: 'brakeSwitchNotClosed', isKnown: true);
  static const shifterLeverNotInPark =
      UdsNrc._(code: 0x90, name: 'shifterLeverNotInPark', isKnown: true);
  static const torqueConverterClutchLocked =
      UdsNrc._(code: 0x91, name: 'torqueConverterClutchLocked', isKnown: true);
  static const voltageTooHigh =
      UdsNrc._(code: 0x92, name: 'voltageTooHigh', isKnown: true);
  static const voltageTooLow =
      UdsNrc._(code: 0x93, name: 'voltageTooLow', isKnown: true);

  static final Map<int, UdsNrc> _knownNrcs = {
    0x10: generalReject,
    0x11: serviceNotSupported,
    0x12: subFunctionNotSupported,
    0x13: incorrectMessageLengthOrInvalidFormat,
    0x14: responseTooLong,
    0x21: busyRepeatRequest,
    0x22: conditionsNotCorrect,
    0x24: requestSequenceError,
    0x25: noResponseFromSubnetComponent,
    0x26: failurePreventsExecutionOfRequestedAction,
    0x31: requestOutOfRange,
    0x33: securityAccessDenied,
    0x34: authenticationRequired,
    0x35: invalidKey,
    0x36: exceedNumberOfAttempts,
    0x37: requiredTimeDelayNotExpired,
    0x38: secureDataVerificationFailed,
    0x70: uploadDownloadNotAccepted,
    0x71: transferDataSuspended,
    0x72: generalProgrammingFailure,
    0x73: wrongBlockSequenceCounter,
    0x78: requestCorrectlyReceivedResponsePending,
    0x7E: subFunctionNotSupportedInActiveSession,
    0x7F: serviceNotSupportedInActiveSession,
    0x81: rpmTooHigh,
    0x82: rpmTooLow,
    0x83: engineIsRunning,
    0x84: engineIsNotRunning,
    0x85: engineRunTimeTooLow,
    0x86: temperatureTooHigh,
    0x87: temperatureTooLow,
    0x88: vehicleSpeedTooHigh,
    0x89: vehicleSpeedTooLow,
    0x8A: throttlePedalTooHigh,
    0x8B: throttlePedalTooLow,
    0x8C: transmissionRangeNotInNeutral,
    0x8D: transmissionRangeNotInGear,
    0x8F: brakeSwitchNotClosed,
    0x90: shifterLeverNotInPark,
    0x91: torqueConverterClutchLocked,
    0x92: voltageTooHigh,
    0x93: voltageTooLow,
  };
}
