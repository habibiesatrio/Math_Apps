import 'package:flutter/material.dart';

class MathLearningAlgebraScreen extends StatelessWidget {
  const MathLearningAlgebraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aljabar, Geometri, Trigonometri'),
        backgroundColor: Colors.orange.shade800,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
                    Text('Soal: x + 5 = 10', style: Theme.of(context).textTheme.titleMedium),
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
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      );

  Widget _buildContentText(String text, BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.bodyMedium);
}