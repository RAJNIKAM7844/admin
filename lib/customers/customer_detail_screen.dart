import 'package:flutter/material.dart';

class CustomerDetailScreen extends StatelessWidget {
  final String name;
  final String number;
  final String area;
  final String profileImageUrl;
  final String shopImageUrl;

  const CustomerDetailScreen({
    super.key,
    required this.name,
    required this.number,
    required this.area,
    required this.profileImageUrl,
    required this.shopImageUrl,
  });

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: InteractiveViewer(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(imageUrl),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Background gradient full height fix + colors from your palette
      body: Container(
        height: double.infinity, // <-- Full height to cover screen
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1A0841), // deep purple/dark navy
              Color(0xFF3B322C), // dark brown/coffee
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top bar
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Customer Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Profile & Shop Images with white border & subtle shadow
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () => _showImageDialog(context, profileImageUrl),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.7),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                          border: Border.all(color: Colors.white70, width: 3),
                        ),
                        child: CircleAvatar(
                          radius: 55,
                          backgroundImage: NetworkImage(profileImageUrl),
                          backgroundColor: Colors.grey.shade300,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showImageDialog(context, shopImageUrl),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.7),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                          border: Border.all(color: Colors.white70, width: 3),
                        ),
                        child: CircleAvatar(
                          radius: 55,
                          backgroundImage: NetworkImage(shopImageUrl),
                          backgroundColor: Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),

                // Info cards with dark background and light text
                _infoCard(
                  icon: Icons.person_outline,
                  label: 'Name',
                  value: name,
                  cardColor: const Color(0xFF3B322C),
                  textColor: Colors.white,
                  iconColor: Colors.white70,
                ),
                const SizedBox(height: 20),
                _infoCard(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: number,
                  cardColor: const Color(0xFF3B322C),
                  textColor: Colors.white,
                  iconColor: Colors.white70,
                ),
                const SizedBox(height: 20),
                _infoCard(
                  icon: Icons.location_on_outlined,
                  label: 'Area',
                  value: area,
                  cardColor: const Color(0xFF3B322C),
                  textColor: Colors.white,
                  iconColor: Colors.white70,
                ),
                const SizedBox(height: 40),

                // Button with matching gradient from your theme
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Implement transaction navigation
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 6,
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF5A4634), // softer brown tone
                            Color(0xFF3B322C), // your dark brown
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        constraints:
                            const BoxConstraints(minHeight: 50, maxWidth: 300),
                        child: const Text(
                          'Transaction',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color cardColor,
    required Color textColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 16),
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
