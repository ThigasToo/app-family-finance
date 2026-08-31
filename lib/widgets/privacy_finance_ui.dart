import 'package:flutter/material.dart';

import '../services/privacy_service.dart';
import '../theme/app_theme.dart';
import 'finance_ui.dart';


// ===========================================================
// PRIVACY HERO CARD
// ===========================================================

class PrivacyFinanceHeroCard extends StatelessWidget {
  final String label;
  final double value;
  final List<Widget> details;

  const PrivacyFinanceHeroCard({
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
          PrivacyMoney(
            value: value,
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
// PRIVACY LIST TILE
// ===========================================================

class PrivacyFinanceListTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final double value;
  final IconData? icon;
  final String? initials;
  final String? institutionName;
  final String? trailingText;
  final double? progress;
  final VoidCallback? onTap;

  const PrivacyFinanceListTile({
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
    return ValueListenableBuilder<bool>(
      valueListenable:
          PrivacyService.instance.valuesVisible,
      builder: (
        context,
        visible,
        child,
      ) {
        return FinanceGlassCard(
          onTap: onTap,
          padding: const EdgeInsets.all(17),
          child: Column(
            children: [
              Row(
                children: [
                  institutionName != null
                      ? InstitutionLogo(
                          institutionName: institutionName!,
                        )
                      : FinanceIconBubble(
                          icon: icon,
                          initials: initials,
                        ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
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
                    crossAxisAlignment:
                        CrossAxisAlignment.end,
                    children: [
                      PrivacyMoney(
                        value: value,
                        style: const TextStyle(
                          color: AppTheme.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (visible &&
                          trailingText != null) ...[
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
              if (visible && progress != null) ...[
                const SizedBox(height: 15),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value:
                        progress!.clamp(0.0, 1.0).toDouble(),
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
      },
    );
  }
}
