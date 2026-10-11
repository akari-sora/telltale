import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/car/car_projection_session_runtime.dart';
import 'package:torque_obd/car/generated/car_projection_session.g.dart';

void main() {
  CarProjectionLeaseMessage lease(bool active, int generation, bool armed) =>
      CarProjectionLeaseMessage(
        active: active,
        generation: generation,
        armed: armed,
        connectionGeneration: armed ? 4 : null,
      );

  test('late armed callbacks cannot revive a released generation', () {
    final order = CarProjectionLeaseOrder();

    expect(order.admit(lease(true, 8, true)), isTrue);
    expect(order.admit(lease(false, 8, false)), isTrue);
    expect(order.admit(lease(true, 8, true)), isFalse);
    expect(order.admit(lease(true, 9, false)), isTrue);
    expect(order.admit(lease(false, 8, false)), isFalse);
  });
}
