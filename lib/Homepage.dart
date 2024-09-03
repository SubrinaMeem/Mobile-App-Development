import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/post_crud/edit_post.dart';
import 'package:project/post_fetch/post_with_user.dart';

import 'package:project/update_profile.dart';
import 'package:project/post_crud/add_post.dart';
import 'package:project/post_list.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:project/notification.dart'; // Make sure to import MessagingPage if not imported
import 'package:project/message/messaging.dart'; // Import MessagingPage
import 'package:app_bar_with_search_switch/app_bar_with_search_switch.dart';

import 'route_observer/route_observer.dart';

class Homepage extends StatefulWidget {
  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> with RouteAware {
  int _selectedIndex = 0;
  int _selectedOption =
      0; // 0 for Worldwide, 1 for Your Community, 2 for Your Posts
  String? _photoUrl;
  String? _userName;
  String? _userId;
  TextEditingController _locationController = TextEditingController();
  bool _isSearching = false;
  bool _hasUnreadNotifications = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _checkUnreadNotifications();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute) {
      routeObserver.subscribe(this, modalRoute);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _locationController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    setState(() {});
  }

  Future<void> _loadUserInfo() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userId = user.uid;
      try {
        DocumentSnapshot<Map<String, dynamic>> snapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (snapshot.exists) {
          Map<String, dynamic>? data = snapshot.data();
          setState(() {
            _photoUrl = data?['photoUrl'];
            _userName = data?['username'];
          });
        } else {
          print("User document does not exist.");
        }
      } catch (e) {
        print("Error loading user info: $e");
      }
    }
  }

  void _checkUnreadNotifications() {
    // Listen to changes in notifications collection for the current user
    FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: _userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _hasUnreadNotifications = snapshot.docs.isNotEmpty;
      });
    });
  }

  void _handleProfileTap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UpdateProfile()),
    );
  }

  void _handleLogout() {
    FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  void _navigateToAddPostPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddPostPage()),
    );
    setState(() {});
  }

  void _navigateToEditPostPage(PostWithUser post, String postId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPostPage(post: post, postId: postId),
      ),
    );
    setState(() {});
  }

  void _onNavBarTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (_selectedIndex == 2) {
      // Navigate to MessagingPage when Message icon is tapped
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => MessagingPage(currentUserId: _userId!)),
      );
    }
  }

  void _storeLocation(String location) async {
    try {
      List<String> locationParts = location.toLowerCase().split(RegExp(r'\s+'));
      await FirebaseFirestore.instance.collection('searchedLocations').add({
        'location': locationParts,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _locationController.clear();
    } catch (e) {
      print("Error storing location: $e");
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _locationController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWithSearchSwitch(
        onChanged: (text) {
          // Handle search text changes here if needed
        },
        appBarBuilder: (context) {
          return AppBar(
            title: _isSearching
                ? Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _locationController,
                          decoration: InputDecoration(
                            hintText: 'Search by Location',
                            border: InputBorder.none,
                          ),
                          onSubmitted: (value) {
                            setState(() {
                              // Perform search logic here
                            });
                          },
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _isSearching = false;
                            _locationController.clear();
                          });
                        },
                      ),
                    ],
                  )
                : Center(child: Text('FoundIt!')),
            actions: [
              IconButton(
                icon: Icon(Icons.search),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _locationController.clear();
                    }
                  });
                },
              ),
            ],
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
          );
        },
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(255, 223, 223, 152),
                    Color.fromARGB(255, 250, 246, 207)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_photoUrl != null)
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(_photoUrl!),
                    )
                  else
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: AssetImage('assets/images/avatar.png'),
                    ),
                  SizedBox(height: 10),
                  Text(
                    'Welcome, ${_userName ?? 'User'}',
                    style: TextStyle(
                      color: Colors.brown[900],
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('My Profile'),
              onTap: _handleProfileTap,
            ),
            ListTile(
              leading: Icon(Icons.post_add),
              title: Text('Add Post'),
              onTap: _navigateToAddPostPage,
            ),
            ListTile(
              leading: Icon(Icons.notifications),
              title: Row(
                children: [
                  Text('Notifications'),
                  if (_hasUnreadNotifications)
                    Text(
                      ' (New)',
                      style: TextStyle(
                        color: Colors.red,
                      ),
                    ),
                ],
              ),
              onTap: () async {
                if (_hasUnreadNotifications) {
                  try {
                    // Update all unread notifications to read
                    QuerySnapshot unreadNotifications = await FirebaseFirestore
                        .instance
                        .collection('notifications')
                        .where('userId', isEqualTo: _userId)
                        .where('read', isEqualTo: false)
                        .get();

                    for (DocumentSnapshot doc in unreadNotifications.docs) {
                      await doc.reference.update({'read': true});
                    }

                    setState(() {
                      _hasUnreadNotifications = false;
                    });

                    // Navigate to notifications page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => NotificationPage()),
                    );
                  } catch (e) {
                    print('Error updating notification status: $e');
                  }
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NotificationPage()),
                  );
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: _handleLogout,
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedOption = 0;
                    });
                  },
                  child: Text(
                    'Worldwide',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: _selectedOption == 0
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: _selectedOption == 0
                          ? Colors.brown[900]
                          : Color.fromARGB(255, 94, 88, 33),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedOption = 1;
                    });
                  },
                  child: Text(
                    'Your Community',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: _selectedOption == 1
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: _selectedOption == 1
                          ? Colors.brown[900]
                          : Color.fromARGB(255, 94, 88, 33),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedIndex == 0
                ? PostList(
                    filterOption: _selectedOption,
                    locationQuery: _locationController.text.isEmpty
                        ? null
                        : _locationController.text,
                  )
                : PostList(
                    filterOption: 2,
                    locationQuery: null,
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 250, 246, 207),
              Color.fromARGB(255, 223, 223, 152)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SalomonBottomBar(
          currentIndex: _selectedIndex,
          onTap: _onNavBarTapped,
          items: [
            SalomonBottomBarItem(
              icon: Icon(Icons.home, color: Colors.black),
              title: Text("Home", style: TextStyle(color: Colors.black)),
              selectedColor: Colors.red,
            ),
            SalomonBottomBarItem(
              icon: Icon(Icons.post_add, color: Colors.black),
              title: Text("My Posts", style: TextStyle(color: Colors.black)),
              selectedColor: Colors.teal,
            ),
            SalomonBottomBarItem(
              icon: Icon(Icons.message, color: Colors.black),
              title: Text("Message", style: TextStyle(color: Colors.black)),
              selectedColor: Colors.indigo,
            ),
          ],
        ),
      ),
    );
  }
}
