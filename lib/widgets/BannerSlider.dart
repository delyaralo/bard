import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:bard/custmerPage/Subcatalge.dart';
import 'package:bard/custmerPage/catalage.dart';

class BannerSlider extends StatefulWidget {
  final List<Map<String, dynamic>> banners;

  const BannerSlider({required this.banners, Key? key}) : super(key: key);

  @override
  _BannerSliderState createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  int _currentBannerIndex = 0;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    if (widget.banners.isEmpty) {
      return Container(
        height: 200,
        width: screenWidth,
        alignment: Alignment.center,
        child: const Text(
          'لا توجد بنرات متاحة حالياً',
          style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
        ),
      );
    }



    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            CarouselSlider.builder(
              itemCount: widget.banners.length,
              options: CarouselOptions(
                height: 220, // ارتفاع مناسب
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 5),
                autoPlayAnimationDuration: const Duration(milliseconds: 800),
                autoPlayCurve: Curves.fastOutSlowIn,
                enlargeCenterPage: false,
                viewportFraction: 1.0,
                scrollPhysics: const BouncingScrollPhysics(),
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentBannerIndex = index;
                  });
                },
              ),
              itemBuilder: (BuildContext context, int index, int realIdx) {
                final banner = widget.banners[index];
                final imageUrl = banner['imageUrl'] ?? '';
                final mainCategoryId = banner['mainCategoryId'] ?? '';
                final subCategoryId = banner['subCategoryId'] ?? '';

                return GestureDetector(
                  onTap: () {
                    // ✅ عند الضغط على البنر، نفحص التصنيفات المخزّنة
                    if (mainCategoryId.isNotEmpty) {
                      if (subCategoryId.isNotEmpty) {
                        // ✅ الانتقال مباشرةً إلى CategoryPage (تصنيف فرعي)
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CategoryPage(
                              mainCategoryId: mainCategoryId,
                              subCategoryId: subCategoryId,
                              categoryName: banner['title'] ?? 'التصنيف الفرعي',
                            ),
                          ),
                        );
                      } else {
                        // ✅ الانتقال إلى SubCategoryPage (تصنيف رئيسي فقط)
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SubCategoryPage(
                              mainCategoryId: mainCategoryId,
                              categoryName: banner['title'] ?? 'التصنيف الرئيسي',
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: Container(
                    width: screenWidth,
                    margin: const EdgeInsets.symmetric(horizontal: 0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8.0,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: imageUrl,
                            placeholder: (context, url) =>
                            const Center(),
                            errorWidget: (context, url, error) =>
                            const Icon(Icons.error, color: Colors.red, size: 50),
                            fit: BoxFit.cover,
                          ),
                          // ✅ تدرج شفاف في الأسفل
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.4),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          // ✅ إذا أردت إظهار عنوان البنر

                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],

        ),

      ],

    );
  }
}
