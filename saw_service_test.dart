import 'package:flutter_test/flutter_test.dart';
import 'package:math_apps/models/alternative_model.dart';
import 'package:math_apps/models/criteria_model.dart';
import 'package:math_apps/services/saw_service.dart';

void main() {
  group('SawService', () {
    late SawService sawService;

    setUp(() {
      sawService = SawService();
    });

    test('should return an empty list if alternatives are empty', () {
      // Arrange
      final criteria = [
        Criteria(id: 'C1', name: 'K1', weight: 1.0, type: CriteriaType.benefit)
      ];
      // Act
      final result = sawService.calculate([], criteria);
      // Assert
      expect(result, isEmpty);
    });

    test('should return an empty list if criteria are empty', () {
      // Arrange
      final alternatives = [
        Alternative(name: 'A1', values: {'C1': 100})
      ];
      // Act
      final result = sawService.calculate(alternatives, []);
      // Assert
      expect(result, isEmpty);
    });

    test('should correctly rank alternatives with benefit and cost criteria',
        () {
      // Arrange
      final criteria = [
        Criteria(id: 'C1', name: 'Kualitas', weight: 0.5, type: CriteriaType.benefit),
        Criteria(id: 'C2', name: 'Harga', weight: 0.3, type: CriteriaType.cost),
        Criteria(id: 'C3', name: 'Fitur', weight: 0.2, type: CriteriaType.benefit),
      ];

      final alternatives = [
        Alternative(name: 'Produk A', values: {'C1': 80, 'C2': 200, 'C3': 90}), // Lower score
        Alternative(name: 'Produk B', values: {'C1': 90, 'C2': 100, 'C3': 80}), // Higher score
      ];

      // Act
      final result = sawService.calculate(alternatives, criteria);

      // Assert
      expect(result.length, 2);

      // Check ranking order
      expect(result[0].name, 'Produk B');
      expect(result[1].name, 'Produk A');

      // Manual Calculation Verification:
      // Max C1: 90, Min C2: 100, Max C3: 90
      // Produk A Norm: C1=80/90=0.889, C2=100/200=0.5, C3=90/90=1.0
      // Produk A Score: (0.889 * 0.5) + (0.5 * 0.3) + (1.0 * 0.2) = 0.4445 + 0.15 + 0.2 = 0.7945
      // Produk B Norm: C1=90/90=1.0, C2=100/100=1.0, C3=80/90=0.889
      // Produk B Score: (1.0 * 0.5) + (1.0 * 0.3) + (0.889 * 0.2) = 0.5 + 0.3 + 0.1778 = 0.9778
      expect(result[0].score, closeTo(0.977, 0.001)); // Produk B
      expect(result[1].score, closeTo(0.794, 0.001)); // Produk A
    });

    test('should handle division by zero for benefit criteria gracefully', () {
      // Arrange
      final criteria = [
        Criteria(id: 'C1', name: 'K1', weight: 1.0, type: CriteriaType.benefit)
      ];
      final alternatives = [
        Alternative(name: 'A1', values: {'C1': 0}),
        Alternative(name: 'A2', values: {'C1': 0}),
      ];

      // Act
      final result = sawService.calculate(alternatives, criteria);

      // Assert
      // With the fix, the score should be 0, not NaN.
      expect(result[0].score, 0);
      expect(result[1].score, 0);
    });

    test('should handle division by zero for cost criteria gracefully', () {
      // Arrange
      final criteria = [
        Criteria(id: 'C1', name: 'K1', weight: 1.0, type: CriteriaType.cost)
      ];
      final alternatives = [
        Alternative(name: 'A1', values: {'C1': 10}),
        Alternative(name: 'A2', values: {'C1': 0}), // This will cause division by zero
      ];

      // Act
      final result = sawService.calculate(alternatives, criteria);

      // Assert
      // With the fix, the score for A2 should be 0.
      expect(result.firstWhere((alt) => alt.name == 'A1').score, 1.0);
      expect(result.firstWhere((alt) => alt.name == 'A2').score, 0);
    });
  });
}