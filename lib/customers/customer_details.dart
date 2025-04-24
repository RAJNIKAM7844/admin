import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    home: CustomerDetailsScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

class Customer {
  final String name;
  final String address;

  Customer(this.name, this.address);
}

class CustomerDetailsScreen extends StatefulWidget {
  const CustomerDetailsScreen({super.key});

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  List<Customer> allCustomers = [
    Customer("Customer 1", "Nayandalli"),
    Customer("Customer 2", "Nayandalli"),
    Customer("Customer 3", "Nayandalli"),
    Customer("Customer 4", "Nayandalli"),
    Customer("Ravi Kumar", "BTM Layout"),
    Customer("Sneha", "Indiranagar"),
  ];

  String query = "";

  @override
  Widget build(BuildContext context) {
    List<Customer> filteredCustomers = allCustomers.where((customer) {
      final lowerQuery = query.toLowerCase();
      return customer.name.toLowerCase().contains(lowerQuery) ||
          customer.address.toLowerCase().contains(lowerQuery);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: 220,
            color: const Color(0xFF4C4A3F),
            padding: const EdgeInsets.only(top: 40, left: 20, right: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context); // Back functionality
                  },
                  child: const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.arrow_back, color: Colors.black),
                  ),
                ),
                const SizedBox(width: 20),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 20),
                    Text(
                      "Customer",
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "Details",
                      style: TextStyle(
                        fontSize: 35,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: const Color(0xFF150C3D),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          query = value;
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: 'search by name,address',
                        border: InputBorder.none,
                        icon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: filteredCustomers.isEmpty
                        ? const Center(
                            child: Text(
                              'No customers found',
                              style: TextStyle(color: Colors.white),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredCustomers.length,
                            itemBuilder: (context, index) {
                              final customer = filteredCustomers[index];
                              return CustomerTile(
                                name: customer.name,
                                address: customer.address,
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomerTile extends StatelessWidget {
  final String name;
  final String address;

  const CustomerTile({
    super.key,
    required this.name,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFF4C4A3F),
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(address),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Add navigation or detail logic here
        },
      ),
    );
  }
}
