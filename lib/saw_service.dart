// services/saw_service.dart
import 'dart:math';
import './alternative_model.dart';
import './criteria_model.dart';

class SawService {
  List<Alternative> calculate(
      List<Alternative> alternatives, List<Criteria> criteria) {
    if (alternatives.isEmpty || criteria.isEmpty) {
      return [];
    }

    // 1. Normalisasi Matriks
    final normalizedMatrix = <String, List<double>>{};

    for (var crit in criteria) {
      List<double> columnValues =
          alternatives.map((alt) => alt.values[crit.id]!).toList();

      if (crit.type == CriteriaType.benefit) {
        double maxValue = columnValues.reduce(max);
        // Handle division by zero if max value is 0
        normalizedMatrix[crit.id] = columnValues.map((val) => maxValue == 0 ? 0.0 : val / maxValue).toList();
      } else {
        // CriteriaType.cost
        double minValue = columnValues.reduce(min);
        // Handle division by zero if a value is 0
        normalizedMatrix[crit.id] = columnValues.map((val) => val == 0 ? 0.0 : minValue / val).toList();
      }
    }

    // 2. Perkalian Bobot & 3. Penjumlahan Nilai Preferensi
    List<Alternative> rankedAlternatives = [];
    for (int i = 0; i < alternatives.length; i++) {
      double totalScore = 0;
      for (var crit in criteria) {
        double normalizedValue = normalizedMatrix[crit.id]![i];
        totalScore += normalizedValue * crit.weight;
      }
      rankedAlternatives.add(Alternative(
          name: alternatives[i].name,
          values: alternatives[i].values,
          score: totalScore));
    }

    // Lakukan Perankingan (sorting dari skor tertinggi ke terendah)
    rankedAlternatives.sort((a, b) => b.score!.compareTo(a.score!));

    return rankedAlternatives;
  }
}