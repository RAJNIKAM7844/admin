import 'package:admin_eggs/drivers/collection_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class CalendarSelectionScreen extends StatefulWidget {
  final int driverId;
  final String driverName;

  const CalendarSelectionScreen({
    super.key,
    required this.driverId,
    required this.driverName,
  });

  @override
  State<CalendarSelectionScreen> createState() =>
      _CalendarSelectionScreenState();
}

class _CalendarSelectionScreenState extends State<CalendarSelectionScreen> {
  final supabase = Supabase.instance.client;
  DateTime? _selectedDate;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  int _selectedTabIndex = 0; // 0: Collection by Date, 1: Today Collection
  double todayCreditTotal = 0.0;
  double todayPaidTotal = 0.0;
  List<Map<String, dynamic>> todayTransactions = [];
  bool isLoading = false;
  Map<String, String> userIdToName = {};

  @override
  void initState() {
    super.initState();
    if (_selectedTabIndex == 1) {
      fetchTodayCollections();
    }
    setupRealtimeSubscription();
  }

  Future<void> fetchTodayCollections() async {
    setState(() {
      isLoading = true;
    });
    try {
      final driverResponse = await supabase
          .from('drivers')
          .select('area_id')
          .eq('id', widget.driverId)
          .limit(1)
          .maybeSingle();

      if (driverResponse == null || driverResponse['area_id'] == null) {
        throw Exception('No area assigned to driver ID ${widget.driverId}');
      }
      final areaId = driverResponse['area_id'];

      final areaResponse = await supabase
          .from('delivery_areas')
          .select('area_name')
          .eq('id', areaId)
          .limit(1)
          .maybeSingle();

      if (areaResponse == null || areaResponse['area_name'] == null) {
        throw Exception('Area not found for area ID $areaId');
      }
      final areaName = areaResponse['area_name'];

      final usersResponse = await supabase
          .from('users')
          .select('id, full_name')
          .eq('location', areaName)
          .eq('role', 'customer'); // Added role filter

      final users = List<Map<String, dynamic>>.from(usersResponse);
      userIdToName.clear();
      for (var user in users) {
        userIdToName[user['id'].toString()] = user['full_name'];
      }

      final today = DateTime.now();
      final startDate = DateTime(today.year, today.month, today.day);
      final endDate = DateTime(today.year, today.month, today.day, 23, 59, 59);

      final transactionsResponse = await supabase
          .from('transactions')
          .select('user_id, credit, paid, date, mode_of_payment')
          .eq('driver_id', widget.driverId)
          .gte('date', startDate.toIso8601String())
          .lte('date', endDate.toIso8601String());

      double tempCreditTotal = 0.0;
      double tempPaidTotal = 0.0;
      List<Map<String, dynamic>> tempTransactions = [];

      for (var transaction in transactionsResponse) {
        final userId = transaction['user_id'].toString();
        if (!userIdToName.containsKey(userId)) {
          continue;
        }
        final credit = (transaction['credit'] as num?)?.toDouble() ?? 0.0;
        final paid = (transaction['paid'] as num?)?.toDouble() ?? 0.0;
        tempCreditTotal += credit;
        tempPaidTotal += paid;
        tempTransactions.add({
          'user_name': userIdToName[userId] ?? 'Customer $userId',
          'credit': credit,
          'paid': paid,
          'date': transaction['date'] != null
              ? DateTime.parse(transaction['date']).toLocal()
              : DateTime.now(),
          'mode_of_payment':
              transaction['mode_of_payment']?.toString() ?? 'N/A',
        });
      }

      setState(() {
        todayCreditTotal = tempCreditTotal;
        todayPaidTotal = tempPaidTotal;
        todayTransactions = tempTransactions;
        isLoading = false;
      });
    } catch (e, stackTrace) {
      print('Error fetching collections: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        todayCreditTotal = 0.0;
        todayPaidTotal = 0.0;
        todayTransactions = [];
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load today\'s collections: $e')),
      );
    }
  }

  void setupRealtimeSubscription() {
    supabase
        .channel('driver_${widget.driverId}_today_collections')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'transactions',
          callback: (payload) {
            if (_selectedTabIndex == 1) {
              fetchTodayCollections();
            }
          },
        )
        .subscribe();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDate = selectedDay;
      _focusedDay = focusedDay;
    });
  }

  void _onTabChanged(int index) {
    setState(() {
      _selectedTabIndex = index;
      if (index == 1) {
        fetchTodayCollections();
        _selectedDate = null;
      }
    });
  }

  @override
  void dispose() {
    supabase
        .channel('driver_${widget.driverId}_today_collections')
        .unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 24),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${widget.driverName}\'s Collections',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Tab Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: _buildTabButton(
                        text: 'Collection by Date',
                        isSelected: _selectedTabIndex == 0,
                        onTap: () => _onTabChanged(0),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTabButton(
                        text: 'Today Collection',
                        isSelected: _selectedTabIndex == 1,
                        onTap: () => _onTabChanged(1),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Content Based on Selected Tab
              Expanded(
                child: _selectedTabIndex == 0
                    ? Column(
                        children: [
                          // Date Display
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              _selectedDate == null
                                  ? 'Select a Date'
                                  : 'Selected: ${DateFormat('d MMMM yyyy').format(_selectedDate!)}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Calendar
                          Expanded(
                            child: Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TableCalendar(
                                firstDay: DateTime(2020),
                                lastDay: DateTime(2030),
                                focusedDay: _focusedDay,
                                calendarFormat: _calendarFormat,
                                selectedDayPredicate: (day) =>
                                    isSameDay(_selectedDate, day),
                                onDaySelected: _onDaySelected,
                                enabledDayPredicate: (day) =>
                                    !day.isAfter(DateTime.now()),
                                calendarStyle: CalendarStyle(
                                  todayDecoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.7),
                                    shape: BoxShape.circle,
                                  ),
                                  selectedDecoration: const BoxDecoration(
                                    color: Color(0xFFE91E63),
                                    shape: BoxShape.circle,
                                  ),
                                  defaultTextStyle:
                                      const TextStyle(color: Colors.black87),
                                  weekendTextStyle:
                                      const TextStyle(color: Colors.black87),
                                  outsideTextStyle:
                                      TextStyle(color: Colors.grey.shade500),
                                ),
                                headerStyle: const HeaderStyle(
                                  formatButtonVisible: false,
                                  titleCentered: true,
                                  titleTextStyle: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  leftChevronIcon: Icon(Icons.chevron_left,
                                      color: Colors.black87, size: 24),
                                  rightChevronIcon: Icon(Icons.chevron_right,
                                      color: Colors.black87, size: 24),
                                ),
                                onPageChanged: (focusedDay) {
                                  _focusedDay = focusedDay;
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Continue Button
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _selectedDate == null
                                    ? null
                                    : () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                CollectionDetailsScreen(
                                              driverId: widget.driverId,
                                              driverName: widget.driverName,
                                              dateRange: DateTimeRange(
                                                start: _selectedDate!,
                                                end: _selectedDate!,
                                              ),
                                              isTodayCollection: false,
                                            ),
                                          ),
                                        );
                                      },
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  disabledBackgroundColor: Colors.transparent,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF4CAF50),
                                        Color(0xFF2E7D32)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.2)),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Continue',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      )
                    : RefreshIndicator(
                        onRefresh: fetchTodayCollections,
                        color: Colors.white,
                        backgroundColor: const Color(0xFFE91E63),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Today\'s Collection',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Date: ${DateFormat('d MMMM yyyy').format(DateTime.now())}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black.withOpacity(0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Total Credit:',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  Colors.black.withOpacity(0.8),
                                            ),
                                          ),
                                          Text(
                                            '₹${todayCreditTotal.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Total Paid:',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  Colors.black.withOpacity(0.8),
                                            ),
                                          ),
                                          Text(
                                            '₹${todayPaidTotal.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Transaction Details',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                isLoading
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : todayTransactions.isEmpty
                                        ? Center(
                                            child: Text(
                                              'No transactions found for today.',
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.7),
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          )
                                        : ListView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            itemCount: todayTransactions.length,
                                            itemBuilder: (context, index) {
                                              final transaction =
                                                  todayTransactions[index];
                                              return Card(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 6),
                                                elevation: 3,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: ListTile(
                                                  contentPadding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 16,
                                                          vertical: 8),
                                                  leading: Container(
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                          color: Colors.black54,
                                                          width: 1.5),
                                                    ),
                                                    child: CircleAvatar(
                                                      radius: 18,
                                                      backgroundColor:
                                                          Colors.grey.shade200,
                                                      child: Icon(Icons.person,
                                                          color: Colors.black54,
                                                          size: 18),
                                                    ),
                                                  ),
                                                  title: Text(
                                                    transaction['user_name'],
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 15,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  subtitle: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      const SizedBox(height: 6),
                                                      Text(
                                                        'Credit: ₹${transaction['credit'].toStringAsFixed(2)}',
                                                        style: const TextStyle(
                                                            fontSize: 13,
                                                            color: Colors.red),
                                                      ),
                                                      Text(
                                                        'Paid: ₹${transaction['paid'].toStringAsFixed(2)}',
                                                        style: const TextStyle(
                                                            fontSize: 13,
                                                            color:
                                                                Colors.green),
                                                      ),
                                                      Text(
                                                        'Mode: ${transaction['mode_of_payment']}',
                                                        style: TextStyle(
                                                            fontSize: 13,
                                                            color: Colors.black
                                                                .withOpacity(
                                                                    0.6)),
                                                      ),
                                                      Text(
                                                        'Time: ${DateFormat('h:mm a').format(transaction['date'])}',
                                                        style: TextStyle(
                                                            fontSize: 13,
                                                            color: Colors.black
                                                                .withOpacity(
                                                                    0.6)),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.1)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.white.withOpacity(0.3)
                : Colors.white.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? Colors.white.withOpacity(0.2)
                  : Colors.black.withOpacity(0.1),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: AnimatedScale(
          scale: isSelected ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Center(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected
                    ? Colors.white.withOpacity(0.9)
                    : Colors.white.withOpacity(0.7),
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}

extension DateTimeExtension on DateTime {
  String get monthName {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }
}
