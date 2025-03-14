import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';

class customerPage extends StatefulWidget {

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<customerPage> with TickerProviderStateMixin {
  bool _isSearching = false;
  String _searchQuery = '';
  Box? _categoriesBox;
  Box? _productsBox;
  final PageController _pageController = PageController();
  late TabController _tabController;
  TextEditingController _searchController = TextEditingController();
  Timer? _bannerTimer;

  final TextStyle subtitleStyle = TextStyle(
    fontSize: 14,
    color: Colors.grey[700],
  );

  @override
  void initState() {
    super.initState();

    // بدء التمرير التلقائي للبنرات كل 5 ثوانٍ
    _bannerTimer = Timer.periodic(Duration(seconds: 5), (Timer timer) {
      if (_pageController.hasClients) {
        int nextPage = (_pageController.page ?? 0).toInt() + 1;
        if (nextPage >= 5) { // إذا تجاوزنا عدد البنرات نعود للأولى
          nextPage = 0;
        }
        _pageController.animateToPage(
          nextPage,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _pageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeHive() async {
    final directory = await getApplicationDocumentsDirectory();
    Hive.init(directory.path);
    _categoriesBox = await Hive.openBox('categories');
    _productsBox = await Hive.openBox('products');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isSearching ? _buildSearchResults() : _buildHomeContent(),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10),
            _buildImageRow(),
            SizedBox(height: 20),
            _buildTitle('التصنيف'),
            Divider(),
            SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('categories')
                  .orderBy('order')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                final categories = snapshot.data!.docs;

                return _buildCategoryList(categories);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('name', isGreaterThanOrEqualTo: _searchQuery)
          .where('name', isLessThanOrEqualTo: _searchQuery + '\uf8ff')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center();
        }

        final products = snapshot.data!.docs;

        if (products.isEmpty) {
          return Center(child: Text('لا توجد نتائج مطابقة'));
        }

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 0.75,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final data = products[index].data() as Map<String, dynamic>;
          },
        );
      },
    );
  }



  Widget _buildTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 24,
        color: Colors.lightBlue,
      ),
    );
  }

  Widget _buildImageRow() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('banners').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center();
        }

        final banners = snapshot.data!.docs;
        if (banners.isEmpty) {
          return Center(child: Text('لا توجد بنرات متاحة'));
        }

        return Stack(
          alignment: Alignment.bottomCenter,
          children: [
            SizedBox(
              height: 200,
              width: double.infinity, // استخدم double.infinity بدلًا من حجم ثابت
              child: PageView(
                controller: _pageController,
                children: banners.map((bannerDoc) {
                  final bannerData = bannerDoc.data() as Map<String, dynamic>;
                  final imageUrl = bannerData['imageUrl'];
                  final route = bannerData['route'];

                  return GestureDetector(
                    onTap: () {
                      if (route.isNotEmpty) {
                        Navigator.pushNamed(context, route);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('المسار غير متاح')));
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: CachedNetworkImageProvider(imageUrl), // استخدم CachedNetworkImageProvider لتخزين الصورة مؤقتًا
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryList(List<DocumentSnapshot> categories) {
    return Container(
      color: Colors.transparent,
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index].data() as Map<String, dynamic>;
          final imageUrl = category['imageUrl'] ?? '';
          return Column(
            children: [
              SizedBox(height: 4),
              Hero(
                tag: 'category-${categories[index].id}',
                child: _buildCategoryCard(
                  context,
                  imageUrl,
                  categories[index].id,
                ),
              ),
              SizedBox(height: 8),
              Text(
                category['name'] ?? 'Unknown',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.lightBlue,
                ),
                overflow: TextOverflow.ellipsis, // تقصير النص الطويل
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, String imageUrl, String categoryId) {
    return GestureDetector(
      onTap: () {
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8.0),
        width: 100,
        height: 110,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.lightBlue,
              blurRadius: 0.6,
              spreadRadius: 0.8,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: imageUrl.isNotEmpty
              ? CachedNetworkImage(
            imageUrl: imageUrl,
            errorWidget: (context, url, error) => Icon(Icons.error),
            width: 60,
            height: 60,
            fit: BoxFit.contain,
          )
              : Icon(Icons.category, color: Colors.blueAccent, size: 40.0),
        ),
      ),
    );
  }
}
