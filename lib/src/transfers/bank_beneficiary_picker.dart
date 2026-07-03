import 'package:flutter/material.dart';

import '../../src/common/bank_icon_spec.dart';
import '../../src/models/models.dart';
import '../../src/scope/bank_ui_scope.dart';
import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

// ---------------------------------------------------------------------------
// BankBeneficiaryPicker
// ---------------------------------------------------------------------------

/// Saved-beneficiaries list with search and an add-new entry point.
///
/// Displays a search bar at the top, followed by an optional "Add new
/// beneficiary" row (when [onAddNew] is non-null), then a filtered list of
/// [BankBeneficiary] rows. The selected beneficiary is highlighted with a
/// trailing checkmark.
///
/// Provide [itemBuilder] to completely replace the default row layout for each
/// beneficiary while retaining the built-in search, filtering, and
/// add-new logic.
///
/// ```dart
/// BankBeneficiaryPicker(
///   beneficiaries: savedBeneficiaries,
///   selectedId: _selectedId,
///   onSelected: (b) => setState(() => _selected = b),
///   onAddNew: () => Navigator.push(context, AddBeneficiaryRoute()),
/// )
/// ```
class BankBeneficiaryPicker extends StatefulWidget {
  /// Full list of beneficiaries to display before any search query is applied.
  final List<BankBeneficiary> beneficiaries;

  /// The [BankBeneficiary.id] of the currently selected beneficiary, or
  /// `null` if none is selected.
  final String? selectedId;

  /// Called when the user taps a beneficiary row.
  final ValueChanged<BankBeneficiary> onSelected;

  /// When non-null, an "Add new beneficiary" row is shown at the top of the
  /// list. The host app is responsible for the add-new navigation flow.
  final VoidCallback? onAddNew;

  /// Optional builder for individual beneficiary rows. When provided, it
  /// completely replaces the default row for each [BankBeneficiary]. The
  /// `isSelected` flag indicates whether this beneficiary is the currently
  /// selected one.
  final Widget Function(BuildContext, BankBeneficiary, bool isSelected)?
      itemBuilder;

  const BankBeneficiaryPicker({
    required this.beneficiaries,
    required this.onSelected,
    super.key,
    this.selectedId,
    this.onAddNew,
    this.itemBuilder,
  });

  @override
  State<BankBeneficiaryPicker> createState() => _BankBeneficiaryPickerState();
}

