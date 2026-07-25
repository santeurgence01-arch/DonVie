import 'package:flutter/material.dart';
import 'package:health_emergency/core/theme/app_theme.dart';

/// Rectangle gris en pulsation, utilisé pour les états de chargement de
/// liste (§5 — jamais un spinner plein écran pour du contenu déjà visité).
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 8,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  late final Animation<double> _opacity = Tween<double>(
    begin: 0.4,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

/// Ligne de carte skeleton imitant une carte donneur/liste (avatar + texte).
class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const SkeletonBox(width: 44, height: 44, borderRadius: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(width: 140, height: 14),
                SizedBox(height: 8),
                SkeletonBox(width: 80, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Liste de plusieurs [SkeletonListTile], pour remplacer une ListView le
/// temps du premier chargement Firestore.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 6});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: count,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) => const SkeletonListTile(),
    );
  }
}
