// checkout_details_page.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:bard/NotificationService.dart';
// إضافة مكتبة intl
import 'package:intl/intl.dart';

class Governorate {
  final String id;
  final String name;
  final double price;

  Governorate({required this.id, required this.name, required this.price});

  factory Governorate.fromMap(Map<String, dynamic> data, String documentId) {
    return Governorate(
      id: documentId,
      name: data['name'] ?? '',
      price: data['price'] != null ? (data['price'] as num).toDouble() : 0.0,
    );
  }
}

class DiscountCode {
  final String id;
  final String code;
  final double discountAmount;
  final bool isPercentage;
  final DateTime expiryDate;
  final int usageLimit;
  final int usedCount;

  DiscountCode({
    required this.id,
    required this.code,
    required this.discountAmount,
    required this.isPercentage,
    required this.expiryDate,
    required this.usageLimit,
    required this.usedCount,
  });

  factory DiscountCode.fromMap(Map<String, dynamic> data, String documentId) {
    return DiscountCode(
      id: documentId,
      code: data['code'] ?? '',
      discountAmount: (data['discount_amount'] as num).toDouble(),
      isPercentage: data['is_percentage'] ?? false,
      expiryDate: (data['expiry_date'] as Timestamp).toDate(),
      usageLimit: data['usage_limit'] ?? 0,
      usedCount: data['used_count'] ?? 0,
    );
  }
}

class CheckoutDetailsPage extends StatefulWidget {
  @override
  _CheckoutDetailsPageState createState() => _CheckoutDetailsPageState();
}

class _CheckoutDetailsPageState extends State<CheckoutDetailsPage> {
  final _formKey = GlobalKey<FormState>();

  // بيانات النموذج
  String buyerName = '';
  String buyerNumber = '';
  String backupNumber = '';
  String? selectedGovernorateId;
  String areaName = '';
  bool requestTechnician = false;
  double deliveryFee = 0.0;
  double technicianFee = 0.0;
  double totalPrice = 0.0;

  // السلة
  List<Map<String, dynamic>> cartItems = [];

  // المحافظات
  List<Governorate> governorates = [];
  bool isLoadingGovernorates = true;

  // الخصم
  String discountCodeInput = '';
  double discountAmount = 0.0;
  bool isDiscountApplied = false;
  String discountError = '';
  List<DiscountCode> discountCodes = [];
  bool isLoadingDiscountCodes = true;

  // خدمة الإشعارات
  late NotificationService notificationService;

