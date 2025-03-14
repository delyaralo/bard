import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'EditProductPage.dart'; // تأكد من صحة مسار الاستيراد

class ProductsPage extends StatefulWidget {
  const ProductsPage({Key? key}) : super(key: key);

  @override
  _ProductsPageState createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final supabase = Supabase.instance.client;

  // متغيرات البحث والتصفية
  String _searchQuery = "";
  String? _selectedMainCategory;
  String? _selectedSubCategory;

  // بيانات التصنيفات من Firestore
  List<Map<String, dynamic>> _mainCategories = [];
  Map<String, List<Map<String, dynamic>>> _subCategories = {};
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  /// جلب التصنيفات الرئيسية والفرعية من Firestore
  Future<void> _fetchCategories() async {
    try {
      QuerySnapshot mainCatsSnapshot =
      await FirebaseFirestore.instance.collection('categories').get();
      List<Map<String, dynamic>> mainCats = mainCatsSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      Map<String, List<Map<String, dynamic>>> subCats = {};
      for (var cat in mainCats) {
        String catId = cat['id'];
        QuerySnapshot subCatsSnapshot = await FirebaseFirestore.instance
            .collection('categories')
            .doc(catId)
            .collection('subcategories')
            .get();
        List<Map<String, dynamic>> subs = subCatsSnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
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
      print("Error fetching categories: $e");
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  /// دالة حذف المنتج:
  /// - حذف الصور من Supabase Storage (باستخدام المسارات المخزنة).
  /// - حذف وثيقة المنتج من Firestore.
  Future<void> _deleteProduct(DocumentSnapshot productDoc) async {
    final productData = productDoc.data() as Map<String, dynamic>;

    // استرجاع مسار الصورة الرئيسية
    String? mainImagePath = productData['mainImagePath'] as String?;
    // استرجاع مسارات الصور الإضافية (إن وجدت)
    List<dynamic>? additionalImagePaths =
    productData['productImagesPaths'] as List<dynamic>?;

    List<String> pathsToDelete = [];
    if (mainImagePath != null && mainImagePath.isNotEmpty) {
      pathsToDelete.add(mainImagePath);
    }
    if (additionalImagePaths != null) {
      for (var element in additionalImagePaths) {
        if (element is String && element.isNotEmpty) {
          pathsToDelete.add(element);
        }
      }
    }

    try {
      if (pathsToDelete.isNotEmpty) {
        await supabase
            .storage
            .from('product-images') // تأكد من صحة اسم الباكيت في Supabase
            .remove(pathsToDelete);
      }
      await FirebaseFirestore.instance
          .collection('products')
          .doc(productDoc.id)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف المنتج بنجاح')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء حذف المنتج: $e')),
      );
    }
  }

  /// عرض نافذة تأكيد الحذف
  void _confirmDelete(DocumentSnapshot productDoc) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا المنتج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteProduct(productDoc);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// التنقل إلى صفحة تعديل المنتج
  void _editProduct(DocumentSnapshot productDoc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) =>
            EditProductPage(productDoc: productDoc),
      ),
    );
  }

  /// تصفية المنتجات بناءً على البحث والتصنيفات
  List<DocumentSnapshot> _filterProducts(List<DocumentSnapshot> products) {
    return products.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final productName = (data['name'] ?? "").toString().toLowerCase();
      final matchesSearch = productName.contains(_searchQuery.toLowerCase());
      final matchesMainCat = _selectedMainCategory == null ||
          (data['mainCategoryId'] == _selectedMainCategory);
      final matchesSubCat = _selectedSubCategory == null ||
          (data['subCategoryId'] == _selectedSubCategory);
      return matchesSearch && matchesMainCat && matchesSubCat;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المنتجات'),
      ),
      body: Column(
        children: [
          // حقل البحث
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'ابحث عن اسم المنتج',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          // خيارات التصفية (التصنيف الرئيسي والفرعي)
          _isLoadingCategories
              ? const Center(child: CircularProgressIndicator())
              : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                // التصنيف الرئيسي
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'التصنيف الرئيسي',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedMainCategory,
                    items: [
                      const DropdownMenuItem<String>(
                        child: Text('الكل'),
                        value: null,
                      ),
                      ..._mainCategories.map((cat) {
                        return DropdownMenuItem<String>(
                          child: Text(cat['name']),
                          value: cat['id'].toString(),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedMainCategory = value;
                        _selectedSubCategory = null;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // التصنيف الفرعي
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'التصنيف الفرعي',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedSubCategory,
                    items: [
                      const DropdownMenuItem<String>(
                        child: Text('الكل'),
                        value: null,
                      ),
                      if (_selectedMainCategory != null &&
                          _subCategories[_selectedMainCategory] != null)
                        ..._subCategories[_selectedMainCategory]!
                            .map((sub) {
                          return DropdownMenuItem<String>(
                            child: Text(sub['name']),
                            value: sub['id'].toString(),
                          );
                        }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedSubCategory = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // عرض قائمة المنتجات باستخدام GridView مع كاردات أصغر
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('products').snapshots(),
              builder:
                  (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('حدث خطأ: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                List<DocumentSnapshot> products = snapshot.data!.docs;
                products = _filterProducts(products);
                if (products.isEmpty) {
                  return const Center(child: Text('لا توجد منتجات'));
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(8.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // عرض 3 أعمدة لبطاقات أصغر
                    childAspectRatio: 0.65, // تعديل النسبة لتقليل ارتفاع الكارد
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                  ),
                  itemCount: products.length,
                  itemBuilder: (BuildContext context, int index) {
                    final productDoc = products[index];
                    final productData = productDoc.data() as Map<String, dynamic>;
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // صورة المنتج
                          Expanded(
                            flex: 5,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8)),
                              child: productData['mainImageUrl'] != null
                                  ? Image.network(
                                productData['mainImageUrl'],
                                fit: BoxFit.cover,
                              )
                                  : Container(
                                color: Colors.grey,
                                child: const Icon(
                                  Icons.image,
                                  size: 30,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          // معلومات المنتج
                          Expanded(
                            flex: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    productData['name'] ?? 'بدون اسم',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    productData['description'] ?? '',
                                    style: const TextStyle(fontSize: 10),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Spacer(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.blue, size: 18),
                                        onPressed: () => _editProduct(productDoc),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red, size: 18),
                                        onPressed: () => _confirmDelete(productDoc),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
