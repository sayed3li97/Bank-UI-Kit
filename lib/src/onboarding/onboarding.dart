/// Onboarding & KYC widgets for the Bank UI Kit.
///
/// Import this barrel to access all onboarding-related widgets:
/// - [BankStepProgressIndicator]: numbered step progress indicator
/// - [BankDocumentCaptureOverlay]: camera frame guide for document capture
/// - [BankLivenessCheckOverlay]: face-guide overlay for liveness detection
/// - [BankAsyncVerificationState]: "under review" holding-state widget
/// - [BankConsentModal]: scrollable terms-acknowledgement modal
library;

import '../../bank_ui_kit.dart';
import '../../core.dart';
import 'onboarding.dart';

export 'bank_address_form.dart';
export 'bank_async_verification_state.dart';
export 'bank_consent_management_list.dart';
export 'bank_consent_modal.dart';
export 'bank_document_capture_overlay.dart';
export 'bank_liveness_check_overlay.dart';
export 'bank_onboarding_carousel.dart';
export 'bank_step_progress_indicator.dart';
