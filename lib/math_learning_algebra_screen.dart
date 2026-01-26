import 'dart:math';
import 'package:flutter/material.dart';
import 'firebase_service.dart';
import 'app_state.dart';

class MathLearningAlgebraScreen extends StatefulWidget {
  const MathLearningAlgebraScreen({super.key});

  @override
  State<MathLearningAlgebraScreen> createState() =>
      _MathLearningAlgebraScreenState();
}

class _MathLearningAlgebraScreenState extends State<MathLearningAlgebraScreen> {
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
    int a = random.nextInt(5) + 2;
    int x = random.nextInt(10) + 1;
    int b = random.nextInt(10) + 1;
    int c = a * x + b;

    setState(() {
      // FIX: Changed '$a\x' to '${a}x' to avoid escape sequence error.
      _quizQuestion = '${a}x + $b = $c';
      _correctAnswer = x;
      _isQuizActive = true;
      _feedbackMessage = '';
      _userAnswerController.clear();
    });
  }

  Future<void> _checkAnswer() async {
    // If user name is not set, prompt for it first.
    if (_appState.userName.isEmpty) {
      await _promptForUserName();
      // If the user didn't enter a name, stop here.
      if (_appState.userName.isEmpty) return;
    }

    final userAnswer = int.tryParse(_userAnswerController.text.trim());
    bool isCorrect = userAnswer == _correctAnswer;

    if (isCorrect) {
      setState(() {
        _feedbackMessage =
            'Benar! Nilai x adalah $_correctAnswer. Poin ditambahkan!';
      });
      // Update score on Firebase
      await _firebaseService.updateUserScore(_appState.userName, 'Aljabar');
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
      barrierDismissible: false, // User must enter a name
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
        title: const Text('Aljabar'),
        backgroundColor: Colors.orange.shade800,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStaticContent(), // The original content
            const Divider(height: 40, thickness: 2),
            _buildSectionTitle('Latihan Soal', context),
            _buildQuizSection(), // The new interactive quiz section
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
                      'Carilah nilai x dari persamaan berikut:',
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
                      width: 150, // Limit width of the text field
                      child: TextField(
                        controller: _userAnswerController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Jawaban (x)',
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
        _buildSectionTitle('Pengenalan Aljabar', context),
        _buildContentText(
          'Aljabar adalah cabang matematika yang mempelajari simbol matematika dan aturan untuk memanipulasi simbol-simbol ini. Aljabar menggunakan huruf (seperti x atau y) untuk mewakili angka yang tidak diketahui nilainya.',
          context,
        ),
        const Divider(height: 30),
        _buildSectionTitle('Apa itu Variabel?', context),
        _buildContentText(
          'Variabel adalah simbol (biasanya huruf) yang mewakili sebuah angka. Anggap saja seperti sebuah "kotak kosong" yang bisa kita isi dengan angka untuk membuat sebuah pernyataan menjadi benar.',
          context,
        ),
        const SizedBox(height: 10),
        _buildContentText(
          'Contoh: Dalam persamaan x + 5 = 10, "x" adalah variabel. Tugas kita adalah mencari tahu angka berapa yang harus dimasukkan ke dalam "kotak" x agar persamaan tersebut menjadi benar.',
          context,
        ),
        const Divider(height: 30),
        _buildSectionTitle('Contoh Sederhana', context),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Soal: x + 5 = 10',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _buildContentText(
                  'Untuk menemukan nilai x, kita perlu "memindahkan" angka 5 ke sisi kanan persamaan. Caranya adalah dengan melakukan operasi kebalikannya.\n\nKarena operasinya adalah penjumlahan (+5), maka kebalikannya adalah pengurangan (-5).\n\nx = 10 - 5\n\nJadi, nilai x adalah 5.',
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
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Text(title, style: Theme.of(context).textTheme.titleLarge),
  );

  Widget _buildContentText(String text, BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.bodyMedium);
}
