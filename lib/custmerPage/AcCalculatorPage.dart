import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'ProductDetailPage.dart';

class AcCalculatorPage extends StatefulWidget {
  @override
  _AcCalculatorPageState createState() => _AcCalculatorPageState();
}

class _AcCalculatorPageState extends State<AcCalculatorPage> {
  final TextEditingController _lengthController = TextEditingController();
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _resultController = TextEditingController();

  double _acSize = 0.0;
  String _acProduct = "";
  String _note = "";

  // دالة لحساب حجم التكييف
  void _calculateAcSize() {
    double length = double.tryParse(_lengthController.text) ?? 0.0;
    double width = double.tryParse(_widthController.text) ?? 0.0;
    double height = double.tryParse(_heightController.text) ?? 0.0;

    if (length > 0 && width > 0 && height > 0) {
      double roomSize = length * width * height;
      double adjustedSize = roomSize * 300; // افتراض بسيط للزيادة
      _acSize = adjustedSize / 12000; // تحويل إلى طن

      setState(() {
        _resultController.text = _acSize.toStringAsFixed(2);
        if (_acSize <= 1) {
          _acProduct = "1 طن";
          _note = "";
        } else if (_acSize > 1 && _acSize <= 2) {
          _acProduct = "2 طن";
          _note = "";
        } else if (_acSize > 2 && _acSize <= 3) {
          _acProduct = "3 طن";
          _note = "";
        } else if (_acSize > 3 && _acSize <= 4) {
          _acProduct = "4 طن";
          _note = "";
        } else if (_acSize > 4 && _acSize <= 5) {
          _acProduct = "5 طن";
          _note = "";
        } else {
          _acProduct = "أكثر من 5 طن";
          _note = "للمزيد من التفاصيل، يرجى الاتصال بالشركة لتحديد السبلت المناسب.";
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("يرجى إدخال جميع الأبعاد بشكل صحيح")),
      );
    }
  }

  // دالة لجلب المنتجات من Firestore والتي يوجد في حقل variants القيمة المناظرة (_acProduct)
  Future<List<Map<String, dynamic>>> _getProductForAcSize(String size) async {
    if (size.isEmpty || size == "أكثر من 5 طن") {
      return [];
    }

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('variants', arrayContains: size)
        .get();

    List<Map<String, dynamic>> products = [];
    for (var doc in querySnapshot.docs) {
      products.add(doc.data() as Map<String, dynamic>);
    }
    return products;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // نجعل خلفية شريط التطبيق شفافة جزئيًا أو نلغي الظلال
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("حاسبة وحدة التكييف"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        // خلفية متدرّجة لأناقة الصفحة
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blueAccent.shade200,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // بطاقة تحتوي على حقول الإدخال وزر "احسب" ونتيجة الحساب
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          "أدخل أبعاد الغرفة:",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        // الطول
                        _buildTextField(
                          controller: _lengthController,
                          label: 'الطول (متر)',
                        ),
                        SizedBox(height: 10),
                        // العرض
                        _buildTextField(
                          controller: _widthController,
                          label: 'العرض (متر)',
                        ),
                        SizedBox(height: 10),
                        // الارتفاع
                        _buildTextField(
                          controller: _heightController,
                          label: 'الارتفاع (متر)',
                        ),
                        SizedBox(height: 20),
                        // زر الحساب
                        ElevatedButton(
                          onPressed: _calculateAcSize,
                          child: Text('احسب'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 40, vertical: 12),
                          ),
                        ),
                        SizedBox(height: 20),
                        // حجم التكييف
                        _buildResultField(
                          controller: _resultController,
                          label: 'حجم التكييف المطلوب (بالطن)',
                        ),
                        SizedBox(height: 10),
                        // نص: منتج السبلت المطلوب
                        Text(
                          'منتج السبلت المطلوب: $_acProduct',
                          style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        // ملاحظة
                        if (_note.isNotEmpty)
                          Text(
                            _note,
                            style: TextStyle(fontSize: 14, color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 30),

                // عنوان المنتجات المناسبة
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'المنتجات المناسبة:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
                SizedBox(height: 10),

                // عرض المنتجات المناسبة
                Container(
                  // خلفية خفيفة أو شفافة
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _getProductForAcSize(_acProduct),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            "حدث خطأ أثناء تحميل البيانات",
                            style: TextStyle(fontSize: 16, color: Colors.red),
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            "لا توجد منتجات متاحة لهذا الحجم.",
                            style: TextStyle(fontSize: 16),
                          ),
                        );
                      }

                      List<Map<String, dynamic>> products = snapshot.data!;
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          var product = products[index];
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                            margin: EdgeInsets.symmetric(
                                vertical: 8, horizontal: 8),
                            child: ListTile(
                              leading: _buildProductImage(product),
                              title: Text(product['name'] ?? 'بدون اسم'),
                              subtitle: Text(
                                'السعر: ${product['highPrice'] ?? ''} '
                                    '${product['currency'] ?? '\$'}',
                              ),
                              onTap: () {
                                // الانتقال إلى صفحة التفاصيل
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailPage(
                                      productData: product,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ويدجت صغيرة لبناء حقل نص بأناقة
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.straighten),
      ),
      keyboardType: TextInputType.number,
    );
  }

  // حقل ناتج القراءة فقط
  Widget _buildResultField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.done),
      ),
      readOnly: true,
    );
  }

  // ويدجت صغيرة لبناء صورة المنتج (50x50) في قائمة المنتجات بشكل مربع
  Widget _buildProductImage(Map<String, dynamic> product) {
    final imageUrl = product['mainImageUrl'] ?? '';
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 50,
        height: 50,
        color: Colors.grey,
        child: imageUrl.isEmpty
            ? Icon(Icons.photo, color: Colors.white)
            : CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          errorWidget: (context, url, error) => Icon(
            Icons.error,
            color: Colors.red,
          ),
        ),
      ),
    );
  }
}
