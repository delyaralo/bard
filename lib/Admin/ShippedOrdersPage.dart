// lib/pages/shipped_orders_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:url_launcher/url_launcher.dart';
import 'OrdersPage.dart';
class ShippedOrdersPage extends StatefulWidget {
  @override
  _ShippedOrdersPageState createState() => _ShippedOrdersPageState();
}

class _ShippedOrdersPageState extends State<ShippedOrdersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الطلبات المشحونة',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.green, // لون مختلف للتمييز
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('orders')
            .where('orderStatus', isEqualTo: 'shipped') // فلترة الطلبات المشحونة
            .orderBy('timestamp', descending: true) // ترتيب حسب التاريخ
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
                color: Colors.green,
                size: 50.0,
              ),
            );
          }

          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'لا توجد طلبات مشحونة.',
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
