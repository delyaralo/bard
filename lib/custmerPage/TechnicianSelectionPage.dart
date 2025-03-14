import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'TechnicianListPage.dart';

class TechnicianSelectionPage extends StatefulWidget {
  @override
  _TechnicianSelectionPageState createState() => _TechnicianSelectionPageState();
}

class _TechnicianSelectionPageState extends State<TechnicianSelectionPage> {
  String? _selectedSpecialty;
  String? _selectedProvince;
  String? _selectedArea;
  String? _userName;
  String? _userPhone;
  String? _userToken;

  List<String> _specialties = [];
  List<String> _provinces = [];
  List<String> _areas = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchSpecialties();
    _getUserToken();
  }

  Future<void> _getUserToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      setState(() {
        _userToken = token;
      });
      print('FCM Token: $token');
    } catch (e) {
      print('Error fetching FCM token: $e');
    }
  }

  Future<void> _fetchSpecialties() async {
    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('technicians').get();
      List<String> specialties = snapshot.docs.map((doc) => doc['specialty'] as String).toSet().toList();

      setState(() {
        _specialties = specialties;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching specialties: $e');
    }
  }

  Future<void> _fetchProvinces() async {
    setState(() {
      _isLoading = true;
      _selectedProvince = null;
      _selectedArea = null;
      _provinces = [];
      _areas = [];
    });

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('technicians')
          .where('specialty', isEqualTo: _selectedSpecialty)
          .get();

      List<String> provinces = snapshot.docs.map((doc) => doc['province'] as String).toSet().toList();

      setState(() {
        _provinces = provinces;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching provinces: $e');
    }
  }

  Future<void> _fetchAreas() async {
    setState(() {
      _isLoading = true;
      _selectedArea = null;
      _areas = [];
    });

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('technicians')
          .where('specialty', isEqualTo: _selectedSpecialty)
          .where('province', isEqualTo: _selectedProvince)
          .get();

      List<String> areas = snapshot.docs.map((doc) => doc['area'] as String).toSet().toList();

      setState(() {
        _areas = areas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching areas: $e');
    }
  }

  void _goToTechnicianList() {
    if (_selectedSpecialty != null &&
        _selectedProvince != null &&
        _selectedArea != null &&
        _userName != null &&
        _userPhone != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TechnicianListPage(
            specialty: _selectedSpecialty!,
            province: _selectedProvince!,
            area: _selectedArea!,
            userName: _userName!,
            userPhone: _userPhone!,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('يرجى إدخال جميع البيانات المطلوبة!'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('اختيار الفني', style: TextStyle(fontWeight: FontWeight.bold)),
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
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'اسم المستخدم',
                        prefixIcon: Icon(Icons.person, color: Colors.blue),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => setState(() => _userName = value),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'رقم الهاتف',
                        prefixIcon: Icon(Icons.phone, color: Colors.green),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      onChanged: (value) => setState(() => _userPhone = value),
                    ),
                    SizedBox(height: 16),
                    _buildDropdown('اختصاص الفني', _specialties, _selectedSpecialty, (value) {
                      setState(() {
                        _selectedSpecialty = value;
                        _selectedProvince = null;
                        _selectedArea = null;
                        _provinces = [];
                        _areas = [];
                      });
                      _fetchProvinces();
                    }),
                    SizedBox(height: 16),
                    _buildDropdown('المحافظة', _provinces, _selectedProvince, (value) {
                      setState(() {
                        _selectedProvince = value;
                        _selectedArea = null;
                        _areas = [];
                      });
                      _fetchAreas();
                    }),
                    SizedBox(height: 16),
                    _buildDropdown('المنطقة', _areas, _selectedArea, (value) {
                      setState(() {
                        _selectedArea = value;
                      });
                    }),
                    SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _goToTechnicianList,
                        child: Text('عرض الفنيين', style: TextStyle(fontSize: 18)),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? selectedValue, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
      value: selectedValue,
    );
  }
}
