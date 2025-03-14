import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hive/hive.dart';

import 'package:bard/custmerPage/catalage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hive/hive.dart';


class SubCategoryPage extends StatefulWidget {
  final String mainCategoryId;
  final String categoryName;

  const SubCategoryPage({
    Key? key,
    required this.mainCategoryId,
    required this.categoryName,
  }) : super(key: key);

  @override
  _SubCategoryPageState createState() => _SubCategoryPageState();
}

class _SubCategoryPageState extends State<SubCategoryPage> {
  Box? _subCategoriesBox;

  @override
  void initState() {
    super.initState();
    _initializeHive();
  }

  Future<void> _initializeHive() async {
    _subCategoriesBox = await Hive.openBox('subcategories');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// AppBar مع تدرج اللون
      appBar: AppBar(
        title: Text(
          widget.categoryName,
          style: const TextStyle(
            fontFamily: 'Amiri',
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xff36D1DC), Color(0xff5B86E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),

      /// محتوى الصفحة: إظهار التصنيفات الفرعية
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('categories')
            .doc(widget.mainCategoryId)
            .collection('subcategories')
            .orderBy('order')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final subCategories = snapshot.data!.docs;

          // إن لم يكن هناك تصنيفات فرعية، ننتقل إلى صفحة عرض المنتجات مباشرة
          if (subCategories.isEmpty) {
            return CategoryPage(
              mainCategoryId: widget.mainCategoryId,
              subCategoryId: '', // قيمة فارغة
              categoryName: widget.categoryName,
            );
          }

          // في حال وجود تصنيفات فرعية
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: subCategories.length,
            itemBuilder: (context, index) {
              final subCategoryData =
              subCategories[index].data() as Map<String, dynamic>;
              final subCategoryId = subCategories[index].id;

              return GestureDetector(
                onTap: () {
                  // الانتقال لصفحة عرض المنتجات
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategoryPage(
                        mainCategoryId: widget.mainCategoryId,
                        subCategoryId: subCategoryId,
                        categoryName: subCategoryData['name'],
                      ),
                    ),
                  );
                },

                // إضافة Margin لكل عنصر لجعله بعيدًا عن الحواف
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          // صورة التصنيف
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: subCategoryData['imageUrl'] ?? '',
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[200],
                              ),
                              errorWidget: (context, url, error) =>
                              const Icon(Icons.error, color: Colors.red),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // الاسم (في مساحة مرنة داخل الـ Row)
                          Expanded(
                            child: Text(
                              subCategoryData['name'] ?? 'بدون اسم',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
