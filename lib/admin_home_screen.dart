import 'package:admin_eggs/customers/customers_screen.dart';
import 'package:admin_eggs/update.dart' as update;
import 'package:admin_eggs/updatetraypage.dart';
import 'package:admin_eggs/vip/update_transactions.dart';
import 'package:admin_eggs/vip/vip_egg_rate.dart';
import 'package:admin_eggs/vip/vip_total_collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'drivers/manage_drivers_screen.dart';
import 'drivers/drivers_screen.dart';
import 'drivers/driver_collection_screen.dart';
import 'total_collection_screen.dart';
import 'manage_areas_screen.dart';
import 'vip/vip_customers_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  bool isVipMode = false;
  double todayTotalCollection = 0.0;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _verifyAdmin();
    _fetchTodayTotalCollection();
  }

  Future<void> _verifyAdmin() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      _redirectToLogin();
      return;
    }

    try {
      final adminCheck = await supabase
          .from('admins')
          .select('email')
          .eq('email', user.email!)
          .maybeSingle();

      if (adminCheck == null) {
        await supabase.auth.signOut();
        _redirectToLogin();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error verifying admin status: $e',
              style: GoogleFonts.roboto(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
      _redirectToLogin();
    }
  }

  Future<void> _fetchTodayTotalCollection() async {
    final table = isVipMode ? 'wholesale_transaction' : 'transactions';
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay
          .add(const Duration(days: 1))
          .subtract(const Duration(milliseconds: 1));

      final response = await supabase
          .from(table)
          .select('paid')
          .gte('date', startOfDay.toIso8601String())
          .lte('date', endOfDay.toIso8601String());

      final total = List<Map<String, dynamic>>.from(response).fold<double>(
          0.0, (sum, row) => sum + (row['paid'] as num).toDouble());

      setState(() {
        todayTotalCollection = total;
      });
    } catch (e) {
      print('Error fetching today\'s total collection from $table: $e');
    }
  }

  void _redirectToLogin() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _logout() async {
    await supabase.auth.signOut();
    _redirectToLogin();
  }

  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchTodayTotalCollection,
        color: Colors.white,
        backgroundColor: Colors.black.withOpacity(0.5),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: Color(0xFF2A1B3D),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Admin Dashboard',
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white, size: 24),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _logout();
                  },
                  tooltip: 'Logout',
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Container(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      kToolbarHeight -
                      MediaQuery.of(context).padding.top,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D0221), Color(0xFF2A1B3D)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 0,
                      color: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isVipMode
                                  ? 'Welcome, Wholesale Admin'
                                  : 'Welcome, Admin',
                              style: GoogleFonts.roboto(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isVipMode
                                  ? 'Manage your wholesale operations'
                                  : 'Manage your operations efficiently',
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.7),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 0,
                      color: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CustomToggle(
                              isVipMode: isVipMode,
                              onToggle: (value) {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  isVipMode = value;
                                  _fetchTodayTotalCollection();
                                });
                              },
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.2)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                'Today: ₹${todayTotalCollection.toStringAsFixed(2)}',
                                style: GoogleFonts.roboto(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isVipMode ? 'Wholesale Options' : 'Options',
                      style: GoogleFonts.roboto(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (!isVipMode) ...[
                      _AdminOptionButton(
                        icon: Icons.person,
                        label: 'Customers',
                        onTap: () => _navigateTo(const CustomersScreen()),
                      ),
                      _AdminOptionButton(
                        icon: Icons.local_shipping,
                        label: 'Drivers',
                        onTap: () => _navigateTo(const DriversScreen()),
                      ),
                      _AdminOptionButton(
                        icon: Icons.manage_accounts,
                        label: 'Manage Drivers',
                        onTap: () => _navigateTo(const ManageDriversScreen()),
                      ),
                      _AdminOptionButton(
                        icon: Icons.attach_money,
                        label: 'Driver Collection',
                        onTap: () =>
                            _navigateTo(const DriverCollectionScreen()),
                      ),
                      _AdminOptionButton(
                        icon: Icons.analytics,
                        label: 'Total Collection',
                        onTap: () => _navigateTo(const TotalCollectionScreen()),
                      ),
                      _AdminOptionButton(
                        icon: Icons.egg,
                        label: 'Update Egg Price',
                        onTap: () => _navigateTo(const update.UpdateRatePage()),
                      ),
                      _AdminOptionButton(
                        icon: Icons.egg,
                        label: 'Update Trays Quantity',
                        onTap: () => _navigateTo(const UpdateTrayPage()),
                      ),
                      _AdminOptionButton(
                        icon: Icons.location_on,
                        label: 'Manage Areas',
                        onTap: () => _navigateTo(const ManageAreasScreen()),
                      ),
                    ] else ...[
                      _AdminOptionButton(
                        icon: Icons.person,
                        label: 'Wholesale Customers',
                        onTap: () => _navigateTo(const VipCustomersScreen()),
                      ),
                      _AdminOptionButton(
                        icon: Icons.egg,
                        label: 'Update Wholesale Egg Price',
                        onTap: () => _navigateTo(const VipUpdateRatePage()),
                      ),
                      _AdminOptionButton(
                        icon: Icons.analytics,
                        label: 'Wholesale Total Collection',
                        onTap: () =>
                            _navigateTo(const VipTotalCollectionScreen()),
                      ),
                      _AdminOptionButton(
                        icon: Icons.payment,
                        label: 'Update Wholesale Transaction',
                        onTap: () =>
                            _navigateTo(const VipUpdateTransactionScreen()),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomToggle extends StatelessWidget {
  final bool isVipMode;
  final Function(bool) onToggle;

  const CustomToggle({
    super.key,
    required this.isVipMode,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onToggle(!isVipMode),
      child: Container(
        width: 120,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withOpacity(0.1),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              alignment:
                  isVipMode ? Alignment.centerRight : Alignment.centerLeft,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Container(
                width: 60,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE91E63), Color(0xFF4CAF50)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      'Public',
                      style: GoogleFonts.roboto(
                        color: isVipMode
                            ? Colors.white.withOpacity(0.7)
                            : Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Stock',
                      style: GoogleFonts.roboto(
                        color: isVipMode
                            ? Colors.white
                            : Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminOptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AdminOptionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withOpacity(0.2)),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.white.withOpacity(0.3),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
