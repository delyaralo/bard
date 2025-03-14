// lib/pages/BannerUploadPage.dart
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
class BannerUploadPage extends StatefulWidget {
  @override
  _BannerUploadPageState createState() => _BannerUploadPageState();
}

class _BannerUploadPageState extends State<BannerUploadPage> {
  File? _imageFile;

  // ✅ التصنيفات
  List<DocumentSnapshot> _mainCategories = [];
  String? _selectedMainCategoryId;
  List<DocumentSnapshot> _subCategories = [];
  String? _selectedSubCategoryId;

  // ✅ قائمة البنرات
  List<Map<String, dynamic>> _banners = [];

  String _title = '';

  @override
  void initState() {
    super.initState();
    _fetchMainCategories();
    _fetchBanners(); // ✅ جلب البنرات عند فتح الصفحة
  }

  /// جلب التصنيفات الرئيسية
  Future<void> _fetchMainCategories() async {
    try {
      QuerySnapshot snapshot =
      await FirebaseFirestore.instance.collection('categories').get();
      setState(() {
        _mainCategories = snapshot.docs;
      });
    } catch (e) {
      print('Error fetching main categories: $e');
    }
  }

  /// جلب التصنيفات الفرعية للتصنيف الرئيسي المختار
  Future<void> _fetchSubCategories(String mainCategoryId) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .doc(mainCategoryId)
          .collection('subcategories')
          .get();

      setState(() {
        _subCategories = snapshot.docs;
      });
    } catch (e) {
      print('Error fetching sub categories: $e');
    }
  }

  /// اختيار صورة من المعرض
  Future<void> _pickImage() async {
    final pickedFile =
    await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }
  Future<String> _uploadImage(File image) async {
    final supabase = Supabase.instance.client;
    final fileBytes = await image.readAsBytes();
    final fileName =
        'product-images/${DateTime.now().millisecondsSinceEpoch}_${path.basename(image.path)}';

    try {
      await supabase.storage.from('product-images').uploadBinary(fileName, fileBytes);
      final publicUrl = supabase.storage.from('product-images').getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      throw Exception('حدث خطأ أثناء رفع الصورة: $e');
    }
  }
  /// رفع البنر إلى Firebase
  Future<void> _uploadBanner() async {
    if (_imageFile == null ||
        _title.isEmpty ||
        _selectedMainCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'يرجى اختيار صورة، إدخال عنوان، واختيار تصنيف رئيسي على الأقل')),
      );
      return;
    }

    try {
      // ✅ رفع الصورة إلى Supabase Storage
      String imageUrl = await _uploadImage(_imageFile!);

      // ✅ حفظ بيانات البنر في Firestore
      await FirebaseFirestore.instance.collection('banners').add({
        'imageUrl': imageUrl,
        'title': _title,
        'mainCategoryId': _selectedMainCategoryId,
        'subCategoryId': _selectedSubCategoryId ?? '',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم رفع البنر بنجاح!')),
      );

      setState(() {
        _imageFile = null;
        _title = '';
        _selectedMainCategoryId = null;
        _selectedSubCategoryId = null;
        _subCategories = [];
      });

      _fetchBanners();
    } catch (e) {
      print('Error uploading banner: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل في رفع البنر')),
      );
    }
  }

  /// جلب البنرات من Firestore
  Future<void> _fetchBanners() async {
    try {
      QuerySnapshot bannerSnapshot =
      await FirebaseFirestore.instance.collection('banners').get();

      List<Map<String, dynamic>> fetchedBanners =
      bannerSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'imageUrl': data['imageUrl'] ?? '',
          'title': data['title'] ?? '',
          'mainCategoryId': data['mainCategoryId'] ?? '',
          'subCategoryId': data['subCategoryId'] ?? '',
        };
      }).toList();

      setState(() {
        _banners = fetchedBanners;
      });
    } catch (e) {
      debugPrint("Error fetching banners: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل في تحميل البنرات. حاول مرة أخرى.')),
      );
    }
  }
  /// حذف البنر
  Future<void> _deleteBanner(String bannerId, String imageUrl) async {
    try {
      await FirebaseFirestore.instance.collection('banners').doc(bannerId).delete();
      await Supabase.instance.client.storage.from('product-images').remove([imageUrl]);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف البنر بنجاح')),
      );

      _fetchBanners();
    } catch (e) {
      print('Error deleting banner: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل في حذف البنر')),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('رفع بنر'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ✅ عرض صورة المعاينة (إن وجدت)
            if (_imageFile != null)
              Container(
                height: 200,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  image: DecorationImage(
                    image: FileImage(_imageFile!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            // ✅ زر اختيار صورة
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('اختر صورة'),
            ),

            const SizedBox(height: 16),

            // ✅ حقل إدخال العنوان
            TextField(
              decoration: const InputDecoration(
                labelText: 'عنوان البنر',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _title = value;
                });
              },
            ),

            const SizedBox(height: 16),

            // ✅ قائمة منسدلة لاختيار التصنيف الرئيسي
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'التصنيف الرئيسي',
                border: OutlineInputBorder(),
              ),
              value: _selectedMainCategoryId,
              items: _mainCategories.map((doc) {
                return DropdownMenuItem<String>(
                  value: doc.id,
                  child: Text(doc['name'] ?? 'بدون اسم'),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedMainCategoryId = newValue;
                  _selectedSubCategoryId = null; // إعادة ضبط التصنيف الفرعي
                });
                if (newValue != null) {
                  _fetchSubCategories(newValue);
                }
              },
            ),

            const SizedBox(height: 16),

            // ✅ قائمة منسدلة لاختيار التصنيف الفرعي (اختياري)
            if (_subCategories.isNotEmpty)
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'التصنيف الفرعي (اختياري)',
                  border: OutlineInputBorder(),
                ),
                value: _selectedSubCategoryId,
                items: _subCategories.map((doc) {
                  return DropdownMenuItem<String>(
                    value: doc.id,
                    child: Text(doc['name'] ?? 'بدون اسم'),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedSubCategoryId = newValue;
                  });
                },
              ),

            const SizedBox(height: 16),

            // ✅ زر رفع البنر
            ElevatedButton(
              onPressed: _uploadBanner,
              child: const Text('رفع البنر'),
            ),

            const SizedBox(height: 16),

            // ✅ عرض البنرات أسفل الصفحة
            Expanded(
              child: _banners.isEmpty
                  ? const Center(child: Text('لا توجد بنرات مرفوعة بعد'))
                  : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // عدد الأعمدة
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 3 / 2, // نسبة العرض إلى الارتفاع
                ),
                itemCount: _banners.length,
                itemBuilder: (context, index) {
                  final banner = _banners[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    elevation: 5,
                    child: Stack(
                      children: [
                        // ✅ خلفية البنر (الصورة)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16.0),
                          child: CachedNetworkImage(
                            imageUrl: banner['imageUrl'],
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) =>
                            const Icon(Icons.error, color: Colors.red),
                          ),
                        ),
                        // ✅ إظهار عنوان البنر (إن وجد)
                        if ((banner['title'] ?? '').isNotEmpty)
                          Positioned(
                            bottom: 10,
                            left: 10,
                            right: 10,
                            child: Container(
                              color: Colors.black.withOpacity(0.6),
                              padding: const EdgeInsets.all(4),
                              child: Text(
                                banner['title'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        // ✅ زر الحذف
                        Positioned(
                          top: 10,
                          right: 10,
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteBanner(
                              banner['id'],
                              banner['imageUrl'],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
