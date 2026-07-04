# Banking Journeys Catalog

The canonical end-to-end user journeys of the world's leading mobile
banking apps (Revolut, Nubank, Monzo, Chase, Toss, Alipay, Paytm,
Al Rajhi, Emirates NBD, DBS, N26, Chime, Wise and peers), compiled from
UX teardowns and product research in July 2026.

Purpose: this file is the blueprint for future journey-level APIs in
Bank UI Kit. Each journey lists its trigger, step sequence, variants,
and the error states a production implementation must handle. When we
build journey scaffolds, each step maps to kit components (most steps
already do: see doc/research/top-20-banking-apps.md for the component
coverage matrix).

Cross-cutting patterns every journey should honor:
one decision per screen, persisted drafts that survive interruption and
re-auth, every money movement ends in a shareable receipt, every error
state carries a next-best-action CTA, and scam interstitials appear at
first-payee and unusual-amount moments.

## Delivery status

Read this catalog as a roadmap, not implied product. Today:

| Layer | Status |
|---|---|
| Screen-level widgets | Composable today for every journey below; each step maps to components that exist in the kit (see doc/research/top-20-banking-apps.md) |
| Headless flow controllers | Shipped: `BankKycFlowController`, `BankTransferFlowController`, `BankIncomeSorterController`, `BankDisputeFlowController`. All other journeys: planned |
| Journey scaffolds (wired reference screens) | Planned; sequenced on the release train in doc/enterprise/versioning-and-releases.md |

---

## JOURNEY: Onboarding + KYC (new account opening)
Trigger: App store install, first app open, or referral deep link
Steps: 1) Splash + value proposition carousel (2-3 swipeable benefit screens, "Sign up" / "Log in" CTA) 2) Phone number entry with country picker, SMS OTP verification 3) Email entry + basic details (legal name, DOB) 4) Residential address (autocomplete lookup, manual fallback) 5) Regulatory questions: citizenship, tax residency (SSN/TIN/Iqama/national ID number), employment status, source of funds, expected usage, PEP/FATCA declaration 6) Document capture: pick ID type (passport, national ID, driver's license), camera framing overlay, auto-capture front/back, blur/glare re-take loop 7) Liveness selfie: face-in-oval prompt, turn head or short video ("Hi my name is X and I want a Monzo account" style spoken video in Monzo variant) 8) Processing/pending screen with realistic wait estimate, allow app exploration in restricted mode while verification runs 9) Terms + privacy consent checkboxes, plan selection upsell (free vs premium tiers with trial) 10) Create passcode + enable biometrics 11) Success: account number issued, virtual card instantly available, prompts to add money and order physical card
Variants: eKYC via national identity rails (Saudi Nafath/Absher for Al Rajhi, UAE Pass for Emirates NBD, Singpass MyInfo for DBS prefills everything and skips doc capture), video-call KYC (N26 in Germany), credit-first onboarding (Nubank starts with credit card invitation), goal-based branching (Nubank asks credit vs savings intent and trims steps), minor/teen account with guardian approval leg, business account variant with company registry lookup
Error states: OTP not received (resend timer, call fallback), document rejected (blurry, expired, unsupported type, name mismatch), liveness fail after N attempts routes to manual review, KYC manual review pending (24-72h waiting state with status tracker), KYC hard rejection (sanctions/age/geography) with appeal or support path, duplicate account detected, address not serviceable, session abandoned mid-flow (resume from last completed step on return), underage user blocked

## JOURNEY: Login / re-auth
Trigger: App open after logout, session expiry, or new device
Steps: 1) Returning user screen with masked identity (avatar, "Welcome back, Sayed") 2) Biometric prompt (FaceID/fingerprint) as primary 3) Fallback to 4-6 digit passcode 4) On new device: phone/email OTP plus optional ID re-verification or selfie match, old-device push approval 5) Optional security notice ("new device added") sent to other channels 6) Land on home dashboard
Variants: PIN-only markets, pattern login, device binding with SIM check (India apps verify SIM via silent SMS), step-up re-auth for sensitive actions inside the session (view card number, raise limits, add payee) even when already logged in, "quick balance" peek widget without full login
Error states: Biometric failure fallback to passcode, passcode wrong x5 triggers cooldown then account lock with support/identity-recovery flow, expired session mid-task (preserve draft, re-auth, return to task), forgotten passcode flow (OTP + selfie re-verification), account locked by fraud engine (call/chat unlock), jailbreak/root detection block, offline mode showing cached balance read-only

