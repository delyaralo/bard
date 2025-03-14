// lib/Admin/AddItem.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class AdditionsPage extends StatefulWidget {
  @override
  _AdditionsPageState createState() => _AdditionsPageState();
}

class _AdditionsPageState extends State<AdditionsPage> {
  // مفاتيح التحكم في الحقول
  final _formKey = GlobalKey<FormState>();

  // الحقول النصية الأساسية
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productDescriptionController =
  TextEditingController();
  final TextEditingController _highPriceController = TextEditingController();

  // الحقول الجديدة المطلوبة
  final TextEditingController _productSpecificationsController =
  TextEditingController(); // مواصفات المنتج
  final TextEditingController _productSizeController = TextEditingController(); // حجم المنتج
  final TextEditingController _productColorController =
  TextEditingController(); // لون المنتج
  final TextEditingController _manufacturerController =
  TextEditingController(); // منشئ المنتج

  // العملة الافتراضية
  String? _selectedCurrency = "\$";

  // التصنيف الرئيسي والفرعي
  String? _selectedMainCategory;
  String? _selectedSubCategory;

  // لإدارة الصورة الرئيسية + 6 صور إضافية
  File? _mainImage;
  List<File?> _productImages = [null, null, null, null, null, null];

  // للتحكم في الطرازات (Variants)
  bool _hasVariants = false;
  List<TextEditingController> _variantControllers = [];

  // مؤشر التحميل
  bool _isUploading = false;

