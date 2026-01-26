import 'dart:math';
import 'package:flutter/material.dart';
import 'firebase_service.dart';
import 'app_state.dart';

class MathLearningLinearEquationScreen extends StatefulWidget {
  const MathLearningLinearEquationScreen({super.key});

  @override
  State<MathLearningLinearEquationScreen> createState() =>
      _MathLearningLinearEquationScreenState();
}

class _MathLearningLinearEquationScreenState
    extends State<MathLearningLinearEquationScreen> {
  // Services and State
  final FirebaseService _firebaseService = FirebaseService();
  final AppState _appState = AppState();
  final _userNameController = TextEditingController();

  // State for Calculator
  final _aController = TextEditingController();
  final _bController = TextEditingController();
  final _cController = TextEditingController();
  String _result = '';
  String _steps = '';

  // State for Quiz
  final _quizAnswerController = TextEditingController();
  String _quizQuestion = '-';
  int _correctQuizAnswer = 0;
  String _quizFeedback = '';
  bool _isQuizActive = false;

  @override
  void dispose() {
    _aController.dispose();
    _bController.dispose();
    _cController.dispose();
    _quizAnswerController.dispose();
    _userNameController.dispose();
    super.dispose();
  }

  // --- LOGIC ---
  Future<void> _checkQuizAnswer() async {
    if (_appState.userName.isEmpty) {
      await _promptForUserName();
      if (_appState.userName.isEmpty) return;
    }

    final userAnswer = int.tryParse(_quizAnswerController.text.trim());
    bool isCorrect = userAnswer == _correctQuizAnswer;

    if (isCorrect) {
      setState(() {
        _quizFeedback =
            'Benar! Nilai x adalah $_correctQuizAnswer. Poin ditambahkan!';
      });
      await _firebaseService.updateUserScore(_appState.userName, 'PLSV');
    } else {
      setState(() {
        _quizFeedback =
            'Salah. Jawaban yang benar adalah $_correctQuizAnswer. Coba lagi!';
      });
    }
  }

  Future<void> _promptForUserName() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Masukkan Nama Anda'),
          content: TextField(
            controller: _userNameController,
            decoration: const InputDecoration(
              hintText: "Nama untuk papan peringkat",
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Simpan'),
              onPressed: () {
                if (_userNameController.text.trim().isNotEmpty) {
                  _appState.userName = _userNameController.text.trim();
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _calculateCalculator() {
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
      _steps =
          '1. Pindahkan b ke kanan:\n   ${a}x = $c - ($b)\n   ${a}x = ${c - b}\n\n'
          '2. Bagi dengan a:\n   x = ${c - b} / $a';
      _result = 'x = ${x.toStringAsFixed(2)}';
    });
  }

  void _generateQuizQuestion() {
    final random = Random();
    int a = random.nextInt(8) + 2;
    int x = random.nextInt(10) + 1;
    int b = random.nextInt(20) - 10;
    int c = a * x + b;
    String bSign = b < 0 ? '-' : '+';
    int bAbs = b.abs();

    setState(() {
      // FIX: Changed '$a\x' to '${a}x' to avoid escape sequence error.
      _quizQuestion = '${a}x $bSign $bAbs = $c';
      _correctQuizAnswer = x;
      _isQuizActive = true;
      _quizFeedback = '';
      _quizAnswerController.clear();
    });
  }

  // --- UI WIDGETS ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Persamaan Linier Satu Variabel'),
        backgroundColor: Colors.pink.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStaticContent(context),
            const Divider(height: 30, thickness: 2),
            _buildCalculatorSection(context),
            const Divider(height: 30, thickness: 2),
            _buildQuizSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Apa itu PLSV?', context),
        _buildContentText(
          'Persamaan Linier Satu Variabel (PLSV) adalah kalimat terbuka yang dihubungkan dengan tanda sama dengan (=) dan hanya mempunyai satu variabel berpangkat satu. Bentuk umumnya adalah ax + b = c.',
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
                Text(
                  'Soal: 2x - 4 = 10',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _buildContentText(
                  '1. Pindahkan konstanta (-4) ke sisi kanan (tanda berubah menjadi +).\n'
                  '   2x = 10 + 4  =>  2x = 14\n\n'
                  '2. Bagi kedua sisi dengan koefisien dari x (yaitu 2).\n'
                  '   x = 14 / 2  =>  x = 7',
                  context,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalculatorSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Kalkulator PLSV', context),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Masukkan nilai untuk ax + b = c',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                _buildInputFields(),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: _calculateCalculator,
                    child: const Text('Hitung Nilai x'),
                  ),
                ),
                if (_result.isNotEmpty) ...[
                  const Divider(height: 30),
                  Text(
                    'Langkah Penyelesaian:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _steps,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      _result,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuizSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Latihan Soal', context),
        Center(
          child: ElevatedButton(
            onPressed: _generateQuizQuestion,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Buat Soal Acak'),
          ),
        ),
        if (_isQuizActive)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Carilah nilai x dari persamaan:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _quizQuestion,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 150,
                      child: TextField(
                        controller: _quizAnswerController,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Jawaban x',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _checkQuizAnswer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Periksa Jawaban'),
                    ),
                    if (_quizFeedback.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Text(
                          _quizFeedback,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: _quizFeedback.startsWith('Benar')
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInputFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: TextField(
            controller: _aController,
            decoration: const InputDecoration(labelText: 'a'),
            keyboardType: TextInputType.number,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text('x  +'),
        ),
        Expanded(
          child: TextField(
            controller: _bController,
            decoration: const InputDecoration(labelText: 'b'),
            keyboardType: TextInputType.number,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text('= '),
        ),
        Expanded(
          child: TextField(
            controller: _cController,
            decoration: const InputDecoration(labelText: 'c'),
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
    child: Text(title, style: Theme.of(context).textTheme.titleLarge),
  );

  Widget _buildContentText(String text, BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.bodyMedium);
}
