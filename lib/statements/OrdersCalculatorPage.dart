import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const OrdersDashboardApp());
}

class OrdersDashboardApp extends StatelessWidget {
  const OrdersDashboardApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "لوحة تحليل الطلبات",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const OrdersDashboardPage(),
    );
  }
}

class OrdersDashboardPage extends StatefulWidget {
  const OrdersDashboardPage({Key? key}) : super(key: key);

  @override
  _OrdersDashboardPageState createState() => _OrdersDashboardPageState();
}

class _OrdersDashboardPageState extends State<OrdersDashboardPage> {
  // متغيرات الفلترة
  String _selectedFilter = 'all'; // خيارات: all, last_week, last_month, last_year, custom
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  bool _isLoading = false;

  // المتغيرات الحسابية
  int totalOrders = 0;
  int countPending = 0;
  int countShipped = 0;
  double amountPending = 0;
  double amountShipped = 0;
  List<Map<String, dynamic>> ordersList = [];

  // متغيرات الفرز
  int? _sortColumnIndex;
  bool _sortAscending = true;

  double parsePrice(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// جلب البيانات من Firestore مع تطبيق الفلترة
  Future<void> fetchOrdersData() async {
    setState(() => _isLoading = true);

    Query query = FirebaseFirestore.instance.collection('orders');
    DateTime now = DateTime.now();
    DateTime? filterStart;
    DateTime? filterEnd = now;

    // تحديد الفترة بناءً على نوع الفلترة
    if (_selectedFilter == 'last_week') {
      filterStart = now.subtract(const Duration(days: 7));
    } else if (_selectedFilter == 'last_month') {
      filterStart = now.subtract(const Duration(days: 30));
    } else if (_selectedFilter == 'last_year') {
      filterStart = now.subtract(const Duration(days: 365));
    } else if (_selectedFilter == 'custom') {
      if (_customStartDate != null && _customEndDate != null) {
        filterStart = _customStartDate;
        filterEnd = _customEndDate;
      }
    }

    // تطبيق الفلترة بالتاريخ إن وجدت
    if (filterStart != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: filterStart);
      if (filterEnd != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: filterEnd);
      }
    }

    try {
      QuerySnapshot snapshot = await query.get();
      int _total = snapshot.docs.length;
      int _pending = 0;
      int _shipped = 0;
      double _pendingAmount = 0;
      double _shippedAmount = 0;

      List<Map<String, dynamic>> tempOrders = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // حقل الحالة
        String status = data['orderStatus']?.toString() ?? '';
        // حقل السعر
        double price = parsePrice(data['totalPrice']);

        // حصر الطلبات المعلقة أو المشحونة
        if (status == 'pending') {
          _pending++;
          _pendingAmount += price;
        } else if (status == 'shipped') {
          _shipped++;
          _shippedAmount += price;
        }

        // حقل التاريخ
        DateTime orderDate;
        if (data['timestamp'] != null && data['timestamp'] is Timestamp) {
          orderDate = (data['timestamp'] as Timestamp).toDate();
        } else {
          orderDate = DateTime.now();
        }

        // تفادي null في الحقول النصية
        String buyerName = data['buyerName']?.toString() ?? "غير معروف";
        String buyerNumber = data['buyerNumber']?.toString() ?? "غير متوفر";
        String areaName = data['areaName']?.toString() ?? "غير محدد";
        bool requestTech = data['requestTechnician'] ?? false;

        tempOrders.add({
          'id': doc.id,
          'buyerName': buyerName,
          'buyerNumber': buyerNumber,
          'areaName': areaName,
          'totalPrice': price,
          'orderStatus': status,
          'timestamp': orderDate,
          'requestTechnician': requestTech,
        });
      }

