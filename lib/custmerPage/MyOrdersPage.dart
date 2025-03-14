import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({Key? key}) : super(key: key);

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  late Future<String> _deviceIdFuture;
  Box? _ordersBox;

  @override
  void initState() {
    super.initState();
    _deviceIdFuture = _getDeviceId();
    _initializeOrdersBox();
  }

  Future<void> _initializeOrdersBox() async {
    _ordersBox = await Hive.openBox('orders');
    setState(() {});
  }

  // جلب deviceId من SharedPreferences
  Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('device_id') ?? '';
  }

  // تخزين بيانات الطلبات في الكاش داخل Hive
  Future<void> _cacheOrders(List<QueryDocumentSnapshot> ordersDocs) async {
    if (_ordersBox != null) {
      final ordersList = ordersDocs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
      await _ordersBox!.put('ordersData', ordersList);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('طلباتي السابقة'),
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
      ),
      backgroundColor: Colors.grey[100],
      body: FutureBuilder<String>(
        future: _deviceIdFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            // في انتظار جلب deviceId
            return Center(child: CircularProgressIndicator());
          }

          final deviceId = snapshot.data!;
          if (deviceId.isEmpty) {
            return Center(child: Text('لا يمكن تحديد الجهاز (deviceId).'));
          }

          // جلب الطلبات من Firestore بناءً على deviceId
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('deviceId', isEqualTo: deviceId)
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, orderSnapshot) {
              // إذا كان الاتصال بطيئًا نحاول استرجاع الكاش
              if (orderSnapshot.connectionState == ConnectionState.waiting) {
                if (_ordersBox != null &&
                    _ordersBox!.containsKey('ordersData')) {
                  final cachedOrders =
                  _ordersBox!.get('ordersData') as List<dynamic>;
                  if (cachedOrders.isNotEmpty) {
                    return _buildOrdersList(cachedOrders);
                  }
                }
                return Center(child: CircularProgressIndicator());
              }
              // في حال حدوث خطأ نحاول استرجاع الكاش
              if (orderSnapshot.hasError) {
                if (_ordersBox != null &&
                    _ordersBox!.containsKey('ordersData')) {
                  final cachedOrders =
                  _ordersBox!.get('ordersData') as List<dynamic>;
                  if (cachedOrders.isNotEmpty) {
                    return _buildOrdersList(cachedOrders);
                  }
                }
                return Center(child: Text('حدث خطأ: ${orderSnapshot.error}'));
              }
              // إذا لم يتم جلب بيانات أو القائمة فارغة
              if (!orderSnapshot.hasData ||
                  orderSnapshot.data!.docs.isEmpty) {
                if (_ordersBox != null &&
                    _ordersBox!.containsKey('ordersData')) {
                  final cachedOrders =
                  _ordersBox!.get('ordersData') as List<dynamic>;
                  if (cachedOrders.isNotEmpty) {
                    return _buildOrdersList(cachedOrders);
                  }
                }
                return Center(child: Text('لا يوجد طلبات سابقة.'));
              }

              final orderDocs = orderSnapshot.data!.docs;
              // حفظ الطلبات في الكاش
              _cacheOrders(orderDocs);
              final ordersList = orderDocs
                  .map((doc) => doc.data() as Map<String, dynamic>)
                  .toList();
              return _buildOrdersList(ordersList);
            },
          );
        },
      ),
    );
  }

  /// دالة لبناء قائمة الطلبات من القائمة المعطاة
  Widget _buildOrdersList(List<dynamic> ordersList) {
    return ListView.builder(
      padding: EdgeInsets.all(8.0),
      itemCount: ordersList.length,
      itemBuilder: (context, index) {
        final data = ordersList[index] as Map<String, dynamic>;

        final String buyerName = data['buyerName'] ?? 'غير معروف';
        final double totalPrice =
        (data['totalPrice'] ?? 0.0).toDouble();
        final Timestamp? timestamp =
        data['timestamp'] is Timestamp ? data['timestamp'] as Timestamp? : null;
        final DateTime dateTime =
        timestamp != null ? timestamp.toDate() : DateTime.now();
        final String orderStatus = data['orderStatus'] ?? 'pending';
        final List<dynamic> products = data['products'] ?? [];
        // يمكن تخزين رقم الطلب في الكاش ضمن data في حالة الحاجة
        final String docId = data['docId'] ?? '';

        return _buildOrderCard(
          context: context,
          buyerName: buyerName,
          totalPrice: totalPrice,
          dateTime: dateTime,
          orderStatus: orderStatus,
          products: products,
          docId: docId,
        );
      },
    );
  }

  /// دالة لبناء بطاقة الطلب مع عرض تفاصيله
  Widget _buildOrderCard({
    required BuildContext context,
    required String buyerName,
    required double totalPrice,
    required DateTime dateTime,
    required String orderStatus,
    required List<dynamic> products,
    required String docId,
  }) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 3.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // المعلومات الأساسية للطلب
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'اسم المشتري: $buyerName',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusChip(orderStatus),
              ],
            ),
            SizedBox(height: 8),
            // تاريخ الطلب
            Text(
              'تاريخ الطلب: ${DateFormat('yyyy-MM-dd | HH:mm').format(dateTime)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            SizedBox(height: 4),
            // إجمالي السعر
            Text(
              'الإجمالي: $totalPrice دينار',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.teal[700],
              ),
            ),
            Divider(thickness: 1.5, height: 20),
            // عنوان المنتجات
            Text(
              'المنتجات:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            // عرض قائمة المنتجات داخل الطلب
            ListView.builder(
              itemCount: products.length,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, prodIndex) {
                final prod = products[prodIndex] as Map<String, dynamic>;
                final String name = prod['name'] ?? 'بدون اسم';
                final double price = (prod['price'] ?? 0.0).toDouble();
                final String imageUrl = prod['imageUrl'] ?? '';
                final int quantity = prod['quantity'] ?? 1;
                final String currency = prod['currency'] ?? 'IQD';

                return _buildProductItem(
                  name: name,
                  price: price,
                  quantity: quantity,
                  imageUrl: imageUrl,
                  currency: currency,
                );
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'رقم الطلب: $docId',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ويدجت لعرض حالة الطلب باستخدام Chip ملون
  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    IconData iconData;
    String label;
    switch (status) {
      case 'pending':
        backgroundColor = Colors.orange;
        iconData = Icons.watch_later_outlined;
        label = 'قيد الانتظار';
        break;
      case 'delivered':
        backgroundColor = Colors.green;
        iconData = Icons.check_circle_outline;
        label = 'تم التوصيل';
        break;
      case 'canceled':
        backgroundColor = Colors.red;
        iconData = Icons.cancel_outlined;
        label = 'ملغي';
        break;
      case 'in-progress':
        backgroundColor = Colors.blue;
        iconData = Icons.delivery_dining;
        label = 'قيد التوصيل';
        break;
      default:
        backgroundColor = Colors.green;
        iconData = Icons.info_outline;
        label = status;
        break;
    }
    return Chip(
      avatar: Icon(iconData, color: Colors.white, size: 18),
      label: Text(label, style: TextStyle(color: Colors.white)),
      backgroundColor: backgroundColor,
    );
  }

  /// ويدجت لعنصر المنتج داخل الطلب
  Widget _buildProductItem({
    required String name,
    required double price,
    required int quantity,
    required String imageUrl,
    required String currency,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6.0),
      padding: EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: SizedBox(
              width: 60,
              height: 60,
              child: imageUrl.isNotEmpty
                  ? FadeInImage.assetNetwork(
                placeholder: 'assets/placeholder.png',
                image: imageUrl,
                fit: BoxFit.cover,
              )
                  : Image.asset('assets/placeholder.png', fit: BoxFit.cover),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text('السعر: $price $currency'),
              ],
            ),
          ),
          Text('x$quantity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              )),
        ],
      ),
    );
  }
}