class _BankBeneficiaryPickerState extends State<BankBeneficiaryPicker> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final q = _searchController.text.trim().toLowerCase();
      if (q != _query) {
        setState(() => _query = q);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<BankBeneficiary> get _filtered {
    if (_query.isEmpty) return widget.beneficiaries;
    return widget.beneficiaries
        .where((b) => b.name.toLowerCase().contains(_query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);
    final filtered = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ----------------------------------------------------------------
        // Search bar
        // ----------------------------------------------------------------
        Padding(
          padding: const EdgeInsets.fromLTRB(
            BankTokens.space4,
            BankTokens.space3,
            BankTokens.space4,
            BankTokens.space2,
          ),
          child: Semantics(
            label: 'Search beneficiaries',
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              style: BankTokens.bodyLarge.copyWith(color: bankTheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Search beneficiaries',
                hintStyle: BankTokens.bodyLarge.copyWith(
                  color: bankTheme.onSurfaceVariant,
                ),
                prefixIcon: Icon(
                  BankIcons.search,
                  color: bankTheme.onSurfaceVariant,
                  size: 20,
                ),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          BankIcons.close,
                          color: bankTheme.onSurfaceVariant,
                          size: 20,
                        ),
                        tooltip: 'Clear search',
                        onPressed: _searchController.clear,
                      )
                    : null,
                filled: true,
                fillColor: bankTheme.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: BankTokens.space4,
                  vertical: BankTokens.space3,
                ),
                border: OutlineInputBorder(
                  borderRadius: bankTheme.chipRadius,
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: bankTheme.chipRadius,
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: bankTheme.chipRadius,
                  borderSide: BorderSide(
                    color: bankTheme.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
        // ----------------------------------------------------------------
        // List
        // ----------------------------------------------------------------
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: BankTokens.space4),
            itemCount: filtered.length + (widget.onAddNew != null ? 1 : 0),
            itemBuilder: (context, index) {
              // "Add new" row pinned at top of list
              if (widget.onAddNew != null && index == 0) {
                return _AddNewRow(
                  bankTheme: bankTheme,
                  onTap: widget.onAddNew!,
                );
              }

              final beneficiaryIndex =
                  widget.onAddNew != null ? index - 1 : index;
              final beneficiary = filtered[beneficiaryIndex];
              final isSelected = beneficiary.id == widget.selectedId;

              if (widget.itemBuilder != null) {
                return widget.itemBuilder!(context, beneficiary, isSelected);
              }

              return _BeneficiaryRow(
                beneficiary: beneficiary,
                isSelected: isSelected,
                bankTheme: bankTheme,
                onTap: () => widget.onSelected(beneficiary),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Add-new row
// ---------------------------------------------------------------------------

class _AddNewRow extends StatelessWidget {
  const _AddNewRow({required this.bankTheme, required this.onTap});

  final BankThemeData bankTheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Add new beneficiary',
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BankTokens.space4,
              vertical: BankTokens.space3,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: bankTheme.primary,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    BankIcons.add,
                    color: bankTheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: BankTokens.space3),
                Text(
                  'Add new beneficiary',
                  style: BankTokens.bodyLarge.copyWith(
                    color: bankTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Beneficiary row
// ---------------------------------------------------------------------------

class _BeneficiaryRow extends StatelessWidget {
  const _BeneficiaryRow({
    required this.beneficiary,
    required this.isSelected,
    required this.bankTheme,
    required this.onTap,
  });

  final BankBeneficiary beneficiary;
  final bool isSelected;
  final BankThemeData bankTheme;
  final VoidCallback onTap;

  String get _initials {
    final parts = beneficiary.name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '${beneficiary.name}, ${beneficiary.maskedAccount}'
          '${isSelected ? ', selected' : ''}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BankTokens.space4,
              vertical: BankTokens.space3,
            ),
            child: Row(
              children: [
                // Avatar
                _BeneficiaryAvatar(
                  avatarUrl: beneficiary.avatarUrl,
                  initials: _initials,
                  bankTheme: bankTheme,
                ),
                const SizedBox(width: BankTokens.space3),
                // Name + account
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              beneficiary.name,
                              style: BankTokens.bodyLarge.copyWith(
                                color: bankTheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (beneficiary.isVerified) ...[
                            const SizedBox(width: BankTokens.space1),
                            Icon(
                              Icons.verified_outlined,
                              size: 14,
                              color: bankTheme.primary,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: BankTokens.space1),
                      Text(
                        [
                          beneficiary.maskedAccount,
                          if (beneficiary.bankName != null)
                            beneficiary.bankName!,
                        ].join(' · '),
                        style: BankTokens.bodySmall.copyWith(
                          color: bankTheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: BankTokens.space3),
                // Checkmark or spacer
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: bankTheme.primary,
                    size: 22,
                  )
                else
                  const SizedBox(width: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Avatar helper
// ---------------------------------------------------------------------------

class _BeneficiaryAvatar extends StatelessWidget {
  const _BeneficiaryAvatar({
    required this.avatarUrl,
    required this.initials,
    required this.bankTheme,
  });

  final String? avatarUrl;
  final String initials;
  final BankThemeData bankTheme;

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: BankUiScope.imageProviderFor(context, avatarUrl!),
        backgroundColor: bankTheme.surfaceVariant,
      );
    }

    return CircleAvatar(
      radius: 22,
      backgroundColor: bankTheme.primary.withValues(alpha: 0.15),
      child: Text(
        initials,
        style: BankTokens.labelMedium.copyWith(color: bankTheme.primary),
      ),
    );
  }
}
