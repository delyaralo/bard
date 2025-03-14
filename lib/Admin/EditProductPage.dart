import 'dart:io'; // لاستيراد File
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // لاستيراد ImagePicker و ImageSource
import 'package:path/path.dart' as p; // استيراد مع alias لتجنب التعارض مع BuildContext
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProductPage extends StatefulWidget {
  final DocumentSnapshot productDoc;

  const EditProductPage({Key? key, required this.productDoc}) : super(key: key);

  @override
  _EditProductPageState createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  // مفاتيح وكنترولر للنموذج
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;

  // متغيرات للتصنيفات والعملة والصورة الجديدة إن وجدت
  String? _selectedCurrency;
  String? _selectedMainCategory;
  String? _selectedSubCategory;
  File? _mainImage;

  // بيانات التصنيفات
  List<Map<String, dynamic>> _mainCategories = [];
  Map<String, List<Map<String, dynamic>>> _subCategories = {};

  // حالات تحميل البيانات ورفع الصورة
  bool _isLoadingCategories = true;
  bool _isUpdating = false; // لمعرفة إن كنا في طور التحديث

  @override
  void initState() {
    super.initState();

    // جلب بيانات المنتج من الوثيقة المستلمة
    final data = widget.productDoc.data() as Map<String, dynamic>;
    _nameController = TextEditingController(text: data['name']);
    _descController = TextEditingController(text: data['description']);
    _priceController = TextEditingController(text: data['highPrice'].toString());
    _selectedCurrency = data['currency'] ?? '\$';
    _selectedMainCategory = data['mainCategoryId']?.toString();
    _selectedSubCategory = data['subCategoryId']?.toString();

    _fetchCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  /// دالة لجلب التصنيفات الرئيسية والفرعية من Firestore
  Future<void> _fetchCategories() async {
    try {
      // جلب التصنيفات الرئيسية
      QuerySnapshot mainCatsSnapshot =
      await FirebaseFirestore.instance.collection('categories').get();

      List<Map<String, dynamic>> mainCats = mainCatsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      // جلب التصنيفات الفرعية لكل تصنيف رئيسي
      Map<String, List<Map<String, dynamic>>> subCats = {};
      for (var cat in mainCats) {
        String catId = cat['id'];
        QuerySnapshot subCatsSnapshot = await FirebaseFirestore.instance
            .collection('categories')
            .doc(catId)
            .collection('subcategories')
            .get();

        List<Map<String, dynamic>> subs = subCatsSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();

        subCats[catId] = subs;
      }

      setState(() {
        _mainCategories = mainCats;
        _subCategories = subCats;
        _isLoadingCategories = false;
      });
    } catch (e) {
      debugPrint("Error fetching categories: $e");
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  /// دالة لرفع الصورة إلى Supabase Storage
  /// تُرجع خريطة تحتوي على رابط الصورة العام ومسارها داخل الباكيت
  Future<Map<String, String>> _uploadMainImage(File image) async {
    final supabaseClient = Supabase.instance.client;
    final fileBytes = await image.readAsBytes();

    // اسم الملف يتضمن مسار product-images وتوقيت التنفيذ واسم الملف الأصلي
    final fileName =
        'product-images/${DateTime.now().millisecondsSinceEpoch}_${p.basename(image.path)}';

    // رفع الملف كـ Binary
    await supabaseClient.storage.from('product-images').uploadBinary(fileName, fileBytes);

    // الحصول على الرابط العام للملف
    final publicUrl = supabaseClient.storage.from('product-images').getPublicUrl(fileName);

    return {'url': publicUrl, 'path': fileName};
  }

  /// دالة اختيار الصورة من المعرض
  Future<void> _pickMainImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _mainImage = File(pickedFile.path);
      });
    }
  }

  /// دالة لحفظ/تحديث المنتج في Firestore
  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUpdating = true;
    });

    final data = widget.productDoc.data() as Map<String, dynamic>;
    String? mainImageUrl = data['mainImageUrl'];
    String? mainImagePath = data['mainImagePath'];

    try {
      // إذا تم اختيار صورة جديدة نقوم برفعها
      if (_mainImage != null) {
        try {
          final result = await _uploadMainImage(_mainImage!);
          mainImageUrl = result['url'];
          mainImagePath = result['path'];
          // يمكنك هنا حذف الصورة السابقة إذا رغبت (باستخدام mainImagePath السابق)
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ في رفع الصورة: $e')),
          );
          setState(() {
            _isUpdating = false;
          });
          return;
        }
      }

      // تحديث بيانات المنتج في Firestore
      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productDoc.id)
          .update({
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'highPrice': double.parse(_priceController.text.trim()),
        'currency': _selectedCurrency,
        'mainCategoryId': _selectedMainCategory,
        'subCategoryId': _selectedSubCategory,
        'mainImageUrl': mainImageUrl,
        'mainImagePath': mainImagePath,
        'updateTime': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث المنتج بنجاح')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء تحديث المنتج: $e')),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  /// ويدجت لحقول الإدخال بتنسيق موحد
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل المنتج'),
      ),
      body: Stack(
        children: [
          // المحتوى الرئيسي
          _isLoadingCategories
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // حقل اسم المنتج
                  _buildTextField(
                    controller: _nameController,
                    label: 'اسم المنتج',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال اسم المنتج';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),

                  // حقل وصف المنتج
                  _buildTextField(
                    controller: _descController,
                    label: 'وصف المنتج',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال وصف المنتج';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),

                  // حقل السعر العالي
                  _buildTextField(
                    controller: _priceController,
                    label: 'السعر العالي',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال السعر';
                      }
                      final double? price = double.tryParse(value);
                      if (price == null) {
                        return 'يرجى إدخال رقم صالح';
                      } else if (price < 0) {
                        return 'لا يمكن أن يكون السعر سالبًا';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),

                  // العملة
                  DropdownButtonFormField<String>(
                    value: _selectedCurrency,
                    decoration: const InputDecoration(
                      labelText: 'العملة',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem<String>(
                        value: '\$',
                        child: Text('\$'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'IQD',
                        child: Text('IQD'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCurrency = value;
                      });
                    },
                    validator: (value) =>
                    value == null ? 'يرجى اختيار العملة' : null,
                  ),
                  const SizedBox(height: 10),

                  // التصنيف الرئيسي
                  DropdownButtonFormField<String>(
                    value: _selectedMainCategory,
                    decoration: const InputDecoration(
                      labelText: 'التصنيف الرئيسي',
                      border: OutlineInputBorder(),
                    ),
                    items: _mainCategories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat['id'].toString(),
                        child: Text(cat['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedMainCategory = value;
                        _selectedSubCategory = null;
                      });
                    },
                    validator: (value) => value == null
                        ? 'يرجى اختيار التصنيف الرئيسي'
                        : null,
                  ),
                  const SizedBox(height: 10),

                  // التصنيف الفرعي
                  DropdownButtonFormField<String>(
                    value: _selectedSubCategory,
                    decoration: const InputDecoration(
                      labelText: 'التصنيف الفرعي',
                      border: OutlineInputBorder(),
                    ),
                    items: _selectedMainCategory != null &&
                        _subCategories[_selectedMainCategory] != null
                        ? _subCategories[_selectedMainCategory]!
                        .map((sub) => DropdownMenuItem<String>(
                      value: sub['id'].toString(),
                      child: Text(sub['name']),
                    ))
                        .toList()
                        : [],
                    onChanged: (value) {
                      setState(() {
                        _selectedSubCategory = value;
                      });
                    },
                    validator: (value) => value == null
                        ? 'يرجى اختيار التصنيف الفرعي'
                        : null,
                  ),
                  const SizedBox(height: 10),

                  // عرض الصورة الرئيسية أو تحديد صورة جديدة
                  GestureDetector(
                    onTap: _pickMainImage,
                    child: _mainImage != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _mainImage!,
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    )
                        : _buildMainImagePlaceholder(context),
                  ),
                  const SizedBox(height: 20),

                  // زر حفظ التعديلات
                  ElevatedButton(
                    onPressed: _isUpdating ? null : _updateProduct,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(150, 45),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    child: _isUpdating
                        ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                        : const Text('حفظ التعديلات'),
                  ),
                ],
              ),
            ),
          ),

          // في حال _isUpdating=true يمكن إضافة أي مؤثرات أخرى إن رغبت
        ],
      ),
    );
  }

  /// عنصر يعرض الصورة الرئيسية الحالية أو أيقونة إضافة في حال لم توجد صورة
  Widget _buildMainImagePlaceholder(BuildContext context) {
    final data = widget.productDoc.data() as Map<String, dynamic>;
    final imageUrl = data['mainImageUrl'] as String?;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          width: 150,
          height: 150,
          fit: BoxFit.cover,
        ),
      );
    } else {
      return Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.add_a_photo,
          color: Colors.grey,
          size: 40,
        ),
      );
    }
  }
}
