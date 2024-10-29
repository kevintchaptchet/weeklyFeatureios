// lib/screens/CreateChallengeScreen.dart

import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

// Import your provider for image selection
import '../Viewmodels/take_or_select_file.dart';

class CreateChallengeScreen extends ConsumerStatefulWidget {
  @override
  _CreateChallengeScreenState createState() => _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends ConsumerState<CreateChallengeScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _criteriaController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();

  // Define a consistent padding value
  final double _padding = 16.0;

  // Track the selected start date
  DateTime? _selectedStartDate;

  @override
  void dispose() {
    _criteriaController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access the image state using Riverpod provider
    final selectedImage = ref.watch(takeOrSelectPictureProvider);

    return Scaffold(
      // Apply a gradient background
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purpleAccent, Colors.blueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: GestureDetector(
            // Dismiss keyboard when tapping outside
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(_padding),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Title
                    Text(
                      'Create Challenge',
                      style: GoogleFonts.roboto(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 8.0,
                            color: Colors.black26,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: _padding),
                    // Image Picker Section
                    GestureDetector(
                      onTap: () => _showImagePicker(context),
                      child: Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              image: selectedImage != null
                                  ? DecorationImage(
                                image: FileImage(selectedImage),
                                fit: BoxFit.cover,
                              )
                                  : null,
                            ),
                            child: selectedImage == null
                                ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.camera_alt,
                                    color: Colors.white70,
                                    size: 50,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Tap to select a background image',
                                    style: GoogleFonts.roboto(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                                : null,
                          ),
                          if (selectedImage != null)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () {
                                  ref.read(takeOrSelectPictureProvider.notifier).resetImage();
                                },
                                child: CircleAvatar(
                                  backgroundColor: Colors.black54,
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: _padding),
                    // Criteria Input
                    _buildInputField(
                      controller: _criteriaController,
                      label: 'Criteria',
                      hint: 'Enter challenge criteria',
                      icon: Icons.list_alt,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter criteria';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: _padding),
                    // Start Date Picker
                    _buildDatePicker(
                      controller: _startDateController,
                      label: 'Start Date',
                      hint: 'Select Start Date',
                      isStartDate: true,
                    ),
                    SizedBox(height: _padding),
                    // End Date Picker
                    _buildDatePicker(
                      controller: _endDateController,
                      label: 'End Date',
                      hint: 'Select End Date',
                      isStartDate: false,
                    ),
                    SizedBox(height: _padding),
                    // Tag Input
                    _buildInputField(
                      controller: _tagController,
                      label: 'Tag',
                      hint: 'Enter a tag',
                      icon: Icons.tag,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a tag';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: _padding * 1.5),
                    // Create Challenge Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _createChallenge(selectedImage);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.greenAccent,
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                        ),
                        child: Text(
                          'Create Challenge',
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build input fields with consistent styling
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.roboto(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70),
        labelText: label,
        labelStyle: GoogleFonts.roboto(color: Colors.white70),
        hintText: hint,
        hintStyle: GoogleFonts.roboto(color: Colors.white54),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white54),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white70),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.redAccent),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      validator: validator,
    );
  }

  // Helper method to build date picker fields with consistent styling
  Widget _buildDatePicker({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isStartDate,
  }) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.roboto(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.calendar_today, color: Colors.white70),
        labelText: label,
        labelStyle: GoogleFonts.roboto(color: Colors.white70),
        hintText: hint,
        hintStyle: GoogleFonts.roboto(color: Colors.white54),
        suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white54),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white70),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.redAccent),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      readOnly: true,
      onTap: () async {
        DateTime initialDate = isStartDate
            ? (_selectedStartDate ?? DateTime.now())
            : (_selectedStartDate != null
            ? _selectedStartDate!.add(Duration(days: 1))
            : DateTime.now().add(Duration(days: 1)));

        DateTime firstDate = isStartDate ? DateTime.now() : (_selectedStartDate != null ? _selectedStartDate!.add(Duration(days: 1)) : DateTime.now().add(Duration(days: 1)));
        DateTime lastDate = isStartDate
            ? DateTime.now().add(Duration(days: 365)) // For start date, allow up to a year in the future
            : (_selectedStartDate != null
            ? _selectedStartDate!.add(Duration(days: 70000)) // End date can be up to one week after start date
            : DateTime.now().add(Duration(days: 70000)));

        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: firstDate,
          lastDate: lastDate,
          builder: (context, child) {
            return Theme(
              data: ThemeData.light().copyWith(
                colorScheme: ColorScheme.light(
                  primary: Colors.blueAccent, // header background color
                  onPrimary: Colors.white, // header text color
                  onSurface: Colors.black, // body text color
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blueAccent, // button text color
                  ),
                ),
              ),
              child: child!,
            );
          },
        );

        if (pickedDate != null) {
          setState(() {
            controller.text = DateFormat('yyyy-MM-dd').format(pickedDate);
            if (isStartDate) {
              _selectedStartDate = pickedDate;
              // Clear the end date if it's beyond the new maximum
              if (_endDateController.text.isNotEmpty) {
                DateTime endDate = DateFormat('yyyy-MM-dd').parse(_endDateController.text);
                if (endDate.isAfter(pickedDate.add(Duration(days: 7)))) {
                  _endDateController.clear();
                }
              }
            }
          });
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a ${label.toLowerCase()}';
        }

        if (!isStartDate) {
          // Additional validation for end date
          if (_selectedStartDate != null) {
            DateTime endDate = DateFormat('yyyy-MM-dd').parse(value);
            DateTime maxEndDate = _selectedStartDate!.add(Duration(days: 7));
            if (endDate.isAfter(maxEndDate)) {
              return 'End Date cannot be more than one week after Start Date';
            }
          }
        }

        return null;
      },
    );
  }

  // Method to show image picker options (select from gallery or take a picture)
  void _showImagePicker(BuildContext context) {
    final selectedImage = ref.watch(takeOrSelectPictureProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white.withOpacity(0.9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Select Image Source',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 16),
                ListTile(
                  leading: Icon(Icons.photo_library, color: Colors.blueAccent),
                  title: Text(
                    'Gallery',
                    style: GoogleFonts.roboto(
                      color: Colors.black87,
                    ),
                  ),
                  onTap: () {
                    ref.read(takeOrSelectPictureProvider.notifier).selectImageFromGallery();
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.camera_alt, color: Colors.blueAccent),
                  title: Text(
                    'Camera',
                    style: GoogleFonts.roboto(
                      color: Colors.black87,
                    ),
                  ),
                  onTap: () {
                    ref.read(takeOrSelectPictureProvider.notifier).takePicture();
                    Navigator.of(context).pop();
                  },
                ),
                if (selectedImage != null)
                  ListTile(
                    leading: Icon(Icons.delete, color: Colors.redAccent),
                    title: Text(
                      'Remove Image',
                      style: GoogleFonts.roboto(
                        color: Colors.black87,
                      ),
                    ),
                    onTap: () {
                      ref.read(takeOrSelectPictureProvider.notifier).resetImage();
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _createChallenge(File? backgroundImage) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Parse the dates from the controllers
        DateTime startDate = DateFormat('yyyy-MM-dd').parse(_startDateController.text);
        DateTime endDate = DateFormat('yyyy-MM-dd').parse(_endDateController.text);

        // Validate that endDate is after startDate
        if (endDate.isBefore(startDate)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('End Date must be after Start Date')),
          );
          return;
        }

        // Validate that the challenge duration does not exceed one week
        if (endDate.difference(startDate).inDays > 7) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Challenge duration cannot exceed one week')),
          );
          return;
        }

        final challengeData = {
          'uid': user.uid,
          'criteria': _criteriaController.text,
          'startDate': Timestamp.fromDate(startDate),
          'endDate': Timestamp.fromDate(endDate),
          'tag': _tagController.text,
          'createdAt': FieldValue.serverTimestamp(),
          'numberOfParticipants': 0,
          'numberOfVoters': 0,
          'ranking': [],
        };

        // Show a loading indicator while creating the challenge
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => Center(child: CircularProgressIndicator()),
        );

        // Create a new document in Firestore and get the document reference (with auto-generated id)
        DocumentReference ChallengeDocRefUser = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('challenge_created')
            .add(challengeData);

        DocumentReference challengeDocRef = await FirebaseFirestore.instance
            .collection('challenge')
            .add(challengeData);

        // Get the generated document ID
        String challengeId = challengeDocRef.id;

        // Update the challenge document with the generated id
        await challengeDocRef.update({'id': challengeId});

        // Upload the background image if one is selected
        if (backgroundImage != null) {
          final imageUrl = await _uploadImage(challengeId, backgroundImage);
          await challengeDocRef.update({'imageURL': imageUrl});
          await ChallengeDocRefUser.update({'imageURL': imageUrl});
        }

        // Dismiss the loading indicator
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Challenge Created Successfully')),
        );

        // Clear the form fields and image selection
        _criteriaController.clear();
        _startDateController.clear();
        _endDateController.clear();
        _tagController.clear();
        ref.read(takeOrSelectPictureProvider.notifier).resetImage();
        setState(() {
          _selectedStartDate = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No user is signed in')),
        );
      }
    } catch (e) {
      // Dismiss the loading indicator if an error occurs
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating challenge: $e')),
      );
    }
  }

  // Method to upload the image to Firebase Storage and get its download URL
  Future<String> _uploadImage(String challengeId, File image) async {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('challenge_backgrounds/$challengeId/${DateTime.now().millisecondsSinceEpoch}');
    final uploadTask = storageRef.putFile(image);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }
}
