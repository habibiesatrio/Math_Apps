import 'package:flutter/material.dart';
import 'math_learning_mean_median_mode_screen.dart'; // Assuming this file is in the same directory
import 'math_learning_algebra_screen.dart'; // Assuming this file is in the same directory
import 'math_learning_linear_equation_screen.dart'; // Assuming this file is in the same directory

class MathLearningMenuScreen extends StatelessWidget {
  const MathLearningMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Topik Matematika'),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          _buildTopicCard(
            context: context,
            title: 'Mean, Median, Modus',
            subtitle: 'Pelajari dasar-dasar statistika.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MeanMedianModeScreen()),
              );
            },
          ),
          _buildTopicCard(
            context: context,
            title: 'Aljabar, Geometri, Trigonometri',
            subtitle: 'Konsep dasar matematika tingkat lanjut.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const MathLearningAlgebraScreen()),
              );
            },
          ),
          _buildTopicCard(
            context: context,
            title: 'Persamaan Linier Satu Variabel',
            subtitle: 'Menyelesaikan persamaan dengan satu variabel.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const MathLearningLinearEquationScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopicCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}