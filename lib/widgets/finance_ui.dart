import 'dart:ui';
import '../services/privacy_service.dart';
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
  final String? institutionName;
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
    this.institutionName,
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
              institutionName != null
                ? InstitutionLogo(
                    institutionName:
                        institutionName!,
                  )
                : FinanceIconBubble(
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

// ===========================================================
// SKELETON LOADING
// ===========================================================

class FinanceSkeleton extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;

  const FinanceSkeleton({
    super.key,
    this.width,
    required this.height,
    this.radius = 14,
  });

  @override
  State<FinanceSkeleton> createState() =>
      _FinanceSkeletonState();
}


class _FinanceSkeletonState
    extends State<FinanceSkeleton>
    with SingleTickerProviderStateMixin {

  late final AnimationController
      _controller;

  late final Animation<double>
      _animation;

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(
      vsync: this,
      duration:
          const Duration(
        milliseconds: 900,
      ),
    );

    _animation =
        Tween<double>(
      begin: 0.35,
      end: 0.75,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.repeat(
      reverse: true,
    );
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration:
            BoxDecoration(
          color:
              Colors.white
                  .withValues(
            alpha: 0.65,
          ),
          borderRadius:
              BorderRadius.circular(
            widget.radius,
          ),
        ),
      ),
    );
  }
}


// ===========================================================
// PAGE SKELETON
// ===========================================================

class FinancePageSkeleton
    extends StatelessWidget {
  const FinancePageSkeleton({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding:
          const EdgeInsets.fromLTRB(
        20,
        8,
        20,
        36,
      ),
      children: [
        const FinanceSkeleton(
          height: 150,
          radius: 28,
        ),

        const SizedBox(
          height: 30,
        ),

        const FinanceSkeleton(
          width: 120,
          height: 12,
          radius: 6,
        ),

        const SizedBox(
          height: 14,
        ),

        ...List.generate(
          3,
          (index) =>
              const Padding(
            padding:
                EdgeInsets.only(
              bottom: 12,
            ),
            child:
                FinanceSkeleton(
              height: 88,
              radius: 22,
            ),
          ),
        ),
      ],
    );
  }
}

// ===========================================================
// INSTITUTION LOGO
// ===========================================================

class InstitutionLogo
    extends StatelessWidget {
  final String institutionName;

  final double size;

  const InstitutionLogo({
    super.key,
    required this.institutionName,
    this.size = 48,
  });

  String _normalize(
    String value,
  ) {
    return value
        .trim()
        .toUpperCase()
        .replaceAll(
          RegExp(r'[^A-Z0-9]'),
          '',
        );
  }

  String? get _domain {
    final name =
        _normalize(
      institutionName,
    );

    if (name.contains('PICPAY')) {
      return 'picpay.com';
    }

    if (name.contains('NUBANK')) {
      return 'nubank.com.br';
    }

    if (name.contains('ITAU')) {
      return 'itau.com.br';
    }

    if (name.contains('BRADESCO')) {
      return 'bradesco.com.br';
    }

    if (name.contains('SANTANDER')) {
      return 'santander.com.br';
    }

    if (name.contains('BANCOINTER') ||
        name == 'INTER') {
      return 'inter.co';
    }

    if (name.contains('BANCODOBRASIL') ||
        name == 'BB') {
      return 'bb.com.br';
    }

    if (name.contains('CAIXA')) {
      return 'caixa.gov.br';
    }

    if (name.contains('C6')) {
      return 'c6bank.com.br';
    }

    if (name.contains('BTG')) {
      return 'btgpactual.com';
    }

    if (name.contains('XP')) {
      return 'xp.com.br';
    }

    if (name.contains('RICO')) {
      return 'rico.com.vc';
    }

    if (name.contains('CLEAR')) {
      return 'clear.com.br';
    }

    if (name.contains('MERCADOPAGO')) {
      return 'mercadopago.com.br';
    }

    if (name.contains('BINANCE')) {
      return 'binance.com';
    }

    if (name.contains('COINBASE')) {
      return 'coinbase.com';
    }

    return null;
  }

  String get _initials {
    final parts =
        institutionName
            .trim()
            .split(
          RegExp(r'\s+'),
        )
            .where(
          (value) =>
              value.isNotEmpty,
        )
            .toList();

    if (parts.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      final value =
          parts.first;

      return value
          .substring(
            0,
            value.length >= 2
                ? 2
                : 1,
          )
          .toUpperCase();
    }

    return '${parts.first[0]}'
            '${parts.last[0]}'
        .toUpperCase();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final domain =
        _domain;

    if (domain == null) {
      return FinanceIconBubble(
        initials: _initials,
      );
    }

    final url =
        'https://www.google.com/s2/favicons'
        '?domain=$domain'
        '&sz=128';

    return Container(
      width: size,
      height: size,
      padding:
          const EdgeInsets.all(
        9,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.white
                .withValues(
          alpha: 0.78,
        ),
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        border:
            Border.all(
          color:
              Colors.white
                  .withValues(
            alpha: 0.85,
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(
          10,
        ),
        child: Image.network(
          url,
          fit: BoxFit.contain,
          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            return Center(
              child: Text(
                _initials,
                style:
                    const TextStyle(
                  color:
                      AppTheme.primary,
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ===========================================================
// PRIVACY MONEY
// ===========================================================

class PrivacyMoney extends StatelessWidget {
  final num? value;

  final TextStyle? style;

  final String hiddenText;

  const PrivacyMoney({
    super.key,
    required this.value,
    this.style,
    this.hiddenText = '••••••',
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return ValueListenableBuilder<bool>(
      valueListenable:
          PrivacyService
              .instance
              .valuesVisible,
      builder:
          (
        context,
        visible,
        child,
      ) {
        return Text(
          visible
              ? formatCurrency(
                  value,
                )
              : hiddenText,
          style:
              style,
        );
      },
    );
  }
}


// ===========================================================
// PRIVACY EYE
// ===========================================================

class PrivacyEyeButton
    extends StatelessWidget {
  const PrivacyEyeButton({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return ValueListenableBuilder<bool>(
      valueListenable:
          PrivacyService
              .instance
              .valuesVisible,
      builder:
          (
        context,
        visible,
        child,
      ) {
        return FinanceIconButton(
          icon:
              visible
                  ? Icons
                      .visibility_outlined
                  : Icons
                      .visibility_off_outlined,
          tooltip:
              visible
                  ? 'Ocultar valores'
                  : 'Mostrar valores',
          onTap:
              PrivacyService
                  .instance
                  .toggle,
        );
      },
    );
  }
}