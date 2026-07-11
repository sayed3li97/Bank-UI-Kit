import 'package:bank_ui_kit/core.dart';
import 'package:flutter/material.dart';

import '../gallery/component_detail.dart';
import '../gallery/component_registry.dart';
import 'showcase.dart';

/// A searchable, responsive catalogue of every gallery component. Tapping a
/// card opens the interactive detail page (live knobs + code) with the
/// preview themed by the current appearance controls.
class ComponentsSection extends StatefulWidget {
  const ComponentsSection({required this.settings, super.key});

  final ShowcaseSettings settings;

  @override
  State<ComponentsSection> createState() => _ComponentsSectionState();
}

class _ComponentsSectionState extends State<ComponentsSection> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<GalleryEntry> get _results {
    final q = _query.trim().toLowerCase();
    final entries = [...kGalleryEntries]..sort((a, b) {
        final c = a.category.index.compareTo(b.category.index);
        return c != 0 ? c : a.name.compareTo(b.name);
      });
    if (q.isEmpty) return entries;
    return entries
        .where((e) =>
            e.name.toLowerCase().contains(q) ||
            e.description.toLowerCase().contains(q) ||
            e.category.label.toLowerCase().contains(q))
        .toList();
  }

  void _open(GalleryEntry entry) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ThemedContent(
          settings: widget.settings,
          child: ComponentDetailPage(entry: entry),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final results = _results;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final cols = w >= 1180
            ? 3
            : w >= 760
                ? 2
                : 1;
        final pad = w >= 760 ? BankTokens.space6 : BankTokens.space4;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(pad, BankTokens.space6, pad, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Components',
                      style: BankTokens.headlineSmall.copyWith(
                        color: theme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: BankTokens.space1),
                    Text(
                      '${kGalleryEntries.length} components with live, editable '
                      'controls and copy-paste code — part of the 147+ in the '
                      'kit.',
                      style: BankTokens.bodyMedium
                          .copyWith(color: theme.onSurfaceVariant),
                    ),
                    const SizedBox(height: BankTokens.space4),
                    _SearchField(
                      controller: _controller,
                      count: kGalleryEntries.length,
                      onChanged: (v) => setState(() => _query = v),
                      onClear: () {
                        _controller.clear();
                        setState(() => _query = '');
                      },
                    ),
                    const SizedBox(height: BankTokens.space4),
                  ],
                ),
              ),
            ),
            if (results.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(BankTokens.space10),
                  child: Center(
                    child: Text(
                      'No components match “$_query”.',
                      style: BankTokens.bodyLarge
                          .copyWith(color: theme.onSurfaceVariant),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(pad, 0, pad, BankTokens.space8),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    mainAxisSpacing: BankTokens.space4,
                    crossAxisSpacing: BankTokens.space4,
                    mainAxisExtent: 132,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _ComponentCard(
                      entry: results[i],
                      onTap: () => _open(results[i]),
                    ),
                    childCount: results.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.count,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final int count;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: BankTokens.bodyLarge.copyWith(color: theme.onSurface),
        decoration: InputDecoration(
          hintText: 'Search $count components…',
          hintStyle:
              BankTokens.bodyLarge.copyWith(color: theme.onSurfaceVariant),
          prefixIcon: Icon(Icons.search_rounded, color: theme.onSurfaceVariant),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon:
                      Icon(Icons.close_rounded, color: theme.onSurfaceVariant),
                  onPressed: onClear,
                ),
          filled: true,
          fillColor: theme.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: BankTokens.space4,
            vertical: BankTokens.space4,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(BankTokens.radiusMedium),
            borderSide: BorderSide(color: theme.outline.withValues(alpha: 0.7)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(BankTokens.radiusMedium),
            borderSide: BorderSide(color: theme.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _ComponentCard extends StatelessWidget {
  const _ComponentCard({required this.entry, required this.onTap});

  final GalleryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    return Material(
      color: theme.surface,
      borderRadius: BorderRadius.circular(BankTokens.radiusLarge),
      child: InkWell(
        borderRadius: BorderRadius.circular(BankTokens.radiusLarge),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(BankTokens.space4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(BankTokens.radiusLarge),
            border: Border.all(color: theme.outline.withValues(alpha: 0.6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(BankTokens.radiusSmall),
                    ),
                    child: Icon(entry.category.icon,
                        size: 20, color: theme.primary),
                  ),
                  const SizedBox(width: BankTokens.space3),
                  Expanded(
                    child: Text(
                      entry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BankTokens.bodyLarge.copyWith(
                        color: theme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_outward_rounded,
                      size: 16, color: theme.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: BankTokens.space3),
              Expanded(
                child: Text(
                  entry.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: BankTokens.bodySmall.copyWith(
                    color: theme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: BankTokens.space2),
              Text(
                entry.category.label,
                style: BankTokens.labelSmall.copyWith(
                  color: theme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
