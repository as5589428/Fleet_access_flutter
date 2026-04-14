import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final String? type;

  const StatusBadge({
    super.key,
    required this.status,
    this.type,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status, type);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config['backgroundColor'],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: config['borderColor'], width: 1),
      ),
      child: Text(
        config['label'],
        style: TextStyle(
          color: config['textColor'],
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusConfig(String status, String? type) {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return {
          'label': 'Open',
          'backgroundColor': AppTheme.success.withValues(alpha: 0.1),
          'borderColor': AppTheme.success,
          'textColor': AppTheme.success,
        };
      case 'BOOKED':
      case 'IN_PROGRESS':
        return {
          'label': status == 'BOOKED' ? 'Booked' : 'In Progress',
          'backgroundColor': Colors.grey.withValues(alpha: 0.1),
          'borderColor': Colors.grey,
          'textColor': Colors.grey[700],
        };
      case 'COMPLETED':
        return {
          'label': 'Completed',
          'backgroundColor': AppTheme.success.withValues(alpha: 0.1),
          'borderColor': AppTheme.success,
          'textColor': AppTheme.success,
        };
      case 'CANCELLED':
        return {
          'label': 'Cancelled',
          'backgroundColor': AppTheme.danger.withValues(alpha: 0.1),
          'borderColor': AppTheme.danger,
          'textColor': AppTheme.danger,
        };
      case 'MAINTENANCE':
        return {
          'label': 'Maintenance',
          'backgroundColor': AppTheme.warning.withValues(alpha: 0.1),
          'borderColor': AppTheme.warning,
          'textColor': AppTheme.warning,
        };
      case 'ACTIVE':
        return {
          'label': 'Active',
          'backgroundColor': AppTheme.success.withValues(alpha: 0.1),
          'borderColor': AppTheme.success,
          'textColor': AppTheme.success,
        };
      case 'INACTIVE':
        return {
          'label': 'Inactive',
          'backgroundColor': Colors.grey.withValues(alpha: 0.1),
          'borderColor': Colors.grey,
          'textColor': Colors.grey[700],
        };
      case 'PRIORITY':
        return {
          'label': 'Priority',
          'backgroundColor': AppTheme.warning.withValues(alpha: 0.1),
          'borderColor': AppTheme.warning,
          'textColor': AppTheme.warning,
        };
      case 'RISK':
        return {
          'label': 'Risk',
          'backgroundColor': AppTheme.danger.withValues(alpha: 0.1),
          'borderColor': AppTheme.danger,
          'textColor': AppTheme.danger,
        };
      case 'NORMAL':
        return {
          'label': 'Normal',
          'backgroundColor': AppTheme.primary.withValues(alpha: 0.1),
          'borderColor': AppTheme.primary,
          'textColor': AppTheme.primary,
        };
      case 'CLOSED':
        return {
          'label': 'Closed',
          'backgroundColor': Colors.grey.withValues(alpha: 0.1),
          'borderColor': Colors.grey,
          'textColor': Colors.grey[700],
        };
      default:
        return {
          'label': status,
          'backgroundColor': Colors.grey.withValues(alpha: 0.1),
          'borderColor': Colors.grey,
          'textColor': Colors.grey[700],
        };
    }
  }
}
