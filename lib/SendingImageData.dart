import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ImageUploadScreen extends StatefulWidget {
  const ImageUploadScreen({Key? key, required this.products}) : super(key: key);
  final String products;

  @override
  _ImageUploadScreenState createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen> {
  List<File> _images = [];
  final picker = ImagePicker();
  TextEditingController _imageNameController = TextEditingController();

  bool _showTextField = false;

  List<String> _dropDownItems = [
    'Defective Product',
    'Wrong Product',
    'Missing Parts',
    'Product Not as Described',
    'Other',
  ];

  String _selectedReason = 'Defective Product';

  List<String> _selectedProducts = [];

  Future<void> _getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _images.add(File(pickedFile.path));
      });
    }
  }

  Future<void> _uploadImage() async {
    String url = 'http://Santhose:3000/upload';

    String reason = _selectedReason;
    if (_selectedReason == 'Other') {
      reason = _imageNameController.text;
    }

    if (_images.isNotEmpty && reason.isNotEmpty) {
      for (File image in _images) {
        var request = http.MultipartRequest('POST', Uri.parse(url));
        request.fields['reason'] = reason;
        request.files.add(
          await http.MultipartFile.fromPath('images', image.path),
        );

        var response = await request.send();
        if (response.statusCode == 200) {
          var imageURL = await response.stream.bytesToString();
          print("Image URL: $imageURL");
          // Handle success logic here
        } else {
          print("Error uploading the image");
          // Handle error logic here
        }
      }
    } else {
      print("Image or image name is not selected");
      // Handle validation or error logic here
    }
  }

  @override
  void dispose() {
    _imageNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Upload'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                children: List.generate(_images.length, (index) {
                  return Padding(
                    padding: EdgeInsets.all(5.0),
                    child: Image.file(_images[index]),
                  );
                }),
              ),
              SizedBox(height: 20.0),
              DropdownButton<String>(
                value: _selectedReason,
                hint: Text('Select a reason'),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedReason = newValue!;
                    _showTextField = (newValue == 'Other');
                  });
                },
                items: _dropDownItems
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              SizedBox(height: 20.0),
              for (String product in widget.products.split(','))
                CheckboxListTile(
                  title: Text(product.trim()),
                  value: _selectedProducts.contains(product.trim()),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedProducts.add(product.trim());
                      } else {
                        _selectedProducts.remove(product.trim());
                      }
                    });
                  },
                ),
              if (_showTextField)
                TextField(
                  controller: _imageNameController,
                  decoration: InputDecoration(
                    labelText: 'Enter the reason for return',
                  ),
                ),
              SizedBox(height: 20.0),
              GestureDetector(
                onTap: () {
                  _getImage();
                },
                child: Container(
                  height: 50,
                  margin: EdgeInsets.symmetric(horizontal: 50),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: Colors.purple,
                  ),
                  child: Center(
                    child: Text(
                      "Take Photo",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.0),
              GestureDetector(
                onTap: () {
                  Fluttertoast.showToast(
                    msg: 'Product is not Delivered',
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    backgroundColor: Colors.grey[700],
                    textColor: Colors.white,
                    fontSize: 16.0,
                  );

                  insertDeliveryStatusFailed();
                  _uploadImage();
                },
                child: Container(
                  height: 50,
                  margin: EdgeInsets.symmetric(horizontal: 50),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: Colors.purple,
                  ),
                  child: Center(
                    child: Text(
                      "Upload",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> insertDeliveryStatusFailed() async {
    final response = await http.post(
      Uri.parse('http://Santhose:3000/delivery-status'),
      body: {'deliveryStatus': 'No'},
    );

    if (response.statusCode == 200) {
      print('Delivery status inserted successfully.');
    } else {
      print('Failed to insert delivery status: ${response.statusCode}');
    }
  }
}
