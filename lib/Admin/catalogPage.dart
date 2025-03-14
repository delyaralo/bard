import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
class CreateCategoryPage extends StatefulWidget {
  @override
  _CreateCategoryPageState createState() => _CreateCategoryPageState();
}

class _CreateCategoryPageState extends State<CreateCategoryPage> {
  File? _selectedImage;

  // دالة لاختيار الصورة من المعرض

  // دالة لرفع الصورة إلى Firebase Storage والحصول على رابط التنزيل
  Future<void> _pickImage() async {
    final pickedFile =
    await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
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
  // دالة لإظهار نافذة إضافة تصنيف جديد
  Future<void> _showAddCategoryDialog(BuildContext context, {String? parentId, int level = 0}) async {
    final TextEditingController _categoryNameController = TextEditingController();
    _selectedImage = null;

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("إضافة تصنيف جديد"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(_categoryNameController, 'اسم التصنيف'),
                SizedBox(height: 10),
                _selectedImage == null
                    ? TextButton(
                  onPressed: _pickImage,
                  child: Text("اختر صورة"),
                )
                    : Image.file(_selectedImage!),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text("إلغاء"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("إضافة"),
              onPressed: () async {
                if (_categoryNameController.text.trim().isNotEmpty) {
                  String? imageUrl;
                  if (_selectedImage != null) {
                    imageUrl = await _uploadImage(_selectedImage!);
                  }

                  int order = await _getNewCategoryOrder(parentId);

                  if (parentId == null) {
                    await FirebaseFirestore.instance.collection('categories').add({
                      'name': _categoryNameController.text.trim(),
                      'level': level,
                      'order': order,
                      'imageUrl': imageUrl,
                    });
                  } else {
                    await FirebaseFirestore.instance
                        .collection('categories')
                        .doc(parentId)
                        .collection('subcategories')
                        .add({
                      'name': _categoryNameController.text.trim(),
                      'level': level,
                      'order': order,
                      'imageUrl': imageUrl,
                    });
                  }

                  setState(() {
                    _selectedImage = null;
                  });

                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تم إضافة التصنيف بنجاح!')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // دالة لإظهار نافذة تعديل تصنيف موجود
  Future<void> _showEditCategoryDialog(
      BuildContext context,
      String categoryId,
      String currentName,
      String? currentImageUrl,
      String? parentId,
      ) async {
    final TextEditingController _categoryNameController = TextEditingController(text: currentName);
    _selectedImage = null;

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("تعديل التصنيف"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(_categoryNameController, 'اسم التصنيف'),
                SizedBox(height: 10),
                _selectedImage == null
                    ? currentImageUrl != null
                    ? Column(
                  children: [
                    Image.network(currentImageUrl, height: 100),
                    TextButton(
                      onPressed: _pickImage,
                      child: Text("تغيير الصورة"),
                    ),
                  ],
                )
                    : TextButton(
                  onPressed: _pickImage,
                  child: Text("اختر صورة"),
                )
                    : Image.file(_selectedImage!),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text("إلغاء"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("تعديل"),
              onPressed: () async {
                if (_categoryNameController.text.trim().isNotEmpty) {
                  String? imageUrl = currentImageUrl;

                  if (_selectedImage != null) {
                    imageUrl = await _uploadImage(_selectedImage!);
                  }

                  if (parentId == null) {
                    await FirebaseFirestore.instance.collection('categories').doc(categoryId).update({
                      'name': _categoryNameController.text.trim(),
                      'imageUrl': imageUrl,
                    });
                  } else {
                    await FirebaseFirestore.instance
                        .collection('categories')
                        .doc(parentId)
                        .collection('subcategories')
                        .doc(categoryId)
                        .update({
                      'name': _categoryNameController.text.trim(),
                      'imageUrl': imageUrl,
                    });
                  }

                  setState(() {
                    _selectedImage = null;
                  });

                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تم تعديل التصنيف بنجاح!')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // دالة لحذف تصنيف
  Future<void> _deleteCategory(String collection, String id, {String? parentId}) async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("تأكيد الحذف"),
          content: Text("هل أنت متأكد أنك تريد حذف هذا التصنيف؟"),
          actions: [
            TextButton(
              child: Text("إلغاء"),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text("حذف"),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        if (parentId != null) {
          await FirebaseFirestore.instance
              .collection('categories')
              .doc(parentId)
              .collection('subcategories')
              .doc(id)
              .delete();
        } else {
          await FirebaseFirestore.instance.collection(collection).doc(id).delete();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حذف التصنيف بنجاح!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في حذف التصنيف: $e')),
        );
      }
    }
  }

  // دالة لتحريك التصنيف للأعلى في الترتيب
  Future<void> _moveCategoryUp(String categoryId, String? parentId) async {
    DocumentSnapshot currentCategory;
    if (parentId != null) {
      currentCategory = await FirebaseFirestore.instance
          .collection('categories')
          .doc(parentId)
          .collection('subcategories')
          .doc(categoryId)
          .get();
    } else {
      currentCategory = await FirebaseFirestore.instance.collection('categories').doc(categoryId).get();
    }

    int currentOrder = currentCategory['order'];

    QuerySnapshot snapshot;
    if (parentId != null) {
      snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .doc(parentId)
          .collection('subcategories')
          .where('order', isLessThan: currentOrder)
          .orderBy('order', descending: true)
          .limit(1)
          .get();
    } else {
      snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .where('order', isLessThan: currentOrder)
          .orderBy('order', descending: true)
          .limit(1)
          .get();
    }

    if (snapshot.docs.isNotEmpty) {
      DocumentSnapshot categoryAbove = snapshot.docs.first;
      int aboveOrder = categoryAbove['order'];

      if (parentId != null) {
        await FirebaseFirestore.instance
            .collection('categories')
            .doc(parentId)
            .collection('subcategories')
            .doc(categoryId)
            .update({'order': aboveOrder});
        await FirebaseFirestore.instance
            .collection('categories')
            .doc(parentId)
            .collection('subcategories')
            .doc(categoryAbove.id)
            .update({'order': currentOrder});
      } else {
        await FirebaseFirestore.instance.collection('categories').doc(categoryId).update({'order': aboveOrder});
        await FirebaseFirestore.instance.collection('categories').doc(categoryAbove.id).update({'order': currentOrder});
      }
    }
  }

  // دالة لتحريك التصنيف للأسفل في الترتيب
  Future<void> _moveCategoryDown(String categoryId, String? parentId) async {
    DocumentSnapshot currentCategory;
    if (parentId != null) {
      currentCategory = await FirebaseFirestore.instance
          .collection('categories')
          .doc(parentId)
          .collection('subcategories')
          .doc(categoryId)
          .get();
    } else {
      currentCategory = await FirebaseFirestore.instance.collection('categories').doc(categoryId).get();
    }

    int currentOrder = currentCategory['order'];

    QuerySnapshot snapshot;
    if (parentId != null) {
      snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .doc(parentId)
          .collection('subcategories')
          .where('order', isGreaterThan: currentOrder)
          .orderBy('order')
          .limit(1)
          .get();
    } else {
      snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .where('order', isGreaterThan: currentOrder)
          .orderBy('order')
          .limit(1)
          .get();
    }

    if (snapshot.docs.isNotEmpty) {
      DocumentSnapshot categoryBelow = snapshot.docs.first;
      int belowOrder = categoryBelow['order'];

      if (parentId != null) {
        await FirebaseFirestore.instance
            .collection('categories')
            .doc(parentId)
            .collection('subcategories')
            .doc(categoryId)
            .update({'order': belowOrder});
        await FirebaseFirestore.instance
            .collection('categories')
            .doc(parentId)
            .collection('subcategories')
            .doc(categoryBelow.id)
            .update({'order': currentOrder});
      } else {
        await FirebaseFirestore.instance.collection('categories').doc(categoryId).update({'order': belowOrder});
        await FirebaseFirestore.instance.collection('categories').doc(categoryBelow.id).update({'order': currentOrder});
      }
    }
  }

  // دالة للحصول على ترتيب جديد للتصنيف
  Future<int> _getNewCategoryOrder(String? parentId) async {
    QuerySnapshot snapshot;
    if (parentId == null) {
      snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .orderBy('order', descending: true)
          .limit(1)
          .get();
    } else {
      snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .doc(parentId)
          .collection('subcategories')
          .orderBy('order', descending: true)
          .limit(1)
          .get();
    }

    if (snapshot.docs.isNotEmpty) {
      int currentHighestOrder = snapshot.docs.first['order'] ?? 0;
      return currentHighestOrder + 1;
    }
    return 0;
  }

  // دالة لبناء عنصر التصنيف في القائمة
  Widget _buildCategoryTile(
      String id,
      String name,
      int level,
      BuildContext context, {
        String? parentId,
        String? imageUrl,
      }) {
    return Padding(
      padding: EdgeInsets.only(left: level * 8.0),
      child: ExpansionTile(
        leading: imageUrl != null
            ? Image.network(imageUrl, width: 40, height: 40)
            : Icon(Icons.folder, color: level == 0 ? Colors.orange : Colors.blue),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: Icon(Icons.arrow_upward, color: Colors.blue),
              onPressed: () => _moveCategoryUp(id, parentId),
            ),
            IconButton(
              icon: Icon(Icons.arrow_downward, color: Colors.blue),
              onPressed: () => _moveCategoryDown(id, parentId),
            ),
            IconButton(
              icon: Icon(Icons.edit, color: Colors.orange),
              onPressed: () => _showEditCategoryDialog(context, id, name, imageUrl, parentId),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => _deleteCategory('categories', id, parentId: parentId),
            ),
          ],
        ),
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('categories')
                .doc(id)
                .collection('subcategories')
                .orderBy('order')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return CircularProgressIndicator();
              return Column(
                children: snapshot.data!.docs.map((subDoc) {
                  final data = subDoc.data() as Map<String, dynamic>;
                  int subLevel = data['level'] ?? level + 1;
                  return _buildCategoryTile(
                    subDoc.id,
                    data['name'],
                    subLevel,
                    context,
                    parentId: id,
                    imageUrl: data['imageUrl'],
                  );
                }).toList(),
              );
            },
          ),
          ElevatedButton(
            onPressed: () => _showAddCategoryDialog(context, parentId: id, level: level + 1),
            child: Text('إضافة تصنيف فرعي'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
          ),
        ],
      ),
    );
  }

  // دالة لبناء حقل النص
  Widget _buildTextField(TextEditingController controller, String labelText) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
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
    );
  }

  // بناء واجهة المستخدم للصفحة
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إدارة التصنيفات'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ElevatedButton(
              onPressed: () => _showAddCategoryDialog(context),
              child: Text('إضافة تصنيف رئيسي'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('categories').orderBy('order').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    int level = data['level'] ?? 0;
                    return _buildCategoryTile(
                      doc.id,
                      data['name'],
                      level,
                      context,
                      imageUrl: data['imageUrl'],
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}