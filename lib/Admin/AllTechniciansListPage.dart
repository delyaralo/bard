import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'EditTechnicianPage.dart';

class AllTechniciansListPage extends StatefulWidget {
  @override
  _TechniciansListPageState createState() => _TechniciansListPageState();
}

class _TechniciansListPageState extends State<AllTechniciansListPage> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedProvince;
  List<Map<String, dynamic>> _technicians = [];
  List<Map<String, dynamic>> _filteredTechnicians = [];

  // قائمة المحافظات
  final List<String> _provinces = [
    'بغداد',
    'البصرة',
    'نينوى',
    'أربيل',
    // أضف المزيد هنا
  ];

  @override
  void initState() {
    super.initState();
    _fetchTechnicians();
  }

  // جلب الفنيين من Firebase
  Future<void> _fetchTechnicians() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('technicians')
          .get();

      List<Map<String, dynamic>> technicians = snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();

      setState(() {
        _technicians = technicians;
        _filteredTechnicians = technicians;
      });
    } catch (e) {
      print('Error fetching technicians: $e');
    }
  }

  // تصفية الفنيين بناءً على البحث أو المحافظة
  void _filterTechnicians() {
    setState(() {
      _filteredTechnicians = _technicians.where((technician) {
        final matchesProvince = _selectedProvince == null ||
            technician['province'] == _selectedProvince;
        final matchesSearch = _searchController.text.isEmpty ||
            (technician['name'] ?? '')
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()) ||
            (technician['area'] ?? '')
                .toLowerCase()
                .contains(_searchController.text.toLowerCase());

        return matchesProvince && matchesSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الفنيون'),
        backgroundColor: Colors.lightBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // قائمة اختيار المحافظة
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'اختر المحافظة',
                border: OutlineInputBorder(),
              ),
              items: _provinces
                  .map((province) => DropdownMenuItem(
                        value: province,
                        child: Text(province),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedProvince = value;
                });
                _filterTechnicians();
              },
            ),
            SizedBox(height: 16),

            // شريط البحث
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'بحث عن الفني',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => _filterTechnicians(),
            ),
            SizedBox(height: 16),

            // قائمة الفنيين
            Expanded(
              child: _filteredTechnicians.isNotEmpty
                  ? ListView.builder(
                      itemCount: _filteredTechnicians.length,
                      itemBuilder: (context, index) {
                        final technician = _filteredTechnicians[index];
                        return Card(
                          elevation: 4,
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: ListTile(
                            title: Text(technician['name'] ?? 'اسم غير متوفر'),
                            subtitle: Text(
                                'المنطقة: ${technician['area'] ?? 'غير متوفر'}'),
                            trailing: Icon(Icons.edit),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditTechnicianPage(
                                    technicianId: technician['id'],
                                    technicianData: technician,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    )
                  : Center(child: Text('لا يوجد فنيون مطابقون للبحث.')),
            ),
          ],
        ),
      ),
    );
  }
}
