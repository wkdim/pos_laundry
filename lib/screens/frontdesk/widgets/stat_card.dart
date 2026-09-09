import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;
  final bool? trendUp; // optional: true = up, false = down, null = no trend

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.trendUp,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasTrend = trendUp != null;

    final bool isMobilePlatform =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        MediaQuery.of(context).size.width < 600;

    if (isMobilePlatform) {
      // Use a custom Row-based layout instead of ListTile to avoid
      // ListTile's trailing-width assertion when the parent is extremely
      // narrow (defensive for very small devices / nested constraints).
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 12),
              // Use a constrained box inside Wrap (Flexible is invalid in Wrap)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Constrain trailing strictly so it can never occupy the whole card
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 88),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (hasTrend)
                      Icon(
                        trendUp!
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: trendUp!
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                        size: 18,
                      ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white12 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return HoverCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row: icon + trend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: accentColor, size: 28),
                  ),
                ),
                if (hasTrend)
                  Icon(
                    trendUp!
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    color: trendUp!
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    size: 20,
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // Value - large & bold
            Text(
              value,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
                height: 1.05,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 6),

            // Title - subtle
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Reusable HoverCard (dark mode compatible)
class HoverCard extends StatefulWidget {
  final Widget child;

  const HoverCard({super.key, required this.child});

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered
                ? colorScheme.primary.withOpacity(0.25)
                : colorScheme.outline.withOpacity(isDark ? 0.3 : 1.0),
            width: 1,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.18 : 0.10),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                    spreadRadius: 1,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.08 : 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: widget.child,
      ),
    );
  }
}
