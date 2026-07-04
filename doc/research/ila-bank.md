# ila Bank: UI Capability Research

ila Bank (Bahrain, by Bank ABC) is the Gulf's flagship cloud-native
digital bank: mobile-only, eKYC onboarding with one ID and a selfie,
Arabic-first alongside English, and a product set that digitizes
traditional Khaleeji money culture rather than importing Western
patterns. Added to the kit's inspiration list as app 21. Compiled
July 2026 from ilabank.com product pages, app store listings, and
launch coverage.

## Design personality

Bold, warm, and personal: vivid gradients, playful copy ("banking that
reflects you"), an assistant with a name and a face (Fatema), and
product names drawn from local tradition (Hassala, the clay saving
pot; Jamiyah, the neighborhood saving circle; Al Kanz, the treasure).
The premium tier (ila Premium, ila Black, ila White) leans dark and
metallic.

## Surface inventory

| Surface | What it does | Kit coverage |
|---|---|---|
| eKYC onboarding | Account in minutes: one ID, a selfie | BankDocumentCaptureOverlay, BankLivenessCheckOverlay, BankStepProgressIndicator |
| Multi-currency accounts | Open and link FX accounts to any card | BankCurrencyWalletTabBar, BankLiveExchangeConverter |
| Hassala | Goal jars per currency, auto-payments, optional interest, celebrate at goal | BankSavingsPotCard, BankRoundUpSettingsSheet |
| Hassala calculator | Deposit amount + duration sliders, projected earnings | BankSavingsProjectionCard (NEW) |
| Jamiyah | Digitized ROSCA: admin, monthly contribution, turn order, auto-collection, payout on your turn | BankMoneyCircleCard (NEW) |
| Al Kanz | Prize-linked savings: monthly draws, prize calendar, deposit cutoffs, gift a chance, winners page | BankPrizeDrawCard (NEW) |
| Ask Fatema | Named AI assistant entry: greeting, suggested prompts, free text | BankAssistantPanel (NEW) |
| Savings+ / Fixed deposit / Government securities / Wakala | Yield products with rate ladders | BankProductItemTile, BankSavingsProjectionCard |
| Card suite (Classic, Premium, Blue, Switch, Gulf Air, Black, White, prepaid) | Tiered physical and virtual cards, freeze, PIN, 3DS | BankVirtualCardWidget, BankCardControlsPanel, BankCardPinManager |
| BenefitPay / Benefit Gateway | Local rail funding and online pay | BankQrPayView, BankWalletProvisioningButton pattern |
| ATM cash and cheque deposit | Fund via ila ATMs | BankAtmLocatorTile (depositCapable), BankChequeCaptureOverlay |
| Transfer by mobile number | P2P without IBAN | BankContactPaymentSheet |
| Offers / ila World | Lifestyle deals hub | BankOffersRail, BankPerksMarketplaceCard |
| alburaq Islamic account | Shariah-supervised sibling brand, Wakala investments, its own Hassala | islamicFinanceMode, BankShariahBadge, Heritage preset |

## Gaps closed by this batch

1. BankMoneyCircleCard (social): the Jamiyah circle card: pot per
   cycle, avatar turn tracker, collection date, paid-count strip,
   admin reminders. The single most requested Khaleeji social-banking
   surface, absent from every Western kit.
2. BankPrizeDrawCard (rewards): prize-linked savings with draw
   calendar, entry count, deposit cutoffs, minimum-deposit
   eligibility, and gift-a-chance action.
3. BankSavingsProjectionCard (saving): the "how much will I earn"
   calculator with amount and duration sliders, Islamic-mode aware
   (expected profit vs interest labels).
4. BankAssistantPanel (support): named-assistant entry surface with
   greeting, suggestion chips, recent queries, input row, and
   thinking state. Pure presentation: bring your own AI.
