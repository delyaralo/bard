import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({Key? key}) : super(key: key);

  @override
  _OrderListPageState createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  Box? _ordersBox;

  @override
  void initState() {
    super.initState();
    _initializeOrdersBox();
  }

  Future<void> _initializeOrdersBox() async {
    _ordersBox = await Hive.openBox('orders');
    setState(() {});
  }

  /// دالة لتحويل قيمة [totalPrice] إلى رقم عشري
  double parseTotalPrice(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  /// دالة لتخزين بيانات الطلبات في الكاش
  Future<void> _cacheOrders(List<QueryDocumentSnapshot> docs) async {
    if (_ordersBox != null) {
      final ordersList = docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['docId'] = doc.id;
        return data;
      }).toList();
      await _ordersBox!.put('ordersData', ordersList);
    }
  }

  /// دالة لاسترجاع بيانات الطلبات من الكاش
  List<dynamic>? _getCachedOrders() {
    if (_ordersBox != null && _ordersBox!.containsKey('ordersData')) {
      return _ordersBox!.get('ordersData');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("قائمة الطلبات"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          List<dynamic>? ordersList;

          if (snapshot.hasError) {
            // في حال حدوث خطأ نحاول استرجاع البيانات من الكاش
            ordersList = _getCachedOrders();
            if (ordersList != null && ordersList.isNotEmpty) {
              return _buildOrderList(ordersList);
            }
            return Center(
              child: Text(
                "حدث خطأ: ${snapshot.error}",
                style: const TextStyle(fontSize: 18, color: Colors.red),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            // أثناء انتظار البيانات نحاول عرض البيانات من الكاش إن وُجدت
            ordersList = _getCachedOrders();
            if (ordersList != null && ordersList.isNotEmpty) {
              return _buildOrderList(ordersList);
            }
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            ordersList = _getCachedOrders();
            if (ordersList != null && ordersList.isNotEmpty) {
              return _buildOrderList(ordersList);
            }
            return const Center(child: Text("لا توجد طلبات."));
          }

          // تحديث الكاش عند جلب البيانات الجديدة من Firestore
          final docs = snapshot.data!.docs;
          _cacheOrders(docs);
          ordersList = docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['docId'] = doc.id;
            return data;
          }).toList();

          return _buildOrderList(ordersList);
        },
      ),
    );
  }

  /// دالة لبناء قائمة الطلبات باستخدام البيانات المعطاة
  Widget _buildOrderList(List<dynamic> ordersList) {
    return ListView.builder(
      itemCount: ordersList.length,
      itemBuilder: (context, index) {
        final doc = ordersList[index] as Map<String, dynamic>;

        // معالجة التاريخ
        DateTime timestamp;
        if (doc['timestamp'] != null && doc['timestamp'] is Timestamp) {
          timestamp = (doc['timestamp'] as Timestamp).toDate();
        } else {
          timestamp = DateTime.now();
        }

        // معالجة السعر
        double totalPrice = parseTotalPrice(doc['totalPrice']);

        // قراءة باقي الحقول مع توفير قيمة افتراضية
        String buyerName = doc['buyerName'] ?? "غير معروف";
        String areaName = doc['areaName'] ?? "غير محدد";
        String orderStatus = doc['orderStatus'] ?? "غير محدد";

        // افتراض وجود حقل "imageUrl" لعرض صورة الطلب إن وُجدت
        String imageUrl = doc['imageUrl'] ?? '';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(10),
            leading: imageUrl.isNotEmpty
                ? CachedNetworkImage(
              imageUrl: imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 60,
                height: 60,
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) =>
              const Icon(Icons.error, color: Colors.red),
            )
                : const Icon(Icons.image, size: 60),
            title: Text("رقم الطلب: ${doc['docId']}",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),
                Text("اسم الزبون: $buyerName"),
                Text("المنطقة: $areaName"),
                Text("السعر: ${NumberFormat("#,### IQD").format(totalPrice)}"),
                Text("الحالة: $orderStatus"),
                Text("التاريخ: ${DateFormat('yyyy-MM-dd HH:mm').format(timestamp)}"),
              ],
            ),
            // يمكنك إضافة تفاعل إضافي هنا مثل التنقل إلى تفاصيل الطلب
            onTap: () {
              // مثال للتنقل: Navigator.push(context, MaterialPageRoute(builder: (context) => OrderDetailPage(orderData: doc)));
            },
          ),
        );
      },
    );
  }
}
