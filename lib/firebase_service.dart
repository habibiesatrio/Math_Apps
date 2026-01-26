import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  // Get a reference to the Firebase Realtime Database
  final DatabaseReference _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://math-app1-e6a68-default-rtdb.firebaseio.com/',
  ).reference();

  // A method to add or update a user's score on the leaderboard.
  Future<void> updateUserScore(String userName, String topic) async {
    if (userName.trim().isEmpty) {
      // Don't update score if the user name is empty
      return;
    }

    // Get a reference to the document for the specific user
    final userDocRef = _db.child('leaderboard').child(userName);

    try {
      await userDocRef.runTransaction((mutableData) {
        final currentData = mutableData.value ?? {};
        final newTotalScore = (currentData['totalScore'] ?? 0) + 1;
        final newTopicScore = (currentData['scoresByTopic']?[topic] ?? 0) + 1;

        mutableData.value = {
          ...currentData,
          'totalScore': newTotalScore,
          'scoresByTopic': {
            ...currentData['scoresByTopic'] ?? {},
            topic: newTopicScore,
          },
          'lastUpdated': ServerValue.timestamp,
        };

        return mutableData;
      });
    } catch (e) {
      // Handle potential errors, e.g., by logging them
      print('Error updating user score: $e');
    }
  }

  // A method to get all leaderboard data, sorted by total score
  Stream<Event> getLeaderboard() {
    return _db.child('leaderboard').orderByChild('totalScore').onValue;
  }
}
