// lib/widgets/category_section.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bard/widgets/categorycard.dart';

class CategorySection extends StatelessWidget {
  const CategorySection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('categories')
          .orderBy('order')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center();
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("لا توجد أقسام حالياً"));
        }

        final categories = snapshot.data!.docs;
        return _buildCategorySection(context, categories);
      },
    );
  }

  Widget _buildCategorySection(
      BuildContext context, List<DocumentSnapshot> categories) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان القسم
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "الأقسام",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),

          const SizedBox(height: 8.0),

          // خلفية متدرجة للأقسام + حواف دائرية + ظل خفيف
          Container(
            height: 100,
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xffF6F9FF),
                  Color(0xffFFFFFF),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.0),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: categories.length,
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                itemBuilder: (context, index) {
                  final categoryData =
                  categories[index].data() as Map<String, dynamic>;
                  final imageUrl = categoryData['imageUrl'] ?? '';
                  final categoryId = categories[index].id;
                  final categoryName = categoryData['name'] ?? '';

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: CategoryCard(
                      imageUrl: imageUrl,
                      categoryId: categoryId,
                      categoryName: categoryName,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
