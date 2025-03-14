import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class AddUsersPage extends StatefulWidget {
  @override
  _AddUsersPageState createState() => _AddUsersPageState();
}

class _AddUsersPageState extends State<AddUsersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // لضبط الاتجاه من اليمين إلى اليسار
      child: Scaffold(
        appBar: AppBar(
          title: Text('إضافة مستخدم'),
          backgroundColor: Colors.lightBlue,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'إضافة فني'),
              Tab(text: 'إضافة موظف'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // 1) التبويب الأول: إضافة فني
            AddTechnicianPage(),
            // 2) التبويب الثاني: إضافة موظف
            AddEmployeePage(),
          ],
        ),
      ),
    );
  }
}

/// التبويب الأول: إضافة فني (نفس الصفحة التي لديك)
class AddTechnicianPage extends StatefulWidget {
  @override
  _AddTechnicianPageState createState() => _AddTechnicianPageState();
}

class _AddTechnicianPageState extends State<AddTechnicianPage> {
  final _formKey = GlobalKey<FormState>();

  String? _province;
  String? _area;
  String? _technicianNumber;
  String? _password;
  String? _technicianName;
  String? _specialty;

  bool _isLoading = false;

  // قائمة المحافظات (يمكنك تعديلها حسب الحاجة)
  final List<String> _provinces = [
    'بغداد',
    'البصرة',
    'نينوى',
    'أربيل',
    // أضف المزيد هنا
  ];

  // قائمة الاختصاصات (يمكنك تعديلها حسب الحاجة)
  final List<String> _specialties = [
    'نصب',
    'صيانة',
    'نصب مع صيانة',
    // أضف المزيد هنا
  ];

  // دالة لعرض تحذير في منتصف الشاشة
  void _showWarningDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تحذير'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('حسناً'),
          ),
        ],
      ),
    );
  }

  // دالة لإضافة الفني إلى Firebase Firestore بعد التأكد من عدم وجود اسم أو رقم مكرر
  Future<void> _addTechnician() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isLoading = true;
      });

      try {
        // التحقق من وجود فني بنفس الاسم
        QuerySnapshot nameSnapshot = await FirebaseFirestore.instance
            .collection('technicians')
            .where('name', isEqualTo: _technicianName)
            .get();

        if (nameSnapshot.docs.isNotEmpty) {
          setState(() {
            _isLoading = false;
          });
          _showWarningDialog('اسم الفني موجود مسبقاً');
          return;
        }

        // التحقق من وجود فني بنفس الرقم
        QuerySnapshot numberSnapshot = await FirebaseFirestore.instance
            .collection('technicians')
            .where('number', isEqualTo: _technicianNumber)
            .get();

        if (numberSnapshot.docs.isNotEmpty) {
          setState(() {
            _isLoading = false;
          });
          _showWarningDialog('رقم الفني موجود مسبقاً');
          return;
        }

        // إذا لم يكن الاسم أو الرقم موجوداً، قم بإضافة الفني
        await FirebaseFirestore.instance.collection('technicians').add({
          'province': _province,
          'area': _area,
          'number': _technicianNumber,
          'password': _password,
          'name': _technicianName,
          'specialty': _specialty,
          'createdAt': FieldValue.serverTimestamp(),
          'subscriptionEndDate': null, // إضافة هذا الحقل
          'isSubscribed': false,       // تعيين حالة الاشتراك إلى false (بدون اشتراك)
        });

        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم إضافة الفني بنجاح')),
        );

        // إعادة تعيين النموذج
        _formKey.currentState!.reset();
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        // إظهار رسالة خطأ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء إضافة الفني: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // اسم الفني
            TextFormField(
              decoration: InputDecoration(
                labelText: 'اسم الفني',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال اسم الفني';
                }
                return null;
              },
              onSaved: (value) {
                _technicianName = value;
              },
            ),
            SizedBox(height: 16),

            // المحافظة
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'المحافظة',
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
                  _province = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى اختيار المحافظة';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // المنطقة
            TextFormField(
              decoration: InputDecoration(
                labelText: 'المنطقة',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال المنطقة';
                }
                return null;
              },
              onSaved: (value) {
                _area = value;
              },
            ),
            SizedBox(height: 16),

            // رقم الفني
            TextFormField(
              decoration: InputDecoration(
                labelText: 'رقم الفني',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال رقم الفني';
                }
                return null;
              },
              onSaved: (value) {
                _technicianNumber = value;
              },
            ),
            SizedBox(height: 16),

            // كلمة السر
            TextFormField(
              decoration: InputDecoration(
                labelText: 'كلمة السر',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال كلمة السر';
                }
                if (value.length < 6) {
                  return 'يجب أن تكون كلمة السر مكونة من 6 أحرف على الأقل';
                }
                return null;
              },
              onSaved: (value) {
                _password = value;
              },
            ),
            SizedBox(height: 16),

            // اختصاص الفني
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'اختصاص الفني',
                border: OutlineInputBorder(),
              ),
              items: _specialties
                  .map((specialty) => DropdownMenuItem(
                value: specialty,
                child: Text(specialty),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _specialty = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى اختيار اختصاص الفني';
                }
                return null;
              },
            ),
            SizedBox(height: 32),

            // زر إضافة الفني
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addTechnician,
                child: Text(
                  'إضافة الفني',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
/// التبويب الثاني: إضافة موظف (صفحة بسيطة: اسم الموظف + كلمة المرور فقط)
class AddEmployeePage extends StatefulWidget {
  @override
  _AddEmployeePageState createState() => _AddEmployeePageState();
}

class _AddEmployeePageState extends State<AddEmployeePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  String? _employeeName;
  String? _employeePassword;

  // دالة لإضافة الموظف إلى Firestore في حقل مختلف مثلاً 'employees'
  Future<void> _addEmployee() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isLoading = true;
      });

      try {
        await FirebaseFirestore.instance.collection('employees').add({
          'employeeName': _employeeName,
          'employeePassword': _employeePassword,
          'createdAt': FieldValue.serverTimestamp(),
        });

        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم إضافة الموظف بنجاح')),
        );

        // إعادة تعيين النموذج
        _formKey.currentState!.reset();
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء إضافة الموظف: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // اسم الموظف
            TextFormField(
              decoration: InputDecoration(
                labelText: 'اسم الموظف',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال اسم الموظف';
                }
                return null;
              },
              onSaved: (value) => _employeeName = value,
            ),
            SizedBox(height: 16),

            // كلمة المرور
            TextFormField(
              decoration: InputDecoration(
                labelText: 'كلمة المرور',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال كلمة المرور';
                }
                if (value.length < 6) {
                  return 'يجب أن تكون كلمة المرور مكونة من 6 أحرف على الأقل';
                }
                return null;
              },
              onSaved: (value) => _employeePassword = value,
            ),
            SizedBox(height: 32),

            // زر إضافة الموظف
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addEmployee,
                child: Text(
                  'إضافة الموظف',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