## JOURNEY: Add money / top-up
Trigger: Empty-balance nudge on home, "Add money" button, or failed payment prompt
Steps: 1) Add money entry: amount keypad with quick-amount chips 2) Choose funding source: linked debit card, bank transfer (show account number/IBAN + copy button), Apple/Google Pay, open banking pull, cash deposit map (Chime retail partners) 3) If new card: card number/expiry/CVV entry with camera scan, 3DS challenge in webview 4) If open banking: bank picker, redirect to bank app, approve, return 5) Review: amount, source, fee (if any), arrival time 6) Confirm (biometric if above threshold) 7) Success screen with new balance, animation, optional "set up recurring top-up" or "turn on auto top-up when balance falls below X"
Variants: Salary direct deposit setup (share account details or automated payroll switch), incoming remittance, cash at agent/ATM (Chime, Paytm), cheque deposit by camera (Chase: endorse, photo front/back, amount confirm, hold notice), auto top-up rule creation
Error states: Card declined by issuer, 3DS failed/timeout, top-up limit exceeded (daily/monthly, show limit and reset time), unsupported card type (credit card blocked for top-up in some markets), duplicate top-up warning, funds hold/settlement delay messaging, cheque image rejected

## JOURNEY: P2P transfer (to contact / same-app user)
Trigger: Home "Send" button, contact search, payment request notification, or share-sheet deep link
Steps: 1) Recipient picker: recent list, phone contacts (permission ask), username/@tag/UPI ID search, QR scan 2) New recipient confirmation card showing verified display name (Confirmation of Payee) 3) Amount keypad with balance shown, optional note/emoji and attachment 4) Optional: request vs send toggle, split-bill multi-select 5) Review sheet: recipient, amount, fee (usually zero), arrival (instant) 6) Authorize: biometric/PIN, UPI PIN in India 7) Success animation, receipt, options: share receipt, repeat, add to favorites 8) Recipient gets push + in-feed item; unregistered recipient gets SMS invite link with claim flow
Variants: Request money (creates pending request the payer approves), split bill from a transaction (select participants, equal/custom shares, track who paid), pay-by-link (Revolut payment link anyone can claim), gift/envelope mechanics (Toss, Alipay red packet), nearby pay via QR
Error states: Recipient not found, name mismatch warning (Confirmation of Payee "no match, are you sure"), insufficient balance (inline top-up offer), per-transaction or daily P2P limit exceeded, fraud interstitial for first-time payee ("Is someone pressuring you? This looks like a scam" quiz screens in Monzo/Revolut), transfer pending review, recipient's account cannot receive (closed/restricted), request expired

## JOURNEY: Domestic bank transfer (to external bank account)
Trigger: Payments tab "Bank transfer", pay-a-person with account details, or scheduled payment due
Steps: 1) Choose "New payee" or saved payee list 2) Enter payee details: account number + sort code/routing/IBAN/IFSC, or fetch via proxy (mobile number, national ID, alias like PayID/Sarie alias) 3) Confirmation of Payee name check result (match / close match with suggested name / no match) 4) Payee added, may require step-up auth (OTP) and cooling-off notice for new payees 5) Amount + reference/memo field 6) Schedule option: now, later date, recurring (standing order frequency + end condition) 7) Review: fees, rail (instant vs ACH/next-day), arrival estimate 8) SCA authorize (biometric + possibly OTP for high value) 9) Success + receipt with reference number, add to favorites
Variants: Instant rail vs batch rail choice (SARIE instant vs normal, ACH vs wire at Chase with wire fee disclosure), own-account transfer between checking/savings, standing order management (edit/skip/cancel future occurrence), bulk transfer (business)
Error states: Invalid account/IFSC/sort code checksum, CoP mismatch hard warning with liability copy, new payee cooling period (delayed first transfer), daily transfer limit exceeded (link to raise limit in security center), cutoff time passed (arrival date shifts, inform user), payment returned/bounced (feed item + refund), suspected APP fraud hold with in-app questionnaire, duplicate payment warning (same payee+amount within minutes)

## JOURNEY: International remittance
Trigger: "Send abroad" entry, currency-tagged recipient, or Wise-style calculator on home
Steps: 1) Corridor setup: destination country + currency picker 2) Amount screen: you-send vs they-receive toggle, live mid-market or quoted rate, fee breakdown line items, guaranteed-rate timer (e.g. rate locked 24-48h), delivery estimate 3) Delivery method: bank account, cash pickup, mobile wallet 4) Recipient details: name exactly as on bank record, IBAN/SWIFT/local scheme fields that change per corridor, address if required 5) Purpose of transfer picker (regulatory: family support, gift, services) 6) Additional KYC step-up if first international or above threshold (source of funds doc upload) 7) Funding method: balance, card, local transfer in 8) Review everything with total cost and rate 9) SCA authorize 10) Tracker screen: staged progress (received, converted, paid out) with push updates and shareable tracking link
Variants: Same-currency international (SEPA/SWIFT), wallet-to-wallet instant (both on Wise/Revolut), scheduled/recurring remittance, rate alert then send, Western-Union-style cash pickup with reference code (Emirates NBD DirectRemit to Philippines/India promises 60 seconds)
Error states: Rate expired before payment (requote consent), corridor unavailable/sanctioned country, recipient bank details fail validation, compliance hold requesting documents (invoice, relationship proof), amount above corridor limit, transfer returned by beneficiary bank (fee-transparent refund), FX volatility disclaimer when rate not guaranteed, weekend markup notice

