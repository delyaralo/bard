// lib/pages/cart_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
// لاستعمال NumberFormat
import 'package:intl/intl.dart';

// مثال على صفحة الإتمام أو الصفحة الرئيسية
import 'CheckoutDetailsPage.dart'; // تأكد من المسار الصحيح أو استبدل بصفحتك
import 'HomePage.dart'; // إن أردت العودة للصفحة الرئيسية

class CartPage2 extends StatefulWidget {
  const CartPage2({Key? key}) : super(key: key);

  @override
  _CartPage2State createState() => _CartPage2State();
}

class _CartPage2State extends State<CartPage2> {
  List<Map<String, dynamic>> cartItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  /// دالة تنسيق السعر:
  /// - وضع فواصل كل 3 أرقام.
  /// - إزالة الأصفار العشرية الزائدة.
  String _formatPrice(double price) {
    final formatter = NumberFormat('#,##0.###', 'en_US');
    return formatter.format(price);
  }

  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final storedCart = prefs.getStringList('cart');

    if (storedCart != null) {
      setState(() {
        cartItems = storedCart
            .map((item) => jsonDecode(item) as Map<String, dynamic>)
            .toList();
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _removeItem(int index) async {
    final prefs = await SharedPreferences.getInstance();
    cartItems.removeAt(index);

    final updatedCart = cartItems.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList('cart', updatedCart);

    setState(() {});
  }

  Future<void> _clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cart');
    setState(() {
      cartItems = [];
    });
  }

  double _calculateTotalPrice() {
    double total = 0.0;
    for (var item in cartItems) {
      total += (item['price'] ?? 0.0) * (item['quantity'] ?? 1);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final double totalPrice = _calculateTotalPrice();

    return Scaffold(
      // AppBar بتصميم احترافي

      // خلفية بتدرّج ناعم
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFECF2FF), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? const Center(
            child: SpinKitFadingCircle(
              color: Colors.blueAccent,
              size: 50.0,
            ),
          )
              : cartItems.isEmpty
              ? Center(
            child: Text(
              'السلة فارغة',
              style: GoogleFonts.cairo(
                fontSize: 20,
                color: Colors.grey,
              ),
            ),
          )
              : Column(
            children: [
              // عرض المنتجات في السلة
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];

                    final String productName =
                        item['name'] ?? 'منتج غير معروف';
                    final double itemPrice =
                    (item['price'] ?? 0.0).toDouble();
                    final int quantity =
                    (item['quantity'] ?? 1).toInt();
                    final String currency =
                        item['currency'] ?? '\$';
                    final String variant = item['variant'] ?? '';
                    final String imageUrl = item['imageUrl'] ?? '';

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            // صورة المنتج
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    Container(
                                      width: 80,
                                      height: 80,
                                      color: Colors.grey[300],
                                      child: const Center(
                                        child: SpinKitCircle(
                                          color: Colors.blueAccent,
                                          size: 30.0,
                                        ),
                                      ),
                                    ),
                                errorWidget: (context, url, error) =>
                                    Container(
                                      width: 80,
                                      height: 80,
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.error,
                                        color: Colors.red,
                                      ),
                                    ),
                              ),
                            ),
                            const SizedBox(width: 16),

                            // تفاصيل المنتج
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    productName,
                                    style: GoogleFonts.cairo(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),

                                  // عرض الطراز (variant) إن وجد
                                  if (variant.isNotEmpty)
                                    Text(
                                      'الطراز: $variant',
                                      style: GoogleFonts.cairo(
                                        fontSize: 16,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  const SizedBox(height: 8),

                                  // السعر
                                  Row(
                                    children: [
                                      Text(
                                        'السعر: ',
                                        style: GoogleFonts.cairo(
                                          fontSize: 16,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      Text(
                                        '${_formatPrice(itemPrice)} $currency',
                                        style: GoogleFonts.cairo(
                                          fontSize: 16,
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // الكمية
                                  Row(
                                    children: [
                                      Text(
                                        'الكمية: ',
                                        style: GoogleFonts.cairo(
                                          fontSize: 16,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      Text(
                                        '$quantity',
                                        style: GoogleFonts.cairo(
                                          fontSize: 16,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // زر حذف المنتج
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              onPressed: () async {
                                final confirm =
                                await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(
                                      'تأكيد',
                                      style: GoogleFonts.cairo(),
                                    ),
                                    content: Text(
                                      'هل تريد إزالة هذا المنتج من السلة؟',
                                      style: GoogleFonts.cairo(),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context)
                                                .pop(false),
                                        child: Text(
                                          'لا',
                                          style: GoogleFonts.cairo(),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context)
                                                .pop(true),
                                        child: Text(
                                          'نعم',
                                          style: GoogleFonts.cairo(),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm ?? false) {
                                  _removeItem(index);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // الإجمالي وزر إتمام الطلب
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    const Divider(
                      color: Colors.blueAccent,
                      thickness: 2,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'الإجمالي:',
                          style: GoogleFonts.cairo(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          // تنسيق السعر الإجمالي
                          '${_formatPrice(totalPrice)} \$',
                          style: GoogleFonts.cairo(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // زر إتمام الطلب
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: cartItems.isEmpty
                            ? null
                            : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CheckoutDetailsPage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 14),
                          elevation: 5,
                        ),
                        child: Text(
                          'إتمام الطلب',
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
