/// Bounded ISO-TP assembler for host-visible (`ATCAF0`) PCI frames.
///
/// Partial, ambiguous, or wrong-source data is unavailable. This never
/// returns a shortened payload for a decoder to consume.
library;

/// Result of ISO-TP reassembly, including whether the payload was recovered
/// from a contiguous prefix of a truncated multi-frame response.
final class IsoTpReassemblyResult {
  const IsoTpReassemblyResult({
    required this.bytes,
    required this.declaredLength,
    required this.isPartialPrefix,
  });

  /// Assembled application PDU bytes.
  final List<int> bytes;

  /// Total application PDU byte length declared by the Single Frame or First Frame.
  final int declaredLength;

  /// True when trailing Consecutive Frames were missing and [bytes] is the
  /// contiguous prefix starting from byte 0.
  final bool isPartialPrefix;
}

/// Reassembles one controller's ISO-TP frames, or returns null.
///
/// PCI high nibbles, ELM327 datasheet p.44-45:
/// `0` Single Frame (length in the low nibble),
/// `1` First Frame (low nibble plus the next byte = 12-bit total),
/// `2` Consecutive Frame (low nibble = sequence),
/// `3` Flow Control (CTS / WAIT / overflow) — never payload.
final class IsoTpAssembler {
  /// ISO 15765-2 twelve-bit length maximum.
  static const int maxPduBytes = 4095;

  /// Whether [frame] is a Single Frame UDS/OBD negative response with NRC `0x78`
  /// (`requestCorrectlyReceived-ResponsePending`, `7F <SID> 78`).
  static bool isResponsePendingSingleFrame(List<int> frame) {
    if (frame.length == 3 && frame[0] == 0x7F && frame[2] == 0x78) {
      return true;
    }
    if (frame.length >= 4 &&
        frame.length <= 8 &&
        frame[0] == 0x03 &&
        frame[1] == 0x7F &&
        frame[3] == 0x78) {
      return true;
    }
    return false;
  }

  /// The service ID a framed or unframed response is about, or null.
  static int? _serviceOfFrame(List<int> body) {
    if (body.isEmpty) return null;
    if (body.length == 3 && body[0] == 0x7F && body[2] == 0x78) {
      return body[1];
    }
    final int payloadStart;
    final int declared;
    switch (body[0] >> 4) {
      case 0x0:
        payloadStart = 1;
        declared = body[0] & 0x0F;
      case 0x1:
        payloadStart = 2;
        declared = ((body[0] & 0x0F) << 8) | (body.length > 1 ? body[1] : 0);
      default:
        return null;
    }
    if (declared == 0 || body.length <= payloadStart) return null;
    final first = body[payloadStart];
    if (first == 0x7F) {
      if (declared < 2) return null;
      return body.length > payloadStart + 1 ? body[payloadStart + 1] : null;
    }
    if (first >= 0x41 && first <= 0x7E) return first - 0x40;
    return null;
  }

  /// Strips intermediate `7F <SID> 78` (`ResponsePending`) Single Frames that
  /// precede a subsequent response frame for the **same service** in the same
  /// buffer.
  ///
  /// A `7F <SID> 78` about a different service is never stripped, preserving
  /// fail-closed detection of contradictory multi-service exchanges.
  static List<List<int>> stripIntermediateResponsePending(
    List<List<int>> raw,
  ) {
    if (raw.length < 2) return raw;
    final out = <List<int>>[];
    for (var i = 0; i < raw.length; i++) {
      final frame = raw[i];
      if (!isResponsePendingSingleFrame(frame)) {
        out.add(frame);
        continue;
      }
      final service = _serviceOfFrame(frame);
      final supersededBySameService =
          service != null &&
          raw.skip(i + 1).any((later) => _serviceOfFrame(later) == service);
      if (!supersededBySameService) {
        out.add(frame);
      }
    }
    return out.isEmpty ? [raw.last] : out;
  }

  /// Single-Frame PCI for an OBD request the host sends after `ATCAF0`.
  ///
  /// Auto-format off applies to transmit as well as receive: a bare `010C`
  /// would go on the bus without a PCI byte. Returns compact uppercase hex,
  /// or null when [command] is not a ≤7-byte hex request (AT commands, odd
  /// nibbles, or a payload that needs First/Consecutive frames).
  static String? frameObdRequest(String command) {
    final upper = command.trim().toUpperCase().replaceAll(' ', '');
    if (upper.isEmpty || upper.startsWith('AT')) return null;
    if (upper.length.isOdd || !RegExp(r'^[0-9A-F]+$').hasMatch(upper)) {
      return null;
    }
    final payload = <int>[];
    for (var i = 0; i < upper.length; i += 2) {
      payload.add(int.parse(upper.substring(i, i + 2), radix: 16));
    }
    if (payload.isEmpty || payload.length > 7) return null;
    final framed = <int>[payload.length & 0x0F, ...payload];
    return framed
        .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
        .join();
  }