## JOURNEY: Bill payment (utilities, telecom, government)
Trigger: Bills hub tab, biller push reminder, or overdue notice
Steps: 1) Bills hub: saved billers with due amounts fetched, "Add biller" CTA 2) Category picker (electricity, water, telecom, government fees, education) 3) Biller search + consumer/account number entry (or QR/barcode scan of paper bill) 4) Bill fetch: display amount due, due date, bill details 5) Amount confirm (full, minimum, custom where allowed) 6) Payment source select 7) Authorize (PIN/biometric) 8) Success + receipt with biller confirmation number 9) Offer auto-pay enrollment (pay full amount automatically each cycle, with cap) and reminders
Variants: SADAD (Saudi) and government payment IDs, prepaid mobile recharge (operator + plan browsing), postpaid fetch-and-pay, scheduled future-dated bill, e-invoice inbox (Nordics), payee is a person not a biller (US billpay mails a check)
Error states: Biller system down (retry later, save draft), bill already paid, invalid consumer number, amount outside biller min/max, auto-pay failed due to insufficient funds (retry schedule + notification), duplicate payment detection, receipt delayed (pending biller confirmation state)

## JOURNEY: QR pay (scan to pay)
Trigger: Persistent scan button on home/tab bar, camera shortcut, widget
Steps: 1) Tap scan, camera opens full screen with gallery-import and torch options 2) Decode QR: static merchant QR or dynamic amount-embedded QR 3) Merchant confirmation screen: verified merchant name, logo 4) Enter amount (static) or confirm prefilled amount (dynamic), optional tip 5) Select funding source (balance, linked bank, credit line like Alipay Huabei) 6) Authorize: UPI PIN / password / biometric (Alipay small amounts skip auth entirely) 7) Success screen with loud confirmation (Paytm soundbox audio on merchant side), cashback/reward reveal 8) Receipt in feed
Variants: Interoperable schemes (UPI, KSA/UAE national QR, SGQR, PayNow), pay offline via code, in-store show-code instead of scan (see next journey), transit QR mode with pregenerated offline codes, cross-border QR (Alipay+ abroad with FX preview)
Error states: Unreadable/damaged QR (manual entry of merchant ID fallback), QR expired (dynamic), amount exceeds tier limit for wallet KYC level, wrong-scheme QR (explain unsupported), network timeout with "payment status unknown, do not pay again" pending resolution state, merchant account flagged (fraud warning interstitial)

## JOURNEY: QR receive (get paid)
Trigger: "Receive" button, merchant mode toggle
Steps: 1) Tap Receive: personal QR displayed with name/@tag 2) Optional: set fixed amount + note to generate dynamic QR 3) Share as image/link 4) Payer scans, payment arrives 5) Push + full-screen received confirmation, feed entry
Variants: Merchant mode with daily settlement summary, printable QR standee ordering, request link instead of QR
Error states: Receiving limit reached (KYC tier upgrade prompt), QR regenerated after account change, payer bank failure (no credit, advise status)

## JOURNEY: Card issuance (virtual + physical)
Trigger: Post-onboarding prompt, Cards tab empty state, or lost-card replacement
Steps: 1) Cards tab: "Get card" CTA, choose virtual (instant) or physical 2) Virtual: instant issue, reveal card art, one tap add to Apple/Google Pay via push provisioning 3) Physical: choose design tier (standard free, premium/metal paid with pricing sheet) 4) Personalization: name on card, color, custom engraving/emoji (Revolut) 5) Confirm delivery address (edit flow inline) 6) Delivery fee + timeline review, pay if applicable 7) Order placed: tracking screen with progress stages (printed, shipped, out for delivery) 8) On arrival: activate by tapping "I received it" + last-4 entry or NFC tap or first chip transaction 9) Set PIN in app 10) Nudge: add to wallet, set as default
Variants: Single-use disposable virtual card (auto-regenerates number after each use), merchant-locked virtual cards, teen card with parent controls, replacement flow preserving card number vs new number, instant card printing at branch/kiosk (Emirates NBD), credit card issuance with underwriting step inserted (limit disclosure + APR consent)
Error states: Address undeliverable/PO box rejected, card lost in mail (reorder free), activation code mismatch, too many virtual cards limit, payment for premium card fails, name too long for embossing

