import 'package:admin_eggs/login.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UpdateRatePage extends StatefulWidget {
  const UpdateRatePage({super.key});

  @override
  State<UpdateRatePage> createState() => _UpdateRatePageState();
}

class _UpdateRatePageState extends State<UpdateRatePage> {
  final _rateController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  final _supabase = Supabase.instance.client;

  void _redirectToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminLoginPage()),
      );
    });
  }

  Future<void> _updateEggRate() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'You must be logged in to update the egg rate';
          _isLoading = false;
        });
        _redirectToLogin();
        return;
      }

      final newRate = double.tryParse(_rateController.text);
      if (newRate == null || newRate <= 0) {
        setState(() {
          _errorMessage = 'Please enter a valid positive number';
          _isLoading = false;
        });
        return;
      }

      await _supabase.from('egg_rates').upsert({
        'id': 1,
        'rate': newRate,
        'updated_at': DateTime.now().toIso8601String(),
      });

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Egg rate updated successfully'),
          backgroundColor: Colors.blue,
        ),
      );
    } on PostgrestException catch (e) {
      setState(() {
        _errorMessage = e.code == '42501'
            ? 'Permission denied: Please log in again'
            : 'Error updating rate: ${e.message}';
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
      if (e.code == '42501') {
        _redirectToLogin();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Unexpected error: $e';
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unexpected error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Egg Rate'),
        backgroundColor: const Color(0xFFB3D2F2),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFB3D2F2), Colors.white],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Enter New Egg Rate (₹)',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _rateController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                labelText: 'Egg Rate',
                prefixText: '₹ ',
                errorText: _errorMessage,
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _updateEggRate,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Update Rate',
                      style: TextStyle(fontSize: 18),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching drivers: $e')),
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
          backgroundColor: Colors.blue,
        ),
      );
    } on PostgrestException catch (e) {
      setState(() {
        _errorMessage = e.code == '42501'
            ? 'Permission denied: Please log in again'
            : 'Error updating quantity: ${e.message}';
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
      if (e.code == '42501') {
        _redirectToLogin();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Unexpected error: $e';
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unexpected error: $e'),
          backgroundColor: Colors.red,
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
      appBar: AppBar(
        title: const Text('Update Tray Quantity'),
        backgroundColor: const Color(0xFFB3D2F2),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFB3D2F2), Colors.white],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Select Driver and Enter Tray Quantity',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: selectedDriverId,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                labelText: 'Select Driver',
                filled: true,
                fillColor: Colors.white,
              ),
              items: drivers.map((driver) {
                return DropdownMenuItem<String>(
                  value: driver['id'].toString(),
                  child: Text(driver['driver_name'] ?? 'Unknown'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedDriverId = value;
                });
              },
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _trayController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                labelText: 'Tray Quantity',
                errorText: _errorMessage,
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _updateTrayQuantity,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Update Quantity',
                      style: TextStyle(fontSize: 18),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
