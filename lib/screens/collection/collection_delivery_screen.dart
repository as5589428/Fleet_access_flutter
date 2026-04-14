import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/collection_delivery_model.dart';
import '../../services/collection_delivery_service.dart';
import 'collection_delivery_form_screen.dart';

class CollectionDeliveryScreen extends StatefulWidget {
  const CollectionDeliveryScreen({super.key});

  @override
  State<CollectionDeliveryScreen> createState() =>
      _CollectionDeliveryScreenState();
}

class _CollectionDeliveryScreenState extends State<CollectionDeliveryScreen>
    with SingleTickerProviderStateMixin {
  final _service = CollectionDeliveryService();
  late TabController _tabController;

  List<CollectionDeliveryModel> _allEntries = [];
  DashboardInfo _dashboardInfo = const DashboardInfo();
  bool _isLoading = true;
  String _errorMessage = '';
  String _selectedType = 'collection';

  static const _primaryColor = Color(0xFF4A4494);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchEntries();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchEntries() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final result = await _service.getAllEntries(type: _selectedType);
      setState(() {
        _allEntries = result.data;
        _dashboardInfo = result.dashboardInfo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<CollectionDeliveryModel> get _pendingEntries =>
      _allEntries.where((e) => (e.status ?? '').toLowerCase() == 'pending').toList();

  List<CollectionDeliveryModel> get _completedEntries =>
      _allEntries.where((e) => (e.status ?? '').toLowerCase() == 'completed').toList();

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(dateStr));
    } catch (_) {
      return 'Invalid Date';
    }
  }

  void _navigateToForm({CollectionDeliveryModel? entry}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CollectionDeliveryFormScreen(
          entry: entry,
          isEditing: entry != null,
        ),
      ),
    );
    if (result == true) {
      _fetchEntries();
    }
  }

  // ─────────── Dashboard Stats Cards ───────────

  Widget _buildStatsRow() {
    final d = _dashboardInfo;
    return SizedBox(
      height: 92,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _statCard('Scheduled', d.scheduledCollection, Icons.calendar_today, const Color(0xFF4A4494)),
          _statCard('Collected', d.collectedCount, Icons.inventory_2, Colors.green),
          _statCard('Delivered', d.deliveredCount, Icons.local_shipping, Colors.blue),
          _statCard('Pending\nCollection', d.pendingCollectedCount, Icons.hourglass_empty, Colors.orange),
          _statCard('Pending\nDelivery', d.pendingDeliveryCount, Icons.pending_actions, Colors.red),
          _statCard('Today Tasks', d.todayTask, Icons.today, Colors.teal),
          _statCard('SRF Pending', d.srfPending, Icons.assignment_late, Colors.purple),
        ],
      ),
    );
  }

  Widget _statCard(String label, int count, IconData icon, Color color) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 3))],
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: color),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ]),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 11, height: 1.3), maxLines: 2),
        ],
      ),
    );
  }

  // ─────────── Filter Tabs ───────────

  Widget _buildTypeFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(children: [
        _typeChip('collection', 'Collection', Icons.inventory_2),
        const SizedBox(width: 10),
        _typeChip('delivery', 'Delivery', Icons.local_shipping),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.refresh, color: _primaryColor),
          onPressed: _fetchEntries,
          tooltip: 'Refresh',
        ),
      ]),
    );
  }

  Widget _typeChip(String type, String label, IconData icon) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        if (_selectedType != type) {
          setState(() => _selectedType = type);
          _fetchEntries();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? _primaryColor : Colors.grey.shade300),
          boxShadow: isSelected
              ? [BoxShadow(color: _primaryColor.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ]),
      ),
    );
  }

  // ─────────── Entry Cards ───────────

  Widget _buildChip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(label,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      );

  Widget _buildCard(CollectionDeliveryModel entry, {bool isPending = true}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              backgroundColor: _primaryColor.withValues(alpha: 0.1),
              child: Icon(
                entry.collectionType == 'delivery' ? Icons.local_shipping : Icons.inventory_2,
                color: _primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(entry.clientName ?? 'Unknown Client',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(
                  '${entry.collectionType?.toUpperCase()} • ${_formatDate(entry.collectionDate)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ]),
            ),
            _buildChip(
              (entry.status ?? 'pending').toUpperCase(),
              entry.status?.toLowerCase() == 'completed' ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
              onPressed: () => _navigateToForm(entry: entry),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ]),
          const Divider(height: 16),
          Wrap(spacing: 16, runSpacing: 8, children: [
            _infoRow(Icons.person, entry.contactPersonName ?? 'N/A'),
            _infoRow(Icons.route, entry.routeDetails ?? 'N/A'),
            _infoRow(Icons.devices_other, '${entry.instrumentCount ?? 0} instruments'),
            _infoRow(Icons.local_shipping_outlined, entry.mode ?? 'N/A'),
            _infoRow(Icons.badge_outlined, entry.assignedEmployee ?? 'N/A'),
          ]),
          if (isPending) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToForm(entry: entry),
                icon: const Icon(Icons.edit_note, size: 18, color: Colors.white),
                label: const Text('Fill Task Data',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
        ],
      );

  Widget _buildListView(List<CollectionDeliveryModel> entries, {bool isPending = true}) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _primaryColor));
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text('Error loading data',
              style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(_errorMessage,
                style: const TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchEntries,
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          )
        ]),
      );
    }

    if (entries.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(isPending ? Icons.hourglass_empty : Icons.check_circle_outline,
              color: Colors.grey.shade400, size: 60),
          const SizedBox(height: 16),
          Text(
            isPending ? 'No pending tasks' : 'No completed tasks',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          const SizedBox(height: 6),
          Text(
            isPending
                ? 'All tasks have been completed or none are assigned yet.'
                : 'Tasks you complete will appear here.',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: entries.length,
      itemBuilder: (_, i) => _buildCard(entries[i], isPending: isPending),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      // No AppBar — handled by MainScreen
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats cards row
          const SizedBox(height: 12),
          _buildStatsRow(),

          // Type filter + refresh
          _buildTypeFilter(),

          const SizedBox(height: 8),

          // Pending / Completed tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: _primaryColor,
              indicatorWeight: 3,
              labelColor: _primaryColor,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: [
                Tab(
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.hourglass_empty, size: 16),
                    const SizedBox(width: 6),
                    Text('Pending (${_pendingEntries.length})'),
                  ]),
                ),
                Tab(
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.check_circle_outline, size: 16),
                    const SizedBox(width: 6),
                    Text('Completed (${_completedEntries.length})'),
                  ]),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildListView(_pendingEntries, isPending: true),
                _buildListView(_completedEntries, isPending: false),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(),
        backgroundColor: _primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Task', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