## JOURNEY: Card controls + travel notice
Trigger: Cards tab, transaction-declined push, or pre-trip reminder
Steps: 1) Card detail screen: card image, balance, quick actions row 2) Freeze/unfreeze toggle with instant effect and undo 3) Controls list: online payments, contactless, ATM withdrawals, magstripe, international usage, gambling block (with 48h cool-off to re-enable) 4) Spending limits: per-transaction and monthly sliders 5) Location-based security toggle (GPS match) 6) Travel notice (traditional banks): add trip, destination countries, date range, cards covered, confirm 7) View card number/CVV behind biometric step-up 8) Change PIN in app, view PIN
Variants: Fintechs (Revolut/Monzo) explicitly need no travel notice and advertise it, granular merchant-category blocks, per-card limits for teen/family members, auto-freeze rules on suspicious signals
Error states: Unfreeze blocked because card reported lost (must reorder), gambling block re-enable forced waiting period, control change requires re-auth, offline device cannot toggle (queued change warning), declined transaction explains which control caused it and deep links to fix

## JOURNEY: Card dispute / chargeback
Trigger: Transaction detail "Report a problem", fraud push ("Did you make this?"), or support chat
Steps: 1) Select transaction from feed (multi-select related charges) 2) "Report an issue" entry 3) Triage question: I don't recognize this vs I recognize it but there's a problem 4) If unrecognized: fraud path, immediate card freeze offer + reissue, confirm other recent charges are yours 5) If merchant issue: reason picker (duplicate charge, wrong amount, goods not received, cancelled subscription still charged, defective) 6) Structured questions per reason (contacted merchant? delivery date? cancellation date?) with doc/photo upload (receipts, emails) 7) Review + submit claim 8) Acknowledgement with case number, timeline expectations (provisional credit within 10 business days language for US Reg E), status tracker screen (submitted, under review, provisional credit, resolved) 9) Push updates on status, final resolution letter in documents
Variants: Fraud vs service dispute branches, pending-transaction wait state (cannot dispute until posted), ATM dispute (cash not dispensed), provisional credit reversal flow if dispute lost with explanation and rebuttal window (7-21 days evidence window at Chase)
Error states: Dispute window expired (60-120 days), reason requires merchant contact first (soft block with guidance), duplicate dispute detected, need more info request pauses timeline, dispute denied with reasoning + appeal path, provisional credit clawback notice

## JOURNEY: Savings goal creation + automation (round-ups)
Trigger: Savings/Vaults tab, insight card ("you could save X"), post-payment nudge
Steps: 1) Spaces/Vaults/Pots hub: create new 2) Choose type: standard goal, interest-earning, group vault, locked/term 3) Name + emoji/image, target amount, target date (app computes needed weekly amount) 4) Currency select (multi-currency apps) 5) Automation setup: round-ups toggle with multiplier (x2-x10), recurring transfer (amount + frequency), payday auto-sweep, spare-balance sweep 6) Initial deposit optional 7) Confirm, goal card appears with progress ring 8) Ongoing: progress notifications, milestone celebrations, auto-pause if balance low 9) Withdraw/close: move money back, celebrate goal completion
Variants: Group/shared vault with invite links and member contributions, locked savings with early-withdrawal friction (notice period), interest-bearing with rate display and daily interest feed (Monzo/Tagihan), term deposit variant with maturity instructions, gamified savings challenges (Toss, 52-week challenge)
Error states: Round-up funding account empty (skip + notify), recurring transfer failed (retry logic), locked vault early withdrawal warning flow, interest product requires additional tax info (W-9 style), goal target date unrealistic warning

## JOURNEY: Budget setup + spending insights
Trigger: Insights/Trends tab first visit, month-start prompt
Steps: 1) Insights tab: auto-categorized spending breakdown for current month 2) "Set budget" CTA: choose overall monthly budget or per-category 3) Suggested amounts based on 3-month history 4) Set budget period anchor (payday-to-payday not calendar month, Monzo) 5) Optional: mark committed spending (rent, bills) excluded from discretionary budget 6) Enable alerts: pace warnings ("spending faster than usual"), category overshoot, low balance forecast 7) Ongoing: daily left-to-spend figure, mid-month check push 8) Recategorize transactions (long-press, change category, apply to future from this merchant) 9) Month-end summary story (Toss/Nubank Wrapped-style shareable recap)
Variants: Envelope-style (allocate salary to pots on payday, Monzo salary sorter), connected external accounts included via open banking for whole-money view, AI chat insights ("how much did I spend on coffee")
Error states: Misclassified merchant correction, insufficient history for suggestions (defaults), budget exceeded state (supportive not shaming copy), external account link expired (reconnect prompt)

