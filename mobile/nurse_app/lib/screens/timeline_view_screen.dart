import 'package:flutter/material.dart';
import '../core/core.dart';
import '../services/api_service.dart';
import '../widgets/timeline_widgets.dart';

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Medical Timeline',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            Text(
              widget.patientName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _loadTimeline,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: AppSpacing.lg),
                  Text(
                    'Loading timeline...',
                    style: AppTypography.bodyRegular,
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xxl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: AppSpacing.iconXLarge + 16,
                          color: AppColors.error,
                        ),
                        SizedBox(height: AppSpacing.lg),
                        const Text(
                          'Failed to load timeline',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: AppSpacing.sm),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        SizedBox(height: AppSpacing.xxl),
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
                          Icon(
                            Icons.timeline_outlined,
                            size: AppSpacing.iconXLarge + 32,
                            color: AppColors.textTertiary,
                          ),
                          SizedBox(height: AppSpacing.lg),
                          Text(
                            'No timeline available',
                            style: TextStyle(
                              fontSize: 18,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: AppSpacing.sm),
                          Text(
                            'Scan documents to generate a timeline',
                            style: TextStyle(color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Timeline Events - AT THE TOP!
                          if (_timeline!['timeline_events'] != null &&
                              (_timeline!['timeline_events'] as List).isNotEmpty)
                            _buildTimelineEvents(_timeline!['timeline_events']),

                          // Summary Card
                          if (_timeline!['summary'] != null)
                            Container(
                              margin: EdgeInsets.all(AppSpacing.lg),
                              padding: EdgeInsets.all(AppSpacing.lg),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.summarize_outlined,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                      SizedBox(width: AppSpacing.sm),
                                      const Text(
                                        'Summary',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2C3E50),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: AppSpacing.md),
                                  Text(
                                    _timeline!['summary'],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.6,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Current Medications
                          if (_timeline!['current_medications'] != null &&
                              (_timeline!['current_medications'] as List).isNotEmpty)
                            _buildSection(
                              icon: Icons.medication_outlined,
                              title: 'Current Medications',
                              color: AppColors.accent,
                              items: _timeline!['current_medications'],
                              builder: (item) => _buildMedicationCard(item),
                            ),

                          // Chronic Conditions
                          if (_timeline!['chronic_conditions'] != null &&
                              (_timeline!['chronic_conditions'] as List).isNotEmpty)
                            _buildSection(
                              icon: Icons.local_hospital_outlined,
                              title: 'Chronic Conditions',
                              color: AppColors.warning,
                              items: _timeline!['chronic_conditions'],
                              builder: (item) => _buildConditionCard(item),
                            ),

                          // Allergies
                          if (_timeline!['allergies'] != null &&
                              (_timeline!['allergies'] as List).isNotEmpty)
                            _buildSection(
                              icon: Icons.warning_outlined,
                              title: 'Allergies',
                              color: AppColors.error,
                              items: _timeline!['allergies'],
                              builder: (item) => _buildAllergyCard(item),
                            ),

                          SizedBox(height: AppSpacing.xxl),
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
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xxl,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.xs + 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              SizedBox(width: AppSpacing.md),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
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
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: items.map((item) => builder(item)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMedicationCard(dynamic item) {
    final dosageInfo = [
      if (item['dosage'] != null) 'Dosage: ${item['dosage']}',
      if (item['frequency'] != null) 'Frequency: ${item['frequency']}',
    ].join(' • ');
    
    return MedicalInfoCard(
      icon: Icons.medication_outlined,
      color: AppColors.accent,
      title: item['name'] ?? 'Unknown medication',
      subtitle: dosageInfo,
    );
  }

  Widget _buildConditionCard(dynamic item) {
    final condition = item is String ? item : (item['condition'] ?? 'Unknown');
    return MedicalInfoCard(
      icon: Icons.local_hospital_outlined,
      color: AppColors.warning,
      title: condition,
      subtitle: '',
    );
  }

  Widget _buildAllergyCard(dynamic item) {
    final allergen = item is String ? item : (item['allergen'] ?? 'Unknown');
    return MedicalInfoCard(
      icon: Icons.warning_outlined,
      color: AppColors.error,
      title: allergen,
      subtitle: '',
    );
  }

  Widget _buildTimelineEvents(List events) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TimelineHeader(eventCount: events.length),
        
        Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: events.length,
            itemBuilder: (context, index) {
              return TimelineEventCard(
                event: events[index],
                index: index,
                isFirst: index == 0,
                isLast: index == events.length - 1,
              );
            },
          ),
        ),
      ],
    );
  }
}
