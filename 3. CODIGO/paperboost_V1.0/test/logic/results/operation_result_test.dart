import 'package:flutter_test/flutter_test.dart';
import 'package:paperboost/logic/results/operation_result.dart';

void main() {
  group('OperationResult', () {
    group('success', () {
      test('crea resultado exitoso con mensaje y datos', () {
        final result = OperationResult<int>.success(
          message: 'Operación exitosa',
          data: 42,
        );
        expect(result.isSuccess, true);
        expect(result.message, 'Operación exitosa');
        expect(result.data, 42);
      });

      test('crea resultado exitoso con null data', () {
        final result = OperationResult<Object?>.success(
          message: 'Sin datos',
        );
        expect(result.isSuccess, true);
        expect(result.data, isNull);
      });
    });

    group('failure', () {
      test('crea resultado fallido con mensaje', () {
        final result = OperationResult<String>.failure(
          message: 'Error ocurrido',
        );
        expect(result.isSuccess, false);
        expect(result.message, 'Error ocurrido');
        expect(result.data, isNull);
      });
    });

    test('success y failure tienen valores opuestos', () {
      final success = OperationResult<int>.success(
        message: 'OK',
        data: 1,
      );
      final failure = OperationResult<int>.failure(
        message: 'Error',
      );
      expect(success.isSuccess, isNot(failure.isSuccess));
    });
  });
}
