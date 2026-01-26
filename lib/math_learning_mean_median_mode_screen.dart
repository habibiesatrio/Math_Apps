import 'dart:math';
import 'package:flutter/material.dart';
import 'firebase_service.dart';
import 'app_state.dart';

class MeanMedianModeScreen extends StatefulWidget {
  const MeanMedianModeScreen({super.key});

  @override
  State<MeanMedianModeScreen> createState() => _MeanMedianModeScreenState();
}

class _MeanMedianModeScreenState extends State<MeanMedianModeScreen> {
  // Services and State
  final FirebaseService _firebaseService = FirebaseService();
  final AppState _appState = AppState();
  final _userNameController = TextEditingController();

  // State for Calculator
  final _numbersController = TextEditingController();
  String _meanResult = '-';
  String _medianResult = '-';
  String _modeResult = '-';

  // State for Quiz
  final _userAnswerController = TextEditingController();
  List<int> _quizNumbers = [];
  String _quizQuestion = '-';
  String _quizQuestionType = '-';
  String _correctAnswer = '-';
  String _feedbackMessage = '';
  bool _isQuizActive = false;

  @override
  void dispose() {
    _numbersController.dispose();
    _userAnswerController.dispose();
    _userNameController.dispose();
    super.dispose();
  }

  // --- LOGIC FOR QUIZ ---
  Future<void> _checkAnswer() async {
    if (_appState.userName.isEmpty) {
      await _promptForUserName();
      if (_appState.userName.isEmpty) return;
    }

    final userAnswer = _userAnswerController.text.trim();
    bool isCorrect = userAnswer.toLowerCase() == _correctAnswer.toLowerCase();

    if (isCorrect) {
      setState(() {
        _feedbackMessage =
            'Benar! Jawabannya adalah $_correctAnswer. Poin ditambahkan!';
      });
      await _firebaseService.updateUserScore(
        _appState.userName,
        'MeanMedianMode',
      );
    } else {
      setState(() {
        _feedbackMessage =
            'Salah. Jawaban yang benar adalah $_correctAnswer. Coba lagi!';
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

  // --- LOGIC FOR CALCULATOR ---
  void _calculate() {
    final inputText = _numbersController.text;
    if (inputText.isEmpty) return;

    final numbers = inputText
        .split(',')
        .map((e) => double.tryParse(e.trim()))
        .where((n) => n != null)
        .cast<double>()
        .toList();

    if (numbers.isEmpty) return;

    setState(() {
      _meanResult = _calculateMean(numbers);
      _medianResult = _calculateMedian(numbers);
      _modeResult = _calculateMode(numbers);
    });
  }

  void _generateQuestion() {
    final random = Random();
    _quizNumbers = List.generate(7, (_) => random.nextInt(20) + 1);
    final questionTypeIndex = random.nextInt(3);
    final numbersAsDouble = _quizNumbers.map((e) => e.toDouble()).toList();

    setState(() {
      _isQuizActive = true;
      _feedbackMessage = '';
      _userAnswerController.clear();

      switch (questionTypeIndex) {
        case 0: // Mean
          _quizQuestionType = 'Mean';
          _correctAnswer = _calculateMean(numbersAsDouble);
          break;
        case 1: // Median
          _quizQuestionType = 'Median';
          _correctAnswer = _calculateMedian(numbersAsDouble);
          break;
        case 2: // Modus
          _quizQuestionType = 'Modus';
          _correctAnswer = _calculateMode(numbersAsDouble);
          break;
      }
      _quizQuestion = 'Berapakah $_quizQuestionType dari deret angka berikut?';
    });
  }

  // --- HELPER CALCULATION METHODS ---
  String _calculateMean(List<double> numbers) {
    if (numbers.isEmpty) return '-';
    final mean = numbers.reduce((a, b) => a + b) / numbers.length;
    return mean.toStringAsFixed(2);
  }

  String _calculateMedian(List<double> numbers) {
    if (numbers.isEmpty) return '-';
    numbers.sort();
    double median;
    int middle = numbers.length ~/ 2;
    if (numbers.length % 2 == 1) {
      median = numbers[middle];
    } else {
      median = (numbers[middle - 1] + numbers[middle]) / 2;
    }
    return median.toStringAsFixed(2);
  }

  String _calculateMode(List<double> numbers) {
    if (numbers.isEmpty) return '-';
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

    if (maxFreq <= 1 && numbers.length > 1) return 'Tidak ada';
    modes.sort();
    return modes.map((d) => d.toStringAsFixed(0)).join(', ');
  }

  // --- UI WIDGETS ---
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle('Kalkulator Praktis'),
            _buildCalculatorSection(),
            const Divider(height: 40, thickness: 2),
            _buildSectionTitle('Latihan Soal'),
            _buildQuizSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculatorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Masukkan angka-angka dipisahkan koma (contoh: 90, 85, 70, 85, 100)',
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
        Text('Hasil:', style: Theme.of(context).textTheme.titleMedium),
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
    );
  }

  Widget _buildQuizSection() {
    return Column(
      children: [
        Center(
          child: ElevatedButton(
            onPressed: _generateQuestion,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _quizQuestion,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _quizNumbers.join(', '),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _userAnswerController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Jawaban Anda',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: ElevatedButton(
                        onPressed: _checkAnswer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text('Periksa Jawaban'),
                      ),
                    ),
                    if (_feedbackMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Text(
                          _feedbackMessage,
                          style: TextStyle(
                            fontSize: 15,
                            color: _feedbackMessage.startsWith('Benar')
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
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

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
    child: Text(title, style: Theme.of(context).textTheme.titleLarge),
  );

  Widget _buildResultRow(String title, String result) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16)),
        Text(
          result,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}
