# Top 20 mobile banking apps: UI capability research

Research base for Bank UI Kit component coverage. Compiled July 2026.
Each app was profiled for its distinctive UI surfaces; the master list
below deduplicates every capability across all twenty. The kit's goal:
a team should be able to recreate any of these apps from kit
components.

## The twenty apps

| # | App | Market | Known for (UI surfaces) |
|---|-----|--------|--------------------------|
| 1 | Alipay | China | QR-first home, mini-app grid, Yu'ebao yield tile, Ant Forest gamification, Huabei BNPL sliders, Zhima credit dial, red packets, transit QR |
| 2 | WeBank | China | One-tap microloan slider with instant decision, sweep-to-yield balance, deposit rate ladders, chat-adjacent banking |
| 3 | Nubank | Brazil | Purple minimal design, card controls, user-dragged credit limit slider, fatura timeline, Caixinhas goal boxes, Pix hub, Street Mode security toggle |
| 4 | Chase | US/UK | Daily Snapshot insight stories, Credit Journey score + simulator, Chase Offers activation tiles, My Chase Plan installments, Autosave rules |
| 5 | Bank of America | US | Erica AI assistant with proactive insights, Life Plan goal canvas, Keep the Change round-ups, Security Center checklist, unified Merrill investing |
| 6 | Cash App | US | Numpad-first home, $Cashtag profiles, Boosts, card designer canvas, Bitcoin + stocks tabs, early paycheck |
| 7 | Venmo | US | Social payments feed with notes and likes, Groups settle-up, teen accounts, business profiles with QR kits |
| 8 | Chime | US | Get-paid-early hero banner, SpotMe overdraft meter, Credit Builder flow, fee-free ATM map, save-when-paid toggles |
| 9 | Revolut | Global | Multi-currency exchange screen, disposable virtual cards, Vaults + Group Vaults, analytics rings, subscriptions manager, plan-tier upsells, eSIM tiles |
| 10 | Monzo | UK | Feed-first timeline, Pots with salary sorter, Trends predicted balance, gambling block, Call Status anti-fraud screen, Year in Monzo |
| 11 | BBVA | Spain/global | Financial health hub, expected-expense cashflow forecast, One View aggregation, one-click pre-approved loans, dynamic CVV |
| 12 | Toss | Korea | Single scrollable feed, 1-tap transfers, gamified rewards (step cash, quizzes), hidden-money discovery, loan comparison marketplace |
| 13 | Kakao Bank | Korea | Character branding, 26-week savings challenge with stamps, Moim group accounts, Safe Box hidden balance, friend-list transfers |
| 14 | Paytm | India | Bill-pay supermarket grid, UPI Scan & Pay front and center, UPI Lite pinless, digital gold, Postpaid BNPL, cashback offers center |
| 15 | Sber | Russia | Stories carousel, Salute assistant, selectable Spasibo cashback categories, transfer-by-phone, utility bill auto-discovery, kids app |
| 16 | T-Bank (Tinkoff) | Russia | Lifestyle super-app, quarterly cashback category reveal, City booking (restaurants, cinema, travel), Pulse investing social feed, chat-first support |
| 17 | Itau | Brazil | Unified super-app shelf, Pix center with nighttime limits, one-tap installment of single purchases, WhatsApp companion, discreet mode |
| 18 | DBS digibank | Singapore | Peek Balance pre-login swipe, intelligent nudges, NAV Planner net worth + retirement simulator, PayNow QR, multi-currency travel mode |
| 19 | CommBank | Australia | Benefits Finder for government rebates, Bill Sense prediction, enriched transactions with maps, Goal Tracker, cardless cash ATM codes |
| 20 | Al Rajhi | Saudi Arabia | Nafath eID onboarding, instant Murabaha financing calculator with schedule preview, Zakat calculator, Sadaqah hub, SADAD bill hub, Tahweel remittance, Mokafaa loyalty, family sub-accounts, Arabic-first RTL |
| 21 | ila Bank | Bahrain | Hassala goal jars with earnings calculator, Jamiyah digitized saving circle (ROSCA), Al Kanz prize-linked savings with draw calendar and gifting, Ask Fatema assistant, multi-currency accounts on any card, eKYC in minutes, BenefitPay rails (full profile: doc/research/ila-bank.md) |

## Master UI capability list

Legend: [x] shipped in Bank UI Kit today, [ ] gap.

### Accounts and home
- [x] balance-first minimal home (compose: BankBalanceText, BankAccountCard)
- [x] feed/timeline home (BankTransactionListTile + group headers)
- [x] stories carousel for promos, tips, recaps (BankStoriesCarousel)
- [x] super-app modular home (BankQuickActionsGrid)
- [x] customizable home (BankQuickActionsGrid editable mode)
- [x] multi-account card carousel (BankAccountCard, BankHorizontalAccountCard)
- [x] pre-login peek balance (BankPeekBalance)
- [x] external aggregation view (compose: BankProductItemTile list)
- [x] hidden/discreet balance (BankPrivacyToggle + scope masking)
- [x] net worth view (compose: BankSummaryStack + BankPortfolioPerformanceChart)
- [x] multi-currency balances (BankCurrencyWalletTabBar)

