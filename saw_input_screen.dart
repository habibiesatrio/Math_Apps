import 'package:flutter/material.dart';
import '../models/criteria_model.dart'; // Assuming models are in lib/models
import '../models/alternative_model.dart'; // Assuming models are in lib/models
// Mengimpor halaman hasil dan service yang dibutuhkan
import 'saw_result_screen.dart'; // Assuming this file is in the same directory
import '../services/saw_service.dart'; // Assuming services are in lib/services

class SawInputScreen extends StatefulWidget {
  const SawInputScreen({super.key});

  @override
  State<SawInputScreen> createState() => _SawInputScreenState();
}

class _SawInputScreenState extends State<SawInputScreen> {
  final List<Criteria> _criteria = [];
  final List<Alternative> _alternatives = [];

  // Controller untuk menambah kriteria baru
  final _criteriaNameController = TextEditingController();
  final _criteriaWeightController = TextEditingController();
  CriteriaType _selectedCriteriaType = CriteriaType.benefit;

  // Controller untuk menambah alternatif baru
  final _alternativeNameController = TextEditingController();

  // Controller untuk nilai-nilai matriks
  // Key: 'alternativeName-criteriaId'
  final Map<String, TextEditingController> _valueControllers = {};

  void _addCriteria() {
    final name = _criteriaNameController.text;
    final weight = double.tryParse(_criteriaWeightController.text) ?? 0.0;

    if (name.isNotEmpty && weight > 0) {
      setState(() {
        final newCriteria = Criteria(
          id: 'C${_criteria.length + 1}',
          name: name,
          weight: weight,
          type: _selectedCriteriaType,
        );
        _criteria.add(newCriteria);
      });
      _criteriaNameController.clear();
      _criteriaWeightController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  void _addAlternative() {
    final name = _alternativeNameController.text;
    if (name.isNotEmpty) {
      setState(() {
        // Inisialisasi nilai awal untuk alternatif baru
        final initialValues = <String, double>{};
        for (var crit in _criteria) {
          initialValues[crit.id] = 0.0;
          _valueControllers['$name-${crit.id}'] = TextEditingController();
        }
        _alternatives.add(Alternative(name: name, values: initialValues));
      });
      _alternativeNameController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  void _calculate() {
    // 1. Update nilai alternatif dari text controllers
    final updatedAlternatives = <Alternative>[];
    for (var alt in _alternatives) {
      final newValues = <String, double>{};
      for (var crit in _criteria) {
        final controller = _valueControllers['${alt.name}-${crit.id}'];
        newValues[crit.id] = double.tryParse(controller?.text ?? '0.0') ?? 0.0;
      }
      updatedAlternatives.add(Alternative(name: alt.name, values: newValues));
    }

    // 2. Panggil service SAW untuk perhitungan
    final sawService = SawService();
    final results = sawService.calculate(updatedAlternatives, _criteria);

    // 3. Navigasi ke halaman hasil
    // Mengganti dialog placeholder dengan navigasi sesungguhnya.
    // Pastikan context masih valid sebelum melakukan navigasi.
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SawResultScreen(results: results),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Data SAW'),
        backgroundColor: Colors.blueGrey,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Form Input Kriteria ---
            _buildSectionTitle('1. Tambah Kriteria'),
            TextField(
              controller: _criteriaNameController,
              decoration: const InputDecoration(labelText: 'Nama Kriteria (e.g., Harga)'),
            ),
            TextField(
              controller: _criteriaWeightController,
              decoration: const InputDecoration(labelText: 'Bobot (e.g., 0.25)'),
              keyboardType: TextInputType.number,
            ),
            DropdownButton<CriteriaType>(
              value: _selectedCriteriaType,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: CriteriaType.benefit, child: Text('Benefit (Makin besar makin baik)')),
                DropdownMenuItem(value: CriteriaType.cost, child: Text('Cost (Makin kecil makin baik)')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCriteriaType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _addCriteria, child: const Text('Tambah Kriteria')),
            // --- Display Total Weight ---
            if (_criteria.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Total Bobot Saat Ini: ${_criteria.fold(0.0, (sum, item) => sum + item.weight).toStringAsFixed(2)}',
                  style: TextStyle(color: Theme.of(context).hintColor),
                ),
              ),
            const Divider(height: 30),

            // --- Form Input Alternatif ---
            _buildSectionTitle('2. Tambah Alternatif'),
            TextField(
              controller: _alternativeNameController,
              decoration: const InputDecoration(labelText: 'Nama Alternatif (e.g., Siswa A)'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _addAlternative, child: const Text('Tambah Alternatif')),
            const Divider(height: 30),

            // --- Tabel Input Nilai ---
            _buildSectionTitle('3. Input Nilai'),
            if (_criteria.isNotEmpty && _alternatives.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    const DataColumn(label: Text('Alternatif')),
                    ..._criteria.map((c) => DataColumn(label: Text('${c.name}\n(${c.id})'))),
                  ],
                  rows: _alternatives.map((alt) {
                    return DataRow(cells: [
                      DataCell(Text(alt.name)),
                      ..._criteria.map((crit) {
                        return DataCell(
                          SizedBox(
                            width: 80,
                            child: TextField(
                              controller: _valueControllers['${alt.name}-${crit.id}'],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        );
                      }),
                    ]);
                  }).toList(),
                ),
              ),
            const SizedBox(height: 30),

            // --- Tombol Hitung ---
            ElevatedButton(
              onPressed: (_criteria.isNotEmpty && _alternatives.isNotEmpty) ? _calculate : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Hitung & Lihat Hasil', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  void dispose() {
    _criteriaNameController.dispose();
    _criteriaWeightController.dispose();
    _alternativeNameController.dispose();
    _valueControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }
}