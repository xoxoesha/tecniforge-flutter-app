import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppTopBar extends StatelessWidget {
  final String title, subtitle;
  final bool showBack;
  const AppTopBar({super.key, required this.title, required this.subtitle, this.showBack = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.navyDeep,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          if (showBack) const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('TECNIFORGE', style: TextStyle(color: AppTheme.forgeAmber, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 2)),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
              Text(subtitle, style: const TextStyle(color: Color(0xFF9FB0CC), fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const AppCard({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(AppTheme.radiusMd), border: Border.all(color: Theme.of(context).dividerColor)),
      child: child,
    );
    if (onTap == null) return card;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(AppTheme.radiusMd), child: card);
  }
}

class AppBadge extends StatelessWidget {
  final String label;
  final Color color;
  const AppBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(50)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

enum AppButtonVariant { primary, secondary, danger }

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final AppButtonVariant variant;
  final IconData? icon;

  const AppButton({super.key, required this.label, required this.onPressed, this.variant = AppButtonVariant.primary, this.icon});

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = switch (widget.variant) {
      AppButtonVariant.primary => AppTheme.navyPrimary,
      AppButtonVariant.secondary => Theme.of(context).colorScheme.surface,
      AppButtonVariant.danger => AppTheme.errorRed.withOpacity(0.1),
    };
    final fg = switch (widget.variant) {
      AppButtonVariant.primary => Colors.white,
      AppButtonVariant.secondary => Theme.of(context).colorScheme.onSurface,
      AppButtonVariant.danger => AppTheme.errorRed,
    };

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: bg,
              elevation: widget.variant == AppButtonVariant.secondary ? 0 : 1,
              side: widget.variant == AppButtonVariant.secondary ? BorderSide(color: Theme.of(context).dividerColor) : null,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[Icon(widget.icon, size: 16, color: fg), const SizedBox(width: 8)],
                Text(widget.label, style: TextStyle(color: fg, fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final IconData? icon;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;

  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.icon,
    this.obscureText = false,
    this.validator,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.slate)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null ? Icon(icon, size: 18, color: AppTheme.slate) : null,
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm), borderSide: const BorderSide(color: AppTheme.navyPrimary, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }
}
