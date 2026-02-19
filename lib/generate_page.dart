import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class GeneratePage extends StatefulWidget {
  const GeneratePage({super.key});

  @override
  State<GeneratePage> createState() => _GeneratePageState();
}

class _GeneratePageState extends State<GeneratePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _textController = TextEditingController();
  
  // Event Controllers
  final TextEditingController _eventTitleController = TextEditingController();
  final TextEditingController _eventLocationController = TextEditingController();
  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now().add(const Duration(hours: 1));

  String _dataToGenerate = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    _eventTitleController.dispose();
    _eventLocationController.dispose();
    super.dispose();
  }

  void _generate() {
    setState(() {
      if (_tabController.index == 0) {
        _dataToGenerate = _textController.text;
      } else {
        _dataToGenerate = _generateEventData();
      }
    });
  }

  String _generateEventData() {
    // Basic vCalendar/vEvent format
    // BEGIN:VEVENT
    // SUMMARY:Title
    // LOCATION:Location
    // DTSTART:20230101T120000
    // DTEND:20230101T130000
    // END:VEVENT
    
    final start = _formatDateTime(_startTime);
    final end = _formatDateTime(_endTime);
    
    return 'BEGIN:VEVENT\n'
           'SUMMARY:${_eventTitleController.text}\n'
           'LOCATION:${_eventLocationController.text}\n'
           'DTSTART:$start\n'
           'DTEND:$end\n'
           'END:VEVENT';
  }

  String _formatDateTime(DateTime dt) {
    // YYYYMMDDTHHMMSS
    return "${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}T"
           "${dt.hour.toString().padLeft(2, '0')}${dt.minute.toString().padLeft(2, '0')}00";
  }

  Future<void> _selectDateTime(bool isStart) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isStart ? _startTime : _endTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && mounted) {
        final TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(isStart ? _startTime : _endTime),
        );
        
        if (pickedTime != null) {
          setState(() {
            final newDateTime = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            );
            if (isStart) {
              _startTime = newDateTime;
            } else {
              _endTime = newDateTime;
            }
          });
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate QR Code'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Text/URL'),
            Tab(text: 'Event'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              height: 300, // Fixed height for inputs area
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Text/URL Tab
                  TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      labelText: 'Enter text or URL',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  // Event Tab
                  Column(
                    children: [
                      TextField(
                        controller: _eventTitleController,
                        decoration: const InputDecoration(labelText: 'Event Title'),
                      ),
                      TextField(
                        controller: _eventLocationController,
                        decoration: const InputDecoration(labelText: 'Location'),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => _selectDateTime(true),
                              child: Text('Start: ${_startTime.toString().split('.')[0]}'),
                            ),
                          ),
                          Expanded(
                            child: TextButton(
                              onPressed: () => _selectDateTime(false),
                              child: Text('End: ${_endTime.toString().split('.')[0]}'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _generate,
              child: const Text('Generate QR'),
            ),
            const SizedBox(height: 20),
            if (_dataToGenerate.isNotEmpty)
              Center(
                child: QrImageView(
                  data: _dataToGenerate,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
