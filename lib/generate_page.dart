
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'services/history_service.dart';

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

    if (_dataToGenerate.isNotEmpty) {
      // Save to History
      final item = HistoryItem(
        data: _dataToGenerate,
        timestamp: DateTime.now(),
        type: HistoryType.generate,
      );
      HistoryService.addHistoryItem(item);
    }
  }

  String _generateEventData() {
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
        title: const Text('Generate Code'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.deepPurple,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.deepPurple,
          tabs: const [
            Tab(text: 'Text/URL'),
            Tab(text: 'Event Ticket'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            SizedBox(
              height: 350, 
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Text/URL Tab
                  _buildInputCard(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        labelText: 'Enter text or URL',
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.text_fields),
                      ),
                      maxLines: 3,
                    ),
                  ),
                  // Event Tab
                  _buildInputCard(
                    child: Column(
                      children: [
                        TextField(
                          controller: _eventTitleController,
                          decoration: const InputDecoration(
                            labelText: 'Event Title', 
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.event),
                          ),
                        ),
                        const Divider(),
                        TextField(
                          controller: _eventLocationController,
                          decoration: const InputDecoration(
                            labelText: 'Location',
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.location_on),
                          ),
                        ),
                        const Divider(),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton.icon(
                                icon: const Icon(Icons.access_time),
                                onPressed: () => _selectDateTime(true),
                                label: Text('Start: ${_startTime.hour}:${_startTime.minute}'),
                              ),
                            ),
                            Expanded(
                              child: TextButton.icon(
                                icon: const Icon(Icons.access_time_filled),
                                onPressed: () => _selectDateTime(false),
                                label: Text('End: ${_endTime.hour}:${_endTime.minute}'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _generate,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
              child: const Text('Generate Ticket', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 30),
            if (_dataToGenerate.isNotEmpty)
              _buildTicketWidget(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInputCard({required Widget child}) {
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
            ],
            border: Border.all(color: Colors.grey.shade200),
        ),
        child: child,
    );
  }

  Widget _buildTicketWidget() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.confirmation_number, color: Colors.deepPurple.shade300),
              Text(
                'OFFICIAL TICKET',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  fontSize: 12,
                ),
              ),
              Icon(Icons.confirmation_number, color: Colors.deepPurple.shade300),
            ],
          ),
          const SizedBox(height: 20),
          QrImageView(
            data: _dataToGenerate,
            version: QrVersions.auto,
            size: 200.0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.deepPurple.shade900,
          ),
          const SizedBox(height: 24),
          Row(
            children: List.generate(30, (index) => Expanded(
              child: Container(
                color: index % 2 == 0 ? Colors.transparent : Colors.grey[300],
                height: 2,
              ),
            )),
          ),
          const SizedBox(height: 24),
          Text(
            _tabController.index == 1 
                ? _eventTitleController.text.isNotEmpty ? _eventTitleController.text : 'Event Ticket' 
                : 'QR Token',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          if (_tabController.index == 1) ...[
            const SizedBox(height: 8),
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      _eventLocationController.text,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                ],
            ),
            const SizedBox(height: 12),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_startTime.hour}:${_startTime.minute} - ${_endTime.hour}:${_endTime.minute}',
                  style: TextStyle(color: Colors.deepPurple[700], fontWeight: FontWeight.bold, fontSize: 12),
                ),
            ),
          ],
        ],
      ),
    );
  }
}
