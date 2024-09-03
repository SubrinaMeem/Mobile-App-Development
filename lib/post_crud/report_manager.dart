import 'package:cloud_firestore/cloud_firestore.dart';

class ReportManager {
  final CollectionReference postReportsCollection =
      FirebaseFirestore.instance.collection('post_reports');
  final CollectionReference userReportsCollection =
      FirebaseFirestore.instance.collection('user_reports');
  final CollectionReference notificationsCollection =
      FirebaseFirestore.instance.collection('notifications');
  final CollectionReference postsCollection =
      FirebaseFirestore.instance.collection('posts');

  Future<void> reportPost(String postId, String reporterId) async {
    bool alreadyReported = await hasReportedPost(postId, reporterId);

    if (!alreadyReported) {
      await postReportsCollection
          .doc(postId)
          .collection('reports')
          .doc(reporterId)
          .set({
        'timestamp': Timestamp.now(),
      });

      int reportCount = await getPostReportCount(postId);
      if (reportCount >= 50) {
        // Fetch post title and userId before deleting
        String postTitle = await _fetchPostTitle(postId);
        String postUserId = await _fetchPostUserId(postId);
        await deletePost(postId);
        await _storeNotification(
            'Your post "$postTitle" has been deleted due to multiple reports.',
            false,
            postUserId);
      }
    } else {
      throw Exception('You have already reported this post.');
    }
  }

  Future<void> reportUser(String userId, String reporterId) async {
    bool alreadyReported = await hasReportedUser(userId, reporterId);

    if (!alreadyReported) {
      await userReportsCollection
          .doc(userId)
          .collection('reports')
          .doc(reporterId)
          .set({
        'timestamp': Timestamp.now(),
      });

      int reportCount = await getUserReportCount(userId);
      if (reportCount >= 50) {
        await disableUser(userId);
        await _storeNotification(
            'You have been disabled due to multiple reports.', false, userId);
      }
    } else {
      throw Exception('You have already reported this user.');
    }
  }

  Future<void> undoReportPost(String postId, String reporterId) async {
    try {
      await postReportsCollection
          .doc(postId)
          .collection('reports')
          .doc(reporterId)
          .delete();
      print('Report undone successfully.');
    } catch (e) {
      print('Error undoing report for post: $e');
      throw Exception('Failed to undo report for post.');
    }
  }

  Future<void> undoReportUser(String userId, String reporterId) async {
    try {
      await userReportsCollection
          .doc(userId)
          .collection('reports')
          .doc(reporterId)
          .delete();
      print('Report undone successfully.');
    } catch (e) {
      print('Error undoing report for user: $e');
      throw Exception('Failed to undo report for user.');
    }
  }

  Future<bool> hasReportedPost(String postId, String reporterId) async {
    DocumentSnapshot reportSnapshot = await postReportsCollection
        .doc(postId)
        .collection('reports')
        .doc(reporterId)
        .get();

    return reportSnapshot.exists;
  }

  Future<bool> hasReportedUser(String userId, String reporterId) async {
    DocumentSnapshot reportSnapshot = await userReportsCollection
        .doc(userId)
        .collection('reports')
        .doc(reporterId)
        .get();

    return reportSnapshot.exists;
  }

  Future<int> getPostReportCount(String postId) async {
    QuerySnapshot querySnapshot =
        await postReportsCollection.doc(postId).collection('reports').get();

    return querySnapshot.size;
  }

  Future<int> getUserReportCount(String userId) async {
    QuerySnapshot querySnapshot =
        await userReportsCollection.doc(userId).collection('reports').get();

    return querySnapshot.size;
  }

  Future<void> deletePost(String postId) async {
    try {
      await postsCollection.doc(postId).delete();
      print('Post deleted successfully.');
    } catch (e) {
      print('Error deleting post: $e');
      throw Exception('Failed to delete post.');
    }
  }

  Future<void> disableUser(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'disabled': true,
      });
      print('User disabled successfully.');
    } catch (e) {
      print('Error disabling user: $e');
      throw Exception('Failed to disable user.');
    }
  }

  Future<void> _storeNotification(
      String message, bool read, String userId) async {
    try {
      await notificationsCollection.add({
        'createdAt': Timestamp.now(),
        'message': message,
        'read': read,
        'userId': userId,
      });
      print('Notification stored successfully.');
    } catch (e) {
      print('Error storing notification: $e');
      throw Exception('Failed to store notification.');
    }
  }

  Future<String> _fetchPostTitle(String postId) async {
    try {
      DocumentSnapshot postSnapshot = await postsCollection.doc(postId).get();

      if (postSnapshot.exists) {
        return postSnapshot.get('title');
      } else {
        throw Exception('Post not found.');
      }
    } catch (e) {
      print('Error fetching post title: $e');
      throw Exception('Failed to fetch post title.');
    }
  }

  Future<String> _fetchPostUserId(String postId) async {
    try {
      DocumentSnapshot postSnapshot = await postsCollection.doc(postId).get();

      if (postSnapshot.exists) {
        return postSnapshot.get('userId');
      } else {
        throw Exception('Post not found.');
      }
    } catch (e) {
      print('Error fetching post userId: $e');
      throw Exception('Failed to fetch post userId.');
    }
  }
}
