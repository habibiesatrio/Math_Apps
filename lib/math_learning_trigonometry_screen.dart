import 'dart:math';
import 'package:flutter/material.dart';
import 'firebase_service.dart';
import 'app_state.dart';

class MathLearningTrigonometryScreen extends StatefulWidget {
  const MathLearningTrigonometryScreen({super.key});

  @override
  State<MathLearningTrigonometryScreen> createState() =>
      _MathLearningTrigonometryScreenState();
}

class _MathLearningTrigonometryScreenState
    extends State<MathLearningTrigonometryScreen> {
  // Services and State
  final FirebaseService _firebaseService = FirebaseService();
  final AppState _appState = AppState();
  final _userNameController = TextEditingController();

  // Quiz State
  final _userAnswerController = TextEditingController();
  String _quizQuestion = '-';
  String _correctAnswer = '-';
  String _feedbackMessage = '';
  bool _isQuizActive = false;

  final Map<int, String> _specialAngles = {
    0: '0',
    30: '0.5',
    45: '0.707',
    60: '0.866',
    90: '1',
  };

  @override
  void dispose() {
    _userAnswerController.dispose();
    _userNameController.dispose();
    super.dispose();
  }

  // --- LOGIC ---
  void _generateQuestion() {
    final random = Random();
    final angles = _specialAngles.keys.toList();
    int angle = angles[random.nextInt(angles.length)];

    setState(() {
      _quizQuestion =
          'Berapakah nilai dari sin($angle°)? (3 angka di belakang koma jika perlu)';
      _correctAnswer = _specialAngles[angle]!;
      _isQuizActive = true;
      _feedbackMessage = '';
      _userAnswerController.clear();
    });
  }

  Future<void> _checkAnswer() async {
    if (_appState.userName.isEmpty) {
      await _promptForUserName();
      if (_appState.userName.isEmpty) return;
    }

    final userAnswer = _userAnswerController.text.trim();
    bool isCorrect = userAnswer == _correctAnswer;

    if (isCorrect) {
      setState(() {
        _feedbackMessage =
            'Benar! Jawabannya adalah $_correctAnswer. Poin ditambahkan!';
      });
      await _firebaseService.updateUserScore(
        _appState.userName,
        'Trigonometri',
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

  // --- UI WIDGETS ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trigonometri'),
        backgroundColor: Colors.teal.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStaticContent(),
            const Divider(height: 40, thickness: 2),
            _buildSectionTitle('Latihan Soal', context),
            _buildQuizSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizSection() {
    return Column(
      children: [
        Center(
          child: ElevatedButton(
            onPressed: _generateQuestion,
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Jawablah pertanyaan berikut:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _quizQuestion,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 200,
                      child: TextField(
                        controller: _userAnswerController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Jawaban (Nilai Sin)',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _checkAnswer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Periksa Jawaban'),
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

  Widget _buildStaticContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Pengenalan Trigonometri', context),
        _buildContentText(
          'Trigonometri adalah cabang matematika yang mempelajari hubungan antara sudut dan panjang sisi segitiga. Tiga fungsi dasar dalam trigonometri adalah Sinus (sin), Cosinus (cos), dan Tangen (tan).',
          context,
        ),
        const Divider(height: 30),
        _buildSectionTitle('Fungsi Sinus (Sin)', context),
        _buildContentText(
          'Dalam segitiga siku-siku, Sinus dari sebuah sudut adalah perbandingan antara panjang sisi yang berhadapan dengan sudut tersebut (sisi depan) dan panjang sisi miring (hipotenusa).\n\nRumus: sin(θ) = Sisi Depan / Sisi Miring',
          context,
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contoh: Sudut Istimewa',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _buildContentText(
                  'Nilai sinus untuk sudut-sudut tertentu (sudut istimewa) sangat umum digunakan:\n\n• sin(0°) = 0\n• sin(30°) = 0.5\n• sin(45°) ≈ 0.707\n• sin(60°) ≈ 0.866\n• sin(90°) = 1',
                  context,
                ),
              ],
            ),
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