### Payments and transfers
- [x] P2P by contact (BankContactPaymentSheet, BankBeneficiaryPicker)
- [x] QR scan and pay (BankQrScannerOverlay, BankMyQrCard)
- [x] instant-rail hub primitives (BankTransferLimitManager, BankScheduledTransferToggle)
- [x] bill-pay hub (BankBillPayTile, BankBillCalendarStrip)
- [x] bill auto-discovery / prediction list (BankBillForecastList)
- [x] bill splitting (BankTransactionCostSplitSheet)
- [x] remittance with rate screen (BankLiveExchangeConverter + BankTransferReviewCard)
- [x] currency exchange (BankLiveExchangeConverter)
- [x] request money (BankPaymentRequestCard)
- [x] ATM finder tile + cardless withdrawal code (BankAtmLocatorTile, BankCardlessCashCode)

### Cards
- [x] instant virtual card (BankVirtualCardWidget)
- [x] disposable single-use virtual card state (BankDisposableCardTile)
- [x] freeze + granular controls (BankCardControlsPanel)
- [x] card designer primitives (BankPhysicalCardMaterialPicker, BankCardDesignOption)
- [x] card-linked offers activation tiles (BankOffersRail)
- [x] selectable cashback categories picker (BankCashbackCategoryPicker)
- [x] PAN reveal (BankCardPinManager, BankAccountNumberText)
- [x] transaction enrichment (BankTransactionListTile + detail sheet)
- [x] single-purchase installment (BankInstallmentPlanSelector)
- [x] wallet provisioning (BankWalletProvisioningButton)

### Savings and goals
- [x] pots/vaults with progress (BankSavingsPotCard)
- [x] round-ups (BankRoundUpSettingsSheet)
- [x] save-when-paid (BankIncomeSorterSheet + controller)
- [x] group savings (BankSharedPotInvite, BankSharedGoalProgressCard)
- [x] gamified savings challenge with stamps/streaks (BankSavingsChallengeCard)
- [x] rotating saving circle / Jamiyah / ROSCA (BankMoneyCircleCard)
- [x] prize-linked savings with draw calendar and gifting (BankPrizeDrawCard)
- [x] savings projection calculator, Islamic-mode aware (BankSavingsProjectionCard)
- [x] yield-bearing balance tile (compose: BankProductItemTile rateLabel)
- [x] early payday / earned wage access card (BankEarlyPaydayCard)

### Budgeting, insights, financial health
- [x] category analytics (BankSpendingBreakdownChart)
- [x] predictive cashflow (BankCashflowChart)
- [x] proactive insight cards (BankInsightCard)
- [x] subscriptions manager (BankRecurringMerchantTile)
- [x] budgets with progress (BankBudgetGaugeWidget)
- [x] composite financial health score (BankFinancialHealthScore)
- [x] found-money discovery list (BankFoundMoneyList)

### Investing and wealth
- [x] brokerage surfaces (BankBuySellSheet, BankHoldingsListTile, charts)
- [x] crypto (BankBuySellSheet + BankCurrencies crypto entries)
- [x] watchlist + ticker (BankWatchlistCard, BankAssetPriceTicker)
- [x] retirement/goal simulator primitives (BankLoanCalculatorCard pattern)

### Credit and lending
- [x] credit score dashboard (BankCreditScoreGauge)
- [x] user-controlled credit limit slider (BankCreditLimitAdjuster)
- [x] one-tap pre-approved loan drawdown card (BankPreapprovedLoanCard)
- [x] BNPL (BankInstallmentPlanSelector, BankFlexEligibleBadge)
- [x] overdraft cushion meter (BankOverdraftCushionMeter)
- [x] repayment schedule (BankRepaymentScheduleView)

### Rewards and engagement
- [x] points program hub: earn/burn balance + redemption (BankPointsHubCard)
- [x] perks marketplace (BankPerksMarketplaceCard)
- [x] referral (BankReferralInviteCard)
- [x] charity/donations hub (BankDonationHubCard)
- [x] tier upsell (BankPlanComparisonTable, BankPaywallSheet)

### Support and assistant
- [x] chat support (BankSecureMessageThread)
- [x] named AI assistant entry surface (BankAssistantPanel)
- [x] help center (BankHelpFaqList)
- [x] disputes (BankDisputeWizardSheet)

### Security and privacy
- [x] call verification screen (BankCallVerificationScreen)
- [x] merchant-category self-exclusion blocks (BankMerchantBlockList)
- [x] limits by channel (BankTransferLimitManager)
- [x] security surfaces (BankDeviceSessionTile, BankDeviceTrustBanner, BankScaApprovalSheet)
- [x] real-time push primitives (BankInAppNotificationCenter, BankToastBanner)
- [x] national eID login/onboarding button (BankEidLoginButton)
- [x] panic freeze-everything control (BankPanicFreezeButton)

### Islamic banking
- [x] profit-rate labeling (islamicFinanceMode), BankShariahBadge, Heritage preset
- [x] Murabaha-style financing calculator (BankLoanCalculatorCard with rateLabel)
- [x] Zakat calculator (BankZakatCalculator)
- [x] Sadaqah/donations hub (BankDonationHubCard)

### Family, teens, business
- [x] joint/social (BankJointTransactionListTile, BankAccountOwnershipBadge)
- [x] business approvals + batch (business/ domain)
- [x] family/teen controlled-card tile with parental limits (BankFamilyCardTile)
