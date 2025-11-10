import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class RangeSelectionCalendarWidget extends StatefulWidget {
  final DateTime initialStart;
  final DateTime initialEnd;
  final Function(DateTime start, DateTime end) onRangeSelected;

  const RangeSelectionCalendarWidget({
    super.key,
    required this.initialStart,
    required this.initialEnd,
    required this.onRangeSelected,
  });

  @override
  State<RangeSelectionCalendarWidget> createState() => _RangeSelectionCalendarWidgetState();
}

class _RangeSelectionCalendarWidgetState extends State<RangeSelectionCalendarWidget> {
  late DateTime _focusedDay;
  DateTime? _startDay;
  DateTime? _endDay;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOn;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialStart;
    _startDay = widget.initialStart;
    _endDay = widget.initialEnd;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('期間を選択')),
      body: Column(
        children: [
          TableCalendar(
            locale: 'ja_JP',
            firstDay: DateTime(2000, 1, 1),
            lastDay: DateTime(2100, 12, 31),
            focusedDay: _focusedDay,
            rangeStartDay: _startDay,
            rangeEndDay: _endDay,
            rangeSelectionMode: _rangeSelectionMode,
            selectedDayPredicate: (day) {
              if (_startDay != null && _endDay != null) {
                return (day.isAtSameMomentAs(_startDay!) ||
                    day.isAtSameMomentAs(_endDay!) ||
                    (day.isAfter(_startDay!) && day.isBefore(_endDay!)));
              }
              return false;
            },
            onRangeSelected: (start, end, focusedDay) {
              setState(() {
                _startDay = start;
                _endDay = end;
                _focusedDay = focusedDay;
                _rangeSelectionMode = RangeSelectionMode.toggledOn;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            availableCalendarFormats: const {CalendarFormat.month: '月'},
            calendarStyle: CalendarStyle(
              rangeHighlightColor: Colors.blue.withOpacity(0.3),
              rangeStartDecoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              rangeEndDecoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              todayDecoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (_startDay != null && _endDay != null) {
                widget.onRangeSelected(_startDay!, _endDay!);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('期間を選択してください')),
                );
              }
            },
            child: const Text('決定'),
          ),
        ],
      ),
    );
  }
}
