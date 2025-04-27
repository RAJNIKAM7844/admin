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
  List<Map<String, dynamic>> driversPerArea = [];
  bool isLoading = false;

  final TextEditingController areaNameController = TextEditingController();
  int? editingAreaId;

  @override
  void initState() {
    super.initState();
    fetchAreas();
  }

  Future<void> fetchAreas() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Fetch all areas
      final areaResponse = await supabase
          .from('delivery_areas')
          .select('id, area_name')
          .order('area_name');

      if (areaResponse != null && areaResponse is List) {
        final List<Map<String, dynamic>> fetchedAreas =
            List<Map<String, dynamic>>.from(areaResponse);

        // Fetch drivers for each area
        final List<Map<String, dynamic>> driversList = [];
        for (var area in fetchedAreas) {
          final driversResponse = await supabase
              .from('drivers')
              .select('id, driver_name, vehicle_number')
              .eq('area_id', area['id']);

          driversList.add({
            'area_id': area['id'],
            'drivers': driversResponse,
          });
        }

        setState(() {
          areas = fetchedAreas;
          driversPerArea = driversList;
          isLoading = false;
        });
      } else {
        setState(() {
          areas = [];
          driversPerArea = [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        areas = [];
        driversPerArea = [];
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching areas: $e')),
      );
    }
  }

  Future<void> addArea(String areaName) async {
    try {
      await supabase.from('delivery_areas').insert({
        'area_name': areaName,
      });
      await fetchAreas();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add area: $e')),
      );
    }
  }

  Future<void> updateArea(int id, String areaName) async {
    try {
      await supabase
          .from('delivery_areas')
          .update({'area_name': areaName}).eq('id', id);
      await fetchAreas();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update area: $e')),
      );
    }
  }

  Future<void> deleteArea(int id) async {
    try {
      // Check if any drivers are assigned to this area
      final driversInArea =
          await supabase.from('drivers').select('id').eq('area_id', id);

      if (driversInArea.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Cannot delete area: Drivers are assigned to it')),
        );
        return;
      }

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
    } else {
      editingAreaId = null;
      areaNameController.clear();
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

              if (areaName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill the area name')),
                );
                return;
              }

              try {
                if (editingAreaId == null) {
                  await addArea(areaName);
                } else {
                  await updateArea(editingAreaId!, areaName);
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
    // Find drivers assigned to this area
    final areaDrivers = driversPerArea.firstWhere(
      (d) => d['area_id'] == area['id'],
      orElse: () => {'drivers': []},
    )['drivers'] as List<dynamic>;

    final driverNames = areaDrivers.isNotEmpty
        ? areaDrivers
            .map((d) => '${d['driver_name']} - ${d['vehicle_number']}')
            .join(', ')
        : 'No drivers assigned';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(area['area_name'] ?? ''),
        subtitle: Text('Drivers: $driverNames'),
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