## JOURNEY: Subscription management
Trigger: Payments > Scheduled/Subscriptions, price-hike alert push, or trends insight
Steps: 1) Subscriptions hub: auto-detected recurring merchants with logo, amount, next-charge date, annual total 2) Detect + confirm ("is this a subscription?" review of candidates) 3) Detail view: charge history, price change history flag 4) Actions: block future payments, cancel via app (where integrated), set reminder before next charge 5) Block confirmation with consequences copy ("merchant may still pursue payment, cancel with merchant too") 6) Insight: total monthly subscription spend, unused-subscription suggestion 7) Notification prefs: pre-charge alert, price-increase alert, free-trial-ending alert
Variants: Card-level block vs mandate cancellation (UPI autopay/e-mandate revoke in India is a formal flow with OTP), virtual card per subscription strategy, negotiate/cancel concierge (US fintechs)
Error states: Merchant retries under different descriptor (re-detect and warn), blocking a utility warns of service risk, mandate cancellation failed at bank (ticket), subscription paid annually surprises user (pre-alert)

## JOURNEY: Loan application (personal loan / credit line / BNPL)
Trigger: Loans tab, pre-approved offer card on home ("You're pre-approved for X"), merchant checkout (BNPL)
Steps: 1) Offer/landing: amount slider + tenor slider with live monthly payment, total cost, APR (or profit rate) 2) Soft-check eligibility screen ("checking won't affect your score") 3) Purpose picker + income/employment confirmation (prefilled from salary account or payroll data) 4) Consent to credit bureau hard pull 5) Instant decision screen: approved amount/rate (may differ from requested), counteroffer handling 6) Document review: key facts statement, amortization schedule, insurance opt-in 7) E-sign contract (checkbox + OTP or biometric signature) 8) Disbursement account select, confirm 9) Money arrives instantly, success screen with first-due-date, auto-debit setup 10) Ongoing: loan dashboard, early settlement calculator, payment holiday request
Variants: Salary-transfer loans (Gulf banks require salary domiciliation step), overdraft activation (simpler, set limit + fee explainer), BNPL split-at-checkout (4 installments, first today), credit limit increase mini-journey, top-up existing loan (Al Rajhi finance top-up), refinance/consolidation
Error states: Declined with reason category + improve-eligibility guidance, income verification needed (payslip/bank statement upload), DBR/DTI limit exceeded (show max affordable), offer expired, e-sign OTP failure, disbursement delayed (status tracker), cooling-off cancellation window (14 days N26-style)

## JOURNEY: Islamic finance application (murabaha / tawarruq)
Trigger: Finance tab in Islamic bank app (Al Rajhi, ADIB), auto/home purchase intent, pre-approved financing card
Steps: 1) Product select: personal finance (tawarruq), auto murabaha, home murabaha/ijara 2) Calculator: financing amount up to eligibility (salary multiple), tenor, shows profit rate (not interest), total murabaha price, monthly installment 3) Identity + employment verification via national eKYC (Nafath push approval), salary certificate auto-fetched for salary-account customers 4) SIMAH/credit bureau consent + DBR check 5) Offer: approved amount, profit rate, Sharia structure explainer 6) Commodity purchase consent: bank buys commodity, customer appoints bank as agent to sell (tawarruq mechanics presented as sequential consents) 7) Contract display with murabaha price breakdown, e-sign with OTP 8) Commodity sale execution confirmation (often seconds, "instant financing without visiting branch") 9) Funds credited, installment schedule + first deduction date shown 10) Ongoing: reschedule installment date, early settlement with rebate (ibra) calculation
Variants: Auto finance adds vehicle selection/dealer quote upload + insurance (takaful) bundling, home finance adds property valuation and Ministry of Housing subsidy integration (Sakani), refinance/buyout of other bank's finance, financing top-up with overtime salary counted
Error states: Salary not transferred to bank (require salary transfer letter first), DBR exceeded (Saudi Central Bank caps, show reduced max), Nafath approval timeout, SIMAH delinquency decline, commodity market closed (execution queued), guarantor required branch visit fallback

