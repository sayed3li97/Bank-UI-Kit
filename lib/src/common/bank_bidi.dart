/// Wraps and unwraps machine identifiers in Unicode directional isolates:
/// account numbers, card PANs, sort codes, routing numbers, phone numbers
/// and dial codes.
///
/// ## Why an identifier needs an isolate
///
/// A grouped identifier is a run of digits with a neutral between each
/// group (`4532 1234 5678 9012`, `20-45-45`). UAX #9 rule N1 resolves a
/// neutral from the strong types on either side of it, and it counts a
/// European or Arabic number *as if it were right-to-left* for that
/// purpose. In a right-to-left paragraph both sides of the gap are
/// therefore R, the gap resolves to R, and rule L2 reverses the sequence:
/// the groups swap places and the customer reads `9012 5678 1234 4532`.
/// That is a wrong number on screen rather than a cosmetic mirror — the
/// digits inside each group keep their order, so nothing about the
/// rendering looks broken enough to distrust.
///
/// Wrapping the run in LEFT-TO-RIGHT ISOLATE … POP DIRECTIONAL ISOLATE
/// gives it its own left-to-right embedding: inside it, rule W7 retypes
/// the European digits as L (the isolate's start-of-sequence is L), every
/// gap resolves L with them, and the groups stay in the order they were
/// written — while the isolate is one neutral object to the paragraph
/// around it, which keeps its own direction and alignment.
///
/// Identifiers that *begin with a Latin letter* — an IBAN's country code,
/// a SWIFT/BIC, a `TXN-…` reference — are already anchored: the leading L
/// makes W7 retype the digits that follow, so the run never reverses.
/// The wrap is harmless there, and applying it unconditionally beats
/// sniffing the value for digits: the kit cannot know whether a
/// host-supplied `maskedNumber` is `•••• 4291` or `SA44 •••• 9021`, and a
/// rule with an exception is a rule that gets applied to the wrong string
/// eventually.
///
/// ## What an isolate cannot fix
///
/// Arabic-Indic digits (U+0660–U+0669) are bidi class AN, and W7 only
/// retypes EN. An identifier converted to that script reverses its groups
/// *inside* an isolate, and inside a left-to-right paragraph too. No
/// directional markup repairs it, which is why the kit renders identifiers
/// in Western digits regardless of the ambient `NumeralStyle`: an account
/// number is a machine token to be read back or typed into another form,
/// not a quantity to be localised.
///
/// ## Where not to use it
///
/// Never in text the user can edit or select — a `TextField` buffer or a
/// `SelectableText`. The controls would travel into the clipboard and be
/// pasted, invisible, into a payment form. Editable and selectable
/// identifiers are pinned with `textDirection: TextDirection.ltr`
/// instead, which fixes the order without touching the string; see
/// `BankMaskedInputField` for the established pattern.
///
/// Nor is it needed for a `Text` that already pins its own paragraph to
/// `TextDirection.ltr`: for a standalone identifier that is equivalent,
/// and the isolate would only add two letter-spaced advances to the
/// measured width (letter spacing is applied to the invisible characters
/// too). Reach for it when the identifier shares a paragraph with other
/// text, or when the paragraph's direction and alignment have to stay the
/// ambient ones.
abstract final class BankBidi {
  /// LEFT-TO-RIGHT ISOLATE (U+2066): opens a run whose internal order is
  /// the identifier's, not the paragraph's.
  static const String lri = '\u2066';

  /// POP DIRECTIONAL ISOLATE (U+2069): closes [lri].
  static const String pdi = '\u2069';

  /// Every invisible bidi control the kit strips before a value leaves for
  /// the clipboard: the marks (LRM/RLM), the deprecated embeddings and
  /// overrides (U+202A-U+202E), and the isolates (U+2066-U+2069).
  static final RegExp _formatting = RegExp(
    '[\u200E\u200F\u202A-\u202E\u2066-\u2069]',
  );

  /// [value] wrapped in an LRI … PDI isolate, so its groups render in the
  /// order they were written whichever direction the paragraph runs.
  ///
  /// An empty string comes back unchanged: an isolate around nothing is
  /// two characters of letter-spaced width for no reordering.
  static String isolate(String value) =>
      value.isEmpty ? value : '$lri$value$pdi';

  /// [value] with every invisible bidi control removed.
  ///
  /// This is the guard on the copy path: what is displayed may be
  /// isolated, what is copied never is. A control character pasted into a
  /// payment form is worse than the reordering the isolate prevents,
  /// because nothing about it is visible to the person pasting it.
  static String strip(String value) => value.replaceAll(_formatting, '');
}
