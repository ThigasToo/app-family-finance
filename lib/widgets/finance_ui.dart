import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';


// ===========================================================
// FINANCE PAGE
// ===========================================================

class FinancePage extends StatelessWidget {
  final String title;
  final Widget child;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onRefreshButton;
  final bool isRefreshing;
  final List<Widget>? actions;

  const FinancePage({
    super.key,
    required this.title,
    required this.child,
    this.onRefresh,
    this.onRefreshButton,
    this.isRefreshing = false,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppTheme.backgroundGradient,
              ),
            ),
          ),

          const Positioned(
            top: -120,
            right: -100,
            child: FinanceGlowOrb(
              size: 280,
              color: Color(0xFF9ED7CE),
            ),
          ),

          const Positioned(
            top: 330,
            left: -150,
            child: FinanceGlowOrb(
              size: 300,
              color: Color(0xFFB7CCE0),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                FinancePageHeader(
                  title: title,
                  isRefreshing: isRefreshing,
                  onRefresh: onRefreshButton,
                  actions: actions,
                ),

                Expanded(
                  child: onRefresh == null
                      ? child
                      : RefreshIndicator(
                          onRefresh: onRefresh!,
                          child: child,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// ===========================================================
// HEADER
// ===========================================================

class FinancePageHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onRefresh;
  final bool isRefreshing;
  final List<Widget>? actions;

  const FinancePageHeader({
    super.key,
    required this.title,
    this.onRefresh,
    this.isRefreshing = false,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        12,
        8,
        16,
        10,
      ),
      child: Row(
        children: [
          FinanceIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            tooltip: 'Voltar',
            onTap: () => Navigator.pop(context),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppTheme.ink,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
          ),

          if (actions != null) ...actions!,

          if (onRefresh != null) ...[
            const SizedBox(width: 8),
            FinanceIconButton(
              icon: Icons.refresh_rounded,
              tooltip: 'Atualizar',
              onTap: isRefreshing ? null : onRefresh,
              child: isRefreshing
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}


// ===========================================================
// GLASS CARD
// ===========================================================

class FinanceGlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double radius;
  final EdgeInsetsGeometry? padding;

  const FinanceGlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.radius = 23,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 15,
          sigmaY: 15,
        ),
        child: Material(
          color: Colors.white.withValues(alpha: 0.61),
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.76),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.025),
                    blurRadius: 24,
                    offset: const Offset(0, 9),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}


// ===========================================================
// HERO CARD
// ===========================================================

class FinanceHeroCard extends StatelessWidget {
  final String label;
  final double value;
  final List<Widget> details;

  const FinanceHeroCard({
    super.key,
    required this.label,
    required this.value,
    this.details = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        gradient: AppTheme.premiumGradient,
        borderRadius: BorderRadius.circular(29),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
        ),
        boxShadow: AppTheme.floatingShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.68),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            formatCurrency(value),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.9,
            ),
          ),

          if (details.isNotEmpty) ...[
            const SizedBox(height: 21),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 13,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.09),
                ),
              ),
              child: Wrap(
                spacing: 18,
                runSpacing: 9,
                children: details,
              ),
            ),
          ],
        ],
      ),
    );
  }
}


// ===========================================================
// HERO DETAIL
// ===========================================================

class FinanceHeroInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  const FinanceHeroInfo({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 15,
          color: Colors.white.withValues(alpha: 0.66),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.70),
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}


// ===========================================================
// SECTION HEADER
// ===========================================================

class FinanceSectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;

  const FinanceSectionHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 3,
        right: 3,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                color: AppTheme.inkSoft,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),

          if (trailing != null)
            Text(
              trailing!,
              style: TextStyle(
                color: AppTheme.inkSoft.withValues(alpha: 0.70),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}


// ===========================================================
// LIST TILE
// ===========================================================

class FinanceListTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final double value;
  final IconData? icon;
  final String? initials;
  final String? trailingText;
  final double? progress;
  final VoidCallback? onTap;

  const FinanceListTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    this.icon,
    this.initials,
    this.trailingText,
    this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FinanceGlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(17),
      child: Column(
        children: [
          Row(
            children: [
              FinanceIconBubble(
                icon: icon,
                initials: initials,
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.inkSoft,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCurrency(value),
                    style: const TextStyle(
                      color: AppTheme.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  if (trailingText != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      trailingText!,
                      style: const TextStyle(
                        color: AppTheme.inkSoft,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(width: 7),

              const Icon(
                Icons.chevron_right_rounded,
                size: 24,
                color: AppTheme.inkSoft,
              ),
            ],
          ),

          if (progress != null) ...[
            const SizedBox(height: 15),

            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: progress!.clamp(0.0, 1.0),
                minHeight: 4.5,
                backgroundColor:
                    AppTheme.primary.withValues(alpha: 0.07),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(
                  AppTheme.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


// ===========================================================
// ICON BUBBLE
// ===========================================================

class FinanceIconBubble extends StatelessWidget {
  final IconData? icon;
  final String? initials;

  const FinanceIconBubble({
    super.key,
    this.icon,
    this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary.withValues(alpha: 0.14),
            AppTheme.primaryLight.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.72),
        ),
      ),
      child: Center(
        child: initials != null
            ? Text(
                initials!,
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              )
            : Icon(
                icon ?? Icons.account_balance_rounded,
                color: AppTheme.primary,
                size: 21,
              ),
      ),
    );
  }
}


// ===========================================================
// ICON BUTTON
// ===========================================================

class FinanceIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Widget? child;

  const FinanceIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: FinanceGlassCard(
        radius: 15,
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Center(
            child: child ??
                Icon(
                  icon,
                  size: 19,
                  color: AppTheme.ink,
                ),
          ),
        ),
      ),
    );
  }
}


// ===========================================================
// EMPTY STATE
// ===========================================================

class FinanceEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const FinanceEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return FinanceGlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 34,
      ),
      child: Column(
        children: [
          FinanceIconBubble(icon: icon),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.ink,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.inkSoft,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}


// ===========================================================
// GLOW
// ===========================================================

class FinanceGlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const FinanceGlowOrb({
    super.key,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(
        sigmaX: 60,
        sigmaY: 60,
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.25),
        ),
      ),
    );
  }
}