## JOURNEY: Zakat + charity payment
Trigger: Ramadan-season home banner, Payments > Zakat/Donations, zakat calculator tool
Steps: 1) Zakat hub: calculator entry 2) Asset input: cash balances (auto-prefill from accounts), gold/silver weight, investments, business assets, deduct debts 3) Nisab threshold check against live gold price, computed zakat due (2.5%) 4) Choose recipient: official body (KSAstore Zakat, government channel) or approved charities list 5) Amount confirm (full computed or custom) 6) Pay from account, authorize 7) Receipt with tax/compliance reference, calendar reminder for next lunar year 8) Optional recurring sadaqah setup
Variants: Direct SADAD government zakat payment (businesses), donation roundups to charity, campaign-based giving (Toss/Alipay style micro-donation feeds)
Error states: Below nisab (explain no zakat due), charity list unavailable offline, payment limit requires step-up, receipt needed for tax authority (document generation)

## JOURNEY: Credit score monitoring
Trigger: Score tile on home (Chase Credit Journey, Nubank, Paytm CIBIL), monthly change push
Steps: 1) Enrollment: consent to soft-pull bureau data, identity confirm 2) Score reveal with gauge, band label (poor to excellent) 3) Score factors breakdown: utilization, on-time payments, age of credit, inquiries, derogatory marks 4) History chart of score over months 5) Simulator: what-if actions (pay down X, open card) 6) Alerts setup: new inquiry, new account, score change, dark web/breach alert 7) Improvement tips feed with personalized actions 8) Deep links to products (credit builder card, secured loan)
Variants: Bureau differs by market (Experian/TransUnion, SIMAH, CIBIL), credit builder subproduct enrollment journey, rent reporting opt-in
Error states: Thin file/no score state (educational + builder product offer), identity mismatch at bureau (manual verify), bureau downtime (stale data timestamp), dispute-a-report-item handoff journey to bureau

## JOURNEY: Investment buy/sell (stocks, funds, gold, crypto)
Trigger: Invest tab, market-news push, watchlist alert
Steps: 1) First-time: suitability/appropriateness questionnaire (experience, risk tolerance, income), W-8/W-9 tax form, disclosures, account opening (seconds) 2) Discover: search, curated collections, watchlist 3) Instrument page: chart, key stats, analyst data, risk label 4) Buy: amount-based (fractional, "invest from $1") or share-count entry, order type (market default, limit optional) 5) Review: estimated shares, fees/spread, FX conversion note for foreign stocks 6) Confirm with biometric 7) Order placed / filled confirmation, position appears in portfolio 8) Sell mirror flow with proceeds destination 9) Recurring investment plan setup (weekly buy), dividend handling choice 10) Statements + tax lot data in documents
Variants: Robo-advisor goal-based (risk quiz then managed portfolio), gold in grams (Paytm, Emirates NBD), crypto with volatility warnings + withdrawal restrictions, Sharia-compliant stock screener filter (Islamic apps), IPO subscription journey (DBS, Gulf markets)
Error states: Market closed (queue order with disclosure), instrument restricted by appropriateness score (educational gate quiz), insufficient settled cash, price moved beyond tolerance (requote), pattern-day-trading or local regulation blocks, tax form expired, extreme-volatility trading halt notice

## JOURNEY: Currency exchange (in-app FX)
Trigger: Multi-currency account switcher, "Exchange" action, rate alert push
Steps: 1) Exchange screen: from/to currency pair pickers with balances 2) Amount entry either side, live rate display with fee/markup breakdown, weekend surcharge notice 3) Rate chart + rate alert toggle ("notify when EUR > X") 4) Optional auto-exchange rule (execute when target rate reached) 5) Review with final rate lock countdown 6) Confirm (small amounts no step-up) 7) Balances update instantly, receipt 8) Prompt to spend from new currency balance or open that currency account
Variants: Fair-usage tier limits (free allowance then 0.5-1% fee on free plans), forward-like scheduled conversion, salary auto-convert rule
Error states: Free tier limit exceeded mid-quote (fee appears, re-consent), rate expired requote, currency pair suspended (volatility), minimum amount not met, holding currency not enabled (one-tap open sub-account)

## JOURNEY: Account statements + tax documents
Trigger: Profile > Documents, tax-season push, third party requesting proof
Steps: 1) Documents hub: statements, tax docs, proofs, contracts 2) Statements: pick account + period (monthly list or custom range) 3) Format choice: PDF (stamped/signed for official use), CSV/Excel for data 4) Generate (async for big ranges) + preview 5) Share/download/email, password-protected option 6) Tax docs: annual interest certificate, 1099/consolidated tax package, capital gains report 7) Proof documents: bank confirmation letter, IBAN certificate, balance certificate (visa applications) instantly generated 8) E-statement preferences toggle (paperless consent)
Variants: Audit-ready stamped statements (Gulf market visa/embassy needs), open-banking export to accounting tools, statement for closed accounts via support
Error states: Range too large (split), document not yet available (tax docs by Jan 31 messaging), closed product documents need support ticket, download blocked on rooted device policy, email delivery failure

