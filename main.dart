import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'review_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkTheme = false;

  void toggleTheme() {
    setState(() {
      isDarkTheme = !isDarkTheme;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Map and Reviews Demo',
      theme: isDarkTheme ? ThemeData.dark() : ThemeData.light(),
      home: MapScreen(onToggleTheme: toggleTheme, isDarkTheme: isDarkTheme),
    );
  }
}

class MapScreen extends StatefulWidget {
  final Function onToggleTheme;
  final bool isDarkTheme;

  const MapScreen({Key? key, required this.onToggleTheme, required this.isDarkTheme}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _controller;
  static const LatLng _center = LatLng(53.6884, 23.8258);
  LatLng _currentPosition = _center;
  Marker? _userMarker;
  Marker? _customLocationMarker;
  List<Marker> _additionalMarkers = []; // добавлен список для дополнительных маркеров
  final List<Map<String, dynamic>> _reviews = [];

  Future<void> _setMapStyle() async {
    final style = widget.isDarkTheme
        ? await rootBundle.loadString('assets/dark_map_style.json')
        : await rootBundle.loadString('assets/light_map_style.json');
    _controller?.setMapStyle(style);
  }

  BitmapDescriptor? customIcon;

void _onMapCreated(GoogleMapController controller) async {
  _controller = controller;
  
  // Загрузите кастомную иконку
  customIcon = await BitmapDescriptor.fromAssetImage(
    const ImageConfiguration(size: Size(32, 32)), 
    'assets/icn.png',
  );
    // Создаем основной и дополнительные маркеры
   _customLocationMarker = Marker(
  markerId: const MarkerId("marker_1"),
  position: const LatLng(53.677034, 23.823495),
   icon: customIcon ?? BitmapDescriptor.defaultMarker, 
  infoWindow: const InfoWindow(title: "Старый замок"),
  onTap: () => _showReviewWidget("marker_1", "Старый замок"), // Передаем заголовок
);

    _additionalMarkers = [
      Marker(
        markerId: const MarkerId("marker_2"),
        position: const LatLng(53.684173, 23.839701),
   icon: customIcon ?? BitmapDescriptor.defaultMarker, 
        infoWindow: const InfoWindow(title: "Дом-музей Э.Ожешко"),
        onTap: () => _showReviewWidget("marker_2", "Дом-музей Э.Ожешко"),
      ),
      Marker(
        markerId: const MarkerId("marker_3"),
        position: const LatLng(53.675364, 23.827657),
   icon: customIcon ?? BitmapDescriptor.defaultMarker, 
        infoWindow: const InfoWindow(title: "Драмтеатр"),
        onTap: () => _showReviewWidget("marker_3","Драмтеатр"),
      ),
      Marker(
        markerId: const MarkerId("marker_4"),
        position: const LatLng(53.677858, 23.824846),
   icon: customIcon ?? BitmapDescriptor.defaultMarker, 
        infoWindow: const InfoWindow(title: "Каланча"),
        onTap: () => _showReviewWidget("marker_4", "Каланча"),
      ),
      Marker(
        markerId: const MarkerId("marker_5"),
        position: const LatLng(53.677744, 23.825630),
   icon: customIcon ?? BitmapDescriptor.defaultMarker, 
        infoWindow: const InfoWindow(title: "Музей религии"),
        onTap: () => _showReviewWidget("marker_5", "Музей религии"),
      ),
      Marker(
        markerId: const MarkerId("marker_6"),
        position: const LatLng(53.680867, 23.816608),
   icon: customIcon ?? BitmapDescriptor.defaultMarker, 
        infoWindow: const InfoWindow(title: "Стела 850-летия Гродно"),
        onTap: () => _showReviewWidget("marker_6", "Стела 850-летия Гродно"),
      ),

      
    ];
    setState(() {});
  }

  void _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition();
    _currentPosition = LatLng(position.latitude, position.longitude);

    setState(() {
      _userMarker = Marker(
        markerId: const MarkerId("user_location"),
        position: _currentPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: "Вы здесь"),
      );
    });

    _controller?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _currentPosition, zoom: 15),
      ),
    );
  }

void _showReviewWidget(String markerId, String title) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return ReviewWidget(
        markerId: markerId,
        title: title, // Передаем название
        onRatingChanged: (rating) {
          setState(() {});
        },
        onReviewSubmitted: (reviewText, List<File> images, rating) {
          setState(() {
            // Добавляем отзыв и привязываем его к маркеру
            _reviews.add({
              'markerId': markerId,  // Сохраняем id маркера
              'review': reviewText,
              'images': images,
              'rating': rating,
            });
          });
        },
      );
    },
  );
}

void _openDrawer() {
  final reviewedMarkers = _reviews.map((review) => review['markerId']).toSet();
  final reviewedMarkersList = [
    if (_userMarker != null && reviewedMarkers.contains("user_location")) _userMarker!,
    if (_customLocationMarker != null && reviewedMarkers.contains("marker_1")) _customLocationMarker!,
    ..._additionalMarkers.where((marker) => reviewedMarkers.contains(marker.markerId.value)),
  ];

  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Мои отзывы", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ...reviewedMarkersList.map((marker) {
            final review = _reviews.firstWhere(
              (rev) => rev['markerId'] == marker.markerId.value,
              orElse: () => {'markerId': marker.markerId.value, 'review': '', 'rating': 0, 'images': []},
            );
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Место: ${marker.infoWindow.title}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text("Оценка: ${review['rating']} звезд", style: const TextStyle(fontSize: 14)),
                  Text("Отзыв: ${review['review']}", style: const TextStyle(fontSize: 14)),
                  if (review['images'] != null && review['images'].isNotEmpty)
                    Image.file(
                      review['images'][0],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _confirmDelete(marker.markerId.value);
                    },
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      );
    },
  );
}

void _confirmDelete(String markerId) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Подтверждение удаления"),
        content: const Text("Вы уверены, что хотите удалить этот отзыв?"),
        actions: <Widget>[
          // Кнопка "Отмена"
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Закрыть диалог, если пользователь отменяет
            },
            child: const Text("Отмена"),
          ),
          // Кнопка "Удалить"
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Закрыть диалог
              Navigator.of(context).pop();
              _deleteReview(markerId); // Удалить отзыв
            },
            child: const Text("Удалить", style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    },
  );
}

void _deleteReview(String markerId) {
  setState(() {
    _reviews.removeWhere((review) => review['markerId'] == markerId); // Удаляем отзыв из списка
  });
  // Логика удаления из базы данных, если нужно
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Достопримечательности'),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkTheme ? Icons.wb_sunny : Icons.nightlight_round),
            onPressed: () => widget.onToggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _openDrawer,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: _center,
              zoom: 12,
            ),
            markers: {
              if (_userMarker != null) _userMarker!,
              if (_customLocationMarker != null) _customLocationMarker!,
              ..._additionalMarkers, // добавляем дополнительные маркеры на карту
            },
          ),
          Positioned(
            bottom: 120,
            right: 10,
            child: FloatingActionButton(
              onPressed: _getCurrentLocation,
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}
