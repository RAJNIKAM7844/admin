import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManageDriversScreen extends StatefulWidget {
  const ManageDriversScreen({super.key});

  @override
  State<ManageDriversScreen> createState() => _ManageDriversScreenState();
}

class _ManageDriversScreenState extends State<ManageDriversScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> drivers = [];
  List<Map<String, dynamic>> deliveryAreas = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchDeliveryAreas();
    fetchDrivers();
  }

  Future<void> fetchDeliveryAreas() async {
    try {
      final response = await supabase
          .from('delivery_areas')
          .select('id, area_name')
          .order('area_name', ascending: true);
      setState(() {
        deliveryAreas = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching delivery areas: $e')),
      );
    }
  }

  Future<void> fetchDrivers() async {
    setState(() => isLoading = true);
    try {
      final response = await supabase
          .from('drivers')
          .select(
              'id, driver_name, vehicle_number, username, area_id, delivery_areas!area_id(area_name)')
          .order('driver_name', ascending: true);
      setState(() {
        drivers = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        drivers = [];
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching drivers: $e')),
      );
    }
  }

  Future<void> addDriver(String name, String vehicle, String username,
      String password, int areaId) async {
    try {
      await supabase.from('drivers').insert({
        'driver_name': name,
        'vehicle_number': vehicle,
        'username': username,
        'password': password,
        'area_id': areaId,
      });
      fetchDrivers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding driver: $e')),
      );
    }
  }

  Future<void> updateDriver(int id, String name, String vehicle,
      String username, String password, int areaId) async {
    try {
      await supabase.from('drivers').update({
        'driver_name': name,
        'vehicle_number': vehicle,
        'username': username,
        'password': password,
        'area_id': areaId,
      }).eq('id', id);
      fetchDrivers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating driver: $e')),
      );
    }
  }

  Future<void> deleteDriver(int id) async {
    try {
      await supabase.from('drivers').delete().eq('id', id);
      fetchDrivers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting driver: $e')),
      );
    }
  }

  void showDriverDialog({Map<String, dynamic>? driver}) {
    final nameController =
        TextEditingController(text: driver?['driver_name'] ?? '');
    final vehicleController =
        TextEditingController(text: driver?['vehicle_number'] ?? '');
    final usernameController =
        TextEditingController(text: driver?['username'] ?? '');
    final passwordController = TextEditingController(text: '');
    int? selectedAreaId = driver?['area_id'];

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white.withOpacity(0.95),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  driver == null ? 'Add Driver' : 'Edit Driver',
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0D0221),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  style:
                      GoogleFonts.roboto(color: Colors.black87, fontSize: 15),
                  decoration: InputDecoration(
                    labelText: 'Driver Name',
                    labelStyle: GoogleFonts.roboto(color: Colors.grey.shade600),
                    prefixIcon: Icon(Icons.person,
                        color: Colors.grey.shade600, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE91E63)),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: vehicleController,
                  style:
                      GoogleFonts.roboto(color: Colors.black87, fontSize: 15),
                  decoration: InputDecoration(
                    labelText: 'Vehicle Number',
                    labelStyle: GoogleFonts.roboto(color: Colors.grey.shade600),
                    prefixIcon: Icon(Icons.local_shipping,
                        color: Colors.grey.shade600, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE91E63)),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: usernameController,
                  style:
                      GoogleFonts.roboto(color: Colors.black87, fontSize: 15),
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle: GoogleFonts.roboto(color: Colors.grey.shade600),
                    prefixIcon: Icon(Icons.account_circle,
                        color: Colors.grey.shade600, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE91E63)),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  style:
                      GoogleFonts.roboto(color: Colors.black87, fontSize: 15),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: GoogleFonts.roboto(color: Colors.grey.shade600),
                    prefixIcon:
                        Icon(Icons.lock, color: Colors.grey.shade600, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE91E63)),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: selectedAreaId,
                  decoration: InputDecoration(
                    labelText: 'Delivery Area',
                    labelStyle: GoogleFonts.roboto(color: Colors.grey.shade600),
                    prefixIcon: Icon(Icons.location_on,
                        color: Colors.grey.shade600, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE91E63)),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: deliveryAreas.map((area) {
                    return DropdownMenuItem<int>(
                      value: area['id'],
                      child: Text(
                        area['area_name'],
                        style: GoogleFonts.roboto(
                            color: Colors.black87, fontSize: 15),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => selectedAreaId = value,
                  validator: (value) =>
                      value == null ? 'Please select an area' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.roboto(
                          color: Colors.grey.shade600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final name = nameController.text.trim();
                        final vehicle = vehicleController.text.trim();
                        final username = usernameController.text.trim();
                        final password = passwordController.text.trim();

                        if (name.isEmpty ||
                            vehicle.isEmpty ||
                            username.isEmpty ||
                            password.isEmpty ||
                            selectedAreaId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Please fill all fields')),
                          );
                          return;
                        }

                        try {
                          if (driver == null) {
                            await addDriver(name, vehicle, username, password,
                                selectedAreaId!);
                          } else {
                            await updateDriver(driver['id'], name, vehicle,
                                username, password, selectedAreaId!);
                          }
                          Navigator.pop(context);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE91E63), Color(0xFF4CAF50)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Text(
                          'Save',
                          style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildDriverItem(Map<String, dynamic> driver) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey.shade200,
              child: Icon(Icons.person, color: Colors.black54, size: 20),
            ),
            title: Text(
              driver['driver_name'],
              style: GoogleFonts.roboto(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vehicle: ${driver['vehicle_number']}',
                  style: GoogleFonts.roboto(
                      color: Colors.white.withOpacity(0.7), fontSize: 13),
                ),
                Text(
                  'Username: ${driver['username']}',
                  style: GoogleFonts.roboto(
                      color: Colors.white.withOpacity(0.7), fontSize: 13),
                ),
                Text(
                  'Area: ${driver['delivery_areas']['area_name']}',
                  style: GoogleFonts.roboto(
                      color: Colors.white.withOpacity(0.7), fontSize: 13),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit,
                      color: Colors.green.withOpacity(0.9), size: 20),
                  onPressed: () => showDriverDialog(driver: driver),
                ),
                IconButton(
                  icon: Icon(Icons.delete,
                      color: Colors.red.withOpacity(0.9), size: 20),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => Dialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        backgroundColor: Colors.white.withOpacity(0.95),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Confirm Delete',
                                style: GoogleFonts.roboto(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0D0221),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Are you sure you want to delete "${driver['driver_name']}"?',
                                style: GoogleFonts.roboto(
                                    color: Colors.black87, fontSize: 15),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text(
                                      'Cancel',
                                      style: GoogleFonts.roboto(
                                          color: Colors.grey.shade600,
                                          fontSize: 15),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 20),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFE91E63),
                                            Color(0xFF4CAF50)
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color:
                                                Colors.white.withOpacity(0.2)),
                                      ),
                                      child: Text(
                                        'Delete',
                                        style: GoogleFonts.roboto(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );

                    if (confirm == true) {
                      await deleteDriver(driver['id']);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D0221), Color(0xFF2A1B3D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 24),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        'Manage Drivers',
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Driver List
              Expanded(
                child: isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Loading Drivers...',
                              style: GoogleFonts.roboto(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : drivers.isEmpty
                        ? Center(
                            child: Text(
                              'No drivers found.',
                              style: GoogleFonts.roboto(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: drivers.length,
                            itemBuilder: (_, index) =>
                                buildDriverItem(drivers[index]),
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDriverDialog(),
        backgroundColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        label: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE91E63), Color(0xFF4CAF50)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.add, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Add Driver',
                style: GoogleFonts.roboto(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
