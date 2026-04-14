import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart'; // ADD THIS IMPORT

import '../../models/closing_model.dart';
import '../../services/closing_service.dart';
import 'closing_form_screen.dart';
import '../../widgets/alert_dialog.dart';
import '../../core/theme/app_theme.dart';

class ClosingListScreen extends StatefulWidget {
  const ClosingListScreen({super.key});

  @override
  State<ClosingListScreen> createState() => _ClosingListScreenState();
}

class _ClosingListScreenState extends State<ClosingListScreen> {
  List<ClosingRecord> _records = [];
  List<ClosingRecord> _filteredRecords = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedFilter;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchRecords();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchRecords() async {
    setState(() => _isLoading = true);

    try {
      final records = await ClosingService.fetchRecords();
      setState(() {
        _records = records;
        _applyFilters();
      });
    } catch (e) {
      _showAlert('Error', 'Failed to load records: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    List<ClosingRecord> filtered = _records;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((record) {
        final searchLower = _searchQuery.toLowerCase();
        final alertType = record.alertType?.toLowerCase() ?? '';

        return record.vehicleId.toLowerCase().contains(searchLower) ||
            record.vehicleNumber.toLowerCase().contains(searchLower) ||
            record.remarks.toLowerCase().contains(searchLower) ||
            record.endKm.toString().contains(_searchQuery) ||
            alertType.contains(searchLower) ||
            record.userId.toLowerCase().contains(searchLower);
      }).toList();
    }

    if (_selectedFilter != null) {
      filtered = filtered.where((record) {
        return record.alertType?.toLowerCase() ==
            _selectedFilter!.toLowerCase();
      }).toList();
    }