      setState(() {
        totalOrders = _total;
        countPending = _pending;
        countShipped = _shipped;
        amountPending = _pendingAmount;
        amountShipped = _shippedAmount;
        ordersList = tempOrders;
      });
    } catch (e) {
      print("Error fetching data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// اختيار فترة زمنية مخصصة
  Future<void> _pickCustomDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchOrdersData();
  }

  /// إنشاء أقسام الرسم البياني الدائري
  List<PieChartSectionData> showingPieChartSections() {
    double totalCount = (countPending + countShipped).toDouble();
    if (totalCount == 0) {
      return [
        PieChartSectionData(
          value: 1,
          title: "0%",
          color: Colors.grey,
          radius: 40,
          titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ];
    }
    double pendingPercent = (countPending / totalCount) * 100;
    double shippedPercent = (countShipped / totalCount) * 100;
    return [
      PieChartSectionData(
        value: countPending.toDouble(),
        title: "${pendingPercent.toStringAsFixed(1)}%",
        color: Colors.orange,
        radius: 40,
        titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        value: countShipped.toDouble(),
        title: "${shippedPercent.toStringAsFixed(1)}%",
        color: Colors.green,
        radius: 40,
        titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    ];
  }

  /// بطاقة صغيرة للملخص
  Widget buildMiniCard({
    required String title,
    required String value,
    required Color color,
    double fontSize = 14,
  }) {
    return Container(
      width: 190,
      height: 120,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: TextStyle(color: Colors.white, fontSize: fontSize + 4, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  /// قسم الفلترة
  Widget buildFilterSection() {
    return Row(
      children: [
        Expanded(
          child: DropdownButton<String>(
            value: _selectedFilter,
            onChanged: (String? value) {
              if (value != null) {
                setState(() => _selectedFilter = value);
              }
            },
            items: const [
              DropdownMenuItem(child: Text("الكل"), value: "all"),
              DropdownMenuItem(child: Text("آخر أسبوع"), value: "last_week"),
              DropdownMenuItem(child: Text("آخر شهر"), value: "last_month"),
              DropdownMenuItem(child: Text("آخر سنة"), value: "last_year"),
              DropdownMenuItem(child: Text("تاريخ محدد"), value: "custom"),
            ],
          ),
        ),
        if (_selectedFilter == 'custom')
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _pickCustomDateRange,
          ),
        ElevatedButton(
          onPressed: fetchOrdersData,
          child: const Text("تطبيق الفلترة"),
        ),
      ],
    );
  }

  /// قسم الملخص الكلي + الرسم البياني
  Widget buildSummarySection(BoxConstraints constraints) {
    double screenWidth = constraints.maxWidth;
    bool isDesktop = screenWidth > 800;
    double chartSize = isDesktop ? 300 : 200;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: chartSize,
              height: chartSize,
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: PieChart(
                  PieChartData(
                    sections: showingPieChartSections(),
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Wrap(
                alignment: WrapAlignment.center,
                children: [
                  buildMiniCard(
                    title: "الطلبات المشحونة",
                    value: "$countShipped",
                    color: Colors.green,
                  ),
                  buildMiniCard(
                    title: "الطلبات المعلقة",
                    value: "$countPending",
                    color: Colors.orange,
                  ),
                  buildMiniCard(
                    title: "مبلغ الطلبات المشحونة",
                    value: NumberFormat("#,###").format(amountShipped),
                    color: Colors.blue,
                  ),
                  buildMiniCard(
                    title: "مبلغ الطلبات المعلقة",
                    value: NumberFormat("#,###").format(amountPending),
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// بناء جدول الطلبات مع فرز لجميع الأعمدة
  Widget buildOrdersTable() {
    double screenWidth = MediaQuery.of(context).size.width;
    // تكبير الخط أكثر لجعل الجدول واضحًا على الشاشات الكبيرة
    double headerFontSize = screenWidth > 900 ? 20 : (screenWidth > 600 ? 16 : 14);
    double cellFontSize = screenWidth > 900 ? 18 : (screenWidth > 600 ? 14 : 12);

    final headingStyle = TextStyle(fontSize: headerFontSize, fontWeight: FontWeight.bold);
    final dataStyle = TextStyle(fontSize: cellFontSize);

    // دوال المقارنة لكل حقل
    int compareString(String a, String b, bool ascending) =>
        ascending ? a.compareTo(b) : b.compareTo(a);
    int compareDouble(double a, double b, bool ascending) =>
        ascending ? a.compareTo(b) : b.compareTo(a);
    int compareDate(DateTime a, DateTime b, bool ascending) =>
        ascending ? a.compareTo(b) : b.compareTo(a);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      padding: const EdgeInsets.all(8),
      width: double.infinity, // لتمديد الجدول قدر الإمكان
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          sortColumnIndex: _sortColumnIndex,
          sortAscending: _sortAscending,
          headingRowColor: MaterialStateColor.resolveWith((states) => Colors.grey[200]!),
          columnSpacing: 20,
          horizontalMargin: 10,
          headingTextStyle: headingStyle,
          dataTextStyle: dataStyle,
          columns: [
            // رقم الطلب
            DataColumn(
              label: Text("رقم الطلب", style: headingStyle),
              onSort: (columnIndex, ascending) {
                setState(() {
                  _sortColumnIndex = columnIndex;
                  _sortAscending = ascending;
                  ordersList.sort((a, b) {
                    return compareString(a['id'], b['id'], ascending);
                  });
                });
              },
            ),
            // اسم الزبون
            DataColumn(
              label: Text("اسم الزبون", style: headingStyle),
              onSort: (columnIndex, ascending) {
                setState(() {
                  _sortColumnIndex = columnIndex;
                  _sortAscending = ascending;
                  ordersList.sort((a, b) {
                    return compareString(a['buyerName'], b['buyerName'], ascending);
                  });
                });
              },
            ),
            // رقم الزبون
            DataColumn(
              label: Text("رقم الزبون", style: headingStyle),
              onSort: (columnIndex, ascending) {
                setState(() {
                  _sortColumnIndex = columnIndex;
                  _sortAscending = ascending;
                  ordersList.sort((a, b) {
                    return compareString(a['buyerNumber'], b['buyerNumber'], ascending);
                  });
                });
              },
            ),
            // طلب فني
            DataColumn(
              label: Text("طلب فني", style: headingStyle),
              onSort: (columnIndex, ascending) {
                setState(() {
                  _sortColumnIndex = columnIndex;
                  _sortAscending = ascending;
                  ordersList.sort((a, b) {
                    // عرض "نعم"/"لا" لكن الأصل bool
                    // نقارنه بالأولوية: false < true
                    bool valA = a['requestTechnician'] == true;
                    bool valB = b['requestTechnician'] == true;
                    if (ascending) {
                      return valA ? 1 : -1; // إذا valA = false => -1 لجعله أولاً
                    } else {
                      return valA ? -1 : 1;
                    }
                  });
                });
              },
            ),
            // المنطقة
            DataColumn(
              label: Text("المنطقة", style: headingStyle),
              onSort: (columnIndex, ascending) {
                setState(() {
                  _sortColumnIndex = columnIndex;
                  _sortAscending = ascending;
                  ordersList.sort((a, b) {
                    return compareString(a['areaName'], b['areaName'], ascending);
                  });
                });
              },
            ),
            // السعر
            DataColumn(
              label: Text("السعر", style: headingStyle),
              numeric: true,
              onSort: (columnIndex, ascending) {
                setState(() {
                  _sortColumnIndex = columnIndex;
                  _sortAscending = ascending;
                  ordersList.sort((a, b) {
                    double priceA = a['totalPrice'] as double;
                    double priceB = b['totalPrice'] as double;
                    return compareDouble(priceA, priceB, ascending);
                  });
                });
              },
            ),
            // الحالة
            DataColumn(
              label: Text("الحالة", style: headingStyle),
              onSort: (columnIndex, ascending) {
                setState(() {
                  _sortColumnIndex = columnIndex;
                  _sortAscending = ascending;
                  ordersList.sort((a, b) {
                    return compareString(a['orderStatus'], b['orderStatus'], ascending);
                  });
                });
              },
            ),
            // التاريخ
            DataColumn(
              label: Text("التاريخ", style: headingStyle),
              onSort: (columnIndex, ascending) {
                setState(() {
                  _sortColumnIndex = columnIndex;
                  _sortAscending = ascending;
                  ordersList.sort((a, b) {
                    DateTime dateA = a['timestamp'] as DateTime;
                    DateTime dateB = b['timestamp'] as DateTime;
                    return compareDate(dateA, dateB, ascending);
                  });
                });
              },
            ),
          ],
          rows: ordersList.map((order) {
            // تحديد لون الصف حسب حالة الطلب
            final rowColor = MaterialStateProperty.resolveWith<Color?>((states) {
              if (order['orderStatus'] == 'pending') {
                return Colors.orange.withOpacity(0.1);
              } else if (order['orderStatus'] == 'shipped') {
                return Colors.green.withOpacity(0.1);
              }
              return null; // اللون الافتراضي
            });

            final isRequestTechnician = order['requestTechnician'] == true ? "نعم" : "لا";

            return DataRow(
              color: rowColor,
              cells: [
                DataCell(Text(order['id'], style: dataStyle)),
                DataCell(Text(order['buyerName'], style: dataStyle)),
                DataCell(Text(order['buyerNumber'], style: dataStyle)),
                DataCell(Text(isRequestTechnician, style: dataStyle)),
                DataCell(Text(order['areaName'], style: dataStyle)),
                DataCell(Text(NumberFormat("#,###").format(order['totalPrice']), style: dataStyle)),
                DataCell(Text(order['orderStatus'], style: dataStyle)),
                DataCell(Text(
                  DateFormat("yyyy-MM-dd HH:mm").format(order['timestamp']),
                  style: dataStyle,
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("لوحة تحليل الطلبات"),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFF8F8F8),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildFilterSection(),
            const SizedBox(height: 16),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
              builder: (context, constraints) {
                return buildSummarySection(constraints);
              },
            ),
            const SizedBox(height: 24),
            const Text(
              "تفاصيل الطلبات",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : buildOrdersTable(),
          ],
        ),
      ),
    );
  }
}
