import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:http/http.dart' as http;
import '../post_fetch/post_with_user.dart';

class EditPostPage extends StatefulWidget {
  final PostWithUser post;
  final String postId;

  EditPostPage({
    Key? key,
    required this.post,
    required this.postId,
  }) : super(key: key);

  @override
  _EditPostPageState createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  late String _title;
  late String _description;
  late String _collectingPlace;
  late String _location;
  late String _country;
  Uint8List? _imageBytes; // Store image bytes for uploading
  String? _imageUrl; // Track the image URL
  String? _imgBBUrl; // Track the imgBB URL
  bool _isUpdating = false; // Track update progress

  List<String> countries = [
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
  ];

  @override
  void initState() {
    super.initState();
    // Initialize state with post data
    _title = widget.post.title;
    _description = widget.post.description;
    _collectingPlace = widget.post.collectingPlace;
    _location = widget.post.location;
    _country = widget.post.country;

    _imgBBUrl = widget.post.imgBBUrl; // Initialize imgBB URL
  }

  Future<void> _updatePost() async {
    setState(() {
      _isUpdating = true; // Show progress indicator
    });

    try {
      // Upload new image if _imageBytes is not null
      if (_imageBytes != null) {
        String mimeType =
            'image/jpeg'; // Example: determine dynamically if needed
        _imageUrl = await uploadImageToFirebaseStorage(_imageBytes!, mimeType);
        _imgBBUrl = await convertImageUrlToImgBB(_imageUrl!);
      }

      // Update post data in Firestore
      await _firestore.collection('posts').doc(widget.post.postId).update({
        'title': _title,
        'description': _description,
        'collectingPlace': _collectingPlace,
        'location': _location,
        'country': _country,
        'imageUrl': _imageUrl,
        'imgBBUrl': _imgBBUrl, // Update imgBB URL
        // Add any other fields you want to update here
      });

      Navigator.pop(context); // Go back to previous page

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Updated Successfully'),
          content: Text('Your post has been updated successfully.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Failed to update post. Please try again later.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      setState(() {
        _isUpdating = false; // Hide progress indicator
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageUrl = null; // Reset imageUrl to null when picking a new image
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Edit Post',
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
            // Display post data for editing
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
                        // ignore: unnecessary_null_comparison
                        : (_imageUrl != null || widget.post.imgBBUrl != null)
                            ? Image.network(
                                _imageUrl ?? widget.post.imgBBUrl,
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
              ),
              onChanged: (value) => _title = value,
              controller: TextEditingController(text: _title),
            ),
            SizedBox(height: 16.0),
            TextField(
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _description = value,
              maxLines: null, // Allow multiline input
              controller: TextEditingController(text: _description),
            ),
            SizedBox(height: 16.0),
            TextField(
              decoration: InputDecoration(
                labelText: 'Meeting Place',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _collectingPlace = value,
              controller: TextEditingController(text: _collectingPlace),
            ),
            SizedBox(height: 16.0),
            TextField(
              decoration: InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _location = value,
              controller: TextEditingController(text: _location),
            ),
            SizedBox(height: 16.0),
            DropdownButtonFormField(
              decoration: InputDecoration(
                labelText: 'Country',
                border: OutlineInputBorder(),
              ),
              value: _country,
              items: countries.map((String country) {
                return DropdownMenuItem<String>(
                  value: country,
                  child: Text(country),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _country = value!;
                });
              },
            ),
            SizedBox(height: 16.0),
            // Add any other fields you want to edit here
            ElevatedButton(
              onPressed: _isUpdating ? null : _updatePost,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.brown[900],
                backgroundColor: Color.fromARGB(255, 227, 227, 164),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: _isUpdating
                  ? CircularProgressIndicator()
                  : Text('Update Post'),
            ),
          ],
        ),
      ),
    );
  }
}
