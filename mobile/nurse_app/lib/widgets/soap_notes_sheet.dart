import 'package:flutter/material.dart';
import '../core/core.dart';

class SoapNotesSheet extends StatelessWidget {
  final List<Map<String, dynamic>> notes;

  const SoapNotesSheet({
    super.key,
    required this.notes,
  });

  static void show(BuildContext context, List<Map<String, dynamic>> notes) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SoapNotesSheet(notes: notes),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.note_alt_outlined,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SOAP Notes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        Text(
                          '${notes.length} note${notes.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: AppColors.primary.withOpacity(0.1)),
            // Notes list
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: EdgeInsets.all(AppSpacing.lg),
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final note = notes[index];
                  final soapNote = note['soap_note'] ?? {};
                  
                  return Container(
                    margin: EdgeInsets.only(bottom: AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Note header
                        Container(
                          padding: EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Note ${index + 1}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                note['created_at']?.toString().substring(0, 10) ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Chief Complaint
                              if (soapNote['chief_complaint'] != null && 
                                  soapNote['chief_complaint'].toString().isNotEmpty)
                                _SoapSection(
                                  icon: Icons.medical_services_outlined,
                                  iconColor: AppColors.error,
                                  label: 'Chief Complaint',
                                  content: soapNote['chief_complaint'],
                                ),
                              
                              // Subjective
                              if (soapNote['subjective'] != null && 
                                  soapNote['subjective'].toString().isNotEmpty)
                                _SoapSection(
                                  icon: Icons.person_outline,
                                  iconColor: AppColors.primary,
                                  label: 'Subjective (S)',
                                  content: soapNote['subjective'],
                                ),
                              
                              // Objective
                              if (soapNote['objective'] != null && 
                                  soapNote['objective'].toString().isNotEmpty)
                                _SoapSection(
                                  icon: Icons.science_outlined,
                                  iconColor: AppColors.info,
                                  label: 'Objective (O)',
                                  content: soapNote['objective'],
                                ),
                              
                              // Assessment
                              if (soapNote['assessment'] != null && 
                                  soapNote['assessment'].toString().isNotEmpty)
                                _SoapSection(
                                  icon: Icons.analytics_outlined,
                                  iconColor: AppColors.warning,
                                  label: 'Assessment (A)',
                                  content: soapNote['assessment'],
                                ),
                              
                              // Plan
                              if (soapNote['plan'] != null && 
                                  soapNote['plan'].toString().isNotEmpty)
                                _SoapSection(
                                  icon: Icons.checklist_outlined,
                                  iconColor: AppColors.success,
                                  label: 'Plan (P)',
                                  content: soapNote['plan'],
                                  isLast: true,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoapSection extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String content;
  final bool isLast;

  const _SoapSection({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.content,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Color(0xFF2C3E50),
            ),
          ),
        ],
      ),
    );
  }
}
