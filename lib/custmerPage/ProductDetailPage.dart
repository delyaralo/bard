// ignore_for_file: prefer_const_constructors

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';

import 'CartPage.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> productData;

  const ProductDetailPage({
    Key? key,
    required this.productData,
  }) : super(key: key);

  @override
  ProductDetailPageState createState() => ProductDetailPageState();
}

class ProductDetailPageState extends State<ProductDetailPage> {
  // صور المنتج
  List<String> _productImages = [];
  // الطرازات
  List<dynamic>? _variants;
  String? _selectedVariant;
  // عداد السلة
  int cartItemCount = 0;
  // مؤشر الصورة الحالية
  int _currentImageIndex = 0;
  // متغيرات الكاش لبيانات المنتج
  Box? _productDetailBox;
  late String _productId;

  @override
  void initState() {
    super.initState();
    _loadCartItemCount();
    _initializeProductDetailCache();

    // جمع الصور
    final mainImage = widget.productData['mainImageUrl']?.toString() ?? '';
    final extraImages =
    List<String>.from(widget.productData['productImagesUrls'] ?? []);
    if (mainImage.isNotEmpty) {
      _productImages.add(mainImage);
    }
    _productImages.addAll(extraImages);

    // الطرازات
    _variants = widget.productData['variants'] ?? [];
    if (_variants != null && _variants!.isNotEmpty) {
      _selectedVariant = _variants![0].toString();
    }
  }

  /// تهيئة بوكس الكاش لتفاصيل المنتج وتخزينها إن لم تكن محفوظة مسبقًا
  Future<void> _initializeProductDetailCache() async {
    _productDetailBox = await Hive.openBox('productDetails');
    // الحصول على معرف المنتج (docId أو id) أو توليد واحد جديد
    _productId = (widget.productData['docId'] ??
        widget.productData['id'] ??
        const Uuid().v4())
        .toString();
    _cacheProductDetail();
  }

  /// دالة لتخزين بيانات المنتج في الكاش (بصيغة JSON)
  void _cacheProductDetail() {
    if (_productDetailBox != null && !_productDetailBox!.containsKey(_productId)) {
      _productDetailBox!.put(_productId, jsonEncode(widget.productData));
    }
  }

  /// تحميل عدد المنتجات في السلة
  Future<void> _loadCartItemCount() async {
    final prefs = await SharedPreferences.getInstance();
    final storedCart = prefs.getStringList('cart');
    setState(() {
      cartItemCount = storedCart?.length ?? 0;
    });
  }

