import 'dart:math';
import 'package:flutter/material.dart';
import 'firebase_service.dart';
import 'app_state.dart';

class MathLearningGeometryScreen extends StatefulWidget {
  const MathLearningGeometryScreen({super.key});

  @override
  State<MathLearningGeometryScreen> createState() =>
      _MathLearningGeometryScreenState();
}

class _MathLearningGeometryScreenState
    extends State<MathLearningGeometryScreen> {
  // Services and State
  final FirebaseService _firebaseService = FirebaseService();
  final AppState _appState = AppState();
  final _userNameController = TextEditingController();

  // Quiz State
  final _userAnswerController = TextEditingController();
  String _quizQuestion = '-';
  int _correctAnswer = 0;
  String _feedbackMessage = '';
  bool _isQuizActive = false;

  @override
  void dispose() {
    _userAnswerController.dispose();
    _userNameController.dispose();
    super.dispose();
  }

  // --- LOGIC ---
  void _generateQuestion() {
    final random = Random();
    int side = random.nextInt(15) + 5;
    int area = side * side;

    setState(() {
      _quizQuestion =
          'Berapakah luas sebuah persegi dengan panjang sisi $side cm?';
      _correctAnswer = area;
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

    final userAnswer = int.tryParse(_userAnswerController.text.trim());
    bool isCorrect = userAnswer == _correctAnswer;

    if (isCorrect) {
      setState(() {
        _feedbackMessage =
            'Benar! Jawabannya adalah $_correctAnswer cm². Poin ditambahkan!';
      });
      await _firebaseService.updateUserScore(_appState.userName, 'Geometri');
    } else {
      setState(() {
        _feedbackMessage =
            'Salah. Jawaban yang benar adalah $_correctAnswer cm². Coba lagi!';
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
        title: const Text('Geometri'),
        backgroundColor: Colors.lightBlue.shade700,
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
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Jawaban (Luas)',
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
        _buildSectionTitle('Pengenalan Geometri', context),
        _buildContentText(
          'Geometri adalah cabang matematika yang bersangkutan dengan pertanyaan bentuk, ukuran, posisi relatif gambar, dan sifat ruang.',
          context,
        ),
        const Divider(height: 30),
        _buildSectionTitle('Konsep Dasar: Luas', context),
        _buildContentText(
          'Luas adalah besaran yang menyatakan ukuran dua dimensi (permukaan) dari suatu daerah tertutup. Rumus luas berbeda-beda tergantung pada bentuknya.',
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
                  'Contoh: Luas Persegi',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _buildContentText(
                  'Untuk menemukan luas persegi, kita mengalikan panjang sisinya dengan dirinya sendiri.\n\nRumus: Luas = Sisi × Sisi\n\nContoh: Jika sebuah persegi memiliki sisi 5 cm, maka luasnya adalah 5 cm × 5 cm = 25 cm².',
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