## JOURNEY: Support (chat + FAQ + escalation)
Trigger: Help tab, contextual "get help with this transaction", error screen CTA
Steps: 1) Help hub: search bar, browse topics, suggested articles based on recent activity 2) Contextual entry passes context (transaction ID) into flow 3) FAQ article with "Did this solve it?" feedback 4) Escalate: chatbot triage (intent classification, guided flows for common tasks) 5) Handoff to human chat with queue-position/ETA, async threading (reply later, push on agent response) 6) Identity re-verification inside chat for account-specific actions 7) Attachment support (screenshots, docs) 8) Resolution + CSAT rating 9) Case history list, reopen option 10) Fallbacks: call request/callback scheduling, emergency line for fraud (24/7), social/branch escalation
Variants: Voice call with in-app verified caller (bank calls you, verify in app to defeat vishing, Revolut/Monzo), premium tier priority queue, complaint formal-ombudsman track with regulatory timelines
Error states: Bot loop frustration escape hatch ("talk to human"), out-of-hours messaging with expectations, chat disconnect resume, unsupported language handoff, complaint SLA breach notice

## JOURNEY: Consent + open banking account linking
Trigger: "Add external account" in accounts list, budgeting whole-view prompt, payment-by-bank checkout
Steps: 1) Explainer screen: what data, why, security assurances, provider branding (Plaid/TrueLayer/Tink) 2) Bank picker with search 3) Consent scope screen: accounts, balances, transactions, duration (90-day/long-lived), explicit consent tap 4) Redirect to bank app/site OAuth (app-to-app if installed) 5) Authenticate at bank + select which accounts to share 6) Bank-side confirm, redirect back 7) Success: accounts appear with balances, initial transaction sync progress 8) Manage consents screen: list of connections, renew, revoke 9) Renewal push before expiry with one-tap reconfirm
Variants: PIS variant (single payment authorization instead of data), credential-based fallback for non-OAuth banks (screen scraping with warnings), variable recurring payment (VRP) mandate setup with limits per period, US Plaid vs UK OBIE vs KSA open banking (Lean/Tarabut) flavors
Error states: Bank not supported, OAuth redirect broken/return-to-app failure, MFA at bank fails, consent expired (stale-data badge + reconnect), bank connection degraded (partial data), user revoked at bank side (cleanup), duplicate account linked detection

## JOURNEY: Security center (devices, limits, alerts)
Trigger: Profile > Security, security push ("new login"), periodic checkup nudge
Steps: 1) Security hub with health score/checklist (Toss-style security checkup gamification) 2) Devices list: current + others with last-active, location, remove/logout-all 3) Change passcode/password flow with old-auth requirement 4) Biometric toggle, 2FA method management (authenticator app, backup codes) 5) Transaction limits screen: view/edit daily transfer, ATM, online limits (raises require step-up + possible cooling period, decreases instant) 6) Alerts prefs: login alerts, transaction thresholds, channels (push/SMS/email) 7) Privacy controls: data sharing, marketing consents, hide balances toggle 8) Advanced: whitelist countries, disable international login, panic freeze-everything button, scam-call verification tool 9) Blocked/trusted merchants and payees management
Variants: Wealth/high-net tiers add hardware token, family admin controls child limits, "safe mode" delays all outbound transfers 24h (elder protection)
Error states: Removing current device warning, limit raise held for review, 2FA reset requires full re-KYC (account recovery journey), suspicious change triggers temporary outbound freeze with countdown

## JOURNEY: Account closure
Trigger: Profile > Settings > Close account, support chat request, or regulatory offboarding
Steps: 1) Entry with retention interstitial: reason survey (fees, moving, service), targeted save-offer (fee waiver, tier downgrade) 2) Blockers checklist auto-generated: withdraw all balances including pots/vaults, cancel paid subscription plan, settle negative balance/loans, cancel scheduled payments and direct debits, download statements now warning 3) Destination account details for remaining funds payout (verified external account) 4) Consequences screen: card deactivation, loss of account number, data retention policy 5) Final confirm with re-auth (PIN/biometric + OTP) 6) Closure processing state (some banks 24h-30 day pipeline) 7) Confirmation email + final statement delivery 8) Post-closure: limited read access or support-only document retrieval
Variants: 14-day cooling-off withdrawal (EU one-click "withdraw from contract" button, N26), dormancy-driven closure with reclaim funds journey, switch-service handoff (UK CASS transfers direct debits automatically then closes), joint account closure requiring both parties' approval
Error states: Non-zero balance blocks (deep link to withdraw), open dispute/loan blocks closure, negative balance requires top-up first, pending incoming payment warning, payout account name mismatch, regulatory hold prevents closure

