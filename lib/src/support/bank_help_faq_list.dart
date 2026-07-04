import 'package:flutter/material.dart';

import '../common/bank_icon_spec.dart';
import '../common/bank_text_field.dart';
import '../states/bank_empty_state_view.dart';
import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';

/// One entry in a [BankHelpFaqList].
class BankFaqItem {
  const BankFaqItem({
    required this.id,
    required this.question,
    required this.answer,
    this.richAnswer,
    this.keywords = const <String>[],
  });

  final String id;
  final String question;

  /// Plain-text answer; ignored when [richAnswer] is provided.
  final String answer;

  /// Optional rich answer widget (links, lists, imagery slots).
  final Widget? richAnswer;

  /// Extra search terms beyond the question text.
  final List<String> keywords;
}

/// Searchable FAQ accordion for the support hub.
///
/// A pinned search field filters by question and keywords with the
/// matching substrings highlighted; items expand one at a time; expanded
/// answers end with a was-this-helpful vote; empty results fall back to
/// `BankEmptyStateView` with a contact-support CTA.
///
/// ```dart
/// BankHelpFaqList(
///   items: faqs,
///   onContactSupport: _openChat,
///   onFeedback: (id, helpful) => analytics.faqVote(id, helpful),
/// )
/// ```
class BankHelpFaqList extends StatefulWidget {
  const BankHelpFaqList({
    required this.items,
    super.key,
    this.searchable = true,
    this.searchHint = 'Search help topics',
    this.onContactSupport,
    this.contactLabel = 'Contact support',
    this.onFeedback,
    this.helpfulPrompt = 'Was this helpful?',
    this.thanksLabel = 'Thanks for the feedback',
    this.emptyTitle = 'No results',
    this.emptyBody = 'Try a different search term, or reach out directly.',
    this.accentColor,
    this.dividerColor,
    this.questionStyle,
    this.answerStyle,
    this.highlightStyle,
    this.searchIcon,
    this.clearIcon,
    this.expandIcon,
    this.contactIcon,
    this.chevronIcon,
    this.thumbUpIcon,
    this.thumbDownIcon,
    this.animationDuration,
    this.animationCurve,
  });

  final List<BankFaqItem> items;

  final bool searchable;
  final String searchHint;

  /// Shows the persistent contact row and the empty-state CTA when set.
  final VoidCallback? onContactSupport;

  final String contactLabel;

  /// Fired after a helpful / not-helpful vote on an expanded answer.
  final void Function(String id, bool helpful)? onFeedback;

  final String helpfulPrompt;
  final String thanksLabel;
  final String emptyTitle;
  final String emptyBody;

  /// Overrides the accent used for search-match highlights and the
  /// contact-row icon. Defaults to the theme primary.
  final Color? accentColor;

  /// Overrides the divider colour between items. Defaults to the theme
  /// outline.
  final Color? dividerColor;

  /// Merged over the question style (BankTokens.bodyLarge in onSurface).
  final TextStyle? questionStyle;

  /// Merged over the answer style (BankTokens.bodyMedium in
  /// onSurfaceVariant).
  final TextStyle? answerStyle;

  /// Merged over the search-match highlight style (accent, w700).
  final TextStyle? highlightStyle;

  /// Glyph inside the search field. Defaults to [BankIcons.search].
  final IconData? searchIcon;

  /// Glyph of the clear-search affordance. Defaults to
  /// [BankIcons.close].
  final IconData? clearIcon;

  /// Expand chevron on each item. Defaults to [BankIcons.expand].
  final IconData? expandIcon;

  /// Leading glyph of the contact-support row. Defaults to
  /// [Icons.forum_outlined].
  final IconData? contactIcon;

  /// Trailing glyph of the contact-support row. Defaults to
  /// [Icons.chevron_right].
  final IconData? chevronIcon;

  /// Helpful-vote glyph. Defaults to [Icons.thumb_up_outlined].
  final IconData? thumbUpIcon;

  /// Not-helpful-vote glyph. Defaults to [Icons.thumb_down_outlined].
  final IconData? thumbDownIcon;

  /// Overrides the expand/collapse animation duration. Defaults to
  /// [BankTokens.durationBase] (chevron: [BankTokens.durationFast]).
  final Duration? animationDuration;

  /// Overrides the expand/collapse animation curve. Defaults to
  /// [BankTokens.curveStandard].
  final Curve? animationCurve;

  @override
  State<BankHelpFaqList> createState() => _BankHelpFaqListState();
}

class _BankHelpFaqListState extends State<BankHelpFaqList> {
  final TextEditingController _search = TextEditingController();
  String? _expandedId;
  final Set<String> _voted = <String>{};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<BankFaqItem> get _filtered {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return widget.items;
    return widget.items.where((item) {
      if (item.question.toLowerCase().contains(query)) return true;
      return item.keywords.any(
        (keyword) => keyword.toLowerCase().contains(query),
      );
    }).toList();
  }

