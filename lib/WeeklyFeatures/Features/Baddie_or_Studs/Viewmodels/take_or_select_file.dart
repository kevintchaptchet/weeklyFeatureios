// Filename: take_or_select_picture.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

// ViewModel StateNotifier class to manage image selection or capture
class TakeOrSelectPictureViewModel extends StateNotifier<File?> {
  TakeOrSelectPictureViewModel() : super(null);

  // Method to select an image from the gallery
  Future<void> selectImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      state = File(image.path); // Update the state with the selected image file
    }
  }

  // Method to take a picture using the camera
  Future<void> takePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      state = File(image.path); // Update the state with the captured image file
    }
  }

  // Method to reset the selected image
  void resetImage() {
    state = null; // Reset the state to null
  }
}

// Create a StateNotifierProvider for the ViewModel
final takeOrSelectPictureProvider = StateNotifierProvider<TakeOrSelectPictureViewModel, File?>(
      (ref) => TakeOrSelectPictureViewModel(),
);