## JOURNEY: Direct deposit / salary switch
Trigger: Onboarding checklist item, "Get paid early" promo (Chime), payday detection insight
Steps: 1) Value pitch: early paycheck access, benefits unlock at deposit threshold 2) Method choice: automatic payroll switch (log into payroll provider via aggregator) or manual (pre-filled direct deposit form PDF with routing/account) 3) Automatic: employer/payroll search, credentials/SSO auth, choose full or partial deposit split 4) Confirmation of switch submitted, effective-date estimate 5) First deposit detection celebration + early-pay activation 6) Salary sorter offer: auto-split incoming pay into bills pot, savings, spending (Monzo)
Variants: Government benefits routing, partial percentage splits across accounts
Error states: Payroll provider unsupported (manual form fallback), employer processing lag (2 pay cycles messaging), deposit detected under threshold (benefit not unlocked explainer)

## JOURNEY: Cardless ATM withdrawal / cash services
Trigger: ATM map in app, "withdraw without card" action
Steps: 1) Cash hub: nearby ATM/agent map with fee labels 2) Choose cardless withdrawal, enter amount 3) Generate one-time code/QR (expiry timer shown) 4) At ATM: select cardless, enter code or scan, second-factor mobile approval 5) Cash dispensed, instant push receipt 6) Emergency variant: send cash code to someone else (beneficiary phone) with their ID check
Variants: NFC tap-to-withdraw via wallet, cash deposit at retail partner with barcode (Chime/GreenDot), cheque services
Error states: Code expired, ATM offline mid-transaction (auto-reversal messaging + dispute path), daily cash limit hit, out-of-network fee consent

## JOURNEY: Rewards / cashback / referral
Trigger: Rewards tab, post-purchase cashback push, referral campaign banner
Steps: 1) Rewards hub: points/cashback balance, earn-rate explainer 2) Offers list: activate merchant-specific offers (tap to activate, then spend) 3) Automatic cashback accrual feed on qualifying transactions 4) Redeem: to balance, gift cards, statement credit, donate, invest 5) Referral: personal link/code share sheet, tracked invitee progress checklist (signed up, KYC done, first transaction), reward release to both sides 6) Tier progress (spend X for next tier)
Variants: Scratch-card gamified rewards (Google Pay India, Toss coin drops), Chase Offers pattern, halal-compliant rewards (no gambling framing)
Error states: Offer expired before purchase, cashback pending merchant confirmation window (30-90 days), referral rejected (self-referral, geo mismatch, KYC incomplete), points expiry warning

## JOURNEY: Profile + life-event updates (address, phone, name, ID renewal)
Trigger: Profile settings, expiring-ID push (compliance), failed SMS delivery detection
Steps: 1) Personal details screen 2) Edit address: new address lookup, proof-of-address upload if required, effective confirmation 3) Change phone: verify old channel + new number OTP, high-risk cooldown on payments after change 4) Legal name change: document upload (marriage cert), manual review 5) ID document renewal: re-capture doc + selfie match, compliance clock reset 6) Confirmation + audit notification to all channels
Variants: National-ID-linked auto-refresh (Absher/Singpass sync), tax residency change triggering new self-certification (CRS/FATCA re-declaration)
Error states: Expired ID freezes outbound features until renewed (grace-period warnings), proof rejected, phone number already in use on another account, SIM-swap risk hold (delay + extra verification)

Notes on cross-cutting patterns observed in research: leading apps use one-decision-per-screen (Toss, Revolut), progress indication with skippable non-critical steps, drafts persisted so any journey survives interruption and re-auth, every money movement ends in a shareable receipt feed item, every error state carries a next-best-action CTA, and fraud/scam interstitials are injected at first-payee and unusual-amount moments.

Sources: builtformars.com (Revolut progressive onboarding, mastering onboarding), craftinnovations.global (Revolut/Monzo/Nubank onboarding teardowns), monzo.com/blog (simple signup KYC, account closure help), pageflows.com and mobbin.com (recorded onboarding flows), userbrain.com (TransferWise UX teardown), wise.com help + docs.wise.com (send money flow), paytm.com/blog and razorpay.com (UPI QR flow), plaid.com/docs and openbankinguk.github.io (consent/OAuth flow), backbase.com (retail journey framing), help.revolut.com (vaults, round-ups, freeze, subscriptions), help.chime.com and privacy.com (dispute + provisional credit), chase.com (track claims, dispute timelines), support.n26.com (closure, withdrawal right), alrajhibank.com.sa + app store listings (instant financing, murabaha products, installment reschedule).
