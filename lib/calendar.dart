import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MaterialApp(home: DateSelectionPage()));
}

class DateSelectionPage extends StatefulWidget {
  const DateSelectionPage({super.key});

  @override
  State<DateSelectionPage> createState() => _DateSelectionPageState();
}

class _DateSelectionPageState extends State<DateSelectionPage> {
  DateTime? startDate;
  DateTime currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  final DateTime today = DateTime.now();

  void _onDateSelected(DateTime selectedDate) {
    if (selectedDate.isAfter(today)) return;

    setState(() {
      startDate = selectedDate; // Only set start date
    });
  }

  void _goToNextMonth() {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1);
    });
  }

  void _goToPreviousMonth() {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month - 1);
    });
  }

  void _resetDates() {
    setState(() {
      startDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final daysInMonth =
        DateUtils.getDaysInMonth(currentMonth.year, currentMonth.month);
    final startWeekday = firstDayOfMonth.weekday % 7;

    List<TableRow> rows = [];
    int totalCells = daysInMonth + startWeekday;
    int weeks = (totalCells / 7).ceil();

    for (int week = 0; week < weeks; week++) {
      List<Widget> row = [];
      for (int day = 0; day < 7; day++) {
        int dayIndex = week * 7 + day;
        int date = dayIndex - startWeekday + 1;

        if (date < 1 || date > daysInMonth) {
          row.add(Container());
        } else {
          DateTime thisDay =
              DateTime(currentMonth.year, currentMonth.month, date);
          bool isStart = startDate != null && _isSameDay(thisDay, startDate!);
          bool isFuture = thisDay.isAfter(today);

          Color bgColor = Colors.transparent;
          Color textColor = isFuture ? Colors.grey : Colors.black;

          if (isStart) {
            bgColor = Colors.green;
            textColor = Colors.white;
          }

          row.add(GestureDetector(
            onTap: isFuture ? null : () => _onDateSelected(thisDay),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: CircleAvatar(
                backgroundColor: bgColor,
                child: Text(
                  "$date",
                  style: TextStyle(
                    color: textColor,
                  ),
                ),
              ),
            ),
          ));
        }
      }
      rows.add(TableRow(children: row));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF160A45),
      body: SafeArea(
        child: GestureDetector(
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity! < 0) {
              _goToNextMonth();
            } else if (details.primaryVelocity! > 0) {
              _goToPreviousMonth();
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                color: const Color(0xFF3D392E),
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.arrow_back, color: Colors.white),
                    SizedBox(height: 10),
                    Text(
                      "Select a date for\nTransaction to be shown",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          const Text("Start Date",
                              style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(startDate != null
                              ? DateFormat("MMM d, yyyy").format(startDate!)
                              : "Select"),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: _goToPreviousMonth,
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Text(
                            DateFormat("MMMM yyyy").format(currentMonth),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            onPressed: _goToNextMonth,
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Table(
                        children: [
                          TableRow(
                            children: [
                              for (var d in ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
                                Center(
                                    child: Text(d,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                            ],
                          ),
                          ...rows,
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: startDate != null
                            ? () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Selected: ${DateFormat("MMM d, yyyy").format(startDate!)}'),
                                  ),
                                );
                              }
                            : null,
                        child: const Text("Continue",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: _resetDates,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
