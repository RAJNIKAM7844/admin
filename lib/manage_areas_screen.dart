import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManageAreasScreen extends StatefulWidget {
  const ManageAreasScreen({Key? key}) : super(key: key);

  @override
  State<ManageAreasScreen> createState() => _ManageAreasScreenState();
}

class _ManageAreasScreenState extends State<ManageAreasScreen> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> areas = [];
  List<Map<String, dynamic>> drivers = [];
  bool isLoading = false;

  final TextEditingController areaNameController = TextEditingController();
  int? selectedDriverId;
  int? editingAreaId;

  @override
  void initState() {
    super.initState();
    fetchDrivers();
    fetchAreas();
  }

  Future<void> fetchDrivers() async {
    try {
      final response = await supabase
          .from('drivers')
          .select('id, driver_name, vehicle_number')
          .order('driver_name');

      if (response != null && response is List) {
        setState(() {
          drivers = List<Map<String, dynamic>>.from(response);
        });
      } else {
        setState(() {
          drivers = [];
        });
      }
    } catch (e) {
      setState(() {
        drivers = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching drivers: $e')),
      );
    }
  }

  Future<void> fetchAreas() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await supabase
          .from('delivery_areas')
          .select(
              'id, area_name, driver_id, drivers(driver_name, vehicle_number)')
          .order('area_name');

      if (response != null && response is List) {
        setState(() {
          areas = List<Map<String, dynamic>>.from(response);
          isLoading = false;
        });
      } else {
        setState(() {
          areas = [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching areas: $e')),
      );
    }
  }

  Future<void> addArea(String areaName, int driverId) async {
    try {
      await supabase.from('delivery_areas').insert({
        'area_name': areaName,
        'driver_id': driverId,
      });
      await fetchAreas();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add area: $e')),
      );
    }
  }

  Future<void> updateArea(int id, String areaName, int driverId) async {
    try {
      await supabase
          .from('delivery_areas')
          .update({'area_name': areaName, 'driver_id': driverId}).eq('id', id);
      await fetchAreas();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update area: $e')),
      );
    }
  }

  Future<void> deleteArea(int id) async {
    try {
      await supabase.from('delivery_areas').delete().eq('id', id);
      await fetchAreas();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete area: $e')),
      );
    }
  }

  void showAreaDialog({Map<String, dynamic>? area}) {
    if (area != null) {
      editingAreaId = area['id'] as int?;
      areaNameController.text = area['area_name'] ?? '';
      selectedDriverId = area['driver_id'] as int?;
    } else {
      editingAreaId = null;
      areaNameController.clear();
      selectedDriverId = null;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(area == null ? 'Add Area' : 'Edit Area'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: areaNameController,
              decoration: const InputDecoration(labelText: 'Area Name'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: selectedDriverId,
              decoration: const InputDecoration(labelText: 'Assign Driver'),
              items: drivers.map((driver) {
                final driverName = driver['driver_name'] ?? '';
                final vehicle = driver['vehicle_number'] ?? '';
                return DropdownMenuItem<int>(
                  value: driver['id'] as int,
                  child: Text('$driverName - $vehicle'),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  selectedDriverId = val;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final areaName = areaNameController.text.trim();
              final driverId = selectedDriverId;

              if (areaName.isEmpty || driverId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              if (editingAreaId == null) {
                await addArea(areaName, driverId);
              } else {
                await updateArea(editingAreaId!, areaName, driverId);
              }

              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> confirmDelete(int id, String areaName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "$areaName"?'),
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
      await deleteArea(id);
    }
  }

  Widget buildAreaItem(Map<String, dynamic> area) {
    final driverData = area['drivers'] as Map<String, dynamic>?;

    final driverName = driverData != null
        ? driverData['driver_name'] ?? ''
        : 'No driver assigned';
    final vehicle =
        driverData != null ? driverData['vehicle_number'] ?? '' : '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(area['area_name'] ?? ''),
        subtitle: Text('Driver: $driverName - $vehicle'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blueAccent),
              onPressed: () => showAreaDialog(area: area),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () =>
                  confirmDelete(area['id'] as int, area['area_name'] ?? ''),
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
          'Manage Areas',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A237E),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAreaDialog(),
        label: const Text('Add Area', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: const Color(0xFF3949AB),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : areas.isEmpty
              ? const Center(child: Text('No areas found.'))
              : ListView.builder(
                  itemCount: areas.length,
                  itemBuilder: (_, index) => buildAreaItem(areas[index]),
                ),
    );
  }
}
