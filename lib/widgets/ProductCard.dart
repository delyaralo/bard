import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bard/custmerPage/ProductDetailPage.dart';
import 'package:intl/intl.dart';

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> productData;

  const ProductCard({required this.productData, Key? key}) : super(key: key);

  /// دالة لتنسيق السعر:
  /// - إضافة فواصل بين كل 3 أرقام.
  /// - إزالة الأصفار العشرية الزائدة.
  /// - إعادة "السعر غير متوفر" إذا فشل التحويل إلى رقم.
  String _formatPrice(dynamic priceInput) {
    final price = double.tryParse(priceInput?.toString() ?? '');
    if (price == null) {
      return 'السعر غير متوفر';
    }
    final formatter = NumberFormat('#,##0.###', 'en_US');
    return formatter.format(price);
  }

  @override
  Widget build(BuildContext context) {
    final String name = productData['name'] ?? 'اسم غير متوفر';
    final String formattedPrice = _formatPrice(productData['highPrice']);
    final String currency = productData['currency']?.toString() ?? '\$';
    final String priceText = (formattedPrice == 'السعر غير متوفر')
        ? formattedPrice
        : '$formattedPrice $currency';

    final String imageUrl = productData['mainImageUrl'] ?? '';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(productData: productData),
          ),
        );
      },
      child: Card(
        elevation: 5,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: Stack(
            children: [
              // الخلفية: صورة المنتج
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorWidget: (context, url, error) =>
                  const Icon(Icons.error, color: Colors.red),
                  fit: BoxFit.cover,
                ),
              ),

              // تدرّج شفاف من الأسفل
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 80,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black54,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // بيانات المنتج (الاسم والسعر)
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // اسم المنتج
                    Text(
                      name,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // السعر (جعل الخط أكثر بروزاً)
                    Text(
                      priceText,
                      style: const TextStyle(
                        fontSize: 14,            // زيادة حجم الخط
                        color: Colors.white,     // لون أبيض قوي
                        fontWeight: FontWeight.bold, // خط سميك
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
}
