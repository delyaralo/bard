// lib/widgets/products_section.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bard/widgets/productcard.dart';
import 'package:bard/widgets/CustomDivider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class ProductsSection extends StatelessWidget {
  final String searchQuery;

  const ProductsSection({this.searchQuery = ''});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('categories')
          .orderBy('order')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final categories = snapshot.data!.docs;
        return _buildProductsList(context, categories);
      },
    );
  }

  Widget _buildProductsList(
      BuildContext context,
      List<DocumentSnapshot> categories,
      ) {
    return Column(
      children: categories.map((categoryDoc) {
        final categoryData = categoryDoc.data() as Map<String, dynamic>;
        final categoryId = categoryDoc.id;
        final categoryName = categoryData['name'] ?? 'اسم غير متوفر';

        // جلب المنتجات الخاصة بكل تصنيف
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('products')
              .where('mainCategoryId', isEqualTo: categoryId)
              .snapshots(),
          builder: (context, productSnapshot) {
            if (!productSnapshot.hasData) {
              return const SizedBox.shrink();
            }

            // تطبيق فلترة البحث
            final products = productSnapshot.data!.docs
                .map((doc) => doc.data() as Map<String, dynamic>)
                .where((product) => product['name']
                .toString()
                .toLowerCase()
                .contains(searchQuery.toLowerCase()))
                .toList();

            if (products.isEmpty) {
              // إذا لم يكن هناك منتجات بعد الفلترة
              return const SizedBox.shrink();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // عنوان التصنيف
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    categoryName,
                    style: GoogleFonts.cairo(
                      fontSize: 22,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // شبكة المنتجات (Grid)
                _buildProductGrid(context, products),

                const SizedBox(height: 20),
                CustomDivider(),
              ],
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildProductGrid(BuildContext context, List<Map<String, dynamic>> products) {
    final crossAxisCount = MediaQuery.of(context).size.width > 600 ? 4 : 2;

    return AnimationLimiter(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        itemCount: products.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 16.0,
          crossAxisSpacing: 16.0,
          childAspectRatio: 0.7,
        ),
        itemBuilder: (context, index) {
          final productData = products[index];
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 400),
            columnCount: crossAxisCount,
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                // ✅ الكارد مع التنسيق الرائع
                child: _buildFancyCard(context, productData),
              ),
            ),
          );
        },
      ),
    );
  }

  /// دالة تبني الكارد (البطاقة) الخاصة بكل منتج مع لمسات جمالية
  Widget _buildFancyCard(BuildContext context, Map<String, dynamic> productData) {
    return Container(
      decoration: BoxDecoration(
        // تدرج لوني خفيف يمكن تغييره أو إزالته
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF5F9FF),
            Color(0xFFFFFFFF),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        // الكارد الأساسية التي تعرض معلومات المنتج
        child: ProductCard(productData: productData),
      ),
    );
  }
}
