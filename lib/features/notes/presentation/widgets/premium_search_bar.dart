import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

class PremiumSearchBar extends StatelessWidget {
  const PremiumSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.focusNode,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.cardColor(brightness),
        borderRadius: BorderRadius.circular(AppTheme.inputRadius),
        border: Border.all(color: AppTheme.border),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => FocusScope.of(context).unfocus(),
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: 'Search notes',
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.inkSoft,
              ),
          filled: false,
          isDense: true,
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppTheme.inkSoft,
            size: 20,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  onPressed: onClear,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppTheme.inkSoft,
                    size: 18,
                  ),
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
