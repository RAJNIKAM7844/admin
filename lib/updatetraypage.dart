import 'package:admin_eggs/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UpdateTrayPage extends StatefulWidget {
  const UpdateTrayPage({super.key});

  @override
  State<UpdateTrayPage> createState() => _UpdateTrayPageState();
}

class _UpdateTrayPageState extends State<UpdateTrayPage> {
  final _trayController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> drivers = [];
  String? selectedDriverId;

  @override
  void initState() {
    super.initState();
    _fetchDrivers();
  }

  Future<void> _fetchDrivers() async {
    try {
      final response = await _supabase
          .from('drivers')
          .select('id, driver_name')
          .order('driver_name', ascending: true);

      setState(() {
        drivers = List<Map<String, dynamic>>.from(response);
        if (drivers.isNotEmpty) {
          selectedDriverId = drivers[0]['id'].toString();
        }
      });
    } on PostgrestException catch (e) {
      String message;
      if (e.code == '42P01') {
        message = 'Table "drivers" does not exist. Verify Supabase schema.';
      } else if (e.code == '42501') {
        message = 'Permission denied for "drivers". Check RLS policies.';
      } else {
        message = 'Error fetching drivers: ${e.message} (Code: ${e.code})';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error fetching drivers: $e')),
      );
    }
  }

  void _redirectToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminLoginPage()),
      );
    });
  }

  Future<void> _updateTrayQuantity() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'You must be logged in to update the tray quantity';
          _isLoading = false;
        });
        _redirectToLogin();
        return;
      }

      if (selectedDriverId == null) {
        setState(() {
          _errorMessage = 'Please select a driver';
          _isLoading = false;
        });
        return;
      }

      final newQuantity = int.tryParse(_trayController.text);
      if (newQuantity == null || newQuantity < 0) {
        setState(() {
          _errorMessage = 'Please enter a valid non-negative integer';
          _isLoading = false;
        });
        return;
      }

      await _supabase.from('tray_quantities').upsert({
        'driver_id': int.parse(selectedDriverId!),
        'quantity': newQuantity,
        'updated_at': DateTime.now().toIso8601String(),
      });

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tray quantity updated successfully'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    } on PostgrestException catch (e) {
      String message;
      if (e.code == '42501') {
        message = 'Permission denied: Please log in again';
        _redirectToLogin();
      } else if (e.code == '42P01') {
        message =
            'Table "tray_quantities" does not exist. Verify Supabase schema.';
      } else {
        message = 'Error updating quantity: ${e.message} (Code: ${e.code})';
      }
      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Unexpected error updating quantity: $e';
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unexpected error updating quantity: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  void dispose() {
    _trayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D0221), Color(0xFF2A1B3D)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      'Update Tray Quantity',
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    titlePadding: const EdgeInsets.only(left: 72, bottom: 16),
                  ),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black,
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
                              'Set Tray Quantity',
                              style: GoogleFonts.roboto(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Select a driver and enter the tray quantity',
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                color: Colors.grey,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: selectedDriverId,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.person,
                                  color: Colors.grey,
                                ),
                                labelText: 'Select Driver',
                                labelStyle: GoogleFonts.roboto(
                                  color: Colors.grey,
                                  fontSize: 15,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade200,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                              ),
                              dropdownColor: Colors.white,
                              style: GoogleFonts.roboto(
                                color: Colors.black,
                                fontSize: 15,
                                letterSpacing: 0.5,
                              ),
                              items: drivers.map((driver) {
                                return DropdownMenuItem<String>(
                                  value: driver['id'].toString(),
                                  child:
                                      Text(driver['driver_name'] ?? 'Unknown'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  selectedDriverId = value;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _trayController,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.roboto(
                                color: Colors.black,
                                fontSize: 15,
                                letterSpacing: 0.5,
                              ),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.egg,
                                  color: Colors.grey,
                                ),
                                labelText: 'Tray Quantity',
                                labelStyle: GoogleFonts.roboto(
                                  color: Colors.grey,
                                  fontSize: 15,
                                ),
                                errorText: _errorMessage,
                                errorStyle: GoogleFonts.roboto(
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade200,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      HapticFeedback.lightImpact();
                                      _updateTrayQuantity();
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors
                                    .transparent, // Transparent button background
                                padding: EdgeInsets
                                    .zero, // No padding to interfere with the container
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      12), // Rounded corners
                                ),
                                minimumSize: const Size(
                                    double.infinity, 50), // Full-width button
                              ),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFE91E63), // Start color (pink)
                                      Color(0xFF4CAF50), // End color (green)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                      12), // Match button's border radius
                                ),
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 20),
                                  child: _isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors
                                              .white, // Loading spinner color
                                        )
                                      : Text(
                                          'Update Quantity',
                                          style: GoogleFonts.roboto(
                                            color: Colors.white, // Text color
                                            fontSize: 15, // Font size
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
