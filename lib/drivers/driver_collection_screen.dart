import 'package:admin_eggs/drivers/calender_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriverCollectionScreen extends StatefulWidget {
  const DriverCollectionScreen({super.key});

  @override
  State<DriverCollectionScreen> createState() => _DriverCollectionScreenState();
}

class _DriverCollectionScreenState extends State<DriverCollectionScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> drivers = [];
  List<Map<String, dynamic>> filteredDrivers = [];
  bool isLoading = false;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchDrivers();
  }

  Future<void> fetchDrivers() async {
    setState(() {
      isLoading = true;
    });
    try {
      print('Fetching drivers with areas...');

      // Fetch drivers with their associated delivery area using area_id
      final driverResponse = await supabase.from('drivers').select('''
            id, driver_name, vehicle_number, 
            delivery_areas!area_id(area_name)
          ''').order('driver_name', ascending: true);

      print('Fetched drivers with areas: $driverResponse');

      setState(() {
        drivers = List<Map<String, dynamic>>.from(driverResponse);
        filteredDrivers = List<Map<String, dynamic>>.from(driverResponse);
        isLoading = false;
      });

      print('Number of drivers fetched: ${drivers.length}');
    } catch (e) {
      setState(() {
        drivers = [];
        filteredDrivers = [];
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching drivers: $e')),
      );
    }
  }

  void filterDrivers(String query) {
    final lowerQuery = query.toLowerCase();
    print('Search query: $lowerQuery');

    setState(() {
      filteredDrivers = drivers.where((driver) {
        final name = driver['driver_name']?.toLowerCase() ?? '';
        final area =
            driver['delivery_areas']?['area_name']?.toLowerCase() ?? '';
        print('Driver: ${driver['driver_name']}, Area: $area');
        return name.contains(lowerQuery) || area.contains(lowerQuery);
      }).toList();
      print('Filtered drivers: $filteredDrivers');
    });
  }

  Widget buildDriverItem(Map<String, dynamic> driver) {
    final areaName =
        driver['delivery_areas']?['area_name'] ?? 'No area assigned';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
        elevation: 3,
        shadowColor: Colors.black87,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white24,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CalendarSelectionScreen(
                  driverId: driver['id'],
                  driverName: driver['driver_name'] ?? 'Unknown',
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white70, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.6),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, color: Colors.black54, size: 28),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver['driver_name'] ?? 'Unknown',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        areaName,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.black54,
                  size: 18,
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
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1A0841),
              Color(0xFF3B322C),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
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
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Driver Collection',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              // Search bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: searchController,
                    onChanged: filterDrivers,
                    style: const TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'search by name, address',
                      hintStyle: TextStyle(color: Colors.grey.shade600),
                      border: InputBorder.none,
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              // Driver list
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredDrivers.isEmpty
                        ? const Center(
                            child: Text(
                              'No drivers found.',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 18),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredDrivers.length,
                            itemBuilder: (context, index) {
                              return buildDriverItem(filteredDrivers[index]);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
