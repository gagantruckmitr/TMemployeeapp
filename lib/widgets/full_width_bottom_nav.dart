import 'package:flutter/material.dart';

class FullWidthBottomNavBar extends StatefulWidget {
  final int initialIndex;
  final Function(int)? onIndexChanged;

  const FullWidthBottomNavBar({
    super.key,
    this.initialIndex = 3,
    this.onIndexChanged,
  });

  @override
  State<FullWidthBottomNavBar> createState() => _FullWidthBottomNavBarState();
}

class _FullWidthBottomNavBarState extends State<FullWidthBottomNavBar> {
  late int _currentIndex;

  final List<NavItem> _items = [
    NavItem(icon: Icons.waving_hand, label: 'Welcome'),
    NavItem(icon: Icons.headset_mic, label: 'Toll Free'),
    NavItem(icon: Icons.handshake, label: 'Match-making'),
    NavItem(icon: Icons.phone_callback, label: 'Callbacks'),
    NavItem(icon: Icons.groups, label: 'Social-Media'),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          child: ClipRect(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(_items.length, (index) {
                    final isSelected = _currentIndex == index;
                    return Expanded(
                      flex: isSelected ? 3 : 1,
                      child: _buildNavButton(
                        index,
                        isSelected,
                        constraints.maxWidth,
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton(int index, bool isSelected, double availableWidth) {
    final item = _items[index];
    final maxLabelWidth = ((availableWidth * 3 / 7) - 70).clamp(50.0, 120.0);

    return GestureDetector(
      onTap: () {
        if (_currentIndex != index) {
          setState(() => _currentIndex = index);
          widget.onIndexChanged?.call(index);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 2.5),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 12 : 4,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6B5AA6).withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              color: isSelected ? const Color(0xFF6B5AA6) : Colors.black87,
              size: isSelected ? 26 : 24,
            ),
            if (isSelected)
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxLabelWidth),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        item.label,
                        style: const TextStyle(
                          color: Color(0xFF6B5AA6),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        softWrap: false,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class NavItem {
  final IconData icon;
  final String label;

  NavItem({required this.icon, required this.label});
}