  /// اختيار صورة من المعرض
  Future<void> _pickImage(int index) async {
    final pickedFile =
    await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (index == 0) {
          // الصورة الرئيسية
          _mainImage = File(pickedFile.path);
        } else {
          // الصور الإضافية
          _productImages[index - 1] = File(pickedFile.path);
        }
      });
    }
  }

  /// إضافة حقل Variant جديد
  void _addVariantController() {
    setState(() {
      _variantControllers.add(TextEditingController());
    });
  }

  /// إزالة حقل Variant
  void _removeVariantController(int index) {
    setState(() {
      _variantControllers[index].dispose();
      _variantControllers.removeAt(index);
    });
  }

  /// رفع الصورة إلى Supabase
  Future<String> _uploadImage(File image) async {
    final supabase = Supabase.instance.client;
    final fileBytes = await image.readAsBytes();

    // بناء اسم فريد للملف
    final fileName =
        'product-images/${DateTime.now().millisecondsSinceEpoch}_${path.basename(image.path)}';

    try {
      // رفع البيانات
      await supabase.storage
          .from('product-images') // اسم الباكت Bucket
          .uploadBinary(fileName, fileBytes);

      // الحصول على الرابط العام
      final publicUrl =
      supabase.storage.from('product-images').getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      throw Exception('حدث خطأ أثناء رفع الصورة: $e');
    }
  }

  /// إضافة المنتج إلى Firestore
  Future<void> _addProduct() async {
    // التحقق من صحة الحقول
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // التحقق من التصنيف الرئيسي
    if (_selectedMainCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يرجى اختيار التصنيف الرئيسي للمنتج!')),
      );
      return;
    }

    // التحقق من الصورة الرئيسية
    if (_mainImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يرجى إضافة الصورة الرئيسية للمنتج!')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // 1) رفع الصورة الرئيسية
      String mainImageUrl = await _uploadImage(_mainImage!);

      // 2) رفع الصور الإضافية
      List<String> productImagesUrls = [];
      for (var image in _productImages) {
        if (image != null) {
          final url = await _uploadImage(image);
          productImagesUrls.add(url);
        }
      }

      // 3) جمع الطرازات إذا تم تفعيلها
      List<String> variants = [];
      if (_hasVariants) {
        for (var controller in _variantControllers) {
          String variantText = controller.text.trim();
          if (variantText.isNotEmpty) {
            variants.add(variantText);
          }
        }
      }

      // 4) تحويل السعر العالي بضربه في 1000
      final double highPriceValue =
          (double.tryParse(_highPriceController.text.trim()) ?? 0.0) * 1000;

      // 5) إذا لم يُدخل حقل المنشئ، نستخدم "مباشر"
      final String manufacturer = _manufacturerController.text.trim().isEmpty
          ? "مباشر"
          : _manufacturerController.text.trim();

      // 6) حفظ في Firestore
      await FirebaseFirestore.instance.collection('products').add({
        'name': _productNameController.text.trim(),
        'description': _productDescriptionController.text.trim(),
        'highPrice': highPriceValue,
        'currency': _selectedCurrency,
        'productSpecifications': _productSpecificationsController.text.trim(),
        'productSize': _productSizeController.text.trim(),
        'productColor': _productColorController.text.trim(),
        'manufacturer': manufacturer,
        'mainCategoryId': _selectedMainCategory,
        'subCategoryId': _selectedSubCategory,
        'mainImageUrl': mainImageUrl,
        'productImagesUrls': productImagesUrls,
        'variants': variants,
        'uploadTime': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إضافة المنتج بنجاح!')),
      );

      // 7) مسح الحقول
      _clearFields();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء إضافة المنتج: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  /// إعادة تعيين الحقول بعد الحفظ
  void _clearFields() {
    _productNameController.clear();
    _productDescriptionController.clear();
    _highPriceController.clear();
    _productSpecificationsController.clear();
    _productSizeController.clear();
    _productColorController.clear();
    _manufacturerController.clear();

    _mainImage = null;
    _productImages = [null, null, null, null, null, null];

    _selectedMainCategory = null;
    _selectedSubCategory = null;

    for (var c in _variantControllers) {
      c.dispose();
    }
    _variantControllers.clear();
    _hasVariants = false;

    setState(() {});
  }

  /// Dropdown للتصنيف الرئيسي
  Widget _buildMainCategoryDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('categories').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        return DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'اختر التصنيف الرئيسي',
            border: OutlineInputBorder(),
            labelStyle: TextStyle(color: Colors.blueAccent),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blueAccent, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blueAccent, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          value: _selectedMainCategory,
          onChanged: (value) {
            setState(() {
              _selectedMainCategory = value;
              _selectedSubCategory = null;
            });
          },
          validator: (value) =>
          value == null ? 'يرجى اختيار التصنيف الرئيسي' : null,
          items: snapshot.data!.docs.map((doc) {
            return DropdownMenuItem<String>(
              value: doc.id,
              child: Text(doc['name']),
            );
          }).toList(),
        );
      },
    );
  }

  /// Dropdown للتصنيف الفرعي
  Widget _buildSubCategoryDropdown() {
    if (_selectedMainCategory == null) {
      // في حال لم يُحدد تصنيف رئيسي بعد
      return Container();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('categories')
          .doc(_selectedMainCategory)
          .collection('subcategories')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        return DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'اختر التصنيف الفرعي',
            border: OutlineInputBorder(),
            labelStyle: TextStyle(color: Colors.blueAccent),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blueAccent, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blueAccent, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          value: _selectedSubCategory,
          onChanged: (value) {
            setState(() {
              _selectedSubCategory = value;
            });
          },
          validator: (value) =>
          value == null ? 'يرجى اختيار التصنيف الفرعي' : null,
          items: snapshot.data!.docs.map((doc) {
            return DropdownMenuItem<String>(
              value: doc.id,
              child: Text(doc['name']),
            );
          }).toList(),
        );
      },
    );
  }

  /// حقل نصي عام
  Widget _buildTextField(
      TextEditingController controller,
      String labelText, {
        TextInputType keyboardType = TextInputType.text,
        String? suffix,
      }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        suffixText: suffix,
        labelStyle: TextStyle(color: Colors.blueAccent),
        border: OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blueAccent, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blueAccent, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      keyboardType: keyboardType,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'يرجى إدخال $labelText';
        }
        if (labelText == 'السعر العالي' &&
            double.tryParse(value.trim()) == null) {
          return 'يرجى إدخال رقم صالح للسعر';
        }
        return null;
      },
    );
  }

  /// Dropdown لاختيار العملة
  Widget _buildCurrencyDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'اختر العملة',
        border: OutlineInputBorder(),
        labelStyle: TextStyle(color: Colors.blueAccent),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blueAccent, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blueAccent, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      value: _selectedCurrency,
      onChanged: (value) {
        setState(() {
          _selectedCurrency = value;
        });
      },
      items: [
        DropdownMenuItem(
          value: '\$',
          child: Text('\$'),
        ),
        DropdownMenuItem(
          value: "IQD",
          child: Text("IQD"),
        ),
      ],
      validator: (value) => value == null ? 'يرجى اختيار العملة' : null,
    );
  }

  /// عرض الصور الإضافية
  Widget _buildAdditionalImages() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(_productImages.length, (index) {
        return GestureDetector(
          onTap: () => _pickImage(index + 1),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
              image: _productImages[index] != null
                  ? DecorationImage(
                image: FileImage(_productImages[index]!),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: _productImages[index] == null
                ? Icon(Icons.add_photo_alternate, color: Colors.grey[700])
                : null,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'إضافة منتج',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.white],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // التصنيف الرئيسي
                      _buildMainCategoryDropdown(),
                      SizedBox(height: 20),

                      // التصنيف الفرعي
                      _buildSubCategoryDropdown(),
                      SizedBox(height: 20),

                      // اسم المنتج
                      _buildTextField(_productNameController, 'اسم المنتج'),
                      SizedBox(height: 20),

                      // وصف المنتج
                      _buildTextField(
                          _productDescriptionController, 'وصف المنتج'),
                      SizedBox(height: 20),

                      // مواصفات المنتج
                      _buildTextField(_productSpecificationsController,
                          'مواصفات المنتج'),
                      SizedBox(height: 20),

                      // حجم المنتج
                      _buildTextField(_productSizeController, 'حجم المنتج'),
                      SizedBox(height: 20),

                      // لون المنتج
                      _buildTextField(_productColorController, 'لون المنتج'),
                      SizedBox(height: 20),

                      // منشئ المنتج
                      _buildTextField(_manufacturerController, 'منشئ المنتج'),
                      SizedBox(height: 20),

                      // اختيار العملة
                      _buildCurrencyDropdown(),
                      SizedBox(height: 20),

                      // السعر العالي
                      _buildTextField(
                        _highPriceController,
                        'السعر العالي',
                        keyboardType: TextInputType.number,
                        suffix: ".000",
                      ),
                      SizedBox(height: 20),

                      // Checkbox لإضافة الطرازات
                      CheckboxListTile(
                        title: Text(
                          'إضافة طرازات أو ألوان',
                          style: GoogleFonts.cairo(fontSize: 16),
                        ),
                        value: _hasVariants,
                        onChanged: (bool? value) {
                          setState(() {
                            _hasVariants = value ?? false;
                            if (!_hasVariants) {
                              for (var c in _variantControllers) {
                                c.dispose();
                              }
                              _variantControllers.clear();
                            }
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),

                      // قائمة حقول الطرازات
                      if (_hasVariants)
                        Column(
                          children: [
                            ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: _variantControllers.length,
                              itemBuilder: (context, index) {
                                return Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _variantControllers[index],
                                        decoration: InputDecoration(
                                          labelText:
                                          'إدخال الطراز ${index + 1}',
                                          border: OutlineInputBorder(),
                                          labelStyle: TextStyle(
                                              color: Colors.blueAccent),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.blueAccent,
                                                width: 2),
                                            borderRadius:
                                            BorderRadius.circular(12),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.blueAccent,
                                                width: 2),
                                            borderRadius:
                                            BorderRadius.circular(12),
                                          ),
                                        ),
                                        validator: (value) {
                                          if (_hasVariants &&
                                              (value == null ||
                                                  value.trim().isEmpty)) {
                                            return 'يرجى إدخال الطراز';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.remove_circle,
                                          color: Colors.redAccent),
                                      onPressed: () =>
                                          _removeVariantController(index),
                                    ),
                                  ],
                                );
                              },
                            ),
                            SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: _addVariantController,
                              icon: Icon(Icons.add),
                              label: Text(
                                'إضافة طراز جديد',
                                style: GoogleFonts.cairo(fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),

                      SizedBox(height: 20),

                      // الصورة الرئيسية
                      Center(
                        child: GestureDetector(
                          onTap: () => _pickImage(0),
                          child: _mainImage == null
                              ? Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Icon(Icons.add_photo_alternate,
                                size: 100, color: Colors.grey[700]),
                          )
                              : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _mainImage!,
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),

                      // الصور الإضافية
                      Text(
                        'الصور الإضافية:',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      _buildAdditionalImages(),

                      SizedBox(height: 30),

                      // زر إضافة المنتج
                      Center(
                        child: ElevatedButton(
                          onPressed: _isUploading ? null : _addProduct,
                          child: _isUploading
                              ? SpinKitCircle(
                            color: Colors.white,
                            size: 24.0,
                          )
                              : Text(
                            'إضافة المنتج',
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: EdgeInsets.symmetric(
                                horizontal: 50, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
