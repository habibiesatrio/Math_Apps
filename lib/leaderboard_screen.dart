import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Papan Peringkat'),
        backgroundColor: Colors.amber.shade800,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firebaseService.getLeaderboard(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada skor. Jadilah yang pertama!',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Terjadi error saat memuat data.'));
          }

          final leaderboardData = snapshot.data!.docs;

          return ListView.builder(
            itemCount: leaderboardData.length,
            itemBuilder: (context, index) {
              final data =
                  leaderboardData[index].data() as Map<String, dynamic>;
              final rank = index + 1;
              final name = data['name'] ?? 'Tanpa Nama';
              final totalScore = data['totalScore'] ?? 0;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 3,
                child: ListTile(
                  leading: _buildRankIcon(rank),
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  trailing: Text(
                    '$totalScore Poin',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.deepOrange,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRankIcon(int rank) {
    IconData iconData;
    Color color;
    switch (rank) {
      case 1:
        iconData = Icons.emoji_events;
        color = Colors.amber.shade700; // Gold
        break;
      case 2:
        iconData = Icons.emoji_events;
        color = Colors.grey.shade500; // Silver
        break;
      case 3:
        iconData = Icons.emoji_events;
        color = Colors.brown.shade400; // Bronze
        break;
      default:
        return CircleAvatar(
          backgroundColor: Colors.blueGrey,
          child: Text(
            '$rank',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
    }
    return Icon(iconData, color: color, size: 40);
  }
}
