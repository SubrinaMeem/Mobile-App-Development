import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:http/http.dart' as http;

class AddPostPage extends StatefulWidget {
  @override
  _AddPostPageState createState() => _AddPostPageState();
}

class _AddPostPageState extends State<AddPostPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  String _title = '';
  String _description = '';
  String _collectingPlace = '';
  String _location = '';
  String _country = '';
  Uint8List? _imageBytes;
  String? _selectedCountry;
  Future<void> _uploadPost() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      try {
        if (_title.isEmpty ||
            _description.isEmpty ||
            _collectingPlace.isEmpty ||
            _location.isEmpty ||
            _selectedCountry == null ||
            _selectedCountry!.isEmpty) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Error'),
              content: Text('Please fill in all required fields.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK'),
                ),
              ],
            ),
          );
          return;
        }

        showDialog(
          context: context,
          builder: (context) => Center(child: CircularProgressIndicator()),
          barrierDismissible: false,
        );

        // Initialize imageUrl and imgBBUrl to empty strings
        String imageUrl = '';
        String imgBBUrl = '';

        // Upload image if _imageBytes is not null
        if (_imageBytes != null) {
          String mimeType = 'image/jpeg';
          imageUrl = await uploadImageToFirebaseStorage(_imageBytes!, mimeType);
          imgBBUrl = await convertImageUrlToImgBB(imageUrl);
        }

        // Prepare data to upload to Firestore
        _country = _selectedCountry ?? '';
        Map<String, dynamic> postData = {
          'userId': user.uid,
          'title': _title,
          'description': _description,
          'collectingPlace': _collectingPlace,
          'location': _location,
          'country': _country,
          'timestamp': Timestamp.now(),
        };

        // Add imageUrl and imgBBUrl to postData if they are not empty
        if (imageUrl.isNotEmpty) {
          postData['imageUrl'] = imageUrl;
        }
        if (imgBBUrl.isNotEmpty) {
          postData['imgBBUrl'] = imgBBUrl;
        }

        // Add the post data to Firestore
        // ignore: unused_local_variable
        DocumentReference postRef =
            await _firestore.collection('posts').add(postData);

        Navigator.pop(context); // Close loading dialog

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Uploaded Successfully'),
            content: Text('Your post has been uploaded successfully.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  setState(() {});
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      } catch (e) {
        print('Error uploading post: $e');
        Navigator.pop(context); // Close loading dialog if an error occurs

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text('Failed to upload post. Please try again later.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
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

  Future<String> uploadImageToFirebaseStorage(
      Uint8List imageBytes, String mimeType) async {
    try {
      String fileExtension = getFileExtension(mimeType);
      String fileName =
          '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final firebase_storage.Reference storageReference = firebase_storage
          .FirebaseStorage.instance
          .ref()
          .child('images')
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

  Future<String> convertImageUrlToImgBB(String imageUrl) async {
    final apiKey =
        'ec6b28964b1a73b40629fa53d69435f6'; // Replace with your actual imgBB API key
    final response = await http.post(
      Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey'),
      body: {
        'image': imageUrl,
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      return responseData['data']['url'];
    } else {
      throw Exception('Failed to upload image to imgBB');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Add Post',
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200.0,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: _imageBytes != null
                        ? Image.memory(
                            _imageBytes!,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: Icon(Icons.camera_alt, size: 50.0),
                            alignment: Alignment.center,
                          ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2.0),
                ),
              ),
              onChanged: (value) => _title = value,
            ),
            SizedBox(height: 16.0),
            TextField(
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2.0),
                ),
              ),
              onChanged: (value) => _description = value,
              maxLines: null, // Allow multiline input
            ),
            SizedBox(height: 16.0),
            TextField(
              decoration: InputDecoration(
                labelText: 'Meeting Place',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2.0),
                ),
              ),
              onChanged: (value) => _collectingPlace = value,
            ),
            SizedBox(height: 16.0),
            TextField(
              decoration: InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2.0),
                ),
              ),
              onChanged: (value) => _location = value,
            ),
            SizedBox(height: 16.0),
            DropdownButtonFormField<String>(
              value: _selectedCountry,
              decoration: InputDecoration(
                labelText: 'Country',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2.0),
                ),
              ),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCountry = newValue!;
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
                'Myanmar',
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
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _uploadPost,
              child: Text('Upload Post'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.brown[900],
                backgroundColor: Color.fromARGB(255, 227, 227, 164),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
