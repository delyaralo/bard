// lib/pages/orders_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:url_launcher/url_launcher.dart';

class OrdersPage extends StatefulWidget {
  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الطلبات قيد الانتظار',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('orders')
            .where('orderStatus', isEqualTo: 'pending') // فلترة الطلبات ذات الحالة "pending"
            .orderBy('timestamp', descending: true) // ترتيب حسب 'timestamp' تنازليًا
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'حدث خطأ أثناء تحميل الطلبات.',
                style: GoogleFonts.cairo(fontSize: 18, color: Colors.red),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: SpinKitFadingCircle(
                color: Colors.blueAccent,
                size: 50.0,
              ),
            );
          }

          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'لا توجد طلبات قيد الانتظار.',
                style: GoogleFonts.cairo(fontSize: 20, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var order = snapshot.data!.docs[index];
              return OrderCard(
                orderData: order.data() as Map<String, dynamic>,
                orderId: order.id, // تمرير معرف الطلب
              );
            },
          );
        },
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final String orderId; // معرف الطلب

  OrderCard({required this.orderData, required this.orderId});

  // دالة لفتح واتساب مع رقم الزبون
  void _openWhatsApp(String phone, BuildContext context) async {
    final Uri whatsappUri = Uri.parse("https://wa.me/$phone");
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      _showSnackBar(context, 'لا يمكن فتح واتساب على هذا الجهاز.');
    }
  }

  // دالة لفتح تطبيق الهاتف مع الرقم
  void _makePhoneCall(String phone, BuildContext context) async {
    final Uri phoneUri = Uri.parse("tel:$phone");
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
    } else {
      _showSnackBar(context, 'لا يمكن فتح تطبيق الهاتف على هذا الجهاز.');
    }
  }

  // دالة لإظهار SnackBar
  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // دالة لتحديث حالة الطلب
  Future<void> _updateOrderStatus(BuildContext context) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد'),
        content: Text('هل تريد تغيير حالة الطلب إلى "shipped"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('لا'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('نعم'),
          ),
        ],
      ),
    );

    if (confirm ?? false) {
      try {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId) // استخدام معرف فريد
            .update({'orderStatus': 'shipped'});
        _showSnackBar(context, 'تم تحديث حالة الطلب إلى "shipped".');
      } catch (e) {
        _showSnackBar(context, 'فشل في تحديث حالة الطلب.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // إضافة طباعة بيانات الطلب للتصحيح
    print("Order Data: $orderData");

    String customerName = orderData['buyerName'] ?? 'غير معروف';
    String customerPhone = orderData['buyerNumber'] ?? '';
    String customerWhatsApp = orderData['customerWhatsApp'] ?? customerPhone;
    double deliveryFee = double.tryParse(orderData['deliveryFee'].toString()) ?? 0.0;
    double technicianFee = double.tryParse(orderData['technicianFee'].toString()) ?? 0.0;
    double discountAmount = double.tryParse(orderData['discountAmount'].toString()) ?? 0.0;
    double totalPrice = double.tryParse(orderData['totalPrice'].toString()) ?? 0.0;
    String orderStatus = orderData['orderStatus']?.toLowerCase() ?? 'pending'; // تحويل إلى حروف صغيرة
    Timestamp orderDateTimestamp = orderData['timestamp'] ?? Timestamp.now();
    DateTime orderDate = orderDateTimestamp.toDate();
    bool requestTechnician = orderData['requestTechnician'] ?? false;


    List<dynamic> products = orderData['products'] ?? [];

    // حساب إجمالي المنتجات
    double productsTotal = products.fold(
        0.0, (sum, item) => sum + ((item['price'] ?? 0.0) * (item['quantity'] ?? 1)));

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // معلومات الزبون
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.blueAccent,
                  child: Text(
                    customerName.isNotEmpty ? customerName[0].toUpperCase() : '?',
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerName,
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'رقم الهاتف: $customerPhone',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            // قائمة المنتجات
            Text(
              'المنتجات:',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            SizedBox(height: 8),
            Column(
              children: products.map<Widget>((product) {
                String productName = product['name'] ?? 'منتج غير معروف';
                int quantity = product['quantity'] ?? 1;
                double price = double.tryParse(product['price'].toString()) ?? 0.0;
                String variant = product['variant'] ?? '';

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title: Text(
                    productName,
                    style: GoogleFonts.cairo(fontSize: 16),
                  ),
                  subtitle: variant.isNotEmpty
                      ? Text(
                    'الطراز: $variant',
                    style: GoogleFonts.cairo(fontSize: 14, color: Colors.black54),
                  )
                      : null,
                  trailing: Text(
                    'x$quantity',
                    style: GoogleFonts.cairo(fontSize: 16, color: Colors.black87),
                  ),
                );
              }).toList(),
            ),
            Divider(thickness: 1.5, color: Colors.blueAccent),
            SizedBox(height: 8),
            // معلومات الطلب
            _buildPriceRow(
              'إجمالي المنتجات:',
              '${productsTotal.toStringAsFixed(2)} \$',
            ),
            SizedBox(height: 8),
            _buildPriceRow(
              'رسوم التوصيل:',
              '${deliveryFee.toStringAsFixed(2)} \$',
            ),
            SizedBox(height: 8),
            _buildPriceRow(
              'رسوم الفني:',
              '${requestTechnician ? technicianFee.toStringAsFixed(2) : '0.00'} \$',

            ),
            SizedBox(height: 8),
            if (discountAmount > 0)
              _buildPriceRow(
                'الخصم:',
                '-${discountAmount.toStringAsFixed(2)} \$',
                isTotal: false,
              ),
            SizedBox(height: 8),
            Divider(),
            SizedBox(height: 8),
            _buildPriceRow(
              'الإجمالي الكلي:',
              '${totalPrice.toStringAsFixed(2)} \$',
              isTotal: true,
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'حالة الطلب:',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  orderStatus.capitalizeFirstLetter(), // لتحويل الحرف الأول إلى كبير
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(orderStatus),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'تاريخ الطلب: ${_formatDate(orderDate)}',
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: 16),
            // أزرار التواصل والتحديث
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // زر واتساب
                IconButton(
                  icon: Icon(Icons.chat, color: Colors.green),
                  onPressed: () {
                    if (customerWhatsApp.isNotEmpty) {
                      _openWhatsApp(customerWhatsApp, context);
                    } else {
                      _showSnackBar(context, 'رقم واتساب غير متوفر للزبون.');
                    }
                  },
                  tooltip: 'تواصل عبر واتساب',
                ),
                // زر الهاتف
                IconButton(
                  icon: Icon(Icons.phone, color: Colors.blueAccent),
                  onPressed: () {
                    if (customerPhone.isNotEmpty) {
                      _makePhoneCall(customerPhone, context);
                    } else {
                      _showSnackBar(context, 'رقم هاتف غير متوفر للزبون.');
                    }
                  },
                  tooltip: 'تواصل عبر الهاتف',
                ),
                // زر لتحديث حالة الطلب
                IconButton(
                  icon: Icon(Icons.update, color: Colors.orange),
                  onPressed: () {
                    _updateOrderStatus(context);
                  },
                  tooltip: 'تحديث حالة الطلب',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// دالة لبناء صف السعر بشكل منظم
Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: GoogleFonts.cairo(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500),
      ),
      Text(
        value,
        style: GoogleFonts.cairo(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? Colors.redAccent : Colors.black),
      ),
    ],
  );
}

extension StringExtension on String {
  String capitalizeFirstLetter() {
    if (this.isEmpty) return this;
    return this[0].toUpperCase() + this.substring(1);
  }
}

// دالة لتنسيق التاريخ
String _formatDate(DateTime date) {
  return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
}

// دالة لتحديد لون حالة الطلب
Color _getStatusColor(String status) {
  switch (status) {
    case 'pending':
      return Colors.orange;
    case 'shipped':
      return Colors.blueAccent;
    case 'delivered':
      return Colors.green;
    case 'cancelled':
      return Colors.red;
    default:
      return Colors.grey;
  }
}
