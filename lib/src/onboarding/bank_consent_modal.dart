import 'package:flutter/material.dart';

import '../../src/theme/bank_theme_data.dart';
import '../../src/theme/tokens.dart';

// ---------------------------------------------------------------------------
// Public widget
// ---------------------------------------------------------------------------

/// Scrollable terms-acknowledgement modal.
///
/// The primary "Accept" action is gated behind two conditions:
///   1. The user has scrolled to the bottom of the terms content.
///   2. The user has explicitly checked the acknowledgement checkbox.
///
/// Use [BankConsentModal.show] to display this as a [Dialog].
class BankConsentModal extends StatefulWidget {
  /// Modal title, shown in `headlineSmall`.
  final String title;

  /// Plain-text terms content. Used when [richTermsContent] is `null`.
  final String termsContent;

  /// If provided, used instead of [termsContent] — allows the host app to
  /// pass rich widgets (e.g. rendered Markdown).
  final Widget? richTermsContent;

  /// Checkbox label. Disabled until the user has scrolled to the bottom.
  final String checkboxLabel;

  /// Label for the accept button.
  final String acceptLabel;

  /// Label for the decline button.
  final String declineLabel;

  /// Called when the user taps the Accept button (requires checkbox checked).
  final VoidCallback onAccept;

  /// Called when the user taps the Decline button.
  final VoidCallback onDecline;

  const BankConsentModal({
    required this.title,
    required this.termsContent,
    required this.onAccept,
    required this.onDecline,
    super.key,
    this.richTermsContent,
    this.checkboxLabel = 'I have read and agree to the terms above',
    this.acceptLabel = 'Accept',
    this.declineLabel = 'Decline',
  });

  // ---------------------------------------------------------------------------
  // Convenience factory
  // ---------------------------------------------------------------------------

  /// Shows [BankConsentModal] in a [Dialog] and returns `true` if accepted,
  /// `false` if declined, or `null` if dismissed without an action.
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String termsContent,
    required VoidCallback onAccept,
    required VoidCallback onDecline,
    Widget? richContent,
  }) =>
      showDialog<bool>(
        context: context,
        builder: (_) => Dialog(
          child: BankConsentModal(
            title: title,
            termsContent: termsContent,
            richTermsContent: richContent,
            onAccept: onAccept,
            onDecline: onDecline,
          ),
        ),
      );

  @override
  State<BankConsentModal> createState() => _BankConsentModalState();
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class _BankConsentModalState extends State<BankConsentModal> {
  final ScrollController _scrollController = ScrollController();

  bool _hasScrolledToBottom = false;
  bool _isChecked = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // If content is very short it may not need scrolling.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkIfAtBottom());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() => _checkIfAtBottom();

  void _checkIfAtBottom() {
    if (!mounted) return;
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    // Treat "within 16 px of the bottom" as "at the bottom" for usability.
    if (pos.pixels >= pos.maxScrollExtent - 16) {
      if (!_hasScrolledToBottom) {
        setState(() => _hasScrolledToBottom = true);
      }
    }
  }

  void _onCheckboxChanged(bool? value) {
    if (!_hasScrolledToBottom) return;
    setState(() => _isChecked = value ?? false);
  }

  bool get _acceptEnabled => _hasScrolledToBottom && _isChecked;

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankThemeData.of(context);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 560,
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: ClipRRect(
        borderRadius: bankTheme.cardRadius,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Title bar ──
            _TitleBar(title: widget.title, bankTheme: bankTheme),

            // ── Scrollable terms body ──
            Flexible(
              child: _TermsScrollBody(
                scrollController: _scrollController,
                termsContent: widget.termsContent,
                richTermsContent: widget.richTermsContent,
                bankTheme: bankTheme,
              ),
            ),

            // ── Scroll-to-bottom hint ──
            _ScrollHint(
              hasScrolledToBottom: _hasScrolledToBottom,
              bankTheme: bankTheme,
            ),

            const Divider(height: 1),

            // ── Checkbox row ──
            _CheckboxRow(
              label: widget.checkboxLabel,
              checked: _isChecked,
              enabled: _hasScrolledToBottom,
              onChanged: _onCheckboxChanged,
              bankTheme: bankTheme,
            ),

            const Divider(height: 1),

            // ── Action buttons ──
            _ActionButtons(
              acceptLabel: widget.acceptLabel,
              declineLabel: widget.declineLabel,
              acceptEnabled: _acceptEnabled,
              onAccept: widget.onAccept,
              onDecline: widget.onDecline,
              bankTheme: bankTheme,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _TitleBar extends StatelessWidget {
  const _TitleBar({required this.title, required this.bankTheme});

  final String title;
  final BankThemeData bankTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        BankTokens.space6,
        BankTokens.space5,
        BankTokens.space6,
        BankTokens.space4,
      ),
      child: Text(
        title,
        style: BankTokens.headlineSmall.copyWith(color: bankTheme.onSurface),
      ),
    );
  }
}

