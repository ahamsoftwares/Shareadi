import 'package:flutter/material.dart';

import '../core/category_icons.dart';

class IconPicker extends StatelessWidget {
  const IconPicker({
    super.key,
    required this.options,
    required this.selectedKey,
    required this.onChanged,
  });

  final List<CategoryIcon> options;
  final String selectedKey;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final selected = option.key == selectedKey;
        return InkWell(
          onTap: () => onChanged(option.key),
          customBorder: const CircleBorder(),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? scheme.primary : scheme.surfaceContainerHighest,
              border: selected
                  ? null
                  : Border.all(color: scheme.outlineVariant),
            ),
            child: Icon(
              option.icon,
              color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
              size: 22,
            ),
          ),
        );
      }).toList(),
    );
  }
}