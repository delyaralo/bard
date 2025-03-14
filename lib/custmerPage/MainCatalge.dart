import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hive/hive.dart';

import 'custmerPage.dart';
import 'package:bard/custmerPage/Subcatalge.dart'; // تأكد من صحة اسم الملف أو المسار

class MainCategoryPage extends StatefulWidget {
  const MainCategoryPage({Key? key}) : super(key: key);

  @override
  _MainCategoryPageState createState() => _MainCategoryPageState();
}

class _MainCategoryPageState extends State<MainCategoryPage> {
  Box? _categoriesBox;

  @override
  void initState() {
    super.initState();
    _initializeHive();
  }

  Future<void> _initializeHive() async {
    // فتح بوكس لتخزين بيانات التصنيفات
    _categoriesBox = await Hive.openBox('categories');
    setState(() {});
  }

  Future<void> _cacheCategoryData(DocumentSnapshot category) async {
    final categoryId = category.id;
    // إذا لم يكن التصنيف محفوظاً مسبقاً في الكاش، قم بتخزين بياناته
    if (_categoriesBox != null && !_categoriesBox!.containsKey(categoryId)) {
      await _categoriesBox!.put(categoryId, {
        'name': category['name'],
        'imageUrl': category['imageUrl'],
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar بواجهة جذابة
      appBar: AppBar(
        automaticallyImplyLeading: true, // زر الرجوع
        elevation: 4,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xff36D1DC),
                Color(0xff5B86E5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        centerTitle: true,
        title: const Text(
          'التصنيفات الرئيسية',
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 20,
            color: Colors.white,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('categories').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.lightBlue),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('لا توجد تصنيفات رئيسية'),
            );
          }

          final categories = snapshot.data!.docs;

          // تخزين التصنيفات في Hive
          for (var category in categories) {
            _cacheCategoryData(category);
          }

          // عرض التصنيفات باستخدام ListView
          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final categoryData =
              categories[index].data() as Map<String, dynamic>;
              final categoryId = categories[index].id;
              final categoryName = categoryData['name'] ?? 'بدون اسم';
              final imageUrl = categoryData['imageUrl'] ?? '';

              return _buildRectangularCategoryCard(
                categoryId: categoryId,
                categoryName: categoryName,
                imageUrl: imageUrl,
              );
            },
          );
        },
      ),
    );
  }

  /// بطاقة مستطيلة: الصورة على اليمين والاسم على اليسار
  Widget _buildRectangularCategoryCard({
    required String categoryId,
    required String categoryName,
    required String imageUrl,
  }) {
    return GestureDetector(
      onTap: () {
        // الانتقال إلى صفحة التصنيفات الفرعية
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SubCategoryPage(
              mainCategoryId: categoryId,
              categoryName: categoryName,
            ),
          ),
        );
      },
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: SizedBox(
          height: 100, // ارتفاع مناسب للبطاقة المستطيلة
          child: Row(
            children: [
              // عرض اسم التصنيف على اليسار
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    categoryName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blueAccent,
                      fontFamily: 'Amiri',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.start,
                  ),
                ),
              ),
              // عرض صورة التصنيف على اليمين باستخدام CachedNetworkImage للكاش
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 100, // عرض الصورة
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.lightBlue,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.error,
                    color: Colors.red,
                  ),
                )
                    : Container(
                  width: 100,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.image_not_supported),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
