// ChallengeRankingPage.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class ChallengeRankingPage extends StatefulWidget {
  final String challengeId;

  ChallengeRankingPage({required this.challengeId});

  @override
  _ChallengeRankingPageState createState() => _ChallengeRankingPageState();
}

class _ChallengeRankingPageState extends State<ChallengeRankingPage> {
  String _selectedSortingOption = 'High to Low Rating';

  // Map of sorting options to their corresponding icons
  final Map<String, IconData> _sortingOptions = {
    'High to Low Rating': Icons.arrow_downward,
    'Low to High Rating': Icons.arrow_upward,
    'Newest First': Icons.new_releases,
    'Oldest First': Icons.history,
  };

  // Pagination variables
  static const int _limit = 20;
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  List<DocumentSnapshot> _documents = [];

  // Function to get images from Firestore with dynamic sorting and pagination
  Stream<List<DocumentSnapshot>> _getChallengeImages() async* {
    if (_hasMore && !_isLoading) {
      _isLoading = true;

      Query query = FirebaseFirestore.instance
          .collection('challenge')
          .doc(widget.challengeId)
          .collection('images');

      switch (_selectedSortingOption) {
        case 'High to Low Rating':
          query = query.orderBy('note', descending: true);
          break;
        case 'Low to High Rating':
          query = query.orderBy('note', descending: false);
          break;
        case 'Newest First':
          query = query.orderBy('uploadedAt', descending: true);
          break;
        case 'Oldest First':
          query = query.orderBy('uploadedAt', descending: false);
          break;
        default:
          query = query.orderBy('note', descending: true);
      }

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!).limit(_limit);
      } else {
        query = query.limit(_limit);
      }

      QuerySnapshot snapshot = await query.get();

      if (snapshot.docs.length < _limit) {
        _hasMore = false;
      }

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        _documents.addAll(snapshot.docs);
      }

      yield _documents;

      _isLoading = false;
    }
  }

  // Function to get the color based on the rating
  Color getRatingColor(double rating) {
    // Normalize the rating to a value between 0 and 1
    double normalizedRating = rating / 10.0;

    // Compute the red and green components
    int red = ((1 - normalizedRating) * 255).toInt();
    int green = (normalizedRating * 255).toInt();

    return Color.fromARGB(255, red, green, 0);
  }

  // Function to show sorting options as icons
  void _showSortingOptions() {
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
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 20,
              runSpacing: 20,
              children: _sortingOptions.entries.map((entry) {
                String option = entry.key;
                IconData icon = entry.value;
                bool isSelected = _selectedSortingOption == option;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSortingOption = option;
                      _documents.clear();
                      _lastDocument = null;
                      _hasMore = true;
                    });
                    Navigator.of(context).pop();
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor:
                        isSelected ? Colors.blueAccent : Colors.grey[300],
                        child: Icon(
                          icon,
                          color: isSelected ? Colors.white : Colors.black87,
                          size: 30,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        option,
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // Function to load more data when reaching the end
  void _loadMore() {
    if (_hasMore && !_isLoading) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            children: [
              // Custom AppBar
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purpleAccent, Colors.blueAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back Button
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    // Title
                    Text(
                      'Challenge Rankings',
                      style: GoogleFonts.roboto(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    // Sorting Icon Button
                    IconButton(
                      icon: Icon(
                        _sortingOptions[_selectedSortingOption],
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: _showSortingOptions,
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: StreamBuilder<List<DocumentSnapshot>>(
                  stream: _getChallengeImages(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error fetching images',
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data!;

                    if (docs.isEmpty) {
                      return Center(
                        child: Text(
                          'No images found for this challenge',
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    return NotificationListener<ScrollNotification>(
                      onNotification: (ScrollNotification scrollInfo) {
                        if (!_isLoading &&
                            _hasMore &&
                            scrollInfo.metrics.pixels ==
                                scrollInfo.metrics.maxScrollExtent) {
                          _loadMore();
                        }
                        return false;
                      },
                      child: ListView.builder(
                        padding: EdgeInsets.all(16.0),
                        itemCount: docs.length + 1,
                        itemBuilder: (context, index) {
                          if (index == docs.length) {
                            return _hasMore
                                ? Center(child: CircularProgressIndicator())
                                : SizedBox.shrink();
                          }

                          final doc = docs[index];
                          final data = doc.data() as Map<String, dynamic>;

                          final imageUrl = data['imageURL'] as String? ?? '';
                          final note = data['note'];
                          final double rating = note is double
                              ? note
                              : double.tryParse(note.toString()) ?? 0.0;
                          final uploadedAt =
                          (data['uploadedAt'] as Timestamp?)?.toDate();

                          // Get the color based on the rating
                          Color ratingColor = getRatingColor(rating);

                          // Assign rank based on the current sorted order
                          int rank = index + 1;

                          return Container(
                            margin: EdgeInsets.only(bottom: 16.0),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              leading: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '#$rank',
                                    style: GoogleFonts.roboto(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                ],
                              ),
                              title: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      imageUrl,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      loadingBuilder:
                                          (context, child, progress) {
                                        if (progress == null) return child;
                                        return Container(
                                          width: 60,
                                          height: 60,
                                          alignment: Alignment.center,
                                          child: CircularProgressIndicator(),
                                        );
                                      },
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          width: 60,
                                          height: 60,
                                          alignment: Alignment.center,
                                          color: Colors.grey[200],
                                          child:
                                          Icon(Icons.broken_image, size: 30),
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.star,
                                                color: ratingColor),
                                            SizedBox(width: 8),
                                            Text(
                                              '${rating.toStringAsFixed(1)} / 10',
                                              style: GoogleFonts.roboto(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: ratingColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Uploaded at: ${uploadedAt != null ? uploadedAt.toLocal().toString().split('.')[0] : 'Unknown'}',
                                          style: GoogleFonts.roboto(
                                            fontSize: 14,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                // Optionally, navigate to a detailed view of the image
                              },
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
