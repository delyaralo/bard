// lib/widgets/category_card.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bard/custmerPage/Subcatalge.dart';

class CategoryCard extends StatelessWidget {
  final String imageUrl;
  final String categoryId;
  final String categoryName;

  const CategoryCard({
    required this.imageUrl,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
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
      borderRadius: BorderRadius.circular(28.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // استخدمنا Stack لوضع هالة ضوئية خلف دائرة الصورة
          Stack(
            alignment: Alignment.center,
            children: [
              // 1) الهالة الدائرية (أكبر قليلًا من الصورة)
              Container(
                width: 85,
                height: 75,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // تدرج لوني دائري (Radial)
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.8,
                    colors: [
                      // يمكنك استخدام ألوان تتناسب مع الهوية البصرية لتطبيقك
                      Theme.of(context).primaryColor.withOpacity(0.2),
                      Colors.white,
                    ],
                  ),
                  // ظل خفيف لإبراز الهالة
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      blurRadius: 8.0,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),

              // 2) الدائرة الأساسية التي تحتوي على الصورة
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.5),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6.0,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  image: imageUrl.isNotEmpty
                      ? DecorationImage(
                    image: CachedNetworkImageProvider(imageUrl),
                    fit: BoxFit.cover,
                  )
                      : null,
                ),
                // إن لم يوجد صورة، نظهر أيقونة
                child: imageUrl.isEmpty
                    ? Icon(
                  Icons.category,
                  color: Theme.of(context).primaryColor,
                  size: 26.0,
                )
                    : null,
              ),
            ],
          ),

          const SizedBox(height: 1),

          // 3) نص التصنيف
          Text(
            categoryName,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              shadows: [
                // ظل خفيف للنص
                Shadow(
                  color: Colors.black12,
                  offset: const Offset(1, 1),
                  blurRadius: 2,
                ),
              ],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
