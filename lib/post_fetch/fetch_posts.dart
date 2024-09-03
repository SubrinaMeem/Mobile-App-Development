import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project/post_fetch/post_with_user.dart';

/// Fetches all posts or filtered posts based on options.
Future<List<PostWithUser>> fetchPosts({
  required int filterOption, // 0: All posts, 1: By country, 2: By user
  String? locationQuery, // Optional location query
}) async {
  final List<PostWithUser> postsWithUser = [];

  // Get the current user
  User? currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    throw Exception('User not authenticated');
  }

  QuerySnapshot<Map<String, dynamic>> postsQuerySnapshot;

  if (filterOption == 1) {
    // Get the current user's country
    DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
        .instance
        .collection('users')
        .doc(currentUser.uid)
        .get();
    String? userCountry = userDoc.data()?['country'];

    if (userCountry == null) {
      throw Exception('User country is not defined');
    }

    // Query posts where the country matches the user's country
    postsQuerySnapshot = await FirebaseFirestore.instance
        .collection('posts')
        .where('country', isEqualTo: userCountry)
        .get();
  } else if (filterOption == 2) {
    // Query posts where the userId matches the current user's ID
    postsQuerySnapshot = await FirebaseFirestore.instance
        .collection('posts')
        .where('userId', isEqualTo: currentUser.uid)
        .get();
  } else {
    // Query all posts
    postsQuerySnapshot =
        await FirebaseFirestore.instance.collection('posts').get();
  }

  // Process each post document
  for (final postDocument in postsQuerySnapshot.docs) {
    final userId = postDocument['userId'];
    final userDocumentSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    // Location query matching
    if (locationQuery != null && locationQuery.isNotEmpty) {
      String postLocation = postDocument['location'].toString().toLowerCase();
      String queryLocation = locationQuery.toLowerCase();

      // Remove punctuation from both location strings
      postLocation = postLocation.replaceAll(RegExp(r'[^\w\s]'), '');
      queryLocation = queryLocation.replaceAll(RegExp(r'[^\w\s]'), '');

      // Compare locations ignoring case and punctuation
      if (!postLocation.contains(queryLocation)) {
        continue; // Skip this post if location doesn't match query
      }
    }

    final postWithUser = PostWithUser(
      postId: postDocument.id,
      userId: userId,
      title: postDocument['title'],
      description: postDocument['description'],
      collectingPlace: postDocument['collectingPlace'],
      location: postDocument['location'],
      country: postDocument['country'],
      imgBBUrl: postDocument['imgBBUrl'],
      userName: userDocumentSnapshot['username'],
      userphotoUrl: userDocumentSnapshot['photoUrl'],
      timestamp: postDocument['timestamp'],
    );

    postsWithUser.add(postWithUser);
  }

  return postsWithUser;
}
