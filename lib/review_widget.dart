import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';



class ReviewWidget extends StatefulWidget {
  final String markerId;
  final String title;
  final Function(int) onRatingChanged;
  final Function(String, List<File>, int) onReviewSubmitted;

//конструктор для передачи полей в виджет
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

//состостояние текущего списка отзывов, рейтинга, описания, картинок
class _ReviewWidgetState extends State<ReviewWidget> {
  int _rating = 0;
  final TextEditingController _reviewController = TextEditingController();
  final List<File> _userImages = [];
  String _description = '';
  List<String> _images = [];


//данные маркера и выгрузка картинок
  @override
  void initState() {
    super.initState();
    _initializeMarkerData(widget.markerId);
    _loadUserImages();
  }

//метод для получения данных markerID и обновление
  void _initializeMarkerData(String markerId) {
    final markerData = _getMarkerData(markerId);
    setState(() {
      _description = markerData['description'] ?? '';
      _images = markerData['images'] ?? [];
    });
  }

//добавление описания и неудаляемых фоток к маркерам
  Map<String, dynamic> _getMarkerData(String markerId) {
    const markerData = {
      'marker_1': {
        'description': 'Старый замок Гродно, построенный в XIV-XV веках, является одной из главных исторических достопримечательностей города. Он был резиденцией польских королей и активно использовался в качестве оборонительного сооружения. Замок, расположенный на живописном холме над рекой Неман, отличается своей архитектурной особенностью и богатой историей.',
        'images': ['assets/zamok.jpg', 'assets/zamok1.jpg'],
      },
      'marker_2': {
        'description': 'Дом-музей Элизы Ожешко посвящен жизни и творчеству польской писательницы Элизы Ожешко, которая провела часть своей жизни в Гродно. Музей рассказывает о её жизни, литературном наследии, а также о культурной атмосфере того времени. Экспозиция включает личные вещи писательницы, рукописи и фотографии.',
        'images': ['assets/ozh.jpg', 'assets/ozh1.jpg'],
      },
      'marker_3': {
        'description': 'Гродненский драматический театр — один из старейших театров в Беларуси. Театр был основан в XIX веке и с тех пор является важным центром культурной жизни города. Здесь проходят спектакли как на белорусском, так и на русском языке, а также различные театральные фестивали и концерты.',
        'images': ['assets/teatr.jpg', 'assets/teatr1.jpg'],
      },
      'marker_4': {
        'description': 'Пожарная каланча Гродно, построенная в начале XX века, представляет собой уникальный архитектурный памятник. Она служила для наблюдения за городом и контроля за возможными пожарами. Сегодня каланча является популярным туристическим объектом с панорамным видом на город и реку Неман.',
        'images': ['assets/kakancha.jpg', 'assets/kalancha1.jpg'],
      },
      'marker_5': {
        'description': 'Музей истории религии в Гродно — уникальная коллекция, рассказывающая о развитии религиозных традиций и культов на территории Беларуси. Здесь представлены экспонаты, связанные с христианством, иудаизмом, исламом, а также различные религиозные артефакты и книги.',
        'images': ['assets/relig.jpg', 'assets/relig1.jpg'],
      },
      'marker_6': {
        'description': 'Стела 850-летия Гродно была установлена в 2011 году в честь юбилея города. Она символизирует долгую историю Гродно и его важное значение в культурной и исторической жизни Беларуси. Стела украшена символами города и выполнена в современном стиле, став одной из ключевых достопримечательностей города.',
        'images': ['assets/stela.jpg', 'assets/stela1.jpg'],
      },
    };
    return markerData[markerId] ?? {'description': '', 'images': []};
  }

  // Сохранение изображений и создание пользовательской папки users для хранения
  Future<String> saveImageToUsersFolder(File image) async {
    final directory = await getApplicationDocumentsDirectory();
    final usersFolder = Directory('${directory.path}/users');

    if (!usersFolder.existsSync()) {
      usersFolder.createSync(recursive: true);
    }

    final fileName = DateTime.now().millisecondsSinceEpoch.toString() + '.jpg'; //уникальное имя 
    final savedImagePath = '${usersFolder.path}/$fileName';

    final savedImage = await image.copy(savedImagePath);

    return savedImage.path;
  }

  // Загрузка изображений из папки "users/"
  Future<void> _loadUserImages() async {
    final directory = await getApplicationDocumentsDirectory();
    final usersFolder = Directory('${directory.path}/users');

    if (usersFolder.existsSync()) {
      final images = usersFolder.listSync().whereType<File>().toList();
      setState(() {
        _userImages.addAll(images);
      });
    }
  }


//сохранение
  void _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final savedImagePath = await saveImageToUsersFolder(File(pickedFile.path));
      setState(() {
        _userImages.add(File(savedImagePath)); // Сохраняем путь к файлу
      });
    }
  }

  // Функция для отображения диалога с действиями
  void _showImageOptionsDialog(File image) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Выберите действие'),
          content: const Text('Удалить изображение?'),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                // Удаление файла
                await image.delete();
                setState(() {
                  _userImages.remove(image);
                });
                Navigator.of(context).pop();
              },
              child: const Text('Удалить'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Отмена'),
            ),
          ],
        );
      },
    );
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
                        padding: const EdgeInsets.all(8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(image, fit: BoxFit.cover),
                        ),
                      )),
                      ..._userImages.map((image) => Padding(
                        padding: const EdgeInsets.all(9.0),
                        child: GestureDetector(
                          onLongPress: () => _showImageOptionsDialog(image), // Обработчик долгого нажатия
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(image, fit: BoxFit.cover),
                          ),
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
