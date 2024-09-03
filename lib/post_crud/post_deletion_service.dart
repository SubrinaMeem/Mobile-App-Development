import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> deleteOldPosts() async {
  try {
    DateTime thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
    CollectionReference postsCollection =
        FirebaseFirestore.instance.collection('posts');

    QuerySnapshot snapshot = await postsCollection
        .where('timestamp', isLessThan: thirtyDaysAgo)
        .get();

    List<Future<void>> deleteFutures = [];
    snapshot.docs.forEach((doc) {
      deleteFutures.add(doc.reference.delete());
    });

    await Future.wait(deleteFutures);
  } catch (e) {
    print('Error deleting old posts: $e');
    throw Exception('Failed to delete old posts.');
  }
}
