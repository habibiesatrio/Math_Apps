import 'package:flutter/material.dart';
import '../alternative_model.dart';

class SawResultScreen extends StatelessWidget {
  final List<Alternative> results;

  const SawResultScreen({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hasil Perankingan (SAW)'),
        backgroundColor: Colors.green,
      ),
      body: results.isEmpty
          ? const Center(
              child: Text(
                'Tidak ada data untuk ditampilkan.',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final alternative = results[index];
                final rank = index + 1;

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getRankColor(rank),
                      child: Text(
                        '$rank',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    title: Text(
                      alternative.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(
                      'Skor Total: ${alternative.score?.toStringAsFixed(4)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                );
              },
            ),
    );
  }

  // Helper function untuk memberikan warna berbeda pada peringkat teratas
  Color _getRankColor(int rank) {
    if (rank == 1) return Colors.amber.shade700; // Emas
    if (rank == 2) return Colors.grey.shade500; // Perak
    if (rank == 3) return Colors.brown.shade400; // Perunggu
    return Colors.blueGrey;
  }
}