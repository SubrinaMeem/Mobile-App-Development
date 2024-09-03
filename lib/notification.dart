import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:project/message/messaging.dart';

class NotificationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final String? currentUserId = currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Notifications',
            textAlign: TextAlign.center,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 227, 227, 164),
                Color.fromARGB(255, 250, 246, 207)
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No notifications available.'));
          }

          final List<DocumentSnapshot> userNotifications = snapshot.data!.docs
              .where((doc) => doc['userId'] == currentUserId)
              .toList();

          if (userNotifications.isEmpty) {
            return Center(child: Text('No notifications for you.'));
          }

          return ListView(
            padding: EdgeInsets.all(20.0),
            children: userNotifications.map((DocumentSnapshot document) {
              Map<String, dynamic> data =
                  document.data() as Map<String, dynamic>;
              String messageId = document.id;

              bool containsMessage =
                  data['message'].contains('wants to communicate with you') ||
                      data['message'].contains('accepted your request');

              Timestamp createdAtTimestamp = data['createdAt'];
              DateTime createdAt = createdAtTimestamp.toDate();
              String formattedDate =
                  DateFormat('yyyy-MM-dd hh:mm a').format(createdAt);

              // Choose gradient colors based on index
              final List<List<Color>> gradients = [
                [
                  Color.fromARGB(255, 250, 246, 207),
                  Color.fromARGB(255, 223, 223, 152)
                ],
                [
                  Color.fromARGB(255, 230, 230, 170),
                  Color.fromARGB(255, 253, 250, 220)
                ],
              ];

              return NotificationCard(
                message: data['message'],
                createdAt: formattedDate,
                messageId: messageId,
                currentUserId: currentUserId,
                onDelete: () {
                  _deleteNotification(messageId, context);
                },
                onTap: containsMessage
                    ? () {
                        _establishMessaging(
                            context, currentUserId!, data['message']);
                      }
                    : null,
                gradientColors: gradients[
                    userNotifications.indexOf(document) % gradients.length],
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Future<void> _deleteNotification(
      String messageId, BuildContext context) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return;
      }

      DocumentSnapshot notificationSnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .doc(messageId)
          .get();

      if (notificationSnapshot.exists &&
          notificationSnapshot['userId'] == currentUser.uid) {
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(messageId)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification deleted successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        print(
            'Notification does not exist or you are not authorized to delete it.');
      }
    } catch (e) {
      print('Error deleting notification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Failed to delete notification. Please try again later.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _establishMessaging(
      BuildContext context, String currentUserId, String message) async {
    try {
      String recipientId = await _getRecipientId(message);
      String currentUserName = await _getUserName(currentUserId);
      bool notificationExists =
          await _checkNotificationExists(currentUserId, recipientId);

      if (!notificationExists) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'createdAt': Timestamp.now(),
          'message': '$currentUserName accepted your request.',
          'senderId': currentUserId,
          'userId': recipientId,
          'read': false, // Set read status to false initially
        });
      } else {
        print('Notification already exists for this interaction.');
      }

      bool messagingConnectionExists =
          await _checkMessagingConnection(currentUserId, recipientId);

      if (!messagingConnectionExists) {
        await FirebaseFirestore.instance.collection('messaging').add({
          'user1Id': currentUserId,
          'user1Name': currentUserName,
          'user2Id': recipientId,
          'user2Name': message.contains('wants to communicate with you')
              ? message.split(' wants to communicate with you')[0]
              : message.split(' accepted your request')[0],
          'createdAt': Timestamp.now(),
        });
      } else {
        print('Messaging connection already exists.');
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MessagingPage(
            currentUserId: currentUserId,
          ),
        ),
      );
    } catch (e) {
      print('Error establishing messaging: $e');
    }
  }

  Future<bool> _checkNotificationExists(String senderId, String userId) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('senderId', isEqualTo: senderId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking notification existence: $e');
      return false;
    }
  }

  Future<String> _getUserName(String userId) async {
    try {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userSnapshot.exists) {
        return userSnapshot['username'];
      } else {
        print('User document not found for userId: $userId');
        return '';
      }
    } catch (e) {
      print('Error fetching user name: $e');
      throw e;
    }
  }

  Future<String> _getUserId(String recipientId) async {
    try {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(recipientId)
          .get();

      if (userSnapshot.exists) {
        return recipientId;
      } else {
        print('User document not found for recipientId: $recipientId');
        return '';
      }
    } catch (e) {
      print('Error fetching user ID: $e');
      throw e;
    }
  }

  Future<String> _getRecipientId(String message) async {
    try {
      String recipientUsername =
          message.contains('wants to communicate with you')
              ? message.split(' wants to communicate with you')[0]
              : message.split(' accepted your request')[0];

      QuerySnapshot usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: recipientUsername)
          .limit(1)
          .get();

      if (usersSnapshot.docs.isNotEmpty) {
        return usersSnapshot.docs.first.id;
      } else {
        print('User not found with username: $recipientUsername');
        return '';
      }
    } catch (e) {
      print('Error fetching recipientId: $e');
      throw e;
    }
  }

  Future<bool> _checkMessagingConnection(String user1Id, String user2Id) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('messaging')
          .where('user1Id', isEqualTo: user1Id)
          .where('user2Id', isEqualTo: user2Id)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking messaging connection: $e');
      return false;
    }
  }
}

class NotificationCard extends StatelessWidget {
  final String message;
  final String createdAt;
  final String messageId;
  final String? currentUserId;
  final VoidCallback onDelete;
  final VoidCallback? onTap;
  final List<Color> gradientColors;

  const NotificationCard({
    required this.message,
    required this.createdAt,
    required this.messageId,
    required this.currentUserId,
    required this.onDelete,
    this.onTap,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 10.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: onTap,
                child: Text(
                  message,
                  style: TextStyle(fontSize: 18.0),
                ),
              ),
              SizedBox(height: 5),
              Text(
                createdAt,
                style: TextStyle(color: Colors.grey),
              ),
              if (onTap != null)
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                    );
                    onTap!();
                  },
                  child: Text(
                    'Click to open chat',
                    style: TextStyle(fontSize: 18.0, color: Colors.blue),
                  ),
                ),
              SizedBox(height: 10),
              if (currentUserId != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          // Show the confirmation dialog
                          return AlertDialog(
                            title: Text('Confirm Deletion'),
                            content: Text(
                                'Are you sure you want to delete this notification?'),
                            actions: <Widget>[
                              TextButton(
                                child: Text('Cancel'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              TextButton(
                                  child: Text('Delete'),
                                  onPressed: () {
                                    // Close the dialog immediately
                                    Navigator.of(context).pop();

                                    onDelete();
                                  })
                            ],
                          );
                        },
                      );
                    },
                    color: Colors.red,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