  void _vote(BankFaqItem item, bool helpful) {
    setState(() => _voted.add(item.id));
    widget.onFeedback?.call(item.id, helpful);
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final results = _filtered;
    final query = _search.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.searchable)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              BankTokens.space4,
              BankTokens.space2,
              BankTokens.space4,
              BankTokens.space3,
            ),
            child: BankTextField(
              controller: _search,
              hint: widget.searchHint,
              prefixIcon: Icon(
                widget.searchIcon ?? BankIcons.search,
                size: 20,
                color: theme.onSurfaceVariant,
              ),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      icon: Icon(
                        widget.clearIcon ?? BankIcons.close,
                        size: 18,
                        color: theme.onSurfaceVariant,
                      ),
                      onPressed: () => setState(_search.clear),
                    ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        if (results.isEmpty)
          Padding(
            padding: const EdgeInsets.all(BankTokens.space6),
            child: BankEmptyStateView(
              title: widget.emptyTitle,
              subtitle: widget.emptyBody,
              actionLabel:
                  widget.onContactSupport == null ? null : widget.contactLabel,
              onAction: widget.onContactSupport,
            ),
          )
        else
          for (final item in results) ...[
            _FaqTile(
              item: item,
              expanded: _expandedId == item.id,
              highlight: query,
              voted: _voted.contains(item.id),
              helpfulPrompt: widget.helpfulPrompt,
              thanksLabel: widget.thanksLabel,
              theme: theme,
              host: widget,
              onToggle: () => setState(
                () => _expandedId = _expandedId == item.id ? null : item.id,
              ),
              onVote: (helpful) => _vote(item, helpful),
            ),
            Divider(
              height: 1,
              color: widget.dividerColor ?? theme.outline,
              indent: BankTokens.space4,
              endIndent: BankTokens.space4,
            ),
          ],
        if (widget.onContactSupport != null)
          InkWell(
            onTap: widget.onContactSupport,
            child: Padding(
              padding: const EdgeInsets.all(BankTokens.space4),
              child: Row(
                children: [
                  Icon(
                    widget.contactIcon ?? Icons.forum_outlined,
                    size: 20,
                    color: widget.accentColor ?? theme.primary,
                  ),
                  const SizedBox(width: BankTokens.space3),
                  Expanded(
                    child: Text(
                      widget.contactLabel,
                      style:
                          BankTokens.bodyLarge.copyWith(color: theme.onSurface),
                    ),
                  ),
                  Icon(
                    widget.chevronIcon ?? Icons.chevron_right,
                    color: theme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.item,
    required this.expanded,
    required this.highlight,
    required this.voted,
    required this.helpfulPrompt,
    required this.thanksLabel,
    required this.theme,
    required this.host,
    required this.onToggle,
    required this.onVote,
  });

  final BankFaqItem item;
  final bool expanded;
  final String highlight;
  final bool voted;
  final String helpfulPrompt;
  final String thanksLabel;
  final BankThemeData theme;
  final BankHelpFaqList host;
  final VoidCallback onToggle;
  final ValueChanged<bool> onVote;

  InlineSpan _highlighted(String text) {
    final base = BankTokens.bodyLarge
        .copyWith(color: theme.onSurface)
        .merge(host.questionStyle);
    if (highlight.isEmpty) return TextSpan(text: text, style: base);
    final lower = text.toLowerCase();
    final query = highlight.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;
    while (true) {
      final index = lower.indexOf(query, start);
      if (index < 0) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: TextStyle(
            color: host.accentColor ?? theme.primary,
            fontWeight: FontWeight.w700,
          ).merge(host.highlightStyle),
        ),
      );
      start = index + query.length;
    }
    return TextSpan(style: base, children: spans);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      expanded: expanded,
      label: item.question,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: BankTokens.space4,
                  vertical: BankTokens.space3,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text.rich(
                        _highlighted(item.question),
                      ),
                    ),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration:
                          host.animationDuration ?? BankTokens.durationFast,
                      child: Icon(
                        host.expandIcon ?? BankIcons.expand,
                        color: theme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: host.animationDuration ?? BankTokens.durationBase,
            curve: host.animationCurve ?? BankTokens.curveStandard,
            alignment: Alignment.topCenter,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(
                      BankTokens.space4,
                      0,
                      BankTokens.space4,
                      BankTokens.space3,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        item.richAnswer ??
                            Text(
                              item.answer,
                              style: BankTokens.bodyMedium
                                  .copyWith(color: theme.onSurfaceVariant)
                                  .merge(host.answerStyle),
                            ),
                        const SizedBox(height: BankTokens.space3),
                        if (voted)
                          Text(
                            thanksLabel,
                            style: BankTokens.labelMedium
                                .copyWith(color: theme.positiveBalance),
                          )
                        else
                          Row(
                            children: [
                              Text(
                                helpfulPrompt,
                                style: BankTokens.labelMedium.copyWith(
                                  color: theme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: BankTokens.space2),
                              IconButton(
                                onPressed: () => onVote(true),
                                iconSize: 18,
                                icon: Icon(
                                  host.thumbUpIcon ?? Icons.thumb_up_outlined,
                                  color: theme.onSurfaceVariant,
                                ),
                              ),
                              IconButton(
                                onPressed: () => onVote(false),
                                iconSize: 18,
                                icon: Icon(
                                  host.thumbDownIcon ??
                                      Icons.thumb_down_outlined,
                                  color: theme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
