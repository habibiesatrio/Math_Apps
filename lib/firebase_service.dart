import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  // Get a reference to the Firestore database
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // A method to add or update a user's score on the leaderboard.
  Future<void> updateUserScore(String userName, String topic) async {
    if (userName.trim().isEmpty) {
      // Don't update score if the user name is empty
      return;
    }

    // Get a reference to the document for the specific user
    final userDocRef = _db.collection('leaderboard').doc(userName);

    try {
      // Run a transaction to ensure atomic read-modify-write
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(userDocRef);

        if (!snapshot.exists) {
          // If the user does not exist, create a new document
          transaction.set(userDocRef, {
            'name': userName,
            'totalScore': 1,
            'scoresByTopic': {topic: 1},
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        } else {
          // If the user exists, update their score
          final currentData = snapshot.data() as Map<String, dynamic>;
          final newTotalScore = (currentData['totalScore'] ?? 0) + 1;
          final newTopicScore =
              ((currentData['scoresByTopic'] ?? {})[topic] ?? 0) + 1;

          transaction.update(userDocRef, {
            'totalScore': newTotalScore,
            'scoresByTopic.$topic':
                newTopicScore, // Using dot notation to update a map field
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      // Handle potential errors, e.g., by logging them
      print('Error updating user score: $e');
      // Depending on the app's needs, you might want to re-throw the error
      // or handle it in a way that is visible to the user.
    }
  }

  // A method to get all leaderboard data, sorted by total score
  Stream<QuerySnapshot> getLeaderboard() {
    return _db
        .collection('leaderboard')
        .orderBy('totalScore', descending: true)
        .snapshots();
  }
}
