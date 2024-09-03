import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'homepage.dart';

class UpdateProfile extends StatefulWidget {
  @override
  _UpdateProfileState createState() => _UpdateProfileState();
}

class _UpdateProfileState extends State<UpdateProfile> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  String? _photoUrl;
  String? _selectedCountry;
  bool _isUpdating = false;

  final List<String> _avatarUrls = List.generate(
    10,
    (index) => 'https://robohash.org/example@example.com/$index',
  );

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot<Map<String, dynamic>> snapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        Map<String, dynamic>? data = snapshot.data();
        if (data != null) {
          _usernameController.text = data['username'] ?? '';
          _locationController.text = data['location'] ?? '';
          setState(() {
            _photoUrl = data['photoUrl'];
            _selectedCountry = data['country'];
          });
        }
      } catch (e) {
        print("Error loading profile: $e");
      }
    }
  }

  Future<void> _updateProfile() async {
    setState(() {
      _isUpdating = true;
    });
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'username': _usernameController.text,
          'location': _locationController.text,
          'country': _selectedCountry,
          'photoUrl': _photoUrl,
        });
        _showProfileUpdatedDialog();
      } catch (e) {
        print("Error updating profile: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile. Please try again.'),
          ),
        );
      } finally {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  void _showProfileUpdatedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Profile Updated'),
          content: Text('Your profile has been updated successfully!'),
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

  void _selectAvatar(String url) {
    setState(() {
      _photoUrl = url;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Update Profile',
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: <Widget>[
            Text(
              'Select an Avatar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
                childAspectRatio: 1.0,
              ),
              itemCount: _avatarUrls.length,
              itemBuilder: (BuildContext context, int index) {
                return GestureDetector(
                  onTap: () => _selectAvatar(_avatarUrls[index]),
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(_avatarUrls[index]),
                    child: _photoUrl == _avatarUrls[index]
                        ? Icon(Icons.check_circle, color: Colors.green)
                        : null,
                  ),
                );
              },
            ),
            SizedBox(height: 32),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 1.0),
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 1.0),
                ),
              ),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCountry,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCountry = newValue;
                });
              },
              items: <String>[
                'Afghanistan',
                'Armenia',
                'Azerbaijan',
                'Bahrain',
                'Bangladesh',
                'Bhutan',
                'Brunei',
                'Cambodia',
                'China',
                'Cyprus',
                'Georgia',
                'India',
                'Indonesia',
                'Iran',
                'Iraq',
                'Israel',
                'Japan',
                'Jordan',
                'Kazakhstan',
                'Kuwait',
                'Kyrgyzstan',
                'Laos',
                'Lebanon',
                'Malaysia',
                'Maldives',
                'Mongolia',
                'Myanmar (Burma)',
                'Nepal',
                'North Korea',
                'Oman',
                'Pakistan',
                'Palestine',
                'Philippines',
                'Qatar',
                'Saudi Arabia',
                'Singapore',
                'South Korea',
                'Sri Lanka',
                'Syria',
                'Taiwan',
                'Tajikistan',
                'Thailand',
                'Timor-Leste',
                'Turkey',
                'Turkmenistan',
                'United Arab Emirates',
                'Uzbekistan',
                'Vietnam',
                'Yemen',
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              decoration: InputDecoration(
                labelText: 'Country',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 1.0),
                ),
              ),
            ),
            SizedBox(height: 32),
            GestureDetector(
              onTap: _isUpdating ? null : _updateProfile,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: _isUpdating
                      ? Colors.grey
                      : Color.fromARGB(255, 227, 227, 164),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: _isUpdating
                      ? CircularProgressIndicator()
                      : Text(
                          'Update Profile',
                          style: TextStyle(
                            color: Colors.brown[900],
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            DrawerHeader(
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.brown[900],
                  fontSize: 18,
                ),
              ),
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
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Homepage()),
                );
              },
            ),
            // Add more ListTile items as needed
          ],
        ),
      ),
    );
  }
}
