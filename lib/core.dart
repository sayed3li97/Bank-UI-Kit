/// Core Bank UI Kit library.
///
/// Includes: accounts, transactions, transfers, cards, authentication,
/// security, states/feedback, shared scope, and design tokens.
///
/// ```dart
/// import 'package:bank_ui_kit/core.dart';
/// ```
library;

export 'src/accounts/bank_account_card.dart';
export 'src/accounts/bank_account_number_text.dart';
export 'src/accounts/bank_account_switcher.dart';
// Accounts & balances
export 'src/accounts/bank_balance_text.dart';
export 'src/accounts/bank_product_item_tile.dart';
export 'src/auth/bank_app_switcher_privacy_overlay.dart';
export 'src/auth/bank_biometric_prompt_button.dart';
export 'src/auth/bank_device_session_tile.dart';
export 'src/auth/bank_device_trust_banner.dart';
export 'src/auth/bank_otp_input.dart';
export 'src/auth/bank_pin_dots.dart';
// Authentication & security
export 'src/auth/bank_pin_keypad.dart';
export 'src/auth/bank_privacy_toggle.dart';
export 'src/auth/bank_sca_approval_sheet.dart';
export 'src/auth/bank_session_timeout_dialog.dart';
// Business banking
export 'src/business/bank_approval_request_tile.dart';
export 'src/business/bank_value_diff_row.dart';
export 'src/cards/bank_card_controls_panel.dart';
export 'src/cards/bank_card_pin_manager.dart';
// Cards
export 'src/cards/bank_flip_card.dart';
export 'src/cards/bank_horizontal_account_card.dart';
export 'src/cards/bank_physical_card_material_picker.dart';
export 'src/cards/bank_virtual_card_widget.dart';
export 'src/cards/bank_wallet_provisioning_button.dart';
// Common utilities & scaffolding
export 'src/common/bank_amount_input_field.dart';
export 'src/common/bank_app_bar.dart';
export 'src/common/bank_bottom_nav_bar.dart';
export 'src/common/bank_country_picker.dart';
export 'src/common/bank_emblem.dart';
export 'src/common/bank_icon_spec.dart';
export 'src/common/bank_masked_input_field.dart';
export 'src/common/bank_money_protection_banner.dart';
export 'src/common/bank_period_selector.dart';
export 'src/common/bank_phone_input_field.dart';
export 'src/common/bank_quick_actions_grid.dart';
export 'src/common/bank_shariah_badge.dart';
export 'src/common/bank_status_tracker.dart';
export 'src/common/bank_summary_stack.dart';
export 'src/common/bank_text_field.dart';
export 'src/common/money_formatter.dart';
export 'src/controllers/bank_income_sorter_controller.dart';
// Headless controllers
export 'src/controllers/bank_kyc_flow_controller.dart';
export 'src/controllers/bank_transfer_flow_controller.dart';
// Documents & statements
export 'src/documents/bank_statement_list_tile.dart';
export 'src/insights/bank_budget_gauge_widget.dart';
export 'src/insights/bank_cashflow_chart.dart';
export 'src/insights/bank_insight_card.dart';
export 'src/insights/bank_recurring_merchant_tile.dart';
// Insights
export 'src/insights/bank_spending_breakdown_chart.dart';
export 'src/models/bank_account.dart';
export 'src/models/bank_insight.dart';
export 'src/models/bank_notification.dart';
export 'src/models/beneficiary.dart';
export 'src/models/budget.dart';
// Data models
export 'src/models/money.dart';
export 'src/models/transaction.dart';
// Notifications
export 'src/notifications/bank_alert_preferences_panel.dart';
export 'src/notifications/bank_in_app_notification_center.dart';
export 'src/onboarding/bank_address_form.dart';
export 'src/onboarding/bank_async_verification_state.dart';
export 'src/onboarding/bank_consent_management_list.dart';
export 'src/onboarding/bank_consent_modal.dart';
export 'src/onboarding/bank_document_capture_overlay.dart';
export 'src/onboarding/bank_liveness_check_overlay.dart';
export 'src/onboarding/bank_onboarding_carousel.dart';
// Onboarding & KYC
export 'src/onboarding/bank_step_progress_indicator.dart';
// Payments & billing
export 'src/payments/bank_bill_pay_tile.dart';
export 'src/payments/bank_qr_pay_view.dart';
export 'src/payments/bank_standing_order_tile.dart';
export 'src/payments/bank_transfer_limit_manager.dart';
// Scope & strings
export 'src/scope/bank_ui_scope.dart';
export 'src/scope/bank_ui_strings.dart';
export 'src/states/bank_empty_state_view.dart';
export 'src/states/bank_error_state_view.dart';
export 'src/states/bank_fraud_alert_banner.dart';
// States & feedback
export 'src/states/bank_skeleton_loader.dart';
export 'src/states/bank_success_animation.dart';
export 'src/states/bank_toast_banner.dart';
// Support & servicing
export 'src/support/bank_help_faq_list.dart';
export 'src/theme/bank_theme_data.dart';
export 'src/theme/extensions.dart';
export 'src/theme/numeral_style.dart';
export 'src/theme/presets/bloom.dart';
export 'src/theme/presets/heritage.dart';
export 'src/theme/presets/studio.dart';
export 'src/theme/presets/voltage.dart';
// Theme & design system
export 'src/theme/tokens.dart';
export 'src/transactions/bank_receipt_view.dart';
export 'src/transactions/bank_transaction_category_split_sheet.dart';
export 'src/transactions/bank_transaction_cost_split_sheet.dart';
export 'src/transactions/bank_transaction_detail_sheet.dart';
export 'src/transactions/bank_transaction_filter_sheet.dart';
export 'src/transactions/bank_transaction_group_header.dart';
// Transactions
export 'src/transactions/bank_transaction_list_tile.dart';
// Transfers & payments
export 'src/transfers/bank_amount_keypad.dart';
export 'src/transfers/bank_beneficiary_picker.dart';
export 'src/transfers/bank_contact_payment_sheet.dart';
export 'src/transfers/bank_payment_request_card.dart';
export 'src/transfers/bank_scheduled_transfer_toggle.dart';
export 'src/transfers/bank_transaction_pin_sheet.dart';
export 'src/transfers/bank_transfer_result_screen.dart';
export 'src/transfers/bank_transfer_review_card.dart';
