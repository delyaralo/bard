import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';

/// خيارات المدة الزمنية للفلترة
enum TimeRangeOption {
  none,      // بدون فلترة زمنية
  lastWeek,  // آخر أسبوع
  lastMonth, // آخر شهر
  lastYear,  // آخر سنة
  custom,    // اختيار تاريخين (من -> إلى)
}

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool isLoading = true;

  // البيانات الأصلية من Firestore
  List<Map<String, dynamic>> techniciansData = [];
  List<Map<String, dynamic>> requestsData = [];

  // متغيّرات الفلترة
  String? selectedArea;              // المنطقة المختارة
  String? selectedTechnicianName;    // اسم الفني المختار
  TimeRangeOption selectedTimeRange = TimeRangeOption.none;
  DateTime? customStartDate;         // تاريخ بداية للفترة المخصصة
  DateTime? customEndDate;           // تاريخ نهاية للفترة المخصصة

  // بوكس الكاش باستخدام Hive
  Box? _analyticsBox;

  @override
  void initState() {
    super.initState();
    _initializeAnalyticsBox().then((_) => fetchData());
  }

  /// تهيئة بوكس الكاش الخاص بالتحليلات
  Future<void> _initializeAnalyticsBox() async {
    _analyticsBox = await Hive.openBox('analytics');
    setState(() {});
  }

  /// جلب البيانات من Firestore وتحديث الكاش
  Future<void> fetchData() async {
    setState(() => isLoading = true);

    try {
      // جلب بيانات الفنيين
      final techniciansSnapshot = await FirebaseFirestore.instance
          .collection('technicians')
          .get();
      techniciansData = techniciansSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      // جلب بيانات الطلبات
      final requestsSnapshot = await FirebaseFirestore.instance
          .collection('requests')
          .get();
      requestsData = requestsSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      // تحديث الكاش عند النجاح
      if (_analyticsBox != null) {
        await _analyticsBox!.put('techniciansData', techniciansData);
        await _analyticsBox!.put('requestsData', requestsData);
      }
    } catch (e) {
      print('Error fetching data: $e');
      // محاولة استرجاع البيانات من الكاش في حال حدوث خطأ
      if (_analyticsBox != null) {
        final cachedTech = _analyticsBox!.get('techniciansData');
        final cachedReq = _analyticsBox!.get('requestsData');
        if (cachedTech != null && cachedReq != null) {
          techniciansData = List<Map<String, dynamic>>.from(cachedTech);
          requestsData = List<Map<String, dynamic>>.from(cachedReq);
        }
      }
    }

    setState(() => isLoading = false);
  }

  // ----------------------------------------------------------------
  //  تحضير قوائم للمناطق والفنيين (للـ Dropdown)
  // ----------------------------------------------------------------
  List<String> get allAreas {
    final areas = techniciansData
        .map((tech) => tech['area']?.toString() ?? 'غير محدد')
        .toSet()
        .toList();
    areas.removeWhere((a) => a == 'غير محدد');
    return areas;
  }

  List<String> get techniciansInSelectedArea {
    if (selectedArea == null || selectedArea!.isEmpty) {
      return techniciansData
          .map((t) => t['name']?.toString() ?? 'بدون اسم')
          .toSet()
          .toList();
    } else {
      return techniciansData
          .where((t) => (t['area'] ?? '') == selectedArea)
          .map((t) => t['name']?.toString() ?? 'بدون اسم')
          .toSet()
          .toList();
    }
  }

  // ----------------------------------------------------------------
  //  الفلترة: إرجاع قوائم مفلترة بناءً على اختيار المنطقة/الفني/المدة
  // ----------------------------------------------------------------
  List<Map<String, dynamic>> get filteredRequests {
    var result = List<Map<String, dynamic>>.from(requestsData);

    // فلترة بالمنطقة
    if (selectedArea != null && selectedArea!.isNotEmpty) {
      result = result
          .where((req) => (req['technicianArea'] ?? '') == selectedArea)
          .toList();
    }

    // فلترة باسم الفني
    if (selectedTechnicianName != null && selectedTechnicianName!.isNotEmpty) {
      result = result
          .where((req) => (req['technicianName'] ?? '') == selectedTechnicianName)
          .toList();
    }

    // فلترة زمنية
    result = _filterByTimeRange(result);

    return result;
  }

  List<Map<String, dynamic>> get filteredTechnicians {
    var result = List<Map<String, dynamic>>.from(techniciansData);

    // فلترة بالمنطقة
    if (selectedArea != null && selectedArea!.isNotEmpty) {
      result = result.where((tech) => tech['area'] == selectedArea).toList();
    }

    // فلترة باسم الفني
    if (selectedTechnicianName != null && selectedTechnicianName!.isNotEmpty) {
      result = result.where((tech) => tech['name'] == selectedTechnicianName).toList();
    }

    return result;
  }

  /// فلترة الطلبات حسب المدة الزمنية
  List<Map<String, dynamic>> _filterByTimeRange(List<Map<String, dynamic>> list) {
    if (selectedTimeRange == TimeRangeOption.none) {
      return list;
    }

    final now = DateTime.now();
    DateTime start = now;
    DateTime end = now;

    if (selectedTimeRange == TimeRangeOption.lastWeek) {
      start = now.subtract(const Duration(days: 7));
    } else if (selectedTimeRange == TimeRangeOption.lastMonth) {
      start = DateTime(now.year, now.month - 1, now.day);
    } else if (selectedTimeRange == TimeRangeOption.lastYear) {
      start = DateTime(now.year - 1, now.month, now.day);
    } else if (selectedTimeRange == TimeRangeOption.custom) {
      if (customStartDate != null && customEndDate != null) {
        start = customStartDate!;
        end = customEndDate!;
      } else {
        return list;
      }
    }

    if (start.isAfter(end)) {
      final tmp = start;
      start = end;
      end = tmp;
    }

    return list.where((req) {
      final ts = req['timestamp'];
      if (ts == null) return false;
      if (ts is Timestamp) {
        final date = ts.toDate();
        return date.isAfter(start) && date.isBefore(end.add(const Duration(days: 1)));
      }
      return false;
    }).toList();
  }

  // ----------------------------------------------------------------
  //   إحصائيات تُبنى على البيانات المفلترة
  // ----------------------------------------------------------------
  /// عدد الطلبات حسب المنطقة
  Map<String, int> get requestsCountByAreaFiltered {
    final map = <String, int>{};
    for (var req in filteredRequests) {
      final area = req['technicianArea'] ?? 'غير محدد';
      map[area] = (map[area] ?? 0) + 1;
    }
    return map;
  }

  /// عدد الطلبات لكل فنّي
  Map<String, int> get requestsCountByTechnicianFiltered {
    final map = <String, int>{};
    for (var req in filteredRequests) {
      final techName = req['technicianName'] ?? 'غير محدد';
      map[techName] = (map[techName] ?? 0) + 1;
    }
    return map;
  }

  /// عدد الفنيين حسب المنطقة (من قائمة الفنيين المفلترة)
  Map<String, int> get techniciansCountByAreaFiltered {
    final map = <String, int>{};
    for (var tech in filteredTechnicians) {
      final area = tech['area'] ?? 'غير محدد';
      map[area] = (map[area] ?? 0) + 1;
    }
    return map;
  }

  // ----------------------------------------------------------------
  //   واجهة المستخدم
  // ----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('لوحة التحكم - التحليلات')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // إجمالي الفنيين بعد الفلترة
    final totalTech = filteredTechnicians.length;
    // إجمالي الطلبات بعد الفلترة
    final totalReq = filteredRequests.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم - التحليلات'),
        backgroundColor: Colors.blueGrey[800],
      ),
      backgroundColor: Colors.grey[200],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1) قسم الفلاتر
            _buildFiltersSection(),
            const SizedBox(height: 16),
            // 2) بطاقات إحصائيات عامة
            _buildHeaderStats(totalTech, totalReq),
            const SizedBox(height: 24),
            // 3) مخطط: عدد الفنيين حسب المنطقة
            _buildSectionTitle('عدد الفنيين حسب المنطقة'),
            _buildBarChart(techniciansCountByAreaFiltered, color: Colors.blue),
            const SizedBox(height: 24),
            // 4) مخطط: عدد الطلبات حسب المنطقة
            _buildSectionTitle('عدد الطلبات حسب المنطقة'),
            _buildBarChart(requestsCountByAreaFiltered, color: Colors.green),
            const SizedBox(height: 24),
            // 5) مخطط دائري: نسبة الطلبات لكل فنّي
            _buildSectionTitle('نسبة الطلبات لكل فنّي'),
            _buildPieChart(requestsCountByTechnicianFiltered),
            const SizedBox(height: 24),
            // 6) جدول الفنيين
            _buildSectionTitle('جدول الفنيين'),
            _buildTechniciansDataTable(),
            const SizedBox(height: 24),
            // 7) جدول الطلبات
            _buildSectionTitle('جدول الطلبات'),
            _buildRequestsDataTable(),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------
  //   واجهة الفلاتر
  // ----------------------------------------------------------------
  Widget _buildFiltersSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // الصف الأول: اختيار المنطقة والفني
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedArea,
                    hint: const Text('اختر المنطقة'),
                    isExpanded: true,
                    items: allAreas.map((area) {
                      return DropdownMenuItem(
                        value: area,
                        child: Text(area),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedArea = val;
                        selectedTechnicianName = null;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedTechnicianName,
                    hint: const Text('اختر الفني'),
                    isExpanded: true,
                    items: techniciansInSelectedArea.map((name) {
                      return DropdownMenuItem(
                        value: name,
                        child: Text(name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedTechnicianName = val;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // الصف الثاني: اختيار المدة الزمنية
            Row(
              children: [
                Expanded(
                  child: DropdownButton<TimeRangeOption>(
                    value: selectedTimeRange,
                    hint: const Text('اختر المدة الزمنية'),
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: TimeRangeOption.none,
                        child: Text('بدون فلترة زمنية'),
                      ),
                      DropdownMenuItem(
                        value: TimeRangeOption.lastWeek,
                        child: Text('آخر أسبوع'),
                      ),
                      DropdownMenuItem(
                        value: TimeRangeOption.lastMonth,
                        child: Text('آخر شهر'),
                      ),
                      DropdownMenuItem(
                        value: TimeRangeOption.lastYear,
                        child: Text('آخر سنة'),
                      ),
                      DropdownMenuItem(
                        value: TimeRangeOption.custom,
                        child: Text('تحديد تاريخ...'),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        selectedTimeRange = val ?? TimeRangeOption.none;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                if (selectedTimeRange == TimeRangeOption.custom) ...[
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().subtract(const Duration(days: 7)),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2050),
                        );
                        if (picked != null) {
                          setState(() => customStartDate = picked);
                        }
                      },
                      child: Container(
                        height: 48,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          customStartDate == null
                              ? 'تاريخ البداية'
                              : DateFormat('yyyy-MM-dd').format(customStartDate!),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2050),
                        );
                        if (picked != null) {
                          setState(() => customEndDate = picked);
                        }
                      },
                      child: Container(
                        height: 48,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          customEndDate == null
                              ? 'تاريخ النهاية'
                              : DateFormat('yyyy-MM-dd').format(customEndDate!),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.close),
                label: const Text('حذف الفلترة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      selectedArea = null;
      selectedTechnicianName = null;
      selectedTimeRange = TimeRangeOption.none;
      customStartDate = null;
      customEndDate = null;
    });
  }

  // ----------------------------------------------------------------
  //   عنواين الأقسام
  // ----------------------------------------------------------------
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  // ----------------------------------------------------------------
  //   بطاقات الإحصائيات (عدد الفنيين، عدد الطلبات)
  // ----------------------------------------------------------------
  Widget _buildHeaderStats(int totalTechnicians, int totalRequests) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'عدد الفنيين',
            value: totalTechnicians.toString(),
            icon: Icons.engineering_outlined,
            color: Colors.teal,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'عدد الطلبات',
            value: totalRequests.toString(),
            icon: Icons.request_page_outlined,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.1),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: double.infinity,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        )),
                    const SizedBox(height: 8),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------
  //   مخطط الأعمدة (Bar Chart)
  // ----------------------------------------------------------------
  Widget _buildBarChart(Map<String, int> dataMap, {Color color = Colors.blue}) {
    if (dataMap.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('لا توجد بيانات لعرضها')),
      );
    }

    final barSpots = <BarChartGroupData>[];
    int x = 0;
    dataMap.forEach((key, value) {
      barSpots.add(
        BarChartGroupData(
          x: x,
          barRods: [
            BarChartRodData(
              toY: value.toDouble(),
              color: color,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
      x++;
    });

    final maxVal = dataMap.values.reduce((a, b) => a > b ? a : b).toDouble();

    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          maxY: maxVal + 2,
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: AxisTitles(),
            rightTitles: AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= dataMap.length) return Container();
                  final label = dataMap.keys.elementAt(idx);
                  return Transform.rotate(
                    angle: -0.5,
                    child: Text(label, style: const TextStyle(fontSize: 12)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
          ),
          barGroups: barSpots,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.black54,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final label = dataMap.keys.elementAt(group.x.toInt());
                final val = rod.toY.toStringAsFixed(0);
                return BarTooltipItem(
                  '$label\n$val',
                  const TextStyle(color: Colors.white),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------------
  //   مخطط دائري (Pie Chart)
  // ----------------------------------------------------------------
  Widget _buildPieChart(Map<String, int> dataMap) {
    if (dataMap.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('لا توجد بيانات لعرضها')),
      );
    }

    final sections = <PieChartSectionData>[];
    final total = dataMap.values.fold(0, (sum, item) => sum + item);

    int i = 0;
    dataMap.forEach((key, value) {
      final percentage = (value / total) * 100;
      final color = Colors.primaries[i % Colors.primaries.length];
      i++;

      sections.add(
        PieChartSectionData(
          color: color,
          value: value.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 80,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          badgeWidget: Text(
            key,
            style: const TextStyle(fontSize: 10, color: Colors.black),
          ),
          badgePositionPercentageOffset: .98,
        ),
      );
    });

    return SizedBox(
      height: 300,
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 40,
          borderData: FlBorderData(show: false),
          sectionsSpace: 2,
        ),
      ),
    );
  }

  // ----------------------------------------------------------------
  //   جدول الفنيين
  // ----------------------------------------------------------------
  Widget _buildTechniciansDataTable() {
    final techs = filteredTechnicians;
    if (techs.isEmpty) {
      return const Center(child: Text('لا يوجد فنيون ضمن الفلاتر الحالية.'));
    }

    final countsMap = <String, int>{};
    for (var req in filteredRequests) {
      final name = req['technicianName'] ?? 'غير محدد';
      countsMap[name] = (countsMap[name] ?? 0) + 1;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('اسم الفني')),
          DataColumn(label: Text('رقم الفني')),
          DataColumn(label: Text('المنطقة')),
          DataColumn(label: Text('التخصص')),
          DataColumn(label: Text('عدد الطلبات')),
          DataColumn(label: Text('نوع الاشتراك')),
          DataColumn(label: Text('انتهاء الاشتراك')),
        ],
        rows: techs.map((tech) {
          final techName = tech['name'] ?? 'بدون اسم';
          final techNumber = tech['number'] ?? 'بدون رقم';
          final techArea = tech['area'] ?? 'بدون منطقة';
          final techSpecialty = tech['specialty'] ?? 'بدون تخصص';

          final requestsCount = countsMap[techName] ?? 0;
          final subscriptionType = tech['subscriptionType'] ?? '-';
          final subscriptionEndRaw = tech['subscriptionEndDate'];
          String subscriptionEndText = '-';
          if (subscriptionEndRaw != null) {
            if (subscriptionEndRaw is Timestamp) {
              final dt = subscriptionEndRaw.toDate();
              subscriptionEndText = DateFormat('yyyy-MM-dd').format(dt);
            } else if (subscriptionEndRaw is String) {
              subscriptionEndText = subscriptionEndRaw;
            }
          }

          return DataRow(cells: [
            DataCell(Text(techName)),
            DataCell(Text(techNumber)),
            DataCell(Text(techArea)),
            DataCell(Text(techSpecialty)),
            DataCell(Text('$requestsCount')),
            DataCell(Text(subscriptionType)),
            DataCell(Text(subscriptionEndText)),
          ]);
        }).toList(),
      ),
    );
  }

  // ----------------------------------------------------------------
  //   جدول الطلبات
  // ----------------------------------------------------------------
  Widget _buildRequestsDataTable() {
    final reqs = filteredRequests;
    if (reqs.isEmpty) {
      return const Center(child: Text('لا توجد طلبات ضمن الفلاتر الحالية.'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('اسم العميل')),
          DataColumn(label: Text('رقم العميل')),
          DataColumn(label: Text('حالة الطلب')),
          DataColumn(label: Text('اسم الفني')),
          DataColumn(label: Text('رقم الفني')),
          DataColumn(label: Text('تخصص الفني')),
          DataColumn(label: Text('المنطقة')),
          DataColumn(label: Text('تاريخ الطلب')),
        ],
        rows: reqs.map((req) {
          final customerName = req['customerName'] ?? 'بدون اسم';
          final customerPhone = req['customerPhone'] ?? 'بدون رقم';
          final status = req['status'] ?? 'غير محدد';
          final techName = req['technicianName'] ?? 'غير محدد';
          final techNumber = req['technicianNumber'] ?? 'بدون رقم';
          final techSpecialty = req['technicianSpecialty'] ?? 'بدون تخصص';
          final techArea = req['technicianArea'] ?? 'غير محدد';

          String dateText = '-';
          final ts = req['timestamp'];
          if (ts is Timestamp) {
            dateText = DateFormat('yyyy-MM-dd HH:mm').format(ts.toDate());
          }

          return DataRow(cells: [
            DataCell(Text(customerName)),
            DataCell(Text(customerPhone)),
            DataCell(Text(status)),
            DataCell(Text(techName)),
            DataCell(Text(techNumber)),
            DataCell(Text(techSpecialty)),
            DataCell(Text(techArea)),
            DataCell(Text(dateText)),
          ]);
        }).toList(),
      ),
    );
  }
}
