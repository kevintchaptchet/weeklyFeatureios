// Participate.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

// Import the new ImageResultPage
import '../Models/imageResultPage.dart'; // Adjust the path accordingly

class Participate extends StatefulWidget {
  final String challengeId; // The ID of the challenge the user is participating in

  Participate({required this.challengeId});

  @override
  _ParticipateState createState() => _ParticipateState();
}

class _ParticipateState extends State<Participate> {
  File? _image;
  final picker = ImagePicker();
  bool _loading = false;
  String _criteria = ''; // Store the challenge criteria

  @override
  void initState() {
    super.initState();
    _fetchChallengeCriteria();
  }

  // Fetch the criteria of the challenge from Firestore
  Future<void> _fetchChallengeCriteria() async {
    try {
      DocumentSnapshot challengeDoc = await FirebaseFirestore.instance
          .collection('challenge')
          .doc(widget.challengeId)
          .get();

      setState(() {
        _criteria = challengeDoc.get('criteria') ?? 'No criteria available';
      });
    } catch (e) {
      print('Error fetching challenge criteria: $e');
      setState(() {
        _criteria = 'No criteria available';
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });
  }

  Future<void> _confirmImage() async {
    if (_image != null) {
      try {
        setState(() {
          _loading = true;
        });

        // Get current user
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('User not logged in');
        }

        // Fetch user's UL (Upload Lefts) from Firestore
        final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        int ul = userDoc.get('ul') ?? 0;

        // Check if user has enough UL
        if (ul <= 0) {
          // If UL is not positive, prompt to buy more UL
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'You do not have enough UL. Please purchase more to participate.')),
          );
          setState(() {
            _loading = false;
          });
          return;
        }

        // Step 1: Upload the image to Firebase Storage and get the URL
        final imageUrl = await _uploadImageToFirebase(_image!);

        // Step 2: Analyze the image using Gemini API
        final note = await _getGeminiImageAnalysis(_image!);

        // Validate the note
        double? rating = double.tryParse(note);
        if (rating == null || rating < 0.1 || rating > 10.0) {
          // Show retry dialog instead of throwing an exception
          _showRetryDialog();
          setState(() {
            _loading = false;
          });
          return;
        }

        // Step 3: Add the image URL and note to Firestore
        await _saveToFirestore(imageUrl, rating);

