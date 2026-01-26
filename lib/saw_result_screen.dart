import 'package:flutter/material.dart';
import 'alternative_model.dart';
import 'criteria_model.dart';

class SawResultScreen extends StatelessWidget {
  final List<Alternative> results;
  final List<Criteria> criteria;
  final List<Alternative> alternatives;

  const SawResultScreen({
    super.key,
    required this.results,
    required this.criteria,
    required this.alternatives,
  });

  @override
  Widget build(BuildContext context) {
    // Sort results in descending order based on score before displaying
    results.sort((a, b) => b.score!.compareTo(a.score!));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hasil & Soal (SAW)'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle(context, 'Soal (Input Data)'),
            const SizedBox(height: 12),
            _buildCriteriaTable(context),
            const SizedBox(height: 20),
            _buildAlternativesTable(context),
            const Divider(height: 40, thickness: 2),
            _buildSectionTitle(context, 'Hasil Perankingan'),
            const SizedBox(height: 12),
            _buildResultsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildCriteriaTable(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tabel Kriteria:', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('Nama Kriteria')),
              DataColumn(label: Text('Bobot')),
              DataColumn(label: Text('Jenis')),
            ],
            rows: criteria.map((c) {
              return DataRow(
                cells: [
                  DataCell(Text(c.id)),
                  DataCell(Text(c.name)),
                  DataCell(Text(c.weight.toString())),
                  DataCell(
                    Text(c.type == CriteriaType.benefit ? 'Benefit' : 'Cost'),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAlternativesTable(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tabel Nilai Alternatif:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              const DataColumn(label: Text('Alternatif')),
              ...criteria.map(
                (c) => DataColumn(label: Text('${c.name}\n(${c.id})')),
              ),
            ],
            rows: alternatives.map((alt) {
              return DataRow(
                cells: [
                  DataCell(Text(alt.name)),
                  ...criteria.map((crit) {
                    return DataCell(
                      Text(alt.values[crit.id]?.toString() ?? '-'),
                    );
                  }),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
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
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            subtitle: Text(
              'Skor Total: ${alternative.score?.toStringAsFixed(4)}',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        );
      },
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return Colors.amber.shade700; // Gold
    if (rank == 2) return Colors.grey.shade500; // Silver
    if (rank == 3) return Colors.brown.shade400; // Bronze
    return Colors.blueGrey;
  }
}
