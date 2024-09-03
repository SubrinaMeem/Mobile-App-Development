import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatPage extends StatefulWidget {
  final String currentUserId;
  final String recipientUserId;

  const ChatPage({
    Key? key,
    required this.currentUserId,
    required this.recipientUserId,
  }) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late String user1Name = ''; // Your username
  late String user2Name = ''; // Other party's username
  late String user1PhotoUrl = ''; // Your photo URL
  late String user2PhotoUrl = ''; // Other party's photo URL
  late Future<DocumentSnapshot> currentUserFuture;

  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  late CollectionReference usersCollection;
  late CollectionReference messagingCollection;
  String? chatDocId; // Changed to nullable to handle initialization state
  String? newChatDocId;
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;
  // Assuming you have a ScrollController declared
  ScrollController _scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
    usersCollection = firestore.collection('users');
    messagingCollection = firestore.collection('messaging');
    _initializeChat(); // Call _initializeChat here
    currentUserFuture = _fetchCurrentUser();
  }

  Future<void> _initializeChat() async {
    try {
      // Fetch user details from users collection
      DocumentSnapshot user1Snapshot =
          await usersCollection.doc(widget.currentUserId).get();
      DocumentSnapshot user2Snapshot =
          await usersCollection.doc(widget.recipientUserId).get();

      // Retrieve user details
      String user1Id = widget.currentUserId;
      String user1Name = user1Snapshot['username'];
      String user2Id = widget.recipientUserId;
      String user2Name = user2Snapshot['username'];

      // Generate a consistent document ID for the chat between the two users
      chatDocId = _getChatDocId(user1Id, user2Id);

      // Check if the messaging document exists
      DocumentSnapshot chatDoc = await messagingCollection.doc(chatDocId).get();
      if (!chatDoc.exists || chatDoc['user1Id'] != user1Id) {
        // If the document doesn't exist or user1Id is not current user, create a new document
        newChatDocId = _getNewChatDocId(); // Generate a new document ID
        await messagingCollection.doc(newChatDocId).set({
          'user1Id': user1Id,
          'user2Id': user2Id,
          'user1Name': user1Name,
          'user2Name': user2Name,
        });

        // Once new document is created, call setState to trigger rebuild
        setState(() {});
      }
    } catch (e) {
      print('Error initializing chat: $e');
    }
  }

  Future<void> _initializeReversedChat() async {
    try {
      // Fetch user details from users collection (reversed)
      DocumentSnapshot user1Snapshot =
          await usersCollection.doc(widget.recipientUserId).get();
      DocumentSnapshot user2Snapshot =
          await usersCollection.doc(widget.currentUserId).get();

      // Retrieve user1 details (reversed)
      String user1Id = widget.recipientUserId;
      String user1Name = user1Snapshot['username'];

      // Retrieve user2 details (reversed)
      String user2Id = widget.currentUserId;
      String user2Name = user2Snapshot['username'];

      // Generate a consistent document ID for the reversed chat
      chatDocId = _getChatDocId(user1Id, user2Id);

      // Check if the messaging document exists
      DocumentSnapshot chatDoc = await messagingCollection.doc(chatDocId).get();
      if (!chatDoc.exists) {
        // If the document doesn't exist, create it with initial details
        newChatDocId = _getNewChatDocId(); // Generate a new document ID
        await messagingCollection.doc(newChatDocId).set({
          'user1Id': user1Id,
          'user2Id': user2Id,
          'user1Name': user1Name,
          'user2Name': user2Name,
        });
      }

      // Once chatDocId is initialized, call setState to trigger rebuild
      setState(() {});
    } catch (e) {
      print('Error initializing reversed chat: $e');
    }
  }

  String _getChatDocId(String userId1, String userId2) {
    // Ensure the document ID is consistent irrespective of user order
    List<String> ids = [userId1, userId2];
    ids.sort();
    return ids.join('_');
  }

  String _getNewChatDocId() {
    // Generate a new unique document ID for the chat
    return firestore.collection('messaging').doc().id;
  }

  Future<void> _sendMessage() async {
    String messageText = _messageController.text.trim();
    if (messageText.isNotEmpty || _imageBytes != null) {
      try {
        // Upload image to Firebase Storage if _imageBytes is not null
        String imageUrl = '';
        String imgBBUrl = ''; // ImgBB URL for the image

        if (_imageBytes != null) {
          String mimeType = 'image/jpeg'; // Example MIME type, adjust as needed
          imageUrl = await uploadImageToFirebaseStorage(_imageBytes!, mimeType);

          // Upload image to ImgBB and get the image URL
          imgBBUrl = await uploadImageToImgBB(_imageBytes!);
        }

        // Add message to the chat subcollection within the messaging document (chatDocId)
        await firestore
            .collection('messaging')
            .doc(chatDocId)
            .collection('chats')
            .add({
          'senderId': widget.currentUserId,
          'recipientId': widget.recipientUserId,
          'message': messageText,
          'imageUrl': imageUrl.isNotEmpty ? imageUrl : null,
          'imgBBUrl': imgBBUrl.isNotEmpty ? imgBBUrl : null,
          'timestamp': Timestamp.now(),
        });

        // Add message to the chat subcollection within the messaging document (newChatDocId)
        await firestore
            .collection('messaging')
            .doc(newChatDocId)
            .collection('chats')
            .add({
          'senderId': widget.currentUserId,
          'recipientId': widget.recipientUserId,
          'message': messageText,
          'imageUrl': imageUrl.isNotEmpty ? imageUrl : null,
          'imgBBUrl': imgBBUrl.isNotEmpty ? imgBBUrl : null,
          'timestamp': Timestamp.now(),
        });

        // Clear the message input field after sending
        _messageController.clear();
        setState(() {
          _imageBytes = null; // Clear image after sending
        });
      } catch (e) {
        print('Error sending message: $e');
      }
    }
  }

  Future<String> uploadImageToFirebaseStorage(
      Uint8List imageBytes, String mimeType) async {
    try {
      String fileExtension = getFileExtension(mimeType);
      String fileName =
          '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final firebase_storage.Reference storageReference = firebase_storage
          .FirebaseStorage.instance
          .ref()
          .child('chat_images')
          .child(fileName);

      final firebase_storage.UploadTask uploadTask = storageReference.putData(
        imageBytes,
        firebase_storage.SettableMetadata(contentType: mimeType),
      );
      await uploadTask;
      final String downloadUrl = await storageReference.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return ''; // Handle error case
    }
  }

  String getFileExtension(String mimeType) {
    switch (mimeType) {
      case 'image/jpeg':
        return 'jpg';
      case 'image/png':
        return 'png';
      case 'image/gif':
        return 'gif';
      default:
        return 'jpg'; // Default to jpg if mime type is unknown
    }
  }

  Future<String> uploadImageToImgBB(Uint8List imageBytes) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload'),
        body: {
          'key':
              'ec6b28964b1a73b40629fa53d69435f6', // Replace with your ImgBB API key
          'image': base64Encode(imageBytes),
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        return responseBody['data']['url'];
      } else {
        print(
            'Failed to upload image to ImgBB. Status code: ${response.statusCode}');
        return ''; // Handle error case
      }
    } catch (e) {
      print('Error uploading image to ImgBB: $e');
      return ''; // Handle error case
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = Uint8List.fromList(bytes);
      });
    }
  }

  Future<DocumentSnapshot> _fetchCurrentUser() async {
    try {
      return await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .get();
    } catch (e) {
      print('Error fetching current user: $e');
      throw e;
    }
  }

  Future<String> _fetchUsername(String userId) async {
    try {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      return userSnapshot.exists ? userSnapshot['username'] ?? '' : '';
    } catch (e) {
      print('Error fetching username: $e');
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.recipientUserId)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text('Loading...');
            }
            if (snapshot.hasError) {
              return Text('Error');
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Text('Chat');
            }
            String username = snapshot.data!['username'];
            return Text(username.isNotEmpty ? username : 'Chat');
          },
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
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messaging')
                  .doc(chatDocId)
                  .collection('chats')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No messages yet.'));
                }

                List<DocumentSnapshot> messages = snapshot.data!.docs;
                return Column(
                  children: [
                    Expanded(
                        child: ListView.builder(
                      controller: _scrollController, // Attach scroll controller
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        Map<String, dynamic> message =
                            messages[index].data() as Map<String, dynamic>;

                        bool isMe = message['senderId'] == widget.currentUserId;
                        String otherUserId =
                            isMe ? message['recipientId'] : message['senderId'];
                        String currentUserId =
                            FirebaseAuth.instance.currentUser?.uid ?? '';

                        // Fetch the other user's details
                        Future<DocumentSnapshot> otherUserSnapshot =
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(otherUserId)
                                .get();
                        Future<DocumentSnapshot> currentUserSnapshot =
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(currentUserId)
                                .get();

                        return FutureBuilder(
                          future: Future.wait(
                              [currentUserSnapshot, otherUserSnapshot]),
                          builder: (context,
                              AsyncSnapshot<List<DocumentSnapshot>> snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return SizedBox
                                  .shrink(); // Placeholder while loading
                            }

                            if (snapshot.hasError) {
                              return Center(
                                  child: Text('Error fetching user data.'));
                            }

                            if (!snapshot.hasData ||
                                snapshot.data!.length != 2 ||
                                !snapshot.data![0].exists ||
                                !snapshot.data![1].exists) {
                              return SizedBox
                                  .shrink(); // Handle error or data not found
                            }

                            DocumentSnapshot currentUserData =
                                snapshot.data![0];

                            String currentUserPhotoUrl =
                                currentUserData['photoUrl'];

                            DocumentSnapshot otherUserData = snapshot.data![1];
                            String otherUserName = otherUserData['username'];
                            String otherUserPhotoUrl =
                                otherUserData['photoUrl'];

                            Timestamp timestamp =
                                message['timestamp'] ?? Timestamp.now();
                            DateTime dateTime = timestamp.toDate();
                            String formattedDate =
                                DateFormat.yMMMd().add_jm().format(dateTime);

                            return GestureDetector(
                              onTap: () {
                                // Handle tapping on the message text (if needed)
                              },
                              child: Align(
                                alignment: isMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 8.0),
                                  child: Column(
                                    crossAxisAlignment: isMe
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: isMe
                                            ? MainAxisAlignment.end
                                            : MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (!isMe)
                                            CircleAvatar(
                                              backgroundImage: NetworkImage(
                                                  otherUserPhotoUrl),
                                            ),
                                          SizedBox(width: 8.0),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: isMe
                                                  ? CrossAxisAlignment.end
                                                  : CrossAxisAlignment.start,
                                              children: [
                                                if (!isMe)
                                                  Text(
                                                    otherUserName,
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                if (message['message'] !=
                                                        null &&
                                                    message['message']
                                                        .toString()
                                                        .isNotEmpty)
                                                  Container(
                                                    padding:
                                                        EdgeInsets.all(10.0),
                                                    decoration: BoxDecoration(
                                                      color: isMe
                                                          ? Color.fromARGB(255,
                                                              227, 227, 164)
                                                          : const Color
                                                              .fromARGB(255,
                                                              230, 230, 230),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8.0),
                                                    ),
                                                    child: Text(
                                                      message['message'],
                                                      style: TextStyle(
                                                        color: isMe
                                                            ? Colors.black
                                                            : Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                if (message['imgBBUrl'] !=
                                                        null &&
                                                    message['imgBBUrl']
                                                        .toString()
                                                        .isNotEmpty)
                                                  InkWell(
                                                    onTap: () async {
                                                      String url =
                                                          message['imgBBUrl'];
                                                      if (await canLaunch(
                                                          url)) {
                                                        await launch(url);
                                                      } else {
                                                        throw 'Could not launch $url';
                                                      }
                                                    },
                                                    child: Container(
                                                      width: 200,
                                                      height: 200,
                                                      child: Image.network(
                                                          message['imgBBUrl']),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: 8.0),
                                          if (isMe)
                                            CircleAvatar(
                                              backgroundImage: NetworkImage(
                                                  currentUserPhotoUrl),
                                            ),
                                        ],
                                      ),
                                      SizedBox(
                                          height:
                                              4.0), // Spacer between message content and date
                                      Align(
                                        alignment: isMe
                                            ? Alignment.centerRight
                                            : Alignment.centerLeft,
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                              right: isMe ? 50.0 : 0.0,
                                              left: isMe ? 0.0 : 50.0),
                                          child: Text(
                                            formattedDate,
                                            style: TextStyle(
                                              fontSize: 12.0,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    )),

                    // Floating Scroll to Bottom Button
                    GestureDetector(
                      onTap: () {
                        _scrollController.animateTo(
                          0.0,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      },
                      child: Icon(Icons.arrow_downward,
                          size: 30, // Adjust the size of the icon as needed
                          color: Color.fromARGB(255, 136, 136, 94)),
                    )
                  ],
                );
              },
            ),
          ),

          Divider(height: 1.0),
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: _buildMessageComposer(),
          ),
          if (_imageBytes != null) _buildImagePreview(), // Added image preview
        ],
      ),
    );
  }

  Widget _buildMessageComposer() {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).colorScheme.secondary),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.image),
              onPressed: _pickImage,
              color: Color.fromARGB(
                  255, 136, 136, 94), // Change icon color to green
            ),
            Flexible(
              child: TextField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration.collapsed(
                  hintText: 'Send a message...',
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send),
              onPressed: _sendMessage,
              color: Color.fromARGB(
                  255, 136, 136, 94), // Change icon color to green
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Row(
      children: [
        SizedBox(width: 8.0),
        Container(
          width: 50.0,
          height: 50.0,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Stack(
            children: [
              Image.memory(
                _imageBytes!,
                width: 50.0,
                height: 50.0,
                fit: BoxFit.cover,
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: Icon(Icons.cancel),
                  onPressed: () {
                    setState(() {
                      _imageBytes = null;
                    });
                  },
                  color: Colors.brown[900],
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 8.0),
      ],
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