        // Step 4: Decrement the user's UL by 1
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'ul': FieldValue.increment(-1),
        });

        setState(() {
          _loading = false;
        });

        // Navigate to the ImageResultPage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageResultPage(
              imageUrl: imageUrl,
              rating: rating,
              criteria: _criteria,
            ),
          ),
        );
      } catch (e) {
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No image selected!')),
      );
    }
  }

  // Upload image to Firebase Storage
  Future<String> _uploadImageToFirebase(File image) async {
    final storageRef = FirebaseStorage.instance.ref().child(
        'challenge_images/${widget.challengeId}/${DateTime.now().millisecondsSinceEpoch}');
    final uploadTask = storageRef.putFile(image);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  // Analyze the image using Gemini's API and get the note
  Future<String> _getGeminiImageAnalysis(File imageFile) async {
    final imageBytes = await imageFile.readAsBytes();

    // Build the prompt using the challenge criteria
    String prompt =
        "Analyze this image based on the following criteria: $_criteria. Provide a rating from 0.1 to 10.0, give number only. be extremely strict";

    // Use Gemini API to analyze the image and provide a note
    final response = await Gemini.instance.textAndImage(
      text: prompt,
      images: [imageBytes],
    );

    // Extract text from the response
    String rawResponse =
        response?.content?.parts?.map((part) => part.text).join(' ') ?? "";

    // Use regex to extract the first occurrence of a number between 0.1 and 10.0
    RegExp regex = RegExp(r'\b([0-9]\.[0-9]|10\.0)\b');
    Match? match = regex.firstMatch(rawResponse);

    if (match != null) {
      return match.group(1) ?? "0.0";
    } else {
      print('Failed to extract rating from Gemini response: $rawResponse');
      return "0.0";
    }
  }

  // Save the uploaded image information to Firestore
  Future<void> _saveToFirestore(String imageUrl, double noteValue) async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? '';

    if (userId.isEmpty) {
      throw Exception('User not logged in');
    }

    // Get a reference to Firestore
    final firestore = FirebaseFirestore.instance;

    // Generate a single uploadId to be used across all collections
    String uploadId = firestore.collection('uploads').doc().id;

    // Initialize a batch
    WriteBatch batch = firestore.batch();

    // Reference to 'uploads' collection
    DocumentReference uploadsRef = firestore.collection('uploads').doc(uploadId);

    // Reference to 'challenge/<challengeId>/images' subcollection
    DocumentReference challengeImagesRef = firestore
        .collection('challenge')
        .doc(widget.challengeId)
        .collection('images')
        .doc(uploadId);

    // Reference to 'users/<userId>/images' subcollection
    DocumentReference userImagesRef =
    firestore.collection('users').doc(userId).collection('images').doc(uploadId);

    // Reference to 'users/<userId>/challenge_participating' subcollection
    DocumentReference userChallengeParticipatingRef =
    firestore
        .collection('users')
        .doc(userId)
        .collection('challenge_participating')
        .doc(widget.challengeId);

    // Data to be saved for image uploads
    Map<String, dynamic> imageData = {
      'id': uploadId, // Include the uploadId within the document
      'userId': userId,
      'challengeId': widget.challengeId,
      'imageURL': imageUrl,
      'uploadedAt': FieldValue.serverTimestamp(),
      'note': noteValue,
      'originalNote': noteValue, // Initialize originalNote
      'voteCount': 0, // Initialize vote count
      'totalVoteValue': 0.0, // Initialize total vote value
      'likes': 0, // Initialize like count
    };

    // Data to be saved for challenge participating
    Map<String, dynamic> challengeParticipatingData = {
      'challengeId': widget.challengeId,
      'joinedAt': FieldValue.serverTimestamp(),
    };

    // Add operations to the batch
    batch.set(uploadsRef, imageData);
    batch.set(challengeImagesRef, imageData);
    batch.set(userImagesRef, imageData);
    batch.set(userChallengeParticipatingRef, challengeParticipatingData,
        SetOptions(merge: true));

    // Increment the images count in the challenge document
    DocumentReference challengeDocRef =
    firestore.collection('challenge').doc(widget.challengeId);
    batch.update(challengeDocRef, {
      'images': FieldValue.increment(1),
    });

    // Commit the batch
    await batch.commit();
  }

  // Function to show the retry dialog
  void _showRetryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Analysis Failed'),
          content: Text('We couldn\'t analyze your image properly. Please try again.'),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text('Try Again', style: TextStyle(color: Colors.blue)),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                // Optionally, you can reset the image or allow the user to pick a new one
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Added a gradient background
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _loading
            ? Center(
          child: CircularProgressIndicator(),
        )
            : SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Display the challenge criteria
                  Text(
                    'Challenge Criteria:',
                    style: GoogleFonts.roboto(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _criteria,
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: 24),
                  // Display selected image or placeholder
                  GestureDetector(
                    onTap: () => _pickImage(ImageSource.gallery),
                    child: Container(
                      height: 300, // Increased height
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white54,
                          width: 2,
                        ),
                      ),
                      child: _image == null
                          ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              size: 80,
                              color: Colors.white54,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Tap to select an image',
                              style: GoogleFonts.roboto(
                                fontSize: 18,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      )
                          : ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.file(
                          _image!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  // Buttons for selecting or taking a photo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: Icon(Icons.photo_library),
                        label: Text('Gallery'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.purpleAccent,
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          textStyle: TextStyle(fontSize: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: Icon(Icons.camera_alt),
                        label: Text('Camera'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.blueAccent,
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          textStyle: TextStyle(fontSize: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  // Confirm button
                  if (_image != null)
                    ElevatedButton(
                      onPressed: _confirmImage,
                      child: Text(
                        'Submit Image',
                        style: TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.greenAccent,
                        padding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        textStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
