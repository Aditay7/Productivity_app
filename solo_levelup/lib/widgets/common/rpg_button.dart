import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../core/utils/responsive.dart';

/// Custom RPG-styled button
class RPGButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final IconData? icon;
  final bool isLoading;

  const RPGButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isPrimary = true,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    
    if (isLoading) {
      return ElevatedButton(
        onPressed: null,
        child: SizedBox(
          height: responsive.isSmall ? 18 : 20,
          width: responsive.isSmall ? 18 : 20,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final buttonChild = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: responsive.isSmall ? 18 : 20),
          SizedBox(width: responsive.spacing * 0.5),
        ],
        Flexible(
          child: Text(
            text,
            style: TextStyle(fontSize: responsive.isSmall ? 14 : 16),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    if (isPrimary) {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryPurple,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: responsive.spacing,
            vertical: responsive.spacing * 0.75,
          ),
        ),
        child: buttonChild,
      );
    } else {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.gold,
          side: const BorderSide(color: AppTheme.gold),
          padding: EdgeInsets.symmetric(
            horizontal: responsive.spacing,
            vertical: responsive.spacing * 0.75,
          ),
        ),
        child: buttonChild,
      );
    }
  }
}
