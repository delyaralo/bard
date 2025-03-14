import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';


class ImageKitUploadPage extends StatefulWidget {
  const ImageKitUploadPage({Key? key}) : super(key: key);

  @override
  State<ImageKitUploadPage> createState() => _ImageKitUploadPageState();



}



class _ImageKitUploadPageState extends State<ImageKitUploadPage> {
  final ImagePicker _picker = ImagePicker();

  String? uploadedImageUrl;   // للاحتفاظ برابط الصورة بعد رفعها
  bool isUploading = false;   // مؤشر لمعرفة ما إذا كان هناك عملية رفع جارية

  // --------------------------------------------------------------------------
  // 1) دالة لاختيار صورة من معرض الهاتف
  // --------------------------------------------------------------------------
  Future<void> pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);
        // بعد اختيار الصورة، ارفعها إلى ImageKit
        await uploadImageToImageKit(imageFile);
      } else {
        debugPrint("لم يتم اختيار أي صورة.");
      }
    } catch (e) {
      debugPrint("حدث خطأ أثناء اختيار الصورة: $e");
    }
  }

  // --------------------------------------------------------------------------
  // 2) دالة رفع الصورة إلى ImageKit (باستخدام حزمة http)
  // --------------------------------------------------------------------------
  Future<void> uploadImageToImageKit(File imageFile) async {
    setState(() {
      isUploading = true;
    });

    final uri = Uri.parse("https://upload.imagekit.io/api/v1/files/upload");
    final request = http.MultipartRequest('POST', uri);

    // حقول مطلوبة من توثيق ImageKit
    request.fields['publicKey'] = 'public_HfytR0xa+QENJlLIGtsc4GjA20c=';   // استبدلها بمفتاحك العام
    request.fields['fileName'] = 'test_image.jpg';

    // إضافة ملف الصورة
    final fileExtension = imageFile.path.split('.').last.toLowerCase();
    MediaType contentType;
    switch (fileExtension) {
      case 'png':
        contentType = MediaType('image', 'png');
        break;
      case 'jpg':
      case 'jpeg':
        contentType = MediaType('image', 'jpeg');
        break;
      default:
        contentType = MediaType('image', 'jpeg');
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: contentType,
      ),
    );

    try {
      final response = await request.send();
      final responseBody = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        debugPrint("تم رفع الصورة بنجاح: ${responseBody.body}");
        final data = jsonDecode(responseBody.body);

        // عادةً يحتوي على حقل 'url' لرابط الصورة
        setState(() {
          uploadedImageUrl = data['url'];
        });
      } else {
        debugPrint("فشل رفع الصورة. رمز الحالة: ${response.statusCode}");
        debugPrint("الرد: ${responseBody.body}");
      }
    } catch (e) {
      debugPrint("حصل خطأ أثناء الرفع: $e");
    }

    setState(() {
      isUploading = false;
    });
  }

  // --------------------------------------------------------------------------
  // تصميم الواجهة
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload to ImageKit'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // زر اختيار الصورة من المعرض
              ElevatedButton(
                onPressed: pickImageFromGallery,
                child: const Text("اختر صورة من المعرض"),
              ),
              const SizedBox(height: 20),

              // مؤشر الرفع إذا كنا في حالة رفع
              if (isUploading) const CircularProgressIndicator(),

              // عرض رابط الصورة إن تم الرفع بنجاح
              if (uploadedImageUrl != null && !isUploading) ...[
                const SizedBox(height: 20),
                const Text("تم رفع الصورة. رابطها:"),
                const SizedBox(height: 10),
                Text(uploadedImageUrl!),
                const SizedBox(height: 20),
                // عرض الصورة من الرابط
                Image.network(uploadedImageUrl!),
              ]
            ],
          ),
        ),
      ),
    );
  }
}