import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Routes/routes.dart';
import '../Viewmodels/take_or_select_file.dart';
import '../Models/bottomnavigation.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

class BaddiesOrStudsDashboard extends ConsumerStatefulWidget {
  @override
  ConsumerState<BaddiesOrStudsDashboard> createState() =>
      _BaddiesOrStudsDashboardState();
}

class _BaddiesOrStudsDashboardState
    extends ConsumerState<BaddiesOrStudsDashboard> {
  String _geminiOutput = "Waiting for image analysis...";
  bool _loading = false;

  Future<void> _getGeminiImageAnalysis(File imageFile) async {
    setState(() {
      _loading = true;
    });

    try {
      final gemini = Gemini.instance;
      // Send image and text to Gemini for analysis
      final value = await gemini.textAndImage(
        text: "on a scale to chritsmas outfit ", //
        images: [imageFile.readAsBytesSync()], // Read image bytes
      );
      setState(() {
        _geminiOutput = value?.content?.parts?.last.text ?? "No output received.";
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _geminiOutput = "Error occurred: $e";
        _loading = false;
      });
      log('textAndImageInput', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access the selected image file using the ViewModel provider
    final selectedImageFile = ref.watch(takeOrSelectPictureProvider);

    // Reference to the ViewModel to call methods
    final viewModel = ref.read(takeOrSelectPictureProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('Take or Select a Picture'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView( // Wrap the content in SingleChildScrollView to make it scrollable
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (selectedImageFile != null)
                Image.file(
                  selectedImageFile,
                  height: 300,
                  width: 300,
                  fit: BoxFit.cover,
                )
              else
                Text('No image selected or taken'),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await viewModel.selectImageFromGallery();
                  final file = ref.read(takeOrSelectPictureProvider);
                  if (file != null) {
                    // Call Gemini after selecting an image
                    await _getGeminiImageAnalysis(file);
                  }
                },
                child: Text('Select Image from Gallery'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await viewModel.takePicture();
                  final file = ref.read(takeOrSelectPictureProvider);
                  if (file != null) {
                    // Call Gemini after taking a picture
                    await _getGeminiImageAnalysis(file);
                  }
                },
                child: Text('Take a Picture'),
              ),
              if (selectedImageFile != null)
                ElevatedButton(
                  onPressed: () => viewModel.resetImage(),
                  child: Text('Reset Image'),
                ),
              SizedBox(height: 20),
              // Show loading indicator or the Gemini output
              if (_loading) CircularProgressIndicator(),
              if (!_loading)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _geminiOutput,
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
      // Add the BottomNavigation widget at the bottom of the Scaffold
      bottomNavigationBar: BottomNavigation(
        currentIndex: 0, // Set the current index to highlight the active tab (Home in this case)
      ),
    );
  }
}
