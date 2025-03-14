import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

// كلاس لإدارة الكاش باستخدام Hive
class ProductCache {
  static Box? _box;

  static Future<void> init() async {
    // تهيئة Hive وفتح بوكس لتخزين بيانات المنتجات
    await Hive.initFlutter();
    _box = await Hive.openBox('productsBox');
  }

  static dynamic getProduct(String id) {
    return _box?.get(id);
  }

  static Future<void> cacheProduct(String id, Map<String, dynamic> data) async {
    await _box?.put(id, data);
  }
}

class CategoryPage extends StatelessWidget {
  final String mainCategoryId;
  final String subCategoryId;
  final String categoryName;

  const CategoryPage({
    Key? key,
    required this.mainCategoryId,
    required this.subCategoryId,
    required this.categoryName,
  }) : super(key: key);

  /// دالة لتنسيق السعر:
  /// - إضافة فواصل بين كل 3 أرقام.
  /// - إزالة الأصفار العشرية الزائدة.
  /// - إعادة "السعر غير متوفر" إذا فشل التحويل.
  String _formatPrice(dynamic priceInput) {
    final price = double.tryParse(priceInput?.toString() ?? '');
    if (price == null) {
      return 'السعر غير متوفر';
    }
    final formatter = NumberFormat('#,##0.###', 'en_US');
    return formatter.format(price);
  }

  /// دالة لبناء كارد المنتج بتصميم جذاب
  Widget _buildProductCard(
      BuildContext context, Map<String, dynamic> productData) {
    final String name = productData['name'] ?? 'اسم غير متوفر';
    final String currency = productData['currency']?.toString() ?? '\$';
    final String formattedPrice = _formatPrice(productData['highPrice']);
    final String finalPrice = (formattedPrice == 'السعر غير متوفر')
        ? formattedPrice
        : '$formattedPrice $currency';
    final String imageUrl = productData['mainImageUrl'] ?? '';
    const double borderRadiusVal = 15.0;

    return GestureDetector(
      onTap: () {
        // الانتقال إلى صفحة تفاصيل المنتج
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ProductDetailPage(productData: productData),
          ),
        );
      },
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusVal),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadiusVal),
          child: Stack(
            children: [
              // صورة المنتج مع تخزين مؤقت باستخدام CachedNetworkImage
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                  const Center(),
                  errorWidget: (context, url, error) =>
                  const Icon(Icons.error, color: Colors.red),
                ),
              ),
              // تدرج شفاف لإظهار نص الاسم والسعر
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 60,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black54, Colors.transparent],
                    ),
                  ),
                ),
              ),
              // نص الاسم والسعر
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      finalPrice,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // عرض المنتجات من خلال StreamBuilder الذي يستمع لتغييرات Firestore
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          categoryName,
          style: const TextStyle(fontFamily: 'Amiri'),
        ),
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('mainCategoryId', isEqualTo: mainCategoryId)
            .where('subCategoryId', isEqualTo: subCategoryId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final products = snapshot.data!.docs;
          if (products.isEmpty) {
            return const Center(child: Text('لا توجد منتجات متاحة'));
          }

          // تخزين المنتجات في الكاش باستخدام Hive
          for (var doc in products) {
            ProductCache.cacheProduct(doc.id, doc.data() as Map<String, dynamic>);
          }

          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.7,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final productData =
              products[index].data() as Map<String, dynamic>;
              return _buildProductCard(context, productData);
            },
          );
        },
      ),
    );
  }
}

class ProductDetailPage extends StatelessWidget {
  final Map<String, dynamic> productData;

  const ProductDetailPage({Key? key, required this.productData})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String name = productData['name'] ?? 'اسم غير متوفر';
    final String description = productData['description'] ?? 'لا يوجد وصف';
    final String imageUrl = productData['mainImageUrl'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عرض الصورة مع تخزين مؤقت
            CachedNetworkImage(
              imageUrl: imageUrl,
              placeholder: (context, url) =>
              const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) =>
              const Icon(Icons.error, color: Colors.red),
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 16),
            // اسم المنتج
            Text(
              name,
              style:
              const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // وصف المنتج
            Text(
              description,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
