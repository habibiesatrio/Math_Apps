import 'package:flutter/material.dart';

class MeanMedianModeScreen extends StatefulWidget {
  const MeanMedianModeScreen({super.key});

  @override
  State<MeanMedianModeScreen> createState() => _MeanMedianModeScreenState();
}

class _MeanMedianModeScreenState extends State<MeanMedianModeScreen> {
  final _numbersController = TextEditingController();
  String _meanResult = '-';
  String _medianResult = '-';
  String _modeResult = '-';

  void _calculate() {
    final inputText = _numbersController.text;
    if (inputText.isEmpty) return;

    // Konversi input string (e.g., "5, 2, 8, 2") menjadi List<double>
    final numbers = inputText
        .split(',')
        .map((e) => double.tryParse(e.trim()))
        .where((n) => n != null)
        .cast<double>()
        .toList();

    if (numbers.isEmpty) return;

    // --- Perhitungan ---
    // Mean
    final mean = numbers.reduce((a, b) => a + b) / numbers.length;

    // Median
    numbers.sort();
    double median;
    int middle = numbers.length ~/ 2;
    if (numbers.length % 2 == 1) {
      median = numbers[middle];
    } else {
      median = (numbers[middle - 1] + numbers[middle]) / 2;
    }

    // Modus
    var frequencyMap = <double, int>{};
    for (var n in numbers) {
      frequencyMap[n] = (frequencyMap[n] ?? 0) + 1;
    }
    int maxFreq = 0;
    List<double> modes = [];
    frequencyMap.forEach((num, freq) {
      if (freq > maxFreq) {
        maxFreq = freq;
        modes = [num];
      } else if (freq == maxFreq) {
        modes.add(num);
      }
    });
    // Jika semua angka muncul sama seringnya, tidak ada modus
    if (modes.length == numbers.length && numbers.length > 1) modes = [];

    setState(() {
      _meanResult = mean.toStringAsFixed(2);
      _medianResult = median.toStringAsFixed(2);
      _modeResult = modes.isEmpty ? 'Tidak ada' : modes.map((d) => d.toStringAsFixed(0)).join(', ');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mean, Median, Modus'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Apa itu Mean, Median, dan Modus?'),
            _buildContentText(
                'Ini adalah tiga jenis "rata-rata" yang paling umum dalam statistika.\n\n'
                '• Mean adalah rata-rata aritmatika.\n'
                '• Median adalah nilai tengah dari kumpulan data yang diurutkan.\n'
                '• Modus adalah nilai yang paling sering muncul.'),
            const Divider(height: 30),
            _buildSectionTitle('Kalkulator Praktis'),
            Text(
              'Masukkan angka-angka dipisahkan dengan koma (contoh: 90, 85, 70, 85, 100)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _numbersController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Data Angka',
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _calculate,
                child: const Text('Hitung'),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Hasil:'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildResultRow('Mean (Rata-rata)', _meanResult),
                    _buildResultRow('Median (Nilai Tengah)', _medianResult),
                    _buildResultRow('Modus (Paling Sering Muncul)', _modeResult),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      );

  Widget _buildContentText(String text) => Text(text, style: Theme.of(context).textTheme.bodyMedium);

  Widget _buildResultRow(String title, String result) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 16)),
            Text(result, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      );
}