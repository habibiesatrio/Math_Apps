// models/alternative_model.dart
class Alternative {
  final String name;
  // Peta untuk menyimpan nilai kriteria, misal: {'C1': 80, 'C2': 90}
  final Map<String, double> values;
  double? score; // Skor akhir setelah perhitungan SAW

  Alternative({required this.name, required this.values, this.score});
}