  @override
  void initState() {
    super.initState();
    _loadCartItems();
    fetchGovernorates();
    fetchTechnicianPrice();
    fetchDiscountCodes();
    _checkAppliedDiscount();

    // تهيئة خدمة الإشعارات
    notificationService = NotificationService(
      serviceAccountJson: {
        "type": "service_account",
        "project_id": "bard-bfaf2",
        "private_key_id": "faae723dea1013678fe3b6f6ed4ae28503b40438",
        "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC13mbfu+afRvDV\nkCENnXV6fT6fODhPKlR7QlnjA4w5hOuII8c6Pk0i6KBb2aVVaclIl3w05HP8ATMX\nOlkMqCUQZZdrEzetiKRw6WRxjTRNrLrVkYfSK8/GD/uP//odvdKtHswUA4KWQ2Y3\nOQy8nge0Qf+ETreewAwMj0QGVKgt7NUIbuf29h81IzpJWXUsxLZynskUKqeLE5+L\nAubTihCzGOwbr4t3ip2165fVuOPpoFpciXwi02ZF4R2612PEvgYUxuWyAU+oJh8d\n6iRQg0rYcR9QElHDW5tEaJsMaCmMKzIQIB2attlrdCeOGr4AZ3pq8LvPU6VHP143\niChrOoPdAgMBAAECggEAC+ymIBtI1r6nAcmucR8W2c4mcfgUsRQcb+x8ykasRgUy\nED4QTQBSvGw2P294yK3j9a+BBFLKTAakG+zGc+7+ZyHSGMIsz2L7LTAQVuWkPUeL\nBH/DQQOAXwMjQmDNPG/6xUEUrmdAg6utowdJj4BpDueY4krq/SyoXZZzJlscn84g\nIsl4TbxP4aLtyn8+7EeRmemS2uLs1cU5x/3bUpzX3ZFo2y/+8t5htBie5vVmVKEA\nD6qqrg2MqA7vF+YVQDTfAx0SBYEWwjrZppjfLf0W4Aae3ODUbEKw9/tOT927tc6G\nu2mCHjhpwJns7WJZDZdUlfCnQub7tebuZtZbSdXCQQKBgQDhqrGruFXzXnH8xFHA\naVB5Zzwey4CqMXymsntwK2gY9qnag9KUfnFZHUk3g7xbvB1raprYdEBA2uNA/SSW\np9VPmtn2+mk6kpzN47upt9CX5iO90zc/nPMGHuSTicW4rRvuOMBI6fhprdzIwin8\nqKM9VNQO9eaOGAUdwA3AZkO+bQKBgQDOUJimZcpQinIflj7ZT+fxac2852OG/Vyd\nJQwAm5ybbXqKrTNIbA/C3q1HYf6ZkoiNUbAQPzZ2Z9vGh2nuKR1sx/c7LdjER4tZ\nmdSIIO7wXOoiEZOuLOVDMFegnIwvPtgvLASls2SoChtM9v9xz9mOc6H+yxz7ugCf\nkIPAmSC1MQKBgQCMg0OD4BCsq+cf84HP5AN2xIAb0Kz5zDyIc2QG8RAtUxFp/WDW\nk3Cyg1i+l2lmWVicNNHb627Cs0iDg9wPbsuUeKA1d7CkBvxZ+u4z/D+HBYbFwMmK\n84gjDINZFpUlq6xThcS84eqKqvZpjvSj3MFgA/zSn+yCF5S/9IDbhxGxdQKBgQCj\nF4VEbMz81CSZIa03HnqNFYWE4imESX7P3rxZMqofF/E59ObIRlxDQMIb3rRj9Dkr\n9bpHbaEBAuLyUpODqE7RclXXG0vzBVd8EiW3IsmfiuOu4NQsaOMnNOzgU0BiDLza\ntWJLFr/oMm0Yb1zJPHSProsNnsSfnY7mlFgChUoc0QKBgBcRSu7hKJS3kOVmoA2b\nuiGw90T/wo8PHarrk+2P88fZsqJnIMUTfchY2N2fCpTR9DE741LwhDBN8eTNhDu+\ni2fkrvrFh81KUNcGz2wsvL06lc/y140ZRbmO3iHYJfAkxReqbPDoFNOyJtM0NczA\nizpa75w2JWGpqQZAeQwbWpfH\n-----END PRIVATE KEY-----\n",
        "client_email": "bard-811@bard-bfaf2.iam.gserviceaccount.com",
        "client_id": "112943468032516999921",
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url":
        "https://www.googleapis.com/robot/v1/metadata/x509/bard-811%40bard-bfaf2.iam.gserviceaccount.com",
        "universe_domain": "googleapis.com",
      },
      projectId: 'bard-bfaf2',
      context: context,
    );
  }

  /// دالة لتنسيق السعر:
  /// - إضافة فواصل بين كل 3 أرقام (مثال: 1,234).
  /// - إزالة الأصفار العشرية الزائدة (100.0 تصبح 100، 100.50 تصبح 100.5).
  String _formatPrice(double price) {
    final formatter = NumberFormat('#,##0.###', 'en_US');
    return formatter.format(price);
  }

  Future<void> _loadCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? storedCart = prefs.getStringList('cart');
    if (storedCart != null) {
      setState(() {
        cartItems = storedCart
            .map((item) => jsonDecode(item) as Map<String, dynamic>)
            .toList();
        _calculateTotalPrice();
      });
    }
  }

  Future<void> fetchGovernorates() async {
    try {
      QuerySnapshot snapshot =
      await FirebaseFirestore.instance.collection('governorates').get();
      List<Governorate> loadedGovernorates = snapshot.docs
          .map((doc) => Governorate.fromMap(
          doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      setState(() {
        governorates = loadedGovernorates;
        isLoadingGovernorates = false;
      });
    } catch (e) {
      setState(() {
        isLoadingGovernorates = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في تحميل المحافظات. حاول مرة أخرى.')),
      );
    }
  }

  Future<void> fetchTechnicianPrice() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('fees')
          .doc('technician')
          .get();
      setState(() {
        technicianFee = snapshot['price'] != null
            ? (snapshot['price'] as num).toDouble()
            : 0.0;
      });
    } catch (e) {
      setState(() {
        technicianFee = 0.0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في تحميل رسوم الفني.')),
      );
    }
  }

  Future<void> fetchDiscountCodes() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('discount_codes')
          .get();
      List<DiscountCode> loadedDiscountCodes = snapshot.docs
          .map((doc) => DiscountCode.fromMap(
          doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      setState(() {
        discountCodes = loadedDiscountCodes;
        isLoadingDiscountCodes = false;
      });
    } catch (e) {
      print('Error fetching discount codes: $e');
      setState(() {
        isLoadingDiscountCodes = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في تحميل كودات الخصم. حاول مرة أخرى.')),
      );
    }
  }

  void _calculateTotalPrice() {
    double productsTotal = cartItems.fold(
      0.0,
          (sum, item) =>
      sum + ((item['price'] ?? 0.0) * (item['quantity'] ?? 1)),
    );
    double total =
        productsTotal + deliveryFee + (requestTechnician ? technicianFee : 0.0);

    if (isDiscountApplied) {
      total -= discountAmount;
      if (total < 0) total = 0.0;
    }

    setState(() {
      totalPrice = total;
    });
  }

  Future<void> fetchDeliveryFee(String governorateId) async {
    try {
      DocumentSnapshot govSnapshot = await FirebaseFirestore.instance
          .collection('governorates')
          .doc(governorateId)
          .get();
      Governorate selectedGovernorate = Governorate.fromMap(
          govSnapshot.data() as Map<String, dynamic>, govSnapshot.id);
      setState(() {
        deliveryFee = selectedGovernorate.price;
        _calculateTotalPrice();
      });
    } catch (e) {
      setState(() {
        deliveryFee = 0.0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في تحميل رسوم التوصيل.')),
      );
    }
  }

  Future<void> _applyDiscount() async {
    if (discountCodeInput.isEmpty) {
      setState(() {
        discountError = 'يرجى إدخال كود الخصم.';
      });
      return;
    }

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('discount_codes')
          .where('code', isEqualTo: discountCodeInput)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          discountError = 'كود الخصم غير صالح.';
        });
        return;
      }

      DocumentSnapshot discountDoc = snapshot.docs.first;
      Map<String, dynamic> discountData =
      discountDoc.data() as Map<String, dynamic>;

      Timestamp expiryTimestamp = discountData['expiry_date'];
      DateTime expiryDate = expiryTimestamp.toDate();
      if (DateTime.now().isAfter(expiryDate)) {
        setState(() {
          discountError = 'كود الخصم منتهي الصلاحية.';
        });
        return;
      }

      int usageLimit = discountData['usage_limit'] ?? 0;
      int usedCount = discountData['used_count'] ?? 0;
      if (usedCount >= usageLimit) {
        setState(() {
          discountError = 'كود الخصم وصل إلى حد الاستخدام.';
        });
        return;
      }

      double discountVal = discountData['discount_amount']?.toDouble() ?? 0.0;
      bool isPercentage = discountData['is_percentage'] ?? false;

      double calculatedDiscount = 0.0;
      if (isPercentage) {
        calculatedDiscount = (totalPrice * discountVal) / 100;
      } else {
        calculatedDiscount = discountVal;
      }

      if (calculatedDiscount > totalPrice) {
        calculatedDiscount = totalPrice;
      }

      setState(() {
        discountAmount = calculatedDiscount;
        isDiscountApplied = true;
        discountError = '';
        totalPrice -= discountAmount;
      });

      // زيادة العداد المستخدم
      await FirebaseFirestore.instance
          .collection('discount_codes')
          .doc(discountDoc.id)
          .update({'used_count': usedCount + 1});
    } catch (e) {
      setState(() {
        discountError = 'حدث خطأ أثناء تطبيق الخصم. حاول مرة أخرى.';
      });
      print('Error applying discount: $e');
    }
  }

  /// دالة التحقق من وجود خصم مطبق مسبقاً (من SharedPreferences)
  Future<void> _checkAppliedDiscount() async {
    final prefs = await SharedPreferences.getInstance();
    String? discountJson = prefs.getString("applied_discount");
    if (discountJson != null) {
      final Map<String, dynamic> discountData = jsonDecode(discountJson);
      String code = discountData["code"] ?? "";
      String type = discountData["type"] ?? "";
      double value = (discountData["value"] != null)
          ? (discountData["value"] as num).toDouble()
          : 0.0;

      double calculatedDiscount = 0.0;
      if (type == "percentage") {
        calculatedDiscount = (totalPrice * value) / 100;
      } else if (type == "fixed") {
        calculatedDiscount = value;
      }
      if (calculatedDiscount > totalPrice) {
        calculatedDiscount = totalPrice;
      }

      setState(() {
        discountCodeInput = code;
        discountAmount = calculatedDiscount;
        isDiscountApplied = true;
        totalPrice -= discountAmount;
      });
    }
  }

  Future<String?> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('device_id');
  }

  Future<void> _submitOrder() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (cartItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('السلة فارغة، يرجى إضافة منتجات!')),
        );
        return;
      }

      String? deviceId = await _getDeviceId();

      Map<String, dynamic> orderData = {
        'buyerName': buyerName,
        'buyerNumber': buyerNumber,
        'backupNumber': backupNumber,
        'governorateId': selectedGovernorateId,
        'areaName': areaName,
        'requestTechnician': requestTechnician,
        'deliveryFee': deliveryFee,
        'technicianFee': requestTechnician ? technicianFee : 0.0,
        'discountCode': isDiscountApplied ? discountCodeInput : null,
        'discountAmount': isDiscountApplied ? discountAmount : null,
        'totalPrice': totalPrice,
        'timestamp': FieldValue.serverTimestamp(),
        'products': cartItems,
        'orderStatus': 'pending',
        'deviceId': deviceId,
      };

      try {
        await FirebaseFirestore.instance.collection('orders').add(orderData);

        // إرسال إشعار للموظفين
        await notificationService.sendEmployeeNotification(
          buyerName,
          discountCode: isDiscountApplied ? discountCodeInput : null,
          discountAmount: isDiscountApplied ? discountAmount : null,
        );

        // إزالة بيانات الخصم بعد إتمام الطلب
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove("applied_discount");

        // تفريغ السلة
        await _clearCart();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم إرسال الطلب بنجاح!')),
        );
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء إرسال الطلب: $e')),
        );
      }
    }
  }

  Future<void> _clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cart');
    setState(() {
      cartItems = [];
      _calculateTotalPrice();
      isDiscountApplied = false;
      discountCodeInput = '';
      discountAmount = 0.0;
      discountError = '';
    });
  }

  /// صف لعرض سعر/عنصر في الملخص
  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isTotal
                  ? Colors.redAccent.withOpacity(0.1)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: GoogleFonts.cairo(
                fontSize: isTotal ? 18 : 16,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                color: isTotal ? Colors.redAccent : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// الحقل النصي
  Widget _buildInputField({
    required String label,
    required IconData icon,
    required FormFieldValidator<String> validator,
    required FormFieldSetter<String> onSaved,
    bool isOptional = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label + (isOptional ? ' (اختياري)' : ''),
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      keyboardType: keyboardType,
      validator: (value) {
        if (!isOptional && (value == null || value.isEmpty)) {
          return 'يرجى إدخال $label';
        }
        return null;
      },
      onSaved: onSaved,
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isLoading = isLoadingGovernorates || isLoadingDiscountCodes;

    // استخدام دالة التنسيق لعرض الـ deliveryFee, technicianFee, discountAmount, totalPrice
    final String formattedDeliveryFee = _formatPrice(deliveryFee);
    final String formattedTechnicianFee =
    _formatPrice(requestTechnician ? technicianFee : 0.0);
    final String formattedDiscount =
    isDiscountApplied ? _formatPrice(discountAmount) : '0';
    final String formattedTotalPrice = _formatPrice(totalPrice);

    // حساب إجمالي المنتجات قبل الخصم:
    final double productsTotal =
    cartItems.fold(0.0, (sum, item) => sum + ((item['price'] ?? 0.0) * (item['quantity'] ?? 1)));
    final String formattedProductsTotal = _formatPrice(productsTotal);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'تفاصيل الطلب',
          style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold),
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
      ),
      body: isLoading
          ? Center(
        child: SpinKitFadingCircle(
          color: Colors.blueAccent,
          size: 50.0,
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // بطاقة بيانات العميل
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'معلومات العميل',
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        label: 'اسم الزبون',
                        icon: Icons.person,
                        validator: (value) =>
                        value!.isEmpty ? 'يرجى إدخال الاسم' : null,
                        onSaved: (value) => buyerName = value!,
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        label: 'رقم الهاتف',
                        icon: Icons.phone,
                        validator: (value) =>
                        value!.isEmpty ? 'يرجى إدخال الرقم' : null,
                        onSaved: (value) => buyerNumber = value!,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        label: 'رقم الهاتف الاحتياطي',
                        icon: Icons.phone_android,
                        isOptional: true,
                        validator: (_) => null,
                        onSaved: (value) => backupNumber = value!,
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // بطاقة معلومات التوصيل
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'معلومات التوصيل',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Dropdown المحافظة
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'اختر المحافظة',
                        prefixIcon: Icon(Icons.location_city),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      value: selectedGovernorateId,
                      items: governorates
                          .map(
                            (gov) => DropdownMenuItem<String>(
                          value: gov.id,
                          child: Text(gov.name),
                        ),
                      )
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedGovernorateId = val;
                          if (val != null) {
                            fetchDeliveryFee(val);
                          }
                        });
                      },
                      validator: (value) =>
                      value == null ? 'يرجى اختيار المحافظة' : null,
                    ),
                    const SizedBox(height: 16),
                    // TextFormField المنطقة
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'اسم المنطقة',
                        prefixIcon: Icon(Icons.map),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) =>
                      value!.isEmpty ? 'يرجى إدخال اسم المنطقة' : null,
                      onSaved: (value) => areaName = value!,
                    ),
                    const SizedBox(height: 16),
                    // Switch لطلب الفني
                    SwitchListTile(
                      title: Text(
                        'طلب فني (رسوم إضافية)',
                        style: GoogleFonts.cairo(fontSize: 16),
                      ),
                      value: requestTechnician,
                      onChanged: (val) {
                        setState(() {
                          requestTechnician = val;
                          _calculateTotalPrice();
                        });
                      },
                      secondary: const Icon(Icons.build),
                      activeColor: Colors.blueAccent,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // بطاقة كود الخصم
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'كود الخصم',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'كود الخصم',
                              prefixIcon: Icon(Icons.card_giftcard),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onChanged: (value) {
                              discountCodeInput = value.trim();
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed:
                          isDiscountApplied ? null : _applyDiscount,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'تطبيق',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (discountError.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          discountError,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    if (isDiscountApplied)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 5),
                            Text(
                              'تم تطبيق الخصم!',
                              style: TextStyle(color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // بطاقة ملخص الأسعار
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ملخص الطلب',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPriceRow(
                      'إجمالي المنتجات:',
                      '${formattedProductsTotal} \$',
                    ),
                    _buildPriceRow(
                      'رسوم التوصيل:',
                      '$formattedDeliveryFee \$',
                    ),
                    _buildPriceRow(
                      'رسوم الفني:',
                      '$formattedTechnicianFee \$',
                    ),
                    if (isDiscountApplied)
                      _buildPriceRow(
                        'الخصم:',
                        '-$formattedDiscount \$',
                      ),
                    const Divider(),
                    _buildPriceRow(
                      'الإجمالي الكلي:',
                      '$formattedTotalPrice \$',
                      isTotal: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // زر الإرسال
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'إرسال الطلب',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
