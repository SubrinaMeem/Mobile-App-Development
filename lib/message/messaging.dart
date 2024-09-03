import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_page.dart'; // Import your ChatPage widget here

class MessagingPage extends StatefulWidget {
  final String currentUserId;

  const MessagingPage({Key? key, required this.currentUserId})
      : super(key: key);

  @override
  _MessagingPageState createState() => _MessagingPageState();
}

class _MessagingPageState extends State<MessagingPage> {
  late Future<List<Map<String, dynamic>>> usersFuture;

  @override
  void initState() {
    super.initState();
    usersFuture = _fetchUsers();
  }

  Future<List<Map<String, dynamic>>> _fetchUsers() async {
    try {
      // Fetch users current user has texted
      QuerySnapshot sentMessagesSnapshot = await FirebaseFirestore.instance
          .collection('messaging')
          .where('user1Id', isEqualTo: widget.currentUserId)
          .get();

      List<Map<String, dynamic>> sentUsers = sentMessagesSnapshot.docs
          .map((doc) => {
                'userId': doc['user2Id'],
                'username': doc['user2Name'],
              })
          .toList();

      // Filter out duplicate users based on user2Name
      List<Map<String, dynamic>> uniqueUsers = [];
      Set<String> seenUserNames = Set();

      for (var user in sentUsers) {
        if (!seenUserNames.contains(user['username'])) {
          uniqueUsers.add(user);
          seenUserNames.add(user['username']);
        }
      }

      return uniqueUsers;
    } catch (e) {
      print('Error fetching users: $e');
      throw e;
    }
  }

  Future<void> _deleteChat(String userId) async {
    try {
      // Find the chat document to delete where currentUserId is user1Id
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('messaging')
          .where('user1Id', isEqualTo: widget.currentUserId)
          .where('user2Id', isEqualTo: userId)
          .get();

      // Delete all found documents
      for (DocumentSnapshot doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Chat deleted successfully'),
        duration: Duration(seconds: 2),
      ));

      // Refresh the user list after deletion
      setState(() {
        usersFuture = _fetchUsers();
      });
    } catch (e) {
      print('Error deleting chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to delete chat. Please try again later.'),
        duration: Duration(seconds: 2),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Messaging',
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
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          List<Map<String, dynamic>> users = snapshot.data ?? [];

          if (users.isEmpty) {
            return Center(child: Text('No users found.'));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> user = users[index];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user['userId'])
                    .get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return SizedBox.shrink();
                  }

                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return SizedBox.shrink();
                  }

                  String username = user['username'];
                  String photoUrl = userSnapshot.data!['photoUrl'];

                  return Card(
                    elevation: 4, // Add elevation for a shadow effect
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12.0), // Round the corners
                    ),
                    margin: EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 16.0), // Add margin
                    color: Colors
                        .transparent, // Make the card transparent to apply gradient to the content
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color.fromARGB(255, 250, 246, 207),
                            Color.fromARGB(255, 223, 223, 152),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius:
                            BorderRadius.circular(12.0), // Round the corners
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                        leading: ClipOval(
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color.fromARGB(255, 234, 223, 206),
                                  const Color.fromARGB(255, 174, 195, 204),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: CircleAvatar(
                              backgroundImage: NetworkImage(photoUrl),
                            ),
                          ),
                        ),
                        title: Text(
                          username,
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                        ),
                        subtitle: Text(
                          'Tap to chat', // Add a subtitle or additional text
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14.0,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          color: Colors.red,
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('Delete Chat'),
                                  content: Text(
                                      'Are you sure you want to delete this chat?'),
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
                                        _deleteChat(user['userId']);
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          tooltip: 'Delete Chat',
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatPage(
                                currentUserId: widget.currentUserId,
                                recipientUserId: user['userId'],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
