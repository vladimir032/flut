import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ReviewWidget extends StatefulWidget {
  final String markerId;
  final String title;
  final Function(int) onRatingChanged;
  final Function(String, List<File>, int) onReviewSubmitted;

  const ReviewWidget({
    Key? key,
    required this.markerId,
    required this.title,
    required this.onRatingChanged,
    required this.onReviewSubmitted,
  }) : super(key: key);

  @override
  _ReviewWidgetState createState() => _ReviewWidgetState();
}

class _ReviewWidgetState extends State<ReviewWidget> {
  int _rating = 0;
  final TextEditingController _reviewController = TextEditingController();
  final List<File> _userImages = [];
  String _description = '';
  List<String> _images = [];

  @override
  void initState() {
    super.initState();
    _initializeMarkerData(widget.markerId);
  }

  void _initializeMarkerData(String markerId) {
    final markerData = _getMarkerData(markerId);
    setState(() {
      _description = markerData['description'] ?? '';
      _images = markerData['images'] ?? [];
    });
  }
  Map<String, dynamic> _getMarkerData(String markerId) {
    const markerData = {
      'marker_1': {
        'description': 'Это красивое место, которое стоит посетить.',
        'images': ['assets/zamok.jpg', 'assets/zamok1.jpg'],
      },
      'marker_2': {
        'description': 'Дом-музей Элизы Ожешко в Гродно.',
        'images': ['assets/ozh.jpg', 'assets/ozh1.jpg'],
      },
      'marker_3': {
        'description': 'Государственный театр, образованный в 1947 году.',
        'images': ['assets/teatr.jpg', 'assets/teatr1.jpg'],
      },
      'marker_4': {
        'description': 'Пожарная каланча — достопримечательность.',
        'images': ['assets/kakancha.jpg', 'assets/kalancha1.jpg'],
      },
      'marker_5': {
        'description': 'Музей истории религии Гродно.',
        'images': ['assets/relig.jpg', 'assets/relig1.jpg'],
      },
      'marker_6': {
        'description': 'Это красивое место, которое стоит посетить.',
        'images': ['assets/stela.jpg', 'assets/stela1.jpg'],
      },
    };
return markerData[markerId] ?? {'description': '', 'images': []};
  }

  void _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _userImages.add(File(pickedFile.path));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      builder: (_, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: [
                Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(
                height: 200,
                child: PageView(
                children: [
                ..._images.map((image) => Padding(
                padding: const EdgeInsets.all(8.0), // Отступы
                child: ClipRRect(
                borderRadius: BorderRadius.circular(12), // Закругленные углы
                child: Image.asset(image, fit: BoxFit.cover),
                ),
               )),
               ..._userImages.map((image) => Padding(
               padding: const EdgeInsets.all(9.0), // Отступы
              child: ClipRRect(
              borderRadius: BorderRadius.circular(12), // Закругленные углы
              child: Image.file(image, fit: BoxFit.cover),
            ),
          )),
    ],
  ),
),
                ElevatedButton(onPressed: _pickImage, child: const Text("Добавить фото")),
                Text(_description, textAlign: TextAlign.center),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(index < _rating ? Icons.star : Icons.star_border, color: Colors.orange),
                      onPressed: () {
                        setState(() => _rating = index + 1);
                        widget.onRatingChanged(_rating);
                      },
                    );
                  }),
                ),
                TextField(
                  controller: _reviewController,
                  decoration: const InputDecoration(labelText: "Ваш отзыв", border: OutlineInputBorder()),
                  maxLines: 3,
                ),
                ElevatedButton(
                  onPressed: () {
                    widget.onReviewSubmitted(_reviewController.text, _userImages, _rating);
                    Navigator.pop(context);
                  },
                  child: const Text("Оставить отзыв"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Marker Review App',
      home: Scaffold(
        appBar: AppBar(title: const Text('Маршрут и отзывы')),
        body: GoogleMap(
          initialCameraPosition: const CameraPosition(target: LatLng(53.679, 23.822), zoom: 15),
          markers: _buildMarkers(context),
        ),
      ),
    );
  }

Set<Marker> _buildMarkers(BuildContext context) {
  const markerData = {
    'marker_1': {'position': LatLng(53.677034, 23.823495), 'title': 'Старый замок'},
    'marker_2': {'position': LatLng(53.684173, 23.839701), 'title': 'Место 1'},
    'marker_3': {'position': LatLng(53.675364, 23.827657), 'title': 'Место 2'},
    'marker_4': {'position': LatLng(53.677858, 23.824846), 'title': 'Место 3'},
    'marker_5': {'position': LatLng(53.677744, 23.825630), 'title': 'Место 4'},
    'marker_6': {'position': LatLng(53.680867, 23.816608), 'title': 'Место 5'},

  };

  return markerData.entries.map((entry) {
    final markerInfo = entry.value as Map<String, dynamic>;
    return Marker(
      markerId: MarkerId(entry.key),
      position: markerInfo['position'] as LatLng,
      infoWindow: InfoWindow(title: markerInfo['title'] as String),
      onTap: () => _showReviewWidget(context, entry.key, markerInfo['title'] as String),
    );
  }).toSet();
}


  void _showReviewWidget(BuildContext context, String markerId, String title) {
    showModalBottomSheet(
      context: context,
      builder: (_) => ReviewWidget(
        markerId: markerId,
        title: title,
        onRatingChanged: (_) {},
        onReviewSubmitted: (reviewText, images, rating) {
          // Сохранение отзыва
        },
      ),
    );
  }
}

void main() => runApp(const MyApp());
