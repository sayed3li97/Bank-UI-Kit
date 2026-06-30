import 'package:flutter/material.dart';

/// Icon specification for the Bank UI Kit icon set.
///
/// All icons in the package follow these rules:
/// - Stroke width: 1.5px at 24x24 logical pixels
/// - Corner rounding: 2px radius on all strokes
/// - Style: outline (not filled) for navigation and category icons;
///   filled for status badges and confirmations
/// - The [BankIcons] class maps semantic names to [IconData] from
///   Material Symbols (outlined weight), providing a coherent set
///   without shipping a custom font.
abstract final class BankIcons {
  // Accounts
  static const IconData account = Icons.account_balance_wallet_outlined;
  static const IconData accountSavings = Icons.savings_outlined;
  static const IconData accountJoint = Icons.group_outlined;
  static const IconData accountBusiness = Icons.business_center_outlined;
  static const IconData accountCrypto = Icons.currency_bitcoin_outlined;

  // Transactions & categories
  static const IconData groceries = Icons.local_grocery_store_outlined;
  static const IconData dining = Icons.restaurant_outlined;
  static const IconData transport = Icons.directions_bus_outlined;
  static const IconData entertainment = Icons.movie_outlined;
  static const IconData utilities = Icons.bolt_outlined;
  static const IconData health = Icons.local_hospital_outlined;
  static const IconData shopping = Icons.shopping_bag_outlined;
  static const IconData travel = Icons.flight_outlined;
  static const IconData education = Icons.school_outlined;
  static const IconData subscription = Icons.subscriptions_outlined;
  static const IconData transfer = Icons.swap_horiz;
  static const IconData income = Icons.arrow_downward;
  static const IconData investment = Icons.show_chart;
  static const IconData creditPayment = Icons.credit_card_outlined;
  static const IconData other = Icons.more_horiz;

  // Actions
  static const IconData send = Icons.send_outlined;
  static const IconData receive = Icons.download_outlined;
  static const IconData add = Icons.add;
  static const IconData remove = Icons.remove;
  static const IconData scan = Icons.qr_code_scanner_outlined;
  static const IconData schedule = Icons.schedule_outlined;
  static const IconData repeat = Icons.repeat;
  static const IconData share = Icons.share_outlined;
  static const IconData dispute = Icons.flag_outlined;
  static const IconData filter = Icons.tune_outlined;
  static const IconData sort = Icons.sort;
  static const IconData search = Icons.search;
  static const IconData close = Icons.close;
  static const IconData back = Icons.arrow_back;
  static const IconData forward = Icons.arrow_forward;
  static const IconData expand = Icons.expand_more;
  static const IconData collapse = Icons.expand_less;
  static const IconData info = Icons.info_outline;
  static const IconData warning = Icons.warning_amber_outlined;
  static const IconData error = Icons.error_outline;
  static const IconData success = Icons.check_circle_outline;
  static const IconData copy = Icons.copy_outlined;
  static const IconData edit = Icons.edit_outlined;
  static const IconData delete = Icons.delete_outline;

  // Security
  static const IconData biometric = Icons.fingerprint;
  static const IconData faceId = Icons.face_retouching_natural;
  static const IconData lock = Icons.lock_outline;
  static const IconData unlock = Icons.lock_open_outlined;
  static const IconData shield = Icons.shield_outlined;
  static const IconData visibility = Icons.visibility_outlined;
  static const IconData visibilityOff = Icons.visibility_off_outlined;

  // Cards
  static const IconData card = Icons.credit_card_outlined;
  static const IconData cardFreeze = Icons.ac_unit_outlined;
  static const IconData cardOnline = Icons.wifi_outlined;
  static const IconData cardContactless = Icons.contactless_outlined;
  static const IconData cardInternational = Icons.public_outlined;
  static const IconData cardLimit = Icons.speed_outlined;

  // Investing
  static const IconData chartLine = Icons.show_chart;
  static const IconData chartBar = Icons.bar_chart;
  static const IconData portfolio = Icons.pie_chart_outline;
  static const IconData trending = Icons.trending_up;
  static const IconData trendingDown = Icons.trending_down;
  static const IconData watchlist = Icons.star_outline;
  static const IconData watchlistFilled = Icons.star;

  // Pots & goals
  static const IconData pot = Icons.savings_outlined;
  static const IconData goal = Icons.flag_outlined;
  static const IconData roundUp = Icons.arrow_circle_up_outlined;
  static const IconData invite = Icons.person_add_alt_1_outlined;

  // Notifications
  static const IconData notification = Icons.notifications_outlined;
  static const IconData notificationUnread = Icons.notifications_active_outlined;
  static const IconData fraud = Icons.gpp_bad_outlined;

  // Misc
  static const IconData calendar = Icons.calendar_today_outlined;
  static const IconData currency = Icons.currency_exchange;
  static const IconData percent = Icons.percent;
  static const IconData location = Icons.location_on_outlined;
  static const IconData receipt = Icons.receipt_outlined;
  static const IconData gift = Icons.card_giftcard_outlined;
  static const IconData referral = Icons.group_add_outlined;
  static const IconData plan = Icons.workspace_premium_outlined;

  // Returns the icon for a given [TransactionCategory] by name
  static IconData forCategoryName(String name) => switch (name) {
    'groceries' => groceries,
    'dining' => dining,
    'transport' => transport,
    'entertainment' => entertainment,
    'utilities' => utilities,
    'health' => health,
    'shopping' => shopping,
    'travel' => travel,
    'education' => education,
    'subscription' => subscription,
    'transfer' => transfer,
    'income' => income,
    'investment' => investment,
    'creditPayment' => creditPayment,
    _ => other,
  };
}
