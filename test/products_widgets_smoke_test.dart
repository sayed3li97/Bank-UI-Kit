import 'package:bank_ui_kit/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => BankUiScope(
      child: MaterialApp(
        theme: BankPreset.studio.apply(ThemeData.light(useMaterial3: true)),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

void main() {
  testWidgets('BankProductCard renders name, rate, and CTA', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _host(
        BankProductCard(
          title: 'Auto Finance',
          subtitle: 'Drive away sooner',
          rate: const BankProductRate(
            value: '5.9%',
            label: 'from APR',
            caption: 'Representative',
          ),
          features: const ['No early settlement fee', 'Decision in minutes'],
          badges: const [
            BankProductBadge(
              label: 'Featured',
              tone: BankProductBadgeTone.promo,
            ),
          ],
          onTap: () => tapped = true,
        ),
      ),
    );
    expect(find.text('Auto Finance'), findsOneWidget);
    expect(find.text('5.9%'), findsOneWidget);
    await tester.tap(find.text('View details'));
    expect(tapped, isTrue);
  });

  testWidgets('BankProductCategoryTile fires onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _host(
        BankProductCategoryTile(
          icon: Icons.directions_car_outlined,
          title: 'Loans',
          subtitle: 'Auto, personal, home',
          count: 6,
          onTap: () => tapped = true,
        ),
      ),
    );
    expect(find.text('Loans'), findsOneWidget);
    await tester.tap(find.text('Loans'));
    expect(tapped, isTrue);
  });

  testWidgets('BankEligibilityResultCard shows outcome and no-impact chip',
      (tester) async {
    await tester.pumpWidget(
      _host(
        BankEligibilityResultCard(
          outcome: BankEligibilityOutcome.likely,
          estimatedRate: '5.9% to 8.4%',
          maxAmount: Money.fromDouble(25000, 'GBP'),
          onApply: () {},
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(BankEligibilityResultCard), findsOneWidget);
  });

  testWidgets('BankOfferSummaryCard renders payment and accept',
      (tester) async {
    var accepted = false;
    await tester.pumpWidget(
      _host(
        BankOfferSummaryCard(
          payment: Money.fromDouble(432.10, 'GBP'),
          amount: Money.fromDouble(25000, 'GBP'),
          rate: '6.4%',
          term: '60 months',
          totalRepayable: Money.fromDouble(25926, 'GBP'),
          representativeExample: 'Representative 6.4% APR.',
          onAccept: () => accepted = true,
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(FilledButton).first);
    expect(accepted, isTrue);
  });

  testWidgets('BankRatioGauge renders percentage and bands', (tester) async {
    await tester.pumpWidget(
      _host(
        const BankRatioGauge(
          value: 0.82,
          title: 'Loan to value',
          thresholdLabel: 'Max 85%',
          threshold: 0.85,
          bands: [
            BankRatioBand(upTo: 0.7, tone: BankRatioTone.positive),
            BankRatioBand(upTo: 0.85, tone: BankRatioTone.warning),
            BankRatioBand(upTo: 1, tone: BankRatioTone.danger),
          ],
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Loan to value'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('BankDisclosureConsentSheet gates continue on required consent',
      (tester) async {
    await tester.pumpWidget(
      _host(
        BankDisclosureConsentSheet(
          disclosures: const [
            BankDisclosure(
              title: 'Representative example',
              body: 'Borrowing 25,000 GBP over 60 months at 6.4% APR.',
            ),
          ],
          consents: const [
            BankConsentItem(
              id: 'terms',
              label: 'I agree to the loan agreement.',
              required: true,
            ),
          ],
          onChanged: (_) {},
          onAgree: () {},
        ),
      ),
    );
    expect(find.text('Representative example'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('BankESignaturePad renders and enables on typed name',
      (tester) async {
    await tester.pumpWidget(
      _host(
        BankESignaturePad(
          onSigned: (_) {},
          now: () => DateTime(2026, 7, 4, 10),
        ),
      ),
    );
    expect(find.byType(BankESignaturePad), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('BankApplicationController advances and tracks progress', () {
    final c = BankApplicationController(
      steps: const [
        BankApplicationStep(id: 'eligibility', title: 'Eligibility'),
        BankApplicationStep(id: 'offer', title: 'Offer'),
        BankApplicationStep(id: 'sign', title: 'Sign'),
      ],
    );
    expect(c.isFirstStep, isTrue);
    expect(c.currentStep.id, 'eligibility');
    c.setStepValid('eligibility', true);
    expect(c.canAdvance, isTrue);
    c.next();
    expect(c.currentStep.id, 'offer');
    c.setStatus(BankApplicationStatus.submitted);
    expect(c.status, BankApplicationStatus.submitted);
    c.back();
    expect(c.currentStep.id, 'eligibility');
  });
}
