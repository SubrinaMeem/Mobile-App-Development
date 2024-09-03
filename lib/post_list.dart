import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher package
import 'package:project/post_crud/post_deletion_service.dart';
import 'package:project/post_fetch/fetch_posts.dart';
import 'package:project/post_fetch/post_with_user.dart';
import 'package:project/post_crud/edit_post.dart';
import 'package:project/post_crud/report_manager.dart';

class PostList extends StatefulWidget {
  final int filterOption; // 0: All posts, 1: By country, 2: By user
  final String? locationQuery; // Add this line

  PostList({
    required this.filterOption,
    this.locationQuery, // Add this line
  });

  @override
  _PostListState createState() => _PostListState();
}

class _PostListState extends State<PostList> {
  @override
  Widget build(BuildContext context) {
    deleteOldPosts();
    return Expanded(
        child: RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(Duration(seconds: 1));
        setState(() {
          fetchPosts(
              filterOption: widget.filterOption,
              locationQuery: widget.locationQuery);
        });
      },
      child: FutureBuilder<List<PostWithUser>>(
        future: fetchPosts(
          filterOption: widget.filterOption,
          locationQuery: widget.locationQuery,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            List<PostWithUser> posts = snapshot.data!;
            final currentUser = FirebaseAuth.instance.currentUser;

            // Sort posts by timestamp in descending order
            posts.sort((a, b) => b.timestamp.compareTo(a.timestamp));

            return ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                List<Color> gradientColors = index % 2 == 0
                    ? [
                        Color.fromARGB(255, 250, 246, 207),
                        Color.fromARGB(255, 223, 223, 152)
                      ]
                    : [
                        Color.fromARGB(255, 230, 230, 170),
                        Color.fromARGB(255, 253, 250, 220)
                      ];

                return GestureDetector(
                  onTap: () {},
                  child: Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: gradientColors,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundImage:
                                          NetworkImage(post.userphotoUrl),
                                      radius: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          post.userName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.brown[900],
                                          ),
                                        ),
                                        Text(
                                          DateFormat('yyyy-MM-dd hh:mm a')
                                              .format(post.timestamp.toDate()),
                                          style: TextStyle(
                                            color: Colors.brown[900],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Spacer(),
                                  ],
                                ),
                                SizedBox(height: 12),
                                GestureDetector(
                                  onTap: () {
                                    launch(post.imgBBUrl); // Open image URL
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        post.title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                          color: Colors.brown[900],
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        post.description,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.brown[900],
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Meeting Place: ${post.collectingPlace}',
                                        style: TextStyle(
                                          color: Colors.brown[900],
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Location: ${post.location}',
                                        style: TextStyle(
                                          color: Colors.brown[900],
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Country: ${post.country}',
                                        style: TextStyle(
                                          color: Colors.brown[900],
                                        ),
                                      ),
                                      SizedBox(height: 12), // Adjusted spacing
                                      Container(
                                        height: 150,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.grey.withOpacity(0.5),
                                              spreadRadius: 2,
                                              blurRadius: 5,
                                              offset: Offset(0, 3),
                                            ),
                                          ],
                                          image: DecorationImage(
                                            image: NetworkImage(post.imgBBUrl),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 15), // Adjusted spacing
                                      if (currentUser != null &&
                                          post.userId == currentUser.uid)
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        EditPostPage(
                                                      post: post,
                                                      postId: post.postId,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit,
                                                      color: Colors.brown[900],
                                                      size: 17),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Edit',
                                                    style: TextStyle(
                                                        color:
                                                            Colors.brown[900]),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(width: 16),
                                            GestureDetector(
                                              onTap: () {
                                                _confirmDeletePost(
                                                    context, post.postId);
                                              },
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete,
                                                      color: Colors.brown[900],
                                                      size: 17),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Delete',
                                                    style: TextStyle(
                                                        color:
                                                            Colors.brown[900]),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 5),
                                if (currentUser != null &&
                                    post.userId != currentUser.uid)
                                  Padding(
                                    padding: EdgeInsets.only(top: 8),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            ReportIconButton(
                                              icon: Icons.report,
                                              onPressed: () {
                                                _handleReportUser(
                                                    context, post.userId);
                                              },
                                              postId: post.userId,
                                              reportType: 'user',
                                              size: 17,
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                _handleReportUser(
                                                    context, post.userId);
                                              },
                                              child: Text(
                                                'Report User',
                                                style: TextStyle(
                                                  color: Colors.brown[900],
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            ReportIconButton(
                                              icon: Icons.flag,
                                              onPressed: () {
                                                _handleReportPost(
                                                    context, post.postId);
                                              },
                                              postId: post.postId,
                                              reportType: 'post',
                                              size: 17,
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                _handleReportPost(
                                                    context, post.postId);
                                              },
                                              child: Text(
                                                'Report Post',
                                                style: TextStyle(
                                                  color: Colors.brown[900],
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(width: 4),
                                        GestureDetector(
                                          onTap: () {
                                            _handleMessageUser(
                                                context, post.userId);
                                          },
                                          child: Row(
                                            children: [
                                              Icon(Icons.message,
                                                  color: Colors.brown[900],
                                                  size: 17),
                                              Text(
                                                'Message',
                                                style: TextStyle(
                                                  color: Colors.brown[900],
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    ));
  }

  Future<void> _confirmDeletePost(BuildContext context, String postId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Post'),
        content: Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('posts')
                    .doc(postId)
                    .delete();
                Navigator.pop(context); // Close dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Post deleted successfully.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              } catch (e) {
                print('Error deleting post: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Failed to delete post. Please try again later.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleMessageUser(BuildContext context, String userId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // Handle if user is not authenticated (though button should be hidden)
      return;
    }

    try {
      // Check if a notification already exists for this user pair
      QuerySnapshot existingNotifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('senderId', isEqualTo: currentUser.uid)
          .get();

      if (existingNotifications.docs.isNotEmpty) {
        // If notification already exists, show a message and return
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Request Already Sent'),
            content: Text('You have already sent a request to this user.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      // Fetch the username of the authenticated user
      DocumentSnapshot currentSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      String currentUsername = currentSnapshot['username'];

      // Fetch the username of the recipient user
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      // ignore: unused_local_variable
      String recipientUsername = userSnapshot['username'];

      // Send notification/message to Firestore
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'senderId': currentUser.uid, // Add sender ID to check duplicates
        'message': '$currentUsername wants to communicate with you.',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false, // Mark notification as unread initially
      });

      // Show a confirmation dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Message Sent'),
          content: Text('Your request has been sent.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error sending message: $e');
      // Handle error as needed
    }
  }
}

void _handleReportUser(BuildContext context, String userId) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    print('User is not authenticated.');
    return;
  }

  try {
    bool alreadyReported =
        await ReportManager().hasReportedUser(userId, currentUser.uid);

    if (alreadyReported) {
      // Offer to undo report
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Undo Report'),
            content: Text('Do you want to undo your report?'),
            actions: <Widget>[
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('Undo'),
                onPressed: () async {
                  // Delete report document
                  await ReportManager().undoReportUser(userId, currentUser.uid);
                  Navigator.of(context).pop();
                  _showReportStatusDialog(context, 'Report undone.');
                },
              ),
            ],
          );
        },
      );
      return;
    }

    await ReportManager().reportUser(userId, currentUser.uid);

    _showReportStatusDialog(context, 'User reported successfully.');
  } catch (e) {
    print('Error reporting user: $e');
    _showReportStatusDialog(
        context, 'Failed to report user. Please try again later.');
  }
}

void _handleReportPost(BuildContext context, String postId) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    print('User is not authenticated.');
    return;
  }

  try {
    bool alreadyReported =
        await ReportManager().hasReportedPost(postId, currentUser.uid);

    if (alreadyReported) {
      // Offer to undo report
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Undo Report'),
            content: Text('Do you want to undo your report?'),
            actions: <Widget>[
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('Undo'),
                onPressed: () async {
                  // Delete report document
                  await ReportManager().undoReportPost(postId, currentUser.uid);
                  Navigator.of(context).pop();
                  _showReportStatusDialog(context, 'Report undone.');
                },
              ),
            ],
          );
        },
      );
      return;
    }

    await ReportManager().reportPost(postId, currentUser.uid);

    _showReportStatusDialog(context, 'Post reported successfully.');
  } catch (e) {
    print('Error reporting post: $e');
    _showReportStatusDialog(
        context, 'Failed to report post. Please try again later.');
  }
}

void _showReportStatusDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Report Status'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

class ReportIconButton extends StatelessWidget {
  final IconData icon;
  final Function onPressed;
  final String postId;
  final String reportType;
  final double size;

  const ReportIconButton({
    Key? key,
    required this.icon,
    required this.onPressed,
    required this.postId,
    required this.reportType,
    this.size = 24.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _getReportCount(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          int reportCount = snapshot.data ?? 0;
          return GestureDetector(
            onTap: () => onPressed(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (reportCount > 0)
                  RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: <TextSpan>[
                        TextSpan(
                          text: '$reportCount',
                          style: TextStyle(fontSize: 12),
                        ),
                        TextSpan(
                          text: '',
                          style: TextStyle(fontSize: 8),
                        ),
                      ],
                    ),
                  ),
                Icon(icon, size: size),
              ],
            ),
          );
        }
      },
    );
  }

  Future<int> _getReportCount() async {
    if (reportType == 'user') {
      return await ReportManager().getUserReportCount(postId);
    } else if (reportType == 'post') {
      return await ReportManager().getPostReportCount(postId);
    } else {
      return 0;
    }
  }
}
