import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DueDatePicker extends StatefulWidget {
  final DateTime? initialDate;
  final Function(DateTime?) onDateSelected;

  const DueDatePicker({
    super.key,
    this.initialDate,
    required this.onDateSelected,
  });

  @override
  _DueDatePickerState createState() => _DueDatePickerState();
}

class _DueDatePickerState extends State<DueDatePicker> {
  DateTime? _selectedDate;
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    if (_selectedDate != null) {
      _selectedTime = TimeOfDay.fromDateTime(_selectedDate!);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color.fromARGB(255, 10, 220, 181),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _combineDateTime();
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color.fromARGB(255, 10, 220, 181),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
      _combineDateTime();
    }
  }

  void _combineDateTime() {
    if (_selectedDate != null) {
      final DateTime combinedDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      widget.onDateSelected(combinedDateTime);
    }
  }

  void _clearDate() {
    setState(() {
      _selectedDate = null;
    });
    widget.onDateSelected(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Срок выполнения:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _selectDate(context),
                style: OutlinedButton.styleFrom(
                  backgroundColor: _selectedDate != null
                      ? const Color.fromARGB(255, 10, 220, 181).withOpacity(0.1)
                      : null,
                ),
                child: Text(
                  _selectedDate != null
                      ? DateFormat('dd.MM.yyyy').format(_selectedDate!)
                      : 'Выберите дату',
                  style: TextStyle(
                    color: _selectedDate != null
                        ? const Color.fromARGB(255, 10, 220, 181)
                        : Colors.grey,
                  ),
                ),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: _selectedDate != null
                    ? () => _selectTime(context)
                    : null,
                style: OutlinedButton.styleFrom(
                  backgroundColor: _selectedDate != null
                      ? const Color.fromARGB(255, 10, 220, 181).withOpacity(0.1)
                      : null,
                ),
                child: Text(
                  _selectedDate != null
                      ? _selectedTime.format(context)
                      : 'Выберите время',
                  style: TextStyle(
                    color: _selectedDate != null
                        ? const Color.fromARGB(255, 10, 220, 181)
                        : Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_selectedDate != null)
          TextButton(
            onPressed: _clearDate,
            child: Text(
              'Очистить срок',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
        SizedBox(height: 16),
      ],
    );
  }
}