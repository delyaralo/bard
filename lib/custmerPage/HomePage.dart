import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

// الصفحات الأخرى
import 'custmerPage.dart';
import 'TechniciansPage.dart';
import 'AcCalculatorPage.dart';
import 'DatPage.dart';
import 'CartPage.dart';
import 'package:bard/device_provider.dart';

// Widgets
import 'package:bard/widgets/bannerslider.dart';
import 'package:bard/widgets/categorysection.dart';
import 'package:bard/widgets/productssection.dart';
import 'package:bard/widgets/CustomDivider.dart';
import 'SpinWheelScreen.dart';
import 'CartPage2.dart';
// --------- الصفحة الرئيسية -----------
class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _pageIndex = 2;         // يبدأ على صفحة الـHome (index = 2)
  int cartItemCount = 0;

  bool _isSearching = false;  // هل المستخدم في وضع البحث؟
  String _searchQuery = '';   // نص البحث الذي سنرسله للصفحة الرئيسية

  late List<Widget> _pages;   // نُعِد الصفحات في initState

  @override
  void initState() {
    super.initState();
    _loadCartItemCount();

    // إنشاء الصفحات وتمرير searchQuery للصفحة الرئيسية
    _pages = [
      CartPage2(),
      TechniciansPage(),
      HomesPageState(searchQuery: _searchQuery),
      WheelPage(),
      DatPage(),
    ];
  }

  Future<void> _loadCartItemCount() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? storedCart = prefs.getStringList('cart');
    setState(() {
      cartItemCount = storedCart?.length ?? 0;
    });
  }

  // دالة تبني حقل البحث في الـAppBar
  Widget _buildSearchField() {
    return TextField(
      autofocus: true,
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
          // إعادة إنشاء الصفحة الرئيسية وتمرير قيمة البحث الجديدة
          _pages[2] = HomesPageState(searchQuery: _searchQuery);
        });
      },
      decoration: const InputDecoration(
        hintText: "ابحث عن منتج...",
        hintStyle: TextStyle(color: Colors.white54),
        border: InputBorder.none,
      ),
      style: const TextStyle(color: Colors.white, fontSize: 18.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    // الوصول إلى deviceId من Provider إن احتجت إليه
    final deviceId = Provider.of<DeviceProvider>(context).deviceId;

    return Scaffold(
      // ---------------- AppBar ----------------
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 4,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xff36D1DC),
                Color(0xff5B86E5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        centerTitle: true,

        title: !_isSearching
            ? const Text(
          'الرئيسية',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        )
            : _buildSearchField(),

        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
              splashRadius: 24,
            )
          else
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchQuery = '';
                  _pages[2] = HomesPageState(searchQuery: _searchQuery);
                });
              },
              splashRadius: 24,
            ),

          // أيقونة السلة مع العداد
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart,
                    color: Colors.white, size: 28),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CartPage()),
                  ).then((_) => _loadCartItemCount());
                },
                splashRadius: 24,
              ),
              if (cartItemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$cartItemCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),

      // ---------------- Body مع Animations ---------------
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 700),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: _pages[_pageIndex],
      ),

      // ------------- BottomNavigationBar احترافي بسيط -------------
      bottomNavigationBar: Container(
        // خلفية متدرجة أسفل الـBottomNavigationBar
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xff36D1DC),
              Color(0xff5B86E5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _pageIndex,
          onTap: (index) {
            setState(() {
              _pageIndex = index;
            });
          },
          backgroundColor: Colors.transparent, // لجعل التدرج يظهر
          elevation: 0, // إزالة الظل الافتراضي
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          // إعداد الأيقونات والتسميات
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'سلة',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.hail),
              label: 'خدمات الفنين',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'الرئيسية',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.card_giftcard_outlined),
              label: 'عجله',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'حسابي',
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- صفحة الهوم الداخلي HomesPageState ----------------

class HomesPageState extends StatefulWidget {
  final String searchQuery; // استلام نص البحث من الـAppBar

  const HomesPageState({Key? key, this.searchQuery = ''}) : super(key: key);

  @override
  _HomesPageState createState() => _HomesPageState();
}

class _HomesPageState extends State<HomesPageState>
    with SingleTickerProviderStateMixin {
  Box? _categoriesBox;
  Box? _productsBox;
  bool _isInitialized = false;

  List<Map<String, dynamic>> _banners = [];
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _initializeBoxes();
    _fetchBanners();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  Future<void> _initializeBoxes() async {
    _categoriesBox = await Hive.openBox('categories');
    _productsBox = await Hive.openBox('products');
    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> _fetchBanners() async {
    try {
      QuerySnapshot bannerSnapshot =
      await FirebaseFirestore.instance.collection('banners').get();

      List<Map<String, dynamic>> fetchedBanners = bannerSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'imageUrl': data['imageUrl'] ?? '',
          'title': data['title'] ?? '',
          'mainCategoryId': data['mainCategoryId'] ?? '',
          'subCategoryId': data['subCategoryId'] ?? '',
        };
      }).toList();

      setState(() {
        _banners = fetchedBanners;
      });
    } catch (e) {
      debugPrint("Error fetching banners: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل في تحميل البنرات. حاول مرة أخرى.')),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final deviceId = Provider.of<DeviceProvider>(context).deviceId;

    return Scaffold(
      body: Stack(
        children: [
          // 1) خلفية علوية بشكل موجة (Wave)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            // ارتفاع الموجة العلوية (يمكنك تغييره)
            child: SizedBox(
              height: 250,

            ),
          ),

          // 2) بقية الصفحة
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // فارق علوي لتعويض مساحة الموجة
                  const SizedBox(height: 70),

                  // البنرات (موضوعة فوق الموجة بشكل متداخل)
                  // يمكننا رفعها قليلاً للأعلى لتظهر متداخلة مع الموجة
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: BannerSlider(banners: _banners),
                  ),

                  // مسافة بعد البنرات
                  const SizedBox(height: 20),

                  // فاصل
                  const CustomDivider(),
                  const SizedBox(height: 10),

                  // التصنيفات
                  const CategorySection(),
                  const SizedBox(height: 10),

                  // فاصل
                  const CustomDivider(),
                  const SizedBox(height: 10),

                  // قسم المنتجات (مفلترة حسب البحث)
                  ProductsSection(searchQuery: widget.searchQuery),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Painter لرسم موجة في الرأس (Header)
