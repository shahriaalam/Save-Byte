import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../location/widgets/location_permission_sheet.dart';

/// Controls whether the customer floating bottom navigation bar is visible.
/// Hidden when modal bottom sheets or overlays are open.
class CustomerNavbarNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void hide() => state = false;
  void show() => state = true;
}

final customerNavbarVisibleProvider =
    NotifierProvider<CustomerNavbarNotifier, bool>(CustomerNavbarNotifier.new);

/// Navigation shell for Customer role providing a floating bottom navigation bar
/// across Home, Search, and Profile (Section 19).
class CustomerShellScreen extends ConsumerStatefulWidget {
  const CustomerShellScreen({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<CustomerShellScreen> createState() => _CustomerShellScreenState();
}

class _CustomerShellScreenState extends ConsumerState<CustomerShellScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LocationPermissionSheet.showIfFirstTime(context, ref);
    });
  }

  void _onDestinationSelected(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final isNavVisible = ref.watch(customerNavbarVisibleProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(child: widget.navigationShell),
          if (isNavVisible)
            Positioned(
              left: 20,
              right: 20,
              bottom: bottomInset + 16,
              child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Container(
                  height: 66,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(33),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.8),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 20,
                        spreadRadius: 1,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(33),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(
                          index: 3,
                          label: 'Hot Deals',
                          icon: Icons.local_fire_department_outlined,
                          selectedIcon: Icons.local_fire_department_rounded,
                        ),
                        _buildNavItem(
                          index: 0,
                          label: 'Home',
                          icon: Icons.home_outlined,
                          selectedIcon: Icons.home_rounded,
                        ),
                        _buildNavItem(
                          index: 1,
                          label: 'Search',
                          icon: Icons.search_rounded,
                          selectedIcon: Icons.search_rounded,
                        ),
                        _buildNavItem(
                          index: 2,
                          label: 'Profile',
                          icon: Icons.person_outline_rounded,
                          selectedIcon: Icons.person_rounded,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData selectedIcon,
  }) {
    final isSelected = widget.navigationShell.currentIndex == index;

    return Expanded(
      child: Semantics(
        selected: isSelected,
        label: label,
        button: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => _onDestinationSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      isSelected ? selectedIcon : icon,
                      size: 21,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