  /// إضافة المنتج إلى السلة
  Future<void> _addToCart() async {
    final prefs = await SharedPreferences.getInstance();
    final storedCart = prefs.getStringList('cart');
    final List<Map<String, dynamic>> cartList = storedCart != null
        ? storedCart
        .map((item) => jsonDecode(item) as Map<String, dynamic>)
        .toList()
        : [];

    final productId = (widget.productData['docId'] ??
        widget.productData['id'] ??
        const Uuid().v4())
        .toString();

    final String imageUrl = _productImages.isNotEmpty ? _productImages[0] : '';
    final String name = widget.productData['name'] ?? 'منتج غير معروف';
    final double highPrice =
        double.tryParse(widget.productData['highPrice']?.toString() ?? '0.0') ??
            0.0;
    final String currency = widget.productData['currency'] ?? '\$';

    // فحص صحة البيانات
    if (name.isEmpty || imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('بيانات المنتج غير صالحة')),
      );
      return;
    }
    if (_variants != null && _variants!.isNotEmpty && _selectedVariant == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يرجى اختيار طراز المنتج')),
      );
      return;
    }

    final existingIndex = cartList.indexWhere(
          (item) =>
      item['productId'] == productId &&
          (item['variant'] ?? '') == (_selectedVariant ?? ''),
    );
    if (existingIndex != -1) {
      cartList[existingIndex]['quantity'] += 1;
    } else {
      cartList.add({
        'productId': productId,
        'name': name,
        'imageUrl': imageUrl,
        'price': highPrice,
        'quantity': 1,
        'variant': _selectedVariant ?? '',
        'currency': currency,
      });
    }

    final updatedCart = cartList.map((e) => jsonEncode(e)).toList();
    await prefs.setStringList('cart', updatedCart);

    setState(() {
      cartItemCount = cartList.length;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تمت إضافة المنتج إلى السلة')),
    );
  }

  /// تنسيق السعر باستخدام intl
  String _formatPrice(double price) {
    final formatter = NumberFormat('#,##0.###', 'en_US');
    return formatter.format(price);
  }

  @override
  Widget build(BuildContext context) {
    // بيانات المنتج
    final String name = widget.productData['name'] ?? 'اسم غير متوفر';
    final double highPrice =
        double.tryParse(widget.productData['highPrice']?.toString() ?? '0.0') ??
            0.0;
    final String currency = widget.productData['currency'] ?? '\$';
    final String description =
        widget.productData['description'] ?? 'لا يوجد وصف';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          name,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
          textAlign: TextAlign.left,
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
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // أيقونة السلة مع عداد
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart, color: Colors.white, size: 28),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CartPage()),
                  ).then((_) => _loadCartItemCount());
                },
              ),
              if (cartItemCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$cartItemCount',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // خلفية على شكل موجة
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: WaveClipper(),
              child: Container(
                height: 220,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xff36D1DC), Color(0xff5B86E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          // المحتوى القابل للتمرير
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 20, bottom: 80),
              child: Column(
                children: [
                  // عرض الصور في كارد كبير
                  _buildCarouselCard(),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        // السعر
                        _buildRadicalSection(
                          child: Text(
                            '${_formatPrice(highPrice)} $currency',
                            style: GoogleFonts.cairo(
                              fontSize: 22,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // عرض الطرازات إن وجدت
                        if (_variants != null && _variants!.isNotEmpty)
                          _buildRadicalSection(
                            title: 'اختر الطراز',
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              alignment: WrapAlignment.start,
                              children: _variants!.map((variant) {
                                final String variantStr = variant.toString();
                                return ChoiceChip(
                                  label: Text(
                                    variantStr,
                                    style: GoogleFonts.cairo(
                                      color: _selectedVariant == variantStr
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                  selected: _selectedVariant == variantStr,
                                  selectedColor: Colors.blueAccent,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedVariant =
                                      selected ? variantStr : null;
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        const SizedBox(height: 16),
                        // الوصف
                        if (description.trim().isNotEmpty &&
                            description.trim() != 'لا يوجد وصف')
                          _buildRadicalSection(
                            title: 'وصف المنتج',
                            child: Text(
                              description,
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        const SizedBox(height: 16),
                        // قسم المواصفات
                        _buildSpecificationsSection(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      // زر إضافة المنتج للسلة
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _addToCart,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 5,
          ),
          child: Text(
            'إضافة إلى السلة',
            style: GoogleFonts.cairo(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ),
    );
  }

  /// حاوية تعرض السلايدر بشكل كارد أكبر
  Widget _buildCarouselCard() {
    final double carouselHeight = 350;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: carouselHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: _productImages.isEmpty
            ? Container(
          color: Colors.grey[200],
          child: Center(
            child: Icon(Icons.photo, size: 60, color: Colors.grey),
          ),
        )
            : Stack(
          children: [
            CarouselSlider(
              options: CarouselOptions(
                height: carouselHeight,
                enlargeCenterPage: true,
                enableInfiniteScroll: false,
                autoPlay: false,
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentImageIndex = index;
                  });
                },
              ),
              items: _productImages.map((imageUrl) {
                return Builder(
                  builder: (BuildContext context) {
                    return CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.white,
                        child: Center(
                          child: SpinKitCircle(
                            color: Colors.blueAccent,
                            size: 30.0,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.white,
                        child: Icon(Icons.error,
                            color: Colors.red, size: 40),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
            Positioned(
              bottom: 6,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _productImages.asMap().entries.map((entry) {
                  return Container(
                    width: 8.0,
                    height: 8.0,
                    margin: EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 4.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentImageIndex == entry.key
                          ? Colors.blueAccent
                          : Colors.grey,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// حاوية جذابة لعرض أقسام المحتوى
  Widget _buildRadicalSection({String? title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (title != null && title.isNotEmpty) ...[
            Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
              textAlign: TextAlign.right,
            ),
            SizedBox(height: 10),
          ],
          child,
        ],
      ),
    );
  }

  /// قسم المواصفات
  Widget _buildSpecificationsSection() {
    final specs =
        widget.productData['productSpecifications']?.toString() ?? '';
    final size = widget.productData['productSize']?.toString() ?? '';
    final color = widget.productData['productColor']?.toString() ?? '';
    final manufacturer =
        widget.productData['manufacturer']?.toString() ?? '';

    final List<Map<String, String>> items = [];
    if (specs.isNotEmpty) {
      items.add({'title': 'المواصفات', 'value': specs});
    }
    if (size.isNotEmpty) {
      items.add({'title': 'الحجم', 'value': size});
    }
    if (color.isNotEmpty) {
      items.add({'title': 'اللون', 'value': color});
    }
    if (manufacturer.isNotEmpty && manufacturer != 'مباشر') {
      items.add({'title': 'المنشئ', 'value': manufacturer});
    }

    if (items.isEmpty) {
      return _buildRadicalSection(
        child: Text(
          'لا توجد مواصفات متاحة',
          style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.right,
        ),
      );
    }

    return _buildRadicalSection(
      title: 'المواصفات',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    '${item['title']}: ${item['value']}',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.check_circle, color: Colors.blueAccent, size: 18),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// موجة (Wave) مخصصة لقص خلفية Container
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height * 0.7);

    var firstControlPoint = Offset(size.width * 0.25, size.height);
    var firstEndPoint = Offset(size.width * 0.5, size.height * 0.7);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint = Offset(size.width * 0.75, size.height * 0.4);
    var secondEndPoint = Offset(size.width, size.height * 0.7);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(WaveClipper oldClipper) => false;
}