  /// Reassemble [raw] PCI frames from one source, returning full metadata.
  ///
  /// When [allowPartialPrefix] is true (or [minPayloadBytes] is non-null),
  /// a valid First Frame followed by contiguous initial Consecutive Frames
  /// (`21`, `22`, ...) whose trailing Consecutive Frames were dropped by a
  /// slow BLE UART bridge returns the contiguous prefix starting at byte 0
  /// (provided at least `minPayloadBytes ?? 1` payload bytes were received).
  static IsoTpReassemblyResult? reassembleWithMetadata(
    List<List<int>> raw, {
    int maxPduBytes = IsoTpAssembler.maxPduBytes,
    bool allowPartialPrefix = false,
    int? minPayloadBytes,
  }) {
    if (raw.isEmpty) return null;
    final filtered = stripIntermediateResponsePending(raw);
    if (filtered.isEmpty) return null;
    final first = filtered.first;
    if (first.isEmpty) return null;
    final cap = maxPduBytes < IsoTpAssembler.maxPduBytes
        ? maxPduBytes
        : IsoTpAssembler.maxPduBytes;
    final recoverPrefix = allowPartialPrefix || minPayloadBytes != null;
    final requiredPrefixBytes = minPayloadBytes ?? 1;

    switch (first[0] >> 4) {
      case 0x0:
        final length = first[0] & 0x0F;
        if (length == 0 || length > 7) return null;
        if (filtered.length != 1) return null;
        if (first.length > 8 || first.length < 1 + length) return null;
        // Some BLE ELM327 v1.5 clones on e-GMP vehicles emit a bogus PCI `03`
        // before a 6-byte J1979 Mode 01 PID 00 support bitmap
        // (`7EA 03 41 00 98 18 00 01`). Because a Mode 01 PID 00 positive
        // response is always 6 bytes (`41 00` + 4 mask bytes) and has non-zero
        // mask bits beyond byte 3, recover the full 6-byte support bitmap.
        if (length == 3 &&
            first.length == 7 &&
            first[1] == 0x41 &&
            first[2] == 0x00 &&
            first.sublist(4, 7).any((b) => b != 0)) {
          final payload = first.sublist(1, 7);
          return IsoTpReassemblyResult(
            bytes: payload,
            declaredLength: 6,
            isPartialPrefix: false,
          );
        }
        final payload = first.sublist(1, 1 + length);
        return IsoTpReassemblyResult(
          bytes: payload,
          declaredLength: length,
          isPartialPrefix: false,
        );

      case 0x1:
        // Classic-CAN First Frames are eight bytes (2-byte PCI + six data).
        // A truncated FF would shift CF padding into the declared PDU.
        if (first.length != 8) return null;
        final total = ((first[0] & 0x0F) << 8) | first[1];
        // A First Frame exists because the payload does not fit in a Single
        // Frame. One declaring seven bytes or fewer is a contradiction.
        if (total <= 7) return null;
        if (total > cap) return null;
        final out = <int>[...first.sublist(2)];
        var expected = 1;
        var stoppedAtGap = false;
        for (final frame in filtered.skip(1)) {
          // Trailing CF after the declared length is corruption, not padding
          // to ignore — refuse rather than silently truncating.
          if (out.length >= total) return null;
          if (frame.isEmpty || frame.length > 8) return null;
          final pci = frame[0] >> 4;
          if (pci == 0x3) return null;
          if (pci != 0x2) return null;
          if ((frame[0] & 0x0F) != (expected & 0x0F)) {
            if (!recoverPrefix) return null;
            stoppedAtGap = true;
            break;
          }
          expected++;
          final data = frame.sublist(1);
          // Classic-CAN ISO-TP: every non-final CF carries seven data bytes.
          // A short intermediate CF would shift later padding into the PDU.
          if (out.length + data.length < total && data.length != 7) {
            if (!recoverPrefix) return null;
            stoppedAtGap = true;
            break;
          }
          out.addAll(data);
        }
        if (out.length < total || stoppedAtGap) {
          if (!recoverPrefix) return null;
          final prefix = out.length > total ? out.sublist(0, total) : out;
          if (prefix.length < requiredPrefixBytes) return null;
          return IsoTpReassemblyResult(
            bytes: prefix,
            declaredLength: total,
            isPartialPrefix: true,
          );
        }
        return IsoTpReassemblyResult(
          bytes: out.sublist(0, total),
          declaredLength: total,
          isPartialPrefix: false,
        );

      case 0x3:
        // WAIT (FS=1), overflow (FS=2), or unexpected CTS: not a PDU.
        return null;

      default:
        return null;
    }
  }

  /// Reassemble [raw] PCI frames from one source.
  ///
  /// [maxPduBytes] is the host bound. A First Frame that declares more than
  /// this, or more than the twelve-bit ISO-TP maximum, is refused.
  static List<int>? reassemble(
    List<List<int>> raw, {
    int maxPduBytes = IsoTpAssembler.maxPduBytes,
    bool allowPartialPrefix = false,
    int? minPayloadBytes,
  }) =>
      reassembleWithMetadata(
        raw,
        maxPduBytes: maxPduBytes,
        allowPartialPrefix: allowPartialPrefix,
        minPayloadBytes: minPayloadBytes,
      )?.bytes;

  /// Reassembles the contiguous prefix of [raw] starting at byte 0 when at
  /// least [minPayloadBytes] bytes were received before a dropped Consecutive
  /// Frame.
  static List<int>? reassemblePrefix(
    List<List<int>> raw, {
    int minPayloadBytes = 1,
    int maxPduBytes = IsoTpAssembler.maxPduBytes,
  }) =>
      reassembleWithMetadata(
        raw,
        maxPduBytes: maxPduBytes,
        allowPartialPrefix: true,
        minPayloadBytes: minPayloadBytes,
      )?.bytes;
}
