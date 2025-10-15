import 'package:flutter/material.dart';

class MathLearningLinearEquationScreen extends StatefulWidget {
  const MathLearningLinearEquationScreen({super.key});

  @override
  State<MathLearningLinearEquationScreen> createState() =>
      _MathLearningLinearEquationScreenState();
}

class _MathLearningLinearEquationScreenState
    extends State<MathLearningLinearEquationScreen> {
  final _aController = TextEditingController();
  final _bController = TextEditingController();
  final _cController = TextEditingController();

  String _result = '';
  String _steps = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Persamaan Linier Satu Variabel'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Apa itu PLSV?', context),
            _buildContentText(
              'Persamaan Linier Satu Variabel (PLSV) adalah kalimat terbuka yang dihubungkan dengan tanda sama dengan (=) dan hanya mempunyai satu variabel berpangkat satu.',
              context,
            ),
            const SizedBox(height: 10),
            _buildContentText(
              'Bentuk umumnya adalah:',
              context,
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'ax + b = c',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontFamily: 'monospace', letterSpacing: 2),
                ),
              ),
            ),
            _buildContentText(
              'Di mana:\n'
              '• x adalah variabel (nilai yang dicari).\n'
              '• a adalah koefisien dari x (tidak boleh 0).\n'
              '• b dan c adalah konstanta (angka tetap).',
              context,
            ),
            const Divider(height: 30),
            _buildSectionTitle('Contoh Penyelesaian', context),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Soal: 2x - 4 = 10', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    _buildContentText(
                      'Tujuan kita adalah menemukan nilai x.\n\n'
                      '1. Pindahkan konstanta (-4) ke sisi kanan. Ingat, tandanya berubah menjadi positif.\n'
                      '   2x = 10 + 4\n'
                      '   2x = 14\n\n'
                      '2. Bagi kedua sisi dengan koefisien dari x (yaitu 2) untuk mendapatkan nilai x.\n'
                      '   x = 14 / 2\n\n'
                      'Jadi, nilai x adalah 7.',
                      context,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 30),
            _buildSectionTitle('Kalkulator PLSV', context),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Masukkan nilai untuk ax + b = c',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    _buildInputFields(),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: _calculate,
                        child: const Text('Hitung Nilai x'),
                      ),
                    ),
                    if (_result.isNotEmpty) ...[
                      const Divider(height: 30),
                      Text('Langkah Penyelesaian:',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Text(_steps, style: const TextStyle(fontFamily: 'monospace')),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          _result,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _calculate() {
    final a = double.tryParse(_aController.text);
    final b = double.tryParse(_bController.text);
    final c = double.tryParse(_cController.text);

    if (a == null || b == null || c == null) {
      setState(() {
        _steps = 'Pastikan semua kolom (a, b, dan c) terisi angka.';
        _result = 'Input tidak valid';
      });
      return;
    }

    if (a == 0) {
      setState(() {
        _steps = 'Koefisien "a" tidak boleh nol untuk PLSV.';
        _result = 'Error';
      });
      return;
    }

    final x = (c - b) / a;

    setState(() {
      _steps = '1. Pindahkan b ke kanan:\n   ${a}x = $c - ($b)\n   ${a}x = ${c - b}\n\n'
          '2. Bagi dengan a:\n   x = ${c - b} / $a';
      _result = 'x = ${x.toStringAsFixed(2)}';
    });
  }

  Widget _buildInputFields() {
    return Row(
      children: [
        Expanded(
            child: TextField(
                controller: _aController,
                decoration: const InputDecoration(labelText: 'a'),
                keyboardType: TextInputType.number)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text('x +'),
        ),
        Expanded(
            child: TextField(
                controller: _bController,
                decoration: const InputDecoration(labelText: 'b'),
                keyboardType: TextInputType.number)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text('= '),
        ),
        Expanded(
            child: TextField(
                controller: _cController,
                decoration: const InputDecoration(labelText: 'c'),
                keyboardType: TextInputType.number)),
      ],
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      );

  Widget _buildContentText(String text, BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.bodyMedium);

  @override
  void dispose() {
    _aController.dispose();
    _bController.dispose();
    _cController.dispose();
    super.dispose();
  }
}