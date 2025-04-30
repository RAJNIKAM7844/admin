import 'package:admin_eggs/customers/customers_screen.dart';
import 'package:admin_eggs/update.dart' as update;
import 'package:admin_eggs/updatetraypage.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'drivers/manage_drivers_screen.dart';
import 'drivers/drivers_screen.dart';
import 'drivers/driver_collection_screen.dart';
import 'total_collection_screen.dart';
import 'manage_areas_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  @override
  void initState() {
    super.initState();
    _verifyAdmin();
  }

  Future<void> _verifyAdmin() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _redirectToLogin();
      return;
    }

    try {
      final adminCheck = await Supabase.instance.client
          .from('admins')
          .select('email')
          .eq('email', user.email!)
          .maybeSingle();

      if (adminCheck == null) {
        await Supabase.instance.client.auth.signOut();
        _redirectToLogin();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error verifying admin status: $e')),
      );
      _redirectToLogin();
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
    await Supabase.instance.client.auth.signOut();
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
      backgroundColor: const Color(0xFF110734),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.brown.shade800,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Welcome,",
                        style: TextStyle(fontSize: 26, color: Colors.white)),
                    Text("Admin",
                        style: TextStyle(fontSize: 18, color: Colors.white70)),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const Center(
                child: Column(
                  children: [
                    Text("Today’s Collection",
                        style: TextStyle(fontSize: 20, color: Colors.white)),
                    SizedBox(height: 8),
                    Text("\$550",
                        style: TextStyle(
                            fontSize: 28,
                            color: Colors.green,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const Text("OPTIONS",
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _AdminOptionButton(
                icon: Icons.person,
                label: "Customers",
                onTap: () => _navigateTo(const CustomersScreen()),
              ),
              _AdminOptionButton(
                icon: Icons.local_shipping,
                label: "Drivers",
                onTap: () => _navigateTo(const DriversScreen()),
              ),
              _AdminOptionButton(
                icon: Icons.manage_accounts,
                label: "Manage Drivers",
                onTap: () => _navigateTo(const ManageDriversScreen()),
              ),
              _AdminOptionButton(
                icon: Icons.attach_money,
                label: "Driver Collection",
                onTap: () => _navigateTo(const DriverCollectionScreen()),
              ),
              _AdminOptionButton(
                icon: Icons.analytics,
                label: "Total Collection",
                onTap: () => _navigateTo(const TotalCollectionScreen()),
              ),
              _AdminOptionButton(
                icon: Icons.egg,
                label: "Update Egg Price",
                onTap: () => _navigateTo(const update.UpdateRatePage()),
              ),
              _AdminOptionButton(
                icon: Icons.egg,
                label: "Update Trays Quantity",
                onTap: () => _navigateTo(const UpdateTrayPage()),
              ),
              _AdminOptionButton(
                icon: Icons.location_on,
                label: "Manage Areas",
                onTap: () => _navigateTo(const ManageAreasScreen()),
              ),
            ],
          ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              children: [
                Icon(icon, color: Colors.black),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(label,
                      style:
                          const TextStyle(fontSize: 16, color: Colors.black)),
                ),
                const Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.black),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
