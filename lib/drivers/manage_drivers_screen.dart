import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManageDriversScreen extends StatefulWidget {
  const ManageDriversScreen({Key? key}) : super(key: key);

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
    setState(() {
      isLoading = true;
    });
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
    final TextEditingController nameController = TextEditingController(
        text: driver != null ? driver['driver_name'] : '');
    final TextEditingController vehicleController = TextEditingController(
        text: driver != null ? driver['vehicle_number'] : '');
    final TextEditingController usernameController =
        TextEditingController(text: driver != null ? driver['username'] : '');
    final TextEditingController passwordController =
        TextEditingController(text: driver != null ? '' : '');
    int? selectedAreaId = driver != null ? driver['area_id'] : null;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(driver == null ? 'Add Driver' : 'Edit Driver'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Driver Name',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: vehicleController,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Number',
                  prefixIcon: Icon(Icons.local_shipping),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.account_circle),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: selectedAreaId,
                decoration: const InputDecoration(
                  labelText: 'Delivery Area',
                  prefixIcon: Icon(Icons.location_on),
                ),
                items: deliveryAreas.map((area) {
                  return DropdownMenuItem<int>(
                    value: area['id'],
                    child: Text(area['area_name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedAreaId = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select an area' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
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
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              try {
                if (driver == null) {
                  await addDriver(
                      name, vehicle, username, password, selectedAreaId!);
                } else {
                  await updateDriver(driver['id'], name, vehicle, username,
                      password, selectedAreaId!);
                }
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget buildDriverItem(Map<String, dynamic> driver) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: ListTile(
        title: Text(driver['driver_name']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vehicle: ${driver['vehicle_number']}'),
            Text('Username: ${driver['username']}'),
            Text('Area: ${driver['delivery_areas']['area_name']}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blueAccent),
              onPressed: () => showDriverDialog(driver: driver),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Confirm Delete'),
                    content: Text(
                        'Are you sure you want to delete "${driver['driver_name']}"?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel')),
                      ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete')),
                    ],
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage Drivers',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A237E),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : drivers.isEmpty
              ? const Center(child: Text('No drivers found.'))
              : ListView.builder(
                  itemCount: drivers.length,
                  itemBuilder: (_, index) => buildDriverItem(drivers[index]),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDriverDialog(),
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Driver',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
