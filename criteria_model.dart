// models/criteria_model.dart
enum CriteriaType { benefit, cost }

class Criteria {
  final String id; // misal: 'C1', 'C2'
  final String name;
  final double weight;
  final CriteriaType type;

  Criteria(
      {required this.id,
      required this.name,
      required this.weight,
      required this.type});
}