    setState(() {
      _filteredRecords = filtered;
    });
  }

  void _showAlert(String title, String message, {String type = 'error'}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialogWidget(
        title: title,
        message: message,
        type: type,
        confirmText: 'OK',
      ),
    );
  }

  void _showDeleteConfirmation(ClosingRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialogWidget(
        title: 'Confirm Delete',
        message: 'Are you sure you want to delete this closing record?',
        type: 'confirm',
        confirmText: 'Delete',
        cancelText: 'Cancel',
        onConfirm: () => _deleteRecord(record),
      ),
    );
  }

  Future<void> _deleteRecord(ClosingRecord record) async {
    try {
      final response = await ClosingService.deleteRecord(record.id!);

      if (!mounted) return;

      if (response.status == 'success') {
        _showAlert('Success', 'Record deleted successfully!', type: 'success');
        _fetchRecords();
      } else {
        _showAlert('Error', response.message);
      }
    } catch (e) {
      _showAlert('Error', 'Failed to delete record: $e');
    }
  }

  Color _getAlertTypeColor(String? alertType) {
    if (alertType == null) return const Color(0xFF6B7280);

    switch (alertType.toLowerCase()) {
      case 'risk':
        return const Color(0xFFEF4444);
      case 'priority':
        return const Color(0xFFF59E0B);
      case 'normal':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getAlertTypeIcon(String? alertType) {
    if (alertType == null) return Icons.info;

    switch (alertType.toLowerCase()) {
      case 'risk':
        return Icons.warning;
      case 'priority':
        return Icons.priority_high;
      case 'normal':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  // UPDATED: Enhanced file opening with image/PDF viewing
  Future<void> _openFile(String url) async {
    // Clean the URL
    final cleanedUrl = url.trim();

    // Check file type
    final uri = Uri.parse(cleanedUrl);
    final fileExtension = uri.path.split('.').last.toLowerCase();
    final isImage =
        ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(fileExtension);
    final isPdf = fileExtension == 'pdf';

    if (isImage) {
      // Show image in dialog
      _showImageDialog(cleanedUrl);
    } else if (isPdf) {
      // Show options dialog for PDFs (including the new View in-app option)
      _showPdfOptionsDialog(cleanedUrl);
    } else {
      // For unknown types, try to open in browser
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (!mounted) return;
        _showUrlDialog(cleanedUrl);
      }
    }
  }

  // NEW: Show image in full-screen dialog
  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(0),
        child: Stack(
          children: [
            // Full screen image
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: AppTheme.secondary,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error,
                              color: Colors.white, size: 50),
                          const SizedBox(height: 10),
                          const Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              if (await canLaunchUrl(Uri.parse(imageUrl))) {
                                await launchUrl(
                                  Uri.parse(imageUrl),
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            },
                            child: const Text('Open in Browser'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // Close button
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // Copy URL button
            Positioned(
              top: 20,
              left: 20,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.copy, color: Colors.white, size: 24),
                ),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: imageUrl));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Image URL copied to clipboard'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                },
              ),
            ),

            // Download button
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      // You can add download functionality here
                      _showUrlDialog(imageUrl);
                    },
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Download'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // NEW: Show PDF options dialog
  void _showPdfOptionsDialog(String pdfUrl) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'PDF Options',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // File info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.picture_as_pdf,
                      color: Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PDF Document',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'URL: ${Uri.parse(pdfUrl).path.split('/').last}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Options
              // View in App (using Google Docs Viewer)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.remove_red_eye, color: Colors.blue),
                ),
                title: const Text('View PDF'),
                subtitle: const Text('View directly in the app'),
                onTap: () async {
                  final viewerUrl =
                      'https://docs.google.com/viewer?url=${Uri.encodeComponent(pdfUrl)}&embedded=true';
                  final uri = Uri.parse(viewerUrl);
                  if (await canLaunchUrl(uri)) {
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    await launchUrl(
                      uri,
                      mode: LaunchMode.inAppWebView,
                    );
                  }
                },
              ),

              const Divider(height: 1),

              // Open in Browser
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.open_in_browser,
                      color: Color(0xFF14ADD6)),
                ),
                title: const Text('Open in Browser'),
                subtitle: const Text('Open using default browser'),
                onTap: () async {
                  final uri = Uri.parse(pdfUrl);
                  if (await canLaunchUrl(uri)) {
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
              ),

              const Divider(height: 1),

              // Copy URL
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.copy, color: Color(0xFF10B981)),
                ),
                title: const Text('Copy URL'),
                subtitle: const Text('Copy PDF link to clipboard'),
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: pdfUrl));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PDF URL copied to clipboard'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                  Navigator.pop(context);
                },
              ),

              const Divider(height: 1),

              // Download
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.download, color: Color(0xFFF59E0B)),
                ),
                title: const Text('Download PDF'),
                subtitle: const Text('Save to device storage'),
                onTap: () {
                  Navigator.pop(context);
                  _showUrlDialog(pdfUrl);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // NEW: Show URL dialog for copying
  void _showUrlDialog(String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Open Document'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Document URL:'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  url,
                  style: const TextStyle(fontSize: 12, fontFamily: 'Monospace'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('URL copied to clipboard'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Copy URL'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (await canLaunchUrl(Uri.parse(url))) {
                if (!context.mounted) return;
                await launchUrl(
                  Uri.parse(url),
                  mode: LaunchMode.externalApplication,
                );
                if (!context.mounted) return;
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondary,
            ),
            child: const Text('Open in Browser',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString).toLocal();
      return DateFormat('dd/MM/yy HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatDateOnly(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString).toLocal();
      return DateFormat('dd/MM/yy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildRecordCard(ClosingRecord record, int index) {
    final hasPhotos = record.photos.isNotEmpty;
    final alertType = record.alertType ?? 'N/A';
    final alertColor = _getAlertTypeColor(alertType);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with vehicle info and actions
            Row(
              children: [
                // Vehicle Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.directions_car,
                              size: 14, color: Colors.blue.shade600),
                          const SizedBox(width: 4),
                          Text(
                            record.vehicleNumber,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.confirmation_number,
                              size: 12, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            record.vehicleId,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Alert Type Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: alertColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: alertColor, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getAlertTypeIcon(alertType),
                        size: 14,
                        color: alertColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        alertType,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: alertColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            const Divider(height: 1, color: Colors.grey),
            const SizedBox(height: 10),

            // Details in a compact grid
            Row(
              children: [
                // Left column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailItem(
                        icon: Icons.speed_outlined,
                        label: 'End KM',
                        value: '${record.endKm} km',
                        iconColor: Colors.blue.shade600,
                      ),
                      const SizedBox(height: 8),
                      _buildDetailItem(
                        icon: Icons.person_outline,
                        label: 'User',
                        value: record.userId,
                        iconColor: Colors.purple.shade600,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Right column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailItem(
                        icon: Icons.access_time_outlined,
                        label: 'Time',
                        value: _formatDateTime(record.createdAt),
                        iconColor: Colors.orange.shade600,
                      ),
                      const SizedBox(height: 8),
                      _buildDetailItem(
                        icon: Icons.calendar_today_outlined,
                        label: 'Date',
                        value: _formatDateOnly(record.createdAt),
                        iconColor: Colors.green.shade600,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Photos Section with enhanced viewing options
            if (hasPhotos) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade100, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.photo_library,
                            size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 6),
                        Text(
                          'Attachments (${record.photos.length})',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: record.photos.asMap().entries.map((entry) {
                        final idx = entry.key + 1;
                        final url = entry.value;
                        final isPdf = url.toLowerCase().contains('.pdf');

                        return ElevatedButton.icon(
                          onPressed: () => _openFile(url),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: isPdf
                                ? Colors.red.shade700
                                : Colors.blue.shade700,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: isPdf
                                    ? Colors.red.shade200
                                    : Colors.blue.shade200,
                                width: 1.5,
                              ),
                            ),
                            elevation: 1,
                          ),
                          icon: Icon(
                            isPdf ? Icons.picture_as_pdf : Icons.image,
                            size: 16,
                          ),
                          label: Text(
                            isPdf ? 'View PDF $idx' : 'View Image $idx',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],

            // Remarks Section
            if (record.remarks.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.note, size: 16, color: Colors.grey.shade700),
                        const SizedBox(width: 6),
                        Text(
                          'Remarks',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        if (record.isRemarks) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.verified,
                                    size: 12, color: Colors.green.shade800),
                                const SizedBox(width: 4),
                                Text(
                                  'Verified',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ]
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      record.remarks,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action buttons
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClosingPage(
                          editingRecord: record,
                          onSave: _fetchRecords,
                          onBack: () => Navigator.pop(context),
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.edit, size: 14, color: Colors.blue.shade700),
                  label: Text(
                    'Edit',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: BorderSide(color: Colors.blue.shade300),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _showDeleteConfirmation(record),
                  icon: Icon(Icons.delete_outline,
                      size: 14, color: Colors.red.shade700),
                  label: Text(
                    'Delete',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: BorderSide(color: Colors.red.shade300),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF14ADD6)),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Loading records...',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // HEADER
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.inventory_2_outlined,
                              size: 22, color: Color(0xFF14ADD6)),
                          const SizedBox(width: 8),
                          const Text(
                            'Closing Records',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_filteredRecords.length}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Search Bar
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                            _applyFilters();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search by vehicle, remarks, user...',
                          hintStyle: const TextStyle(fontSize: 13),
                          prefixIcon: const Icon(Icons.search,
                              size: 18, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          isDense: false,
                        ),
                      ),
                    ],
                  ),
                ),

                // FILTER CHIPS
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  width: double.infinity,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Status:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Wrap(
                          spacing: 8,
                          children: [
                          // All filter
                          FilterChip(
                            selected: _selectedFilter == null,
                            label: Text(
                              'All (${_records.length})',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _selectedFilter == null
                                    ? Colors.white
                                    : Colors.grey.shade700,
                              ),
                            ),
                            selectedColor: Colors.blue.shade600,
                            backgroundColor: Colors.grey.shade100,
                            onSelected: (selected) {
                              setState(() {
                                _selectedFilter = null;
                                _applyFilters();
                              });
                            },
                          ),

                          // Normal filter
                          FilterChip(
                            selected: _selectedFilter == 'Normal',
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle,
                                    size: 14,
                                    color: _selectedFilter == 'Normal'
                                        ? Colors.white
                                        : Colors.green),
                                const SizedBox(width: 4),
                                Text(
                                  'Normal (${_records.where((r) => r.alertType?.toLowerCase() == 'normal').length})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedFilter == 'Normal'
                                        ? Colors.white
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                            selectedColor: Colors.green,
                            backgroundColor: Colors.green.shade50,
                            onSelected: (selected) {
                              setState(() {
                                _selectedFilter = selected ? 'Normal' : null;
                                _applyFilters();
                              });
                            },
                          ),

                          // Priority filter
                          FilterChip(
                            selected: _selectedFilter == 'Priority',
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.priority_high,
                                    size: 14,
                                    color: _selectedFilter == 'Priority'
                                        ? Colors.white
                                        : Colors.orange),
                                const SizedBox(width: 4),
                                Text(
                                  'Priority (${_records.where((r) => r.alertType?.toLowerCase() == 'priority').length})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedFilter == 'Priority'
                                        ? Colors.white
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                            selectedColor: Colors.orange,
                            backgroundColor: Colors.orange.shade50,
                            onSelected: (selected) {
                              setState(() {
                                _selectedFilter = selected ? 'Priority' : null;
                                _applyFilters();
                              });
                            },
                          ),

                          // Risk filter
                          FilterChip(
                            selected: _selectedFilter == 'Risk',
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.warning,
                                    size: 14,
                                    color: _selectedFilter == 'Risk'
                                        ? Colors.white
                                        : Colors.red),
                                const SizedBox(width: 4),
                                Text(
                                  'Risk (${_records.where((r) => r.alertType?.toLowerCase() == 'risk').length})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedFilter == 'Risk'
                                        ? Colors.white
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                            selectedColor: Colors.red,
                            backgroundColor: Colors.red.shade50,
                            onSelected: (selected) {
                              setState(() {
                                _selectedFilter = selected ? 'Risk' : null;
                                _applyFilters();
                              });
                            },
                          ),
                        ],
                      ),
                      ],
                    ),
                  ),
                ),

                // Records list
                Expanded(
                  child: _filteredRecords.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inventory_outlined,
                                  size: 60,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty &&
                                          _selectedFilter == null
                                      ? 'No closing records found'
                                      : _searchQuery.isNotEmpty &&
                                              _selectedFilter != null
                                          ? 'No "$_selectedFilter" records found for "$_searchQuery"'
                                          : _searchQuery.isNotEmpty
                                              ? 'No results found for "$_searchQuery"'
                                              : 'No "$_selectedFilter" records found',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _searchQuery.isEmpty &&
                                          _selectedFilter == null
                                      ? 'Tap + to add your first record'
                                      : 'Try different search terms or filters',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                if (_searchQuery.isEmpty &&
                                    _selectedFilter == null) ...[
                                  const SizedBox(height: 20),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ClosingPage(
                                            onSave: _fetchRecords,
                                            onBack: () =>
                                                Navigator.pop(context),
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text('Add Closing Record'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4A4494),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 2,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchRecords,
                          color: AppTheme.secondary,
                          displacement: 40,
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.only(top: 8, bottom: 16),
                            itemCount: _filteredRecords.length,
                            itemBuilder: (context, index) {
                              return _buildRecordCard(
                                _filteredRecords[index],
                                index,
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClosingPage(
                onSave: _fetchRecords,
                onBack: () => Navigator.pop(context),
              ),
            ),
          );
        },
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'Add Closing',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF4A4494),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 4,
      ),
    );
  }
}
