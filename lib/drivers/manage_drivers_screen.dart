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
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchDrivers();
  }

  Future<void> fetchDrivers() async {
    setState(() {
      isLoading = true;
    });
    final response = await supabase
        .from('drivers')
        .select()
        .order('driver_name', ascending: true) as List<dynamic>?;

    if (response != null) {
      setState(() {
        drivers = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } else {
      setState(() {
        drivers = [];
        isLoading = false;
      });
    }
  }

  Future<void> addDriver(String name, String vehicle) async {
    final response = await supabase.from('drivers').insert({
      'driver_name': name,
      'vehicle_number': vehicle,
    });

    fetchDrivers();
  }

  Future<void> updateDriver(int id, String name, String vehicle) async {
    await supabase.from('drivers').update({
      'driver_name': name,
      'vehicle_number': vehicle,
    }).eq('id', id);

    fetchDrivers();
  }

  Future<void> deleteDriver(int id) async {
    await supabase.from('drivers').delete().eq('id', id);
    fetchDrivers();
  }

  void showDriverDialog({Map<String, dynamic>? driver}) {
    final TextEditingController nameController = TextEditingController(
        text: driver != null ? driver['driver_name'] : '');
    final TextEditingController vehicleController = TextEditingController(
        text: driver != null ? driver['vehicle_number'] : '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(driver == null ? 'Add Driver' : 'Edit Driver'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Driver Name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            TextField(
              controller: vehicleController,
              decoration: const InputDecoration(
                labelText: 'Vehicle Number',
                prefixIcon: Icon(Icons.local_shipping),
              ),
            ),
          ],
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

              if (name.isEmpty || vehicle.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              if (driver == null) {
                await addDriver(name, vehicle);
              } else {
                await updateDriver(driver['id'], name, vehicle);
              }
              Navigator.pop(context);
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
        subtitle: Text('Vehicle: ${driver['vehicle_number']}'),
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
