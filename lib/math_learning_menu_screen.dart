import 'package:flutter/material.dart';
import 'math_learning_mean_median_mode_screen.dart';
import 'math_learning_algebra_screen.dart';
import 'math_learning_geometry_screen.dart'; // Import the new screen
import 'math_learning_trigonometry_screen.dart'; // Import the new screen
import 'math_learning_linear_equation_screen.dart';

class MathLearningMenuScreen extends StatelessWidget {
  const MathLearningMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Topik Matematika'),
        backgroundColor: Colors.indigo,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildTopicCard(
            context: context,
            title: 'Mean, Median, Modus',
            subtitle: 'Pelajari dasar-dasar statistika.',
            icon: Icons.bar_chart,
            color: Colors.deepPurple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MeanMedianModeScreen(),
                ),
              );
            },
          ),
          _buildTopicCard(
            context: context,
            title: 'Aljabar',
            subtitle: 'Pengenalan variabel dan persamaan.',
            icon: Icons.functions,
            color: Colors.orange.shade800,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MathLearningAlgebraScreen(),
                ),
              );
            },
          ),
          _buildTopicCard(
            context: context,
            title: 'Geometri',
            subtitle: 'Mempelajari bentuk dan ruang.',
            icon: Icons.square_foot,
            color: Colors.lightBlue.shade700,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MathLearningGeometryScreen(),
                ),
              );
            },
          ),
          _buildTopicCard(
            context: context,
            title: 'Trigonometri',
            subtitle: 'Hubungan sudut dan sisi segitiga.',
            icon: Icons.architecture,
            color: Colors.teal.shade700,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MathLearningTrigonometryScreen(),
                ),
              );
            },
          ),
          _buildTopicCard(
            context: context,
            title: 'Persamaan Linier Satu Variabel',
            subtitle: 'Menyelesaikan persamaan sederhana.',
            icon: Icons.linear_scale,
            color: Colors.pink.shade700,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const MathLearningLinearEquationScreen(),
                ),
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
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
