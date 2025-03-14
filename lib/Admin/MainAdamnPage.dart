import 'dart:io'; // لاستدعاء exit(0)
import 'package:flutter/material.dart';

import 'AddItem.dart';
import 'bannarUpper.dart';
import 'catalogPage.dart';
import 'AddTechnicianPage.dart';
import 'AllTechniciansListPage.dart';
import 'AdminRequestsPage.dart';
import 'AdminPage.dart';
import 'OrdersPage.dart';
import 'ShippedOrdersPage.dart';
import 'ProductsPage.dart';
import 'package:bard/statements/OrdersCalculatorPage.dart';
import 'TechnicianAnalyticsScreen.dart';
import 'PrizeSetupPage.dart';

class EmployeeHomePage extends StatefulWidget {
  const EmployeeHomePage({Key? key}) : super(key: key);

  @override
  _EmployeeHomePageState createState() => _EmployeeHomePageState();
}

class _EmployeeHomePageState extends State<EmployeeHomePage> {
  int _selectedIndex = 0;

  // قائمة عناصر القائمة الجانبية مع العنوان، الأيقونة والصفحة المرتبطة
  final List<_MenuItem> _menuItems = [
    _MenuItem(
      title: "كشف الدخل",
      icon: Icons.insert_chart_outlined,
      page: OrdersDashboardPage(),
    ),
    _MenuItem(
      title: "كشف الفنيين",
      icon: Icons.pie_chart_rounded,
      page: AnalyticsScreen(),
    ),
    _MenuItem(
      title: "إضافة بنرات",
      icon: Icons.add_photo_alternate_outlined,
      page: BannerUploadPage(),
    ),
    _MenuItem(
      title: "إضافة منتجات",
      icon: Icons.add_business_outlined,
      page: AdditionsPage(),
    ),
    _MenuItem(
      title: "التصنيفات",
      icon: Icons.category_outlined,
      page: CreateCategoryPage(),
    ),
    _MenuItem(
      title: "العجلة",
      icon: Icons.add,
      page: DiscountSetupPage(),
    ),
    _MenuItem(
      title: "تعديل المنتجات",
      icon: Icons.edit,
      page: ProductsPage(),
    ),
    _MenuItem(
      title: "إضافة فني + موظف",
      icon: Icons.person_add,
      page: AddUsersPage(),
    ),
    _MenuItem(
      title: "التعديل + الاشتراكات",
      icon: Icons.admin_panel_settings,
      page: AllTechniciansListPage(),
    ),
    _MenuItem(
      title: "طلبات الفنيين",
      icon: Icons.flag_outlined,
      page: AdminRequestsPage(),
    ),
    _MenuItem(
      title: "تعديل المحافظات + الفنيين",
      icon: Icons.edit_location,
      page: AdminPage(),
    ),
    _MenuItem(
      title: "طلبات الزبائن",
      icon: Icons.shopping_cart_outlined,
      page: OrdersPage(),
    ),
    _MenuItem(
      title: "طلبات الزبائن المشحونة",
      icon: Icons.local_shipping,
      page: ShippedOrdersPage(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // شريط العنوان العلوي بتصميم متناسق مع زر خروج معروض بشكل واضح
      appBar: AppBar(
        title: Text(
          'لوحة التحكم - الموظف',
          style: TextStyle(
            fontFamily: 'Amiri',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 4,
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            tooltip: "خروج",
            onPressed: () {
              // عرض رسالة تأكيد قبل الخروج
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text("تأكيد الخروج"),
                  content: Text("هل أنت متأكد من رغبتك في الخروج؟"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text("إلغاء"),
                    ),
                    TextButton(
                      onPressed: () => exit(0),
                      child: Text("خروج"),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // القائمة الجانبية باستخدام NavigationRail بوضعية ممتدة لعرض العناوين مع الأيقونات
          NavigationRail(
            extended: true,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            backgroundColor: Colors.blueAccent,
            selectedIconTheme: IconThemeData(color: Colors.white, size: 32),
            unselectedIconTheme: IconThemeData(color: Colors.white70, size: 28),
            selectedLabelTextStyle: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'Amiri',
            ),
            unselectedLabelTextStyle: TextStyle(
              color: Colors.white70,
              fontFamily: 'Amiri',
            ),
            destinations: _menuItems
                .map(
                  (item) => NavigationRailDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.icon, color: Colors.white),
                label: Text(item.title),
              ),
            )
                .toList(),
          ),
          // فاصل عمودي أنيق بين القائمة والمحتوى الرئيسي
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: Colors.grey.shade300,
          ),
          // المنطقة الرئيسية التي تعرض الصفحة المختارة مع حواف داخلية لتناسق المحتوى
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16),
              color: Colors.grey.shade50,
              child: _menuItems[_selectedIndex].page,
            ),
          ),
        ],
      ),
    );
  }
}

// نموذج بسيط لعنصر القائمة الجانبية
class _MenuItem {
  final String title;
  final IconData icon;
  final Widget page;

  _MenuItem({
    required this.title,
    required this.icon,
    required this.page,
  });
}