class _TermsScrollBody extends StatelessWidget {
  const _TermsScrollBody({
    required this.scrollController,
    required this.termsContent,
    required this.richTermsContent,
    required this.bankTheme,
  });

  final ScrollController scrollController;
  final String termsContent;
  final Widget? richTermsContent;
  final BankThemeData bankTheme;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: BankTokens.space6,
        vertical: BankTokens.space4,
      ),
      child: richTermsContent ??
          Text(
            termsContent,
            style: BankTokens.bodyMedium.copyWith(
              color: bankTheme.onSurface,
              height: 1.6,
            ),
          ),
    );
  }
}

class _ScrollHint extends StatelessWidget {
  const _ScrollHint({
    required this.hasScrolledToBottom,
    required this.bankTheme,
  });

  final bool hasScrolledToBottom;
  final BankThemeData bankTheme;

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      duration: BankTokens.durationFast,
      firstChild: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: BankTokens.space6,
          vertical: BankTokens.space2,
        ),
        child: Row(
          children: [
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: bankTheme.onSurfaceVariant,
            ),
            const SizedBox(width: BankTokens.space1),
            Text(
              'Scroll to read all terms',
              style: BankTokens.bodySmall.copyWith(
                color: bankTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      secondChild: const SizedBox(height: BankTokens.space2),
      crossFadeState: hasScrolledToBottom
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
    );
  }
}

class _CheckboxRow extends StatelessWidget {
  const _CheckboxRow({
    required this.label,
    required this.checked,
    required this.enabled,
    required this.onChanged,
    required this.bankTheme,
  });

  final String label;
  final bool checked;
  final bool enabled;
  final ValueChanged<bool?> onChanged;
  final BankThemeData bankTheme;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: checked,
      enabled: enabled,
      label: label,
      child: InkWell(
        onTap: enabled ? () => onChanged(!checked) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BankTokens.space4,
            vertical: BankTokens.space3,
          ),
          child: Row(
            children: [
              Checkbox(
                value: checked,
                onChanged: enabled ? onChanged : null,
                activeColor: bankTheme.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: BankTokens.space3),
              Expanded(
                child: Text(
                  label,
                  style: BankTokens.bodySmall.copyWith(
                    color: enabled
                        ? bankTheme.onSurface
                        : bankTheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.acceptLabel,
    required this.declineLabel,
    required this.acceptEnabled,
    required this.onAccept,
    required this.onDecline,
    required this.bankTheme,
  });

  final String acceptLabel;
  final String declineLabel;
  final bool acceptEnabled;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final BankThemeData bankTheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(BankTokens.space4),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: declineLabel,
              child: OutlinedButton(
                onPressed: onDecline,
                style: OutlinedButton.styleFrom(
                  minimumSize:
                      const Size(double.infinity, BankTokens.minTapTarget),
                  shape: RoundedRectangleBorder(
                    borderRadius: bankTheme.buttonRadius,
                  ),
                ),
                child: Text(declineLabel),
              ),
            ),
          ),
          const SizedBox(width: BankTokens.space3),
          Expanded(
            child: Semantics(
              button: true,
              enabled: acceptEnabled,
              label: acceptLabel,
              child: FilledButton(
                onPressed: acceptEnabled ? onAccept : null,
                style: FilledButton.styleFrom(
                  minimumSize:
                      const Size(double.infinity, BankTokens.minTapTarget),
                  shape: RoundedRectangleBorder(
                    borderRadius: bankTheme.buttonRadius,
                  ),
                ),
                child: Text(acceptLabel),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
