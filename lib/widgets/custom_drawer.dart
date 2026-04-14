import 'package:fleet_management/core/constants/app_constants.dart';
import 'package:fleet_management/core/theme/app_theme.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CustomDrawer extends StatefulWidget {
  final Function(int)? onItemSelected;
  final int selectedIndex;

  const CustomDrawer({
    super.key,
    this.onItemSelected,
    this.selectedIndex = 0,
  });

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer>
    with SingleTickerProviderStateMixin {
  bool _isHoveringLogout = false;
  late AnimationController _drawerAnimationController;
  late Animation<double> _widthAnimation;
  late Animation<double> _scaleAnimation;

  // Track hover states for menu items
  final Map<int, bool> _hoverStates = {};

  @override
  void initState() {
    super.initState();

    _drawerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    // Fixed drawer width (slightly larger)
    _widthAnimation = Tween<double>(
      begin: 240,
      end: 240,
    ).animate(CurvedAnimation(
      parent: _drawerAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _drawerAnimationController,
      curve: Curves.easeOutBack,
    ));

    _drawerAnimationController.forward();
  }

  @override
  void dispose() {
    _drawerAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return AnimatedBuilder(
      animation: _drawerAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          alignment: Alignment.centerLeft,
          child: Container(
            width: _widthAnimation.value,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: Offset(3, 0),
                  spreadRadius: -2,
                ),
              ],
              border: Border(
                right: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Logo/Branding Section
                  Padding(
                    padding: const EdgeInsets.only(top: 24, bottom: 16),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Center(
                          child: Image.asset(
                            'lib/assets/hitech-logo.png',
                            height: 60,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(
                      color: Colors.white.withValues(alpha: 0.12),
                      thickness: 0.5,
                      height: 24,
                    ),
                  ),

                  // User Info Section
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.secondary,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF14ADD6).withValues(alpha: 0.3),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.name ?? 'User',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Text(
                                    _formatRole(user?.role ?? 'User'),
                                    style: TextStyle(
                                      color: const Color(0xFFA3B2ED),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Menu Items Section
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: // In custom_drawer.dart - Update the menu items
                          Column(
                        children: [
                          const SizedBox(height: 4),

                          _buildDrawerItem(
                            context: context,
                            label: 'Dashboard',
                            icon: Icons.dashboard_rounded,
                            index: 0,
                          ),
                          const SizedBox(height: 4),

                          _buildDrawerItem(
                            context: context,
                            label: 'Vehicle Master',
                            icon: Icons.directions_car_rounded,
                            index: 1,
                          ),
                          const SizedBox(height: 4),

                          _buildDrawerItem(
                            context: context,
                            label: 'Service Master',
                            icon: Icons.miscellaneous_services_rounded,
                            index: 2,
                          ),
                          const SizedBox(height: 4),

                          _buildDrawerItem(
                            context: context,
                            label: 'Booking',
                            icon: Icons.book_rounded,
                            index: 3,
                          ),
                          const SizedBox(height: 4),

                          _buildDrawerItem(
                            context: context,
                            label: 'Maintenance',
                            icon: Icons.build_rounded,
                            index: 4,
                          ),
                          const SizedBox(height: 4),

                          _buildDrawerItem(
                            context: context,
                            label: 'Fuel',
                            icon: Icons.local_gas_station_rounded,
                            index: 5,
                          ),
                          const SizedBox(height: 4),

                          _buildDrawerItem(
                            context: context,
                            label: 'Service History',
                            icon: Icons.receipt_long_rounded,
                            index: 6,
                          ),
                          const SizedBox(height: 4),

                          _buildDrawerItem(
                            context: context,
                            label: 'Profile',
                            icon: Icons.person_rounded,
                            index: 7,
                          ),
                          const SizedBox(height: 4),

                          _buildDrawerItem(
                            context: context,
                            label: 'Vehicle Start',
                            icon: Icons.play_circle_fill_rounded,
                            index: 8,
                          ),
                          const SizedBox(height: 4),

                          _buildDrawerItem(
                            context: context,
                            label: 'Closing',
                            icon: Icons.analytics_rounded,
                            index: 9,
                          ),
                          const SizedBox(height: 4),

                          _buildDrawerItem(
                            context: context,
                            label: 'Time Extension',
                            icon: Icons.timer_outlined,
                            index: 10,
                          ),
                          const SizedBox(height: 4),

                          _buildDrawerItem(
                            context: context,
                            label: 'Collection & Delivery',
                            icon: Icons.local_shipping_rounded,
                            index: 11,
                          ),
                          const SizedBox(height: 4),

                          _buildDrawerItem(
                            context: context,
                            label: 'Action Alerts',
                            icon: Icons.notifications_active_rounded,
                            index: 12,
                          ),

                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Settings Button
                        _buildBottomItem(
                          context: context,
                          label: 'Settings',
                          icon: Icons.settings_rounded,
                          index: 99,
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Settings coming soon!')),
                            );
                          },
                        ),

                        const SizedBox(height: 8),

                        // Logout Button
                        _buildLogoutItem(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required String label,
    required IconData icon,
    required int index,
  }) {
    final isSelected = widget.selectedIndex == index;
    final isHovering = _hoverStates[index] ?? false;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoverStates[index] = true),
      onExit: (_) => setState(() => _hoverStates[index] = false),
      child: GestureDetector(
        onTap: () {
          Navigator.pop(context);
          if (!isSelected) {
            widget.onItemSelected?.call(index);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isSelected
                  ? Colors.white
                  : (isHovering
                      ? Colors.white.withValues(alpha: 0.1)
                      : null),
            border: isSelected
                ? Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  )
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : (isHovering
                    ? [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: isSelected
                        ? AppTheme.secondary
                        : (isHovering
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? Colors.white
                        : (isHovering
                            ? const Color(0xFFB8C4FF)
                            : const Color(0xFFA3B2ED)),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF4A4494)
                          : const Color(0xFFA3B2ED),
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected)
                  AnimatedOpacity(
                    opacity: isSelected ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: 4,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppTheme.secondary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomItem({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required int index,
  }) {
    final isHovering = _hoverStates[index] ?? false;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoverStates[index] = true),
      onExit: (_) => setState(() => _hoverStates[index] = false),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isHovering
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.04),
            border: Border.all(
              color: Colors.white.withValues(alpha: isHovering ? 0.15 : 0.08),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  child: Icon(
                    icon,
                    color: isHovering
                        ? const Color(0xFFB8C4FF)
                        : const Color(0xFFA3B2ED),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isHovering
                          ? const Color(0xFFB8C4FF)
                          : const Color(0xFFA3B2ED),
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutItem(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHoveringLogout = true),
      onExit: (_) => setState(() => _isHoveringLogout = false),
      child: GestureDetector(
        onTap: () => _showLogoutDialog(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: _isHoveringLogout ? Colors.red.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.04),
            border: Border.all(
              color: _isHoveringLogout
                  ? Colors.red.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: _isHoveringLogout
                        ? Colors.red.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: _isHoveringLogout
                        ? Colors.red
                        : const Color(0xFFA3B2ED),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Logout',
                    style: TextStyle(
                      color: _isHoveringLogout
                          ? Colors.red
                          : const Color(0xFFA3B2ED),
                      fontWeight:
                          _isHoveringLogout ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            width: 320,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon Container
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFF6B6B),
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Are you sure you want to logout?',
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF6B7280).withValues(alpha: 0.9),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                side: const BorderSide(
                                  color: Color(0xFFE5E7EB),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF4B5563),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                context.read<AuthProvider>().logout();
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  AppConstants.loginRoute,
                                  (route) => false,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                backgroundColor: const Color(0xFFDC2626),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Logout',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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
        );
      },
    );
  }

  String _formatRole(String role) {
    if (role.length > 12) {
      return '${role.substring(0, 10)}...';
    }
    return role
        .toLowerCase()
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) =>
            word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join(' ');
  }
}
