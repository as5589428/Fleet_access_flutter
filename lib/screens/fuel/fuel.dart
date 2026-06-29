import 'package:fleet_management/models/fuel_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/fuel_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import 'package:intl/intl.dart';
import 'add_fuel_dialog.dart';
import 'package:flutter/services.dart';

class FuelScreen extends StatefulWidget {
  const FuelScreen({super.key});

  @override
  State<FuelScreen> createState() => _FuelScreenState();
}

class _FuelScreenState extends State<FuelScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<FuelEntry> _filteredEntries = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FuelProvider>().loadFuelEntries();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterEntries(String query, List<FuelEntry> entries) {
    setState(() {
      if (query.isEmpty) {
        _filteredEntries = entries;
      } else {
        _filteredEntries = entries
            .where((entry) =>
                entry.vehicleNumber
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                (entry.remarks?.toLowerCase().contains(query.toLowerCase()) ??
                    false))
            .toList();
      }
    });
  }

  void _showAddFuelDialog({FuelEntry? entry}) {
    showDialog(
      context: context,
      builder: (context) => AddFuelDialog(initialData: entry),
    ).then((success) {
      if (success == true && mounted) {
        context.read<FuelProvider>().loadFuelEntries();
      }
    });
  }

  void _handleDeleteEntry(String id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this fuel entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final provider = context.read<FuelProvider>();
              final success = await provider.deleteFuelEntry(id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fuel entry deleted successfully!'),
                    backgroundColor: AppTheme.success,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.danger,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Function to handle bill URL viewing with multiple options
  Future<void> _viewBill(String? billUrl) async {
    if (billUrl == null || billUrl.isEmpty || billUrl == "undefined") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No bill available for this entry'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    // Your Render backend base URL
    final baseUrl = AppConstants.rootUrl;
    String fullUrl;

    // Clean the URL
    final cleanedUrl = billUrl.trim().replaceAll('"', '');

    // Debug print
    debugPrint('DEBUG - Original billUrl: "$billUrl"');
    debugPrint('DEBUG - Cleaned billUrl: "$cleanedUrl"');

    // Handle different URL patterns
    if (cleanedUrl.startsWith('http')) {
      fullUrl = cleanedUrl;
    } else if (cleanedUrl.startsWith('/')) {
      fullUrl = '$baseUrl$cleanedUrl';
    } else if (cleanedUrl.contains('storage/')) {
      // If it contains storage/, make sure it starts with /
      if (cleanedUrl.startsWith('storage/')) {
        fullUrl = '$baseUrl/$cleanedUrl';
      } else {
        fullUrl = '$baseUrl/$cleanedUrl';
      }
    } else {
      // Default case - assume it's a relative path
      fullUrl = '$baseUrl/$cleanedUrl';
    }

    // Remove any double slashes (but preserve http://)
    fullUrl = fullUrl.replaceAll(':/', '://').replaceAll(':///', '://');

    debugPrint('DEBUG - Final URL: $fullUrl');

    try {
      final uri = Uri.parse(fullUrl);

      // Check if it's an image
      final fileExtension = uri.path.split('.').last.toLowerCase();
      final isImage =
          ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(fileExtension);

      if (isImage) {
        // Show image in dialog
        _showImageDialog(fullUrl);
      } else {
        // For non-images, try to open in browser
        if (await canLaunchUrl(uri)) {
          if (!mounted) return;
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
            webViewConfiguration: const WebViewConfiguration(
              enableJavaScript: true,
            ),
          );
        } else {
          if (!mounted) return;
          _showUrlDialog(fullUrl);
        }
      }
    } catch (e) {
      debugPrint('Error opening URL: $e');

      // Fallback: Try alternative URL construction
      final fallbackUrl = '$baseUrl/storage/$cleanedUrl';
      try {
        if (await canLaunchUrl(Uri.parse(fallbackUrl))) {
          if (!mounted) return;
          await launchUrl(
            Uri.parse(fallbackUrl),
            mode: LaunchMode.externalApplication,
          );
        } else {
          if (!mounted) return;
          _showUrlDialog(fullUrl);
        }
      } catch (e2) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot open bill. URL: $fullUrl'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  // Image dialog function
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
                        color: AppTheme.primary,
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
                      backgroundColor: AppTheme.success,
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

  // URL dialog function
  void _showUrlDialog(String url) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Open Bill'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('URL:'),
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('URL copied to clipboard'),
                  backgroundColor: AppTheme.success,
                ),
              );
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
            },
            child: const Text('Copy URL'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(
                  Uri.parse(url),
                  mode: LaunchMode.externalApplication,
                );
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
            ),
            child: const Text('Open in Browser',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<FuelProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && _filteredEntries.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.danger.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline,
                        size: 40,
                        color: AppTheme.danger,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Unable to Load Data',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        provider.error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.neutral,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => provider.loadFuelEntries(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Try Again',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (provider.fuelEntries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.local_gas_station_outlined,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No Fuel Entries',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 10),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Pull down to refresh or Tap + to add',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.neutral,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddFuelDialog(),
                        icon: const Icon(Icons.add,
                            color: Colors.white, size: 18),
                        label: const Text(
                          'Add First Entry',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Initialize filtered entries
          if (_filteredEntries.isEmpty) {
            _filteredEntries = provider.fuelEntries;
          }

          return RefreshIndicator(
            onRefresh: () async {
              await provider.loadFuelEntries();
              _filteredEntries = provider.fuelEntries;
            },
            backgroundColor: Colors.white,
            color: AppTheme.primary,
            displacement: 40,
            edgeOffset: 10,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // Search Bar with Add Button
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child: Row(
                                    children: [
                                      Icon(Icons.search,
                                          color: AppTheme.primary
                                              .withValues(alpha: 0.7)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          controller: _searchController,
                                          decoration: InputDecoration(
                                            hintText:
                                                'Search by vehicle or remarks...',
                                            hintStyle: TextStyle(
                                              color: AppTheme.neutral
                                                  .withValues(alpha: 0.6),
                                              fontSize: 14,
                                            ),
                                            border: InputBorder.none,
                                          ),
                                          style: const TextStyle(fontSize: 14),
                                          onChanged: (value) => _filterEntries(
                                              value, provider.fuelEntries),
                                        ),
                                      ),
                                      if (_searchController.text.isNotEmpty)
                                        IconButton(
                                          icon: Icon(Icons.clear,
                                              size: 18,
                                              color: AppTheme.neutral),
                                          onPressed: () {
                                            _searchController.clear();
                                            _filterEntries(
                                                '', provider.fuelEntries);
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // List Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Fuel Entries',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                  Text(
                                    '${_filteredEntries.length} records',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.neutral,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Fuel Entries List or Empty State
                if (_filteredEntries.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 60,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No matching entries found',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Try a different search term',
                            style: TextStyle(
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final entry = _filteredEntries[index];
                        return Container(
                          margin: EdgeInsets.fromLTRB(
                              16, index == 0 ? 0 : 16, 16, 12),
                          child: _buildFuelEntryCard(context, entry),
                        );
                      },
                      childCount: _filteredEntries.length,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddFuelDialog(),
        icon: const Icon(Icons.add, size: 22),
        label: const Text(
          'Add Fuel',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildFuelEntryCard(BuildContext context, FuelEntry entry) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final fuelTypeColor = _getFuelTypeColor(entry.fuelType);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showAddFuelDialog(entry: entry),
            splashColor: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getFuelTypeIcon(entry.fuelType),
                          color: fuelTypeColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    entry.vehicleNumber,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: fuelTypeColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color:
                                          fuelTypeColor.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Text(
                                    entry.fuelType.toUpperCase(),
                                    style: TextStyle(
                                      color: fuelTypeColor,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 10,
                                  color:
                                      AppTheme.neutral.withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat('MMM dd, yyyy â€¢ HH:mm').format(
                                      entry.createdAt ?? DateTime.now()),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color:
                                        AppTheme.neutral.withValues(alpha: 0.7),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: AppTheme.neutral.withValues(alpha: 0.6),
                          size: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_rounded,
                                    size: 15, color: AppTheme.primary),
                                const SizedBox(width: 6),
                                const Text('Edit'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'view_bill',
                            child: Row(
                              children: [
                                Icon(Icons.receipt,
                                    size: 15, color: AppTheme.info),
                                const SizedBox(width: 6),
                                const Text('View Bill'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_rounded,
                                    size: 15, color: AppTheme.danger),
                                const SizedBox(width: 6),
                                const Text('Delete'),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showAddFuelDialog(entry: entry);
                          } else if (value == 'view_bill') {
                            _viewBill(entry.billUrl);
                          } else if (value == 'delete') {
                            _handleDeleteEntry(entry.id!);
                          }
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Metrics Grid
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildMetricItem(
                            icon: Icons.straighten_rounded,
                            value: '${entry.km.toStringAsFixed(0)} km',
                            label: 'Odometer',
                            color: AppTheme.primary,
                            isSmallScreen: isSmallScreen,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricItem(
                            icon: Icons.currency_rupee_rounded,
                            value: '₹${entry.price.toStringAsFixed(0)}',
                            label: 'Price',
                            color: AppTheme.success,
                            isSmallScreen: isSmallScreen,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricItem(
                            icon: Icons.local_gas_station_rounded,
                            value: entry.unit,
                            label: 'Unit',
                            color: AppTheme.info,
                            isSmallScreen: isSmallScreen,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Bill Button Row
                  if (entry.billUrl != null &&
                      entry.billUrl!.isNotEmpty &&
                      entry.billUrl != "undefined")
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _viewBill(entry.billUrl),
                        icon: Icon(
                          Icons.receipt_long,
                          color: Colors.white,
                          size: 16,
                        ),
                        label: const Text(
                          'View Bill',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.info,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),

                  // Added By & Remarks
                  if ((entry.addedBy != null && entry.addedBy!.isNotEmpty) ||
                      (entry.remarks != null && entry.remarks!.isNotEmpty))
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (entry.addedBy != null &&
                              entry.addedBy!.isNotEmpty)
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline_rounded,
                                  size: 11,
                                  color:
                                      AppTheme.neutral.withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    'Added by ${entry.addedBy!}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.neutral
                                          .withValues(alpha: 0.7),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          if (entry.remarks != null &&
                              entry.remarks!.isNotEmpty) ...[
                            if (entry.addedBy != null &&
                                entry.addedBy!.isNotEmpty)
                              const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(8),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.note_outlined,
                                    size: 11,
                                    color:
                                        AppTheme.primary.withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      entry.remarks!,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.neutral
                                            .withValues(alpha: 0.8),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isSmallScreen,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 12, color: color),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    color: AppTheme.neutral.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getFuelTypeColor(String fuelType) {
    switch (fuelType.toLowerCase()) {
      case 'petrol':
        return const Color(0xFFF72585);
      case 'diesel':
        return const Color(0xFF4361EE);
      case 'cng':
        return const Color(0xFF4CC9F0);
      case 'electric':
        return const Color(0xFF7209B7);
      default:
        return AppTheme.primary;
    }
  }

  IconData _getFuelTypeIcon(String fuelType) {
    switch (fuelType.toLowerCase()) {
      case 'petrol':
      case 'diesel':
        return Icons.local_gas_station_rounded;
      case 'cng':
        return Icons.propane_tank_rounded;
      case 'electric':
        return Icons.electric_car_rounded;
      default:
        return Icons.local_gas_station_rounded;
    }
  }
}
