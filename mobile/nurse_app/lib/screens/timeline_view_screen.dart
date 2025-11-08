import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TimelineViewScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const TimelineViewScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<TimelineViewScreen> createState() => _TimelineViewScreenState();
}

class _TimelineViewScreenState extends State<TimelineViewScreen> {
  Map<String, dynamic>? _timeline;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTimeline();
    print('📊 [TimelineView] Initialized for ${widget.patientId}');
  }

  Future<void> _loadTimeline() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('📥 [TimelineView] Fetching timeline...');
      
      final response = await ApiService.getPatientTimeline(widget.patientId);
      
      // Extract the nested timeline object
      final timelineData = response['timeline'] as Map<String, dynamic>?;
      
      print('📊 [TimelineView] Response keys: ${response.keys.toList()}');
      if (timelineData != null) {
        print('📊 [TimelineView] Timeline keys: ${timelineData.keys.toList()}');
        print('📊 [TimelineView] Events count: ${(timelineData['timeline_events'] as List?)?.length ?? 0}');
      }
      
      setState(() {
        _timeline = timelineData;
        _isLoading = false;
      });
      
      print('✅ [TimelineView] Timeline loaded successfully');
    } catch (e) {
      print('❌ [TimelineView] Failed to load timeline: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Medical Timeline'),
            Text(
              widget.patientName,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTimeline,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading timeline...'),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text(
                          'Failed to load timeline',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadTimeline,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _timeline == null || _timeline!.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.timeline_outlined,
                              size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No timeline available',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Scan documents to generate a timeline',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Summary Card
                          if (_timeline!['summary'] != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                border: Border(
                                  bottom: BorderSide(color: Colors.blue[200]!),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.summarize, color: Colors.blue[700]),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Summary',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue[900],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _timeline!['summary'],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Current Medications
                          if (_timeline!['current_medications'] != null &&
                              (_timeline!['current_medications'] as List).isNotEmpty)
                            _buildSection(
                              icon: Icons.medication,
                              title: 'Current Medications',
                              color: Colors.purple,
                              items: _timeline!['current_medications'],
                              builder: (item) => ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.purple[100],
                                  child: Icon(Icons.medication, color: Colors.purple),
                                ),
                                title: Text(
                                  item['name'] ?? 'Unknown medication',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (item['dosage'] != null)
                                      Text('Dosage: ${item['dosage']}'),
                                    if (item['frequency'] != null)
                                      Text('Frequency: ${item['frequency']}'),
                                  ],
                                ),
                              ),
                            ),

                          // Chronic Conditions
                          if (_timeline!['chronic_conditions'] != null &&
                              (_timeline!['chronic_conditions'] as List).isNotEmpty)
                            _buildSection(
                              icon: Icons.local_hospital,
                              title: 'Chronic Conditions',
                              color: Colors.orange,
                              items: _timeline!['chronic_conditions'],
                              builder: (item) => ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.orange[100],
                                  child: Icon(Icons.local_hospital, color: Colors.orange),
                                ),
                                title: Text(
                                  item is String ? item : (item['condition'] ?? 'Unknown'),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),

                          // Allergies
                          if (_timeline!['allergies'] != null &&
                              (_timeline!['allergies'] as List).isNotEmpty)
                            _buildSection(
                              icon: Icons.warning,
                              title: 'Allergies',
                              color: Colors.red,
                              items: _timeline!['allergies'],
                              builder: (item) => ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.red[100],
                                  child: Icon(Icons.warning, color: Colors.red),
                                ),
                                title: Text(
                                  item is String ? item : (item['allergen'] ?? 'Unknown'),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),

                          // Timeline Events
                          if (_timeline!['timeline_events'] != null &&
                              (_timeline!['timeline_events'] as List).isNotEmpty)
                            _buildTimelineEvents(_timeline!['timeline_events']),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Color color,
    required List items,
    required Widget Function(dynamic) builder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${items.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...items.map((item) => Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: builder(item),
            )),
      ],
    );
  }

  Widget _buildTimelineEvents(List events) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            children: [
              const Icon(Icons.timeline, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Timeline Events',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${events.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline line
                    SizedBox(
                      width: 40,
                      child: Column(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                          if (index < events.length - 1)
                            Expanded(
                              child: Container(
                                width: 2,
                                color: Colors.blue[200],
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Event card
                    Expanded(
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 16, left: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (event['date'] != null)
                                Text(
                                  event['date'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                event['description'] ?? 'No description',
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                              if (event['medications'] != null &&
                                  (event['medications'] as List).isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: (event['medications'] as List)
                                      .map((med) => Chip(
                                            label: Text(
                                              med is String ? med : med['name'] ?? '',
                                              style: const TextStyle(fontSize: 10),
                                            ),
                                            backgroundColor: Colors.purple[50],
                                            padding: EdgeInsets.zero,
                                            materialTapTargetSize:
                                                MaterialTapTargetSize.shrinkWrap,
                                          ))
                                      .toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
