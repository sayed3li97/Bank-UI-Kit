# Banking Products: Terminology, Metrics, and Journeys

A reference for building product catalog and application (apply) journeys
in the Bank UI Kit. It covers the retail product suite a major bank
ships: lending, deposits, cards, wealth, and insurance, conventional and
Islamic, with the exact metrics each product screen shows, the ordered
application journey, and the servicing views after origination.

Compiled July 2026 from public product pages (Chase, Bank of America,
Wells Fargo, Ally, Marcus, American Express, Fidelity, Rocket Mortgage,
SoFi, Emirates NBD, DBS) and consumer-finance references (CFPB,
Investopedia). Rates and limits are illustrative and dated where cited.

This document maps each product to the kit components that build it, and
underpins the flagship product-suite sample app in `example/`.

---

## Part 1: Lending products

A product-and-screen reference for a production-grade banking app. For each lending
product it defines: (a) a one-line definition, (b) the terminology and metrics a UI must
display, (c) the ordered application journey (screens/steps), and (d) the servicing/manage
views shown after origination. Section 8 covers Islamic (Shariah-compliant) equivalents and
how the terminology and disclosures change.

Terminology and numbers below were verified against Rocket Mortgage, Chase Auto, SoFi,
Bank of America (HELOC), Sallie Mae, Self, Emirates NBD / Emirates Islamic, Riyad Bank,
the U.S. Small Business Administration, and CFPB / Federal Reserve consumer references
(current as of July 2026).

---

## Cross-cutting concepts (apply to most products)

- **Interest rate vs. APR.** The interest rate is the yearly cost to borrow the principal,
  expressed as a percent, excluding fees. The **APR** (Annual Percentage Rate) folds in
  interest *plus* fees, points, and certain closing/mortgage-insurance costs, so it is the
  apples-to-apples comparison number. A UI should show both and label them distinctly; a
  Truth-in-Lending (Reg Z) disclosure requires APR.
- **Fixed vs. variable rate.** Fixed stays constant for the life of the loan; variable
  (indexed, e.g. to Prime or SOFR) can move. Variable-rate screens must show the index,
  margin, current rate, adjustment cadence, and rate caps/floors.
- **Soft vs. hard credit pull.** Pre-qualify/pre-approve flows use a soft pull (no score
  impact); the binding application uses a hard pull. The UI must state which is happening
  before the user proceeds.
- **Secured vs. unsecured.** Secured loans have collateral (home, vehicle, deposit); pricing
  and LTV are collateral-driven. Unsecured (personal loan, most credit-builder cards)
  price on credit and income only.
- **Amortization.** Fixed installment loans amortize: each payment is split into
  principal + interest, with interest front-loaded. Every servicing UI should offer an
  amortization schedule (per-payment principal/interest/balance).
- **Universal disclosures.** APR, finance charge, total of payments, payment schedule
  (Truth in Lending / Reg Z); for mortgages the Loan Estimate and Closing Disclosure;
  e-consent (ESIGN); privacy notice. These are gating screens before signature.

---

## 1) Mortgage / Home Loan (purchase + refinance)

**(a) Definition.** A long-term secured loan to buy or refinance real property, with the home
itself as collateral, typically 15 or 30 years.

**(b) Key terminology & metrics the UI must show**
- Purchase price / appraised value; loan amount (principal)
- Down payment (amount and %)
- **Interest rate** and **APR** (shown side by side)
- Rate type: fixed vs. **ARM** (adjustable, e.g. 5/1, 7/6) with index, margin, caps, adjustment date
- Loan term / amortization period (e.g. 30-yr, 15-yr)
- **LTV** (loan-to-value) and, if a second lien, **CLTV** (combined LTV)
- **DTI** (debt-to-income); front-end vs. back-end ratios (43% is a common qualifying threshold)
- **PMI** (private mortgage insurance): required when down payment < 20% until ~20% equity;
  FHA loans use **MIP** instead
- **Escrow / impound** account for property taxes + homeowners insurance (and PMI)
- **Points**: discount points (1 point = 1% of loan, buys down the rate) and origination points
- **Monthly P&I** (principal & interest) vs. **PITI** (P&I + taxes + insurance)
- Total interest over life; total of payments
- **Closing costs** / cash to close; lender credits; **rate lock** (with expiry)
- Prepayment terms; loan type (Conventional, FHA, VA, USDA, Jumbo)
- Refinance-specific: current balance, current rate, cash-out amount, break-even point,
  new payment vs. old payment (savings)

**(c) Application journey (ordered screens)**
1. Goal select: purchase vs. refinance (and refi type: rate-and-term vs. cash-out)
2. Affordability / eligibility pre-qualify (soft pull): income, debts, target price/down payment
3. Rate & product explorer / **mortgage calculator**: adjust price, down payment, term, points → live P&I, APR, LTV, PMI
4. Pre-approval (Verified/underwritten pre-approval; hard pull) → pre-approval letter
5. Property details / purchase contract (address, purchase price, offer accepted)
6. Choose loan program + rate lock
7. Loan application (full 1003/URLA): employment, income, assets, declarations
8. Document upload & KYC/identity: pay stubs, W-2s/tax returns, bank statements, ID
9. Disclosures: **Loan Estimate** delivered, intent-to-proceed
10. Processing → appraisal ordered → title/insurance → **underwriting** (conditional approval → clear-to-close)
11. **Closing Disclosure** (3-day review window) + final review
12. **E-sign / closing (settlement)**: sign note, deed of trust, disclosures
13. Funding & recording → loan boarded to servicing

**(d) Servicing / manage views**
- Current principal balance and original amount
- Next payment amount (PITI breakdown) and due date; autopay setup
- **Amortization schedule** (principal/interest/balance per month)
- Escrow account: balance, tax/insurance disbursements, annual **escrow analysis**, shortage/surplus
- **Payoff quote** (per-diem interest to a chosen date)
- PMI status and removal eligibility (LTV progress toward 78/80%)
- Statements & year-end tax docs (1098 mortgage interest)
- **Extra / principal-only payment** and recast option
- **Refinance / cash-out offer** and current home value / equity estimate
- Escrow, insurance, and property-tax management; hardship/forbearance requests

---

## 2) Auto Loan / Vehicle Finance

**(a) Definition.** A secured installment loan to buy a new or used vehicle, with the vehicle
as collateral; also covers lease buyouts and auto refinance.

**(b) Key terminology & metrics**
- Vehicle price / selling price; new vs. used; VIN, year/make/model, mileage
- Down payment; **trade-in** value (and any negative equity rolled in)
- Amount financed (price − down payment − trade-in + fees/tax)
- **APR** (and interest rate); term (months, e.g. 36/48/60/72/84)
- Monthly payment; total cost / total of payments; total interest / finance charge
- Sales tax, title, registration, dealer/doc fees
- **LTV** on the vehicle; loan-to-value relative to book value
- **GAP** (Guaranteed Asset Protection) coverage; extended warranty / VSC add-ons
- Prepayment terms; refinance: current balance, current rate, payoff, new payment
- Prequalification note: estimate based on self-reported income and an estimated APR
  (e.g. Chase prequalifies at a default 72-month term; not a guaranteed offer)

**(c) Application journey**
1. Prequalify (soft pull): income, desired amount → estimated APR & max amount
2. Vehicle shopping / valuation: choose car, trade-in valuation, budget → **payment calculator**
3. Customize deal: price, down payment, trade-in, term → monthly payment & total cost
4. Full application (hard pull): personal, employment, income, residence
5. Documents & KYC: ID, proof of income, proof of insurance, vehicle info (VIN)
6. Offer/decision: approved amount, APR, term, conditions
7. Dealer coordination (for dealer-network purchase) / direct funding for refinance
8. Review + disclosures (Truth-in-Lending retail installment contract)
9. **E-sign** contract (and GAP/warranty election)
10. Funding: to dealer or to payoff lender (refinance); title lien recorded

**(d) Servicing / manage views**
- Current balance, original amount, payoff amount (with per-diem)
- Next payment & due date; autopay
- **Amortization schedule**
- Extra-payment / principal-only payment
- Statements; interest paid YTD
- GAP/warranty status and claims
- Title/lien status and release upon payoff
- Refinance offer; end-of-term / lease-buyout options
- Payment deferral / hardship

---

## 3) Personal Loan / Unsecured Installment

**(a) Definition.** A fixed-rate, unsecured installment loan for general purposes (debt
consolidation, home improvement, major purchase), repaid in equal monthly payments.

**(b) Key terminology & metrics**
- Loan amount / requested amount (e.g. $5,000 to $100,000)
- **APR** and interest rate; fixed rate
- Term (e.g. 2 to 7 years)
- **Origination fee** (0% to 7%, often deducted from proceeds) → **net proceeds / amount deposited**
- Monthly payment; total interest; total of payments
- Purpose (consolidation, home improvement, etc.)
- Autopay discount (commonly 0.25%)
- No collateral; no prepayment penalty (typical); funding speed (e.g. same-day)
- Credit tier / rate band the offer falls in

**(c) Application journey**
1. **Prequalify / check rate** (soft pull): amount, purpose, income → estimated APR & term options
2. Choose offer: pick amount + term; toggle origination-fee-vs-rate trade-off → payment & net proceeds
3. Full application (hard pull): identity, income, employment, housing
4. Verification & KYC: ID, income docs, bank account (for disbursement + autopay)
5. Final offer/decision: confirmed APR, term, fee, net amount
6. Review + Truth-in-Lending disclosures + loan agreement
7. **E-sign**
8. Funding to bank account (often 1 to 3 days, sometimes same-day)

**(d) Servicing / manage views**
- Balance, original amount, payoff amount
- Next payment & due date; autopay management
- **Amortization schedule** / payments remaining
- Extra payment
- Statements; interest paid
- Refinance / additional loan offer; hardship / due-date change

---

## 4) HELOC / Home Equity

**(a) Definition.** A revolving line of credit secured by home equity: borrow, repay, and
re-borrow up to a limit during a draw period, then repay over a repayment period. (A
**home equity loan** is the closed-end lump-sum cousin.)

**(b) Key terminology & metrics**
- Home value / appraised value; existing mortgage balance; available equity
- **Credit limit / line amount**
- **CLTV** (combined loan-to-value): max commonly ~85%
- **Variable APR** with index (e.g. Prime) + margin; often an **intro rate** for a fixed
  window (e.g. 6-month introductory APR, then ongoing variable) with rate caps
- **Draw period** (e.g. 10 years) vs. **repayment period** (e.g. 20 years)
- Payment type during draw: interest-only vs. principal+interest
- Fixed-rate lock option on portions of the balance
- Fees: annual fee, closing costs, early-closure fee, minimum draw
- Minimum payment; outstanding balance vs. available credit

**(c) Application journey**
1. Estimate equity / eligibility: home value, mortgage balance → available credit (soft pull)
2. **HELOC calculator**: desired line, CLTV → estimated APR & payment
3. Apply (hard pull): property, income, existing liens
4. Documents & KYC; property/appraisal (often automated valuation), title check
5. Underwriting / decision → offer: limit, APR, draw/repayment terms
6. Disclosures (HELOC early disclosure / CHARM booklet, Reg Z), 3-day right of rescission
7. **E-sign** / closing (rescission period for primary residence)
8. Line opens; initial draw

**(d) Servicing / manage views**
- Outstanding balance, available credit, credit limit
- Current variable APR (index + margin), next rate change
- **Draw funds** (transfer to account) and repay
- Phase indicator: draw period vs. repayment period + end dates
- Minimum payment & due date; interest-only vs. amortizing indicator
- Fixed-rate lock on balance segments
- Payoff quote; statements; interest (1098)
- Convert to fixed / refinance offer

---

## 5) Student Loan

**(a) Definition.** A loan to finance higher education, in three flavors: federal, private
(in-school), and **refinance** (replace existing student debt with a new private loan).

**(b) Key terminology & metrics**
- Loan type: federal vs. private vs. refinance
- Principal / amount borrowed (or cost of attendance minus aid, for in-school)
- **Fixed vs. variable APR** (e.g. fixed ~3.9% to 16.7%, variable indexed)
- Term (e.g. 5 to 20 years)
- **Cosigner** (and cosigner-release eligibility)
- **In-school deferment** and **grace period** (e.g. 6 months after leaving school; deferment
  up to 48 months while enrolled half-time)
- Repayment plan while in school: deferred vs. interest-only vs. immediate P&I
- **Capitalized interest** (accrued interest added to principal at end of grace/deferment)
- Autopay discount; origination fee (federal loans) / no fee (typical private refi)
- Refinance-specific: loans being consolidated, weighted current rate, new rate, monthly
  savings, and a **federal-benefits-loss warning** (income-driven repayment, forgiveness,
  forbearance are forfeited when refinancing federal loans privately)

**(c) Application journey**
1. Goal: pay for school (in-school) vs. **refinance existing loans**
2. Prequalify / check rate (soft pull): school, amount or existing balances, income, degree
3. Choose rate type (fixed/variable) + term; add **cosigner** if needed → payment & total cost
4. Full application (hard pull): identity, income/enrollment, existing loan details
5. Documents & KYC: ID, income, enrollment verification (in-school) / payoff statements (refi)
6. School certification (in-school) or payoff verification (refi)
7. Disclosures: TILA, self-certification form (private in-school), federal-benefits-loss notice (refi)
8. **E-sign**
9. Disbursement to school (in-school) or payoff of prior loans (refi)

**(d) Servicing / manage views**
- Balance(s), original amount, interest rate(s), status (in-school / grace / repayment / deferment)
- Next payment & due date; autopay
- **Amortization / payoff** projection
- Grace-period countdown; deferment/forbearance requests
- Accrued (unpaid) interest and capitalization warnings
- Extra payment (with allocation choice across loans)
- Cosigner-release application
- Statements; **1098-E** interest for taxes
- Refinance offer

---

## 6) Credit-Builder / Secured Loan

**(a) Definition.** A small product designed to establish or rebuild credit by reporting
on-time payments to the bureaus. Two forms: a **credit-builder loan** (you pay first, funds
released at the end) and a **secured credit card** (cash deposit sets the credit limit).

**(b) Key terminology & metrics**
- Product type: credit-builder installment loan vs. secured card
- For a credit-builder loan: loan amount held in a **locked savings/CD** (e.g. $300 to $1,000),
  monthly payment, term (e.g. 12 to 24 months), APR, admin/setup fee, and **funds released at
  completion** (minus interest/fees)
- For a secured card: **security deposit** = credit limit, APR, annual fee, deposit
  refundability, graduation-to-unsecured path
- **Reports to all three bureaus** (Equifax, Experian, TransUnion): this is the headline feature
- Credit-mix note (installment vs. revolving); expected time-to-score-impact
- No hard credit check to qualify (typical)

**(c) Application journey**
1. Choose product (builder loan vs. secured card) and plan (amount/term or deposit/limit)
2. Application (often no hard pull): identity, bank account
3. KYC / identity verification
4. Fund: pay the deposit (secured card) or set up the payment plan (builder loan)
5. Disclosures + agreement
6. **E-sign**
7. Activate: card issued / savings account locked and reporting begins

**(d) Servicing / manage views**
- Payments made vs. remaining; on-time streak; next payment
- Bureau-reporting status / last reported date; **credit score tracker**
- For builder loan: locked-savings balance accrued; projected release amount & date
- For secured card: balance, available credit, deposit held, utilization; deposit-refund /
  **graduation to unsecured** status
- Statements; autopay
- Early payoff / close-out

---

## 7) SME / Business Loan + Line of Credit

**(a) Definition.** Financing for a business: a **term loan** (lump sum, fixed repayment),
a **business line of credit** (revolving draw-as-needed), or an **SBA-guaranteed** loan/line.

**(b) Key terminology & metrics**
- Product: term loan vs. **revolving line of credit** vs. SBA 7(a)/504/Express/CAPLine
- Loan/line amount (e.g. up to $5M for SBA lines); term (up to ~10 yrs SBA lines, 25 yrs real estate)
- **APR** / interest rate (often variable, Prime + margin); for a line, interest only on drawn balance
- Monthly/periodic payment; total cost; draw fee; annual fee; origination/packaging fee; SBA guaranty fee
- Business profile: legal entity, **EIN**, industry/NAICS, years in business, **annual revenue**, DSCR
- Owner profile: personal credit, ownership %, **personal guarantee** (SBA requires one from any ≥20% owner)
- Collateral / UCC lien (secured vs. unsecured line)
- Use of proceeds (working capital, equipment, real estate, expansion)
- For revolving lines: outstanding balance, available credit, **annual review** (unsatisfactory
  review can force conversion to an amortizing term loan)

**(c) Application journey**
1. Product selector: term loan vs. line of credit vs. SBA
2. Eligibility / prequalify: business age, revenue, industry, amount needed (soft pull)
3. Estimate / calculator: amount, term → payment / cost of capital
4. Application: business details (EIN, entity, revenue), owner(s) details & ownership %
5. Documents & KYC/KYB: business + personal tax returns (2 yrs), bank statements, financial
   statements, formation docs, cap table; beneficial-ownership (BOI)
6. Underwriting: credit, cash flow/DSCR, collateral; SBA eligibility check
7. **Personal guarantee** and collateral/UCC agreements
8. Offer / commitment letter: amount, rate, term, covenants, conditions
9. Disclosures + loan/credit agreement
10. **E-sign** / closing
11. Funding (term loan) or line activation (draw availability)

**(d) Servicing / manage views**
- Term loan: balance, next payment, amortization schedule, payoff
- Line: outstanding balance, available credit, limit, **draw** and repay, interest on drawn amount
- Rate (variable index + margin) and changes
- Statements; interest paid; covenant/annual-review status and document requests
- Extra payment; renewal/increase offer; multiple-user roles & approvals (business admins)
- Collateral / lien status

---

## 8) Islamic Financing Equivalents (Shariah-compliant)

Islamic finance forbids **riba** (interest), **gharar** (excessive uncertainty), and financing
of non-permissible (haram) activities. Instead of lending money at interest, the bank
transacts in real assets and earns a **profit** (or **rent/rental**), not interest. A
Shariah-compliant UI therefore changes the vocabulary and adds disclosures.

**What a Shariah-compliant UI must show differently (across all products):**
- **"Profit rate" not "interest rate"; no "APR/interest"** language. Some jurisdictions still
  require an equivalent effective-rate / cost disclosure (e.g. an "annualized profit rate" or
  "effective profit rate") for comparison, shown alongside the Shariah structure.
- **Contract/structure name is prominent** (Murabaha, Ijara, Diminishing Musharaka, Tawarruq) -
  the customer is buying/leasing/partnering in an asset, not "borrowing."
- **Cost-plus / sale price breakdown**: asset cost + bank's disclosed profit = total sale
  price (fixed and known up front for Murabaha), instead of an amortizing interest schedule.
- **Rental vs. ownership split** for lease/partnership structures (Ijara / Musharaka):
  monthly payment = rent + acquisition of the bank's share.
- **Late payments**: no compounding penalty interest; instead a **late-payment charity/
  donation** (ta'widh / donated to charity): must be labeled as such, not as extra profit.
- **Shariah governance**: Shariah Supervisory Board approval / **fatwa** reference, and often a
  Takaful (Islamic insurance) option instead of conventional insurance for escrow/protection.
- **Ownership-transfer milestone** shown explicitly (for lease/partnership products).

### 8a) Murabaha Auto (Islamic vehicle finance): equivalent of the auto loan
- **Structure:** the bank buys the vehicle, then sells it to the customer at **cost + a
  disclosed, fixed profit margin**, payable in installments. Total price is fixed at signing.
- **UI shows:** vehicle cost, **bank profit amount** and **profit rate** (fixed), total sale
  price, down payment, term, fixed installment, ownership transfer terms: no interest/APR;
  no variable rate; Takaful option.
- **Journey:** prequalify → configure (price, down payment, term → installment & total price) →
  application + KYC → bank purchase & **Murabaha sale contract** → disclosures + Shariah terms →
  e-sign → funding/vehicle delivery. **Manage:** fixed schedule, outstanding sale price,
  early-settlement (with possible profit rebate/**ibra**), statements.

### 8b) Ijara / Diminishing Musharaka Home (Islamic mortgage): equivalent of the mortgage
- **Structure (Diminishing Musharaka, most common for homes):** bank and customer **co-own**
  the property; customer pays **rent** on the bank's share plus periodic payments to **buy out**
  that share until owning 100%. **Ijara** = lease-to-own: bank owns and leases to customer,
  ownership transfers after the final payment. (Emirates NBD / Emirates Islamic "Binaa" is
  structured this way.)
- **UI shows:** property value, bank's vs. customer's **ownership share** (updating over time),
  **rental amount** and **profit/rental rate**, share-acquisition amount, monthly payment
  (rent + equity purchase), term, ownership-percentage tracker, ownership-transfer date,
  Takaful (property): no interest/APR/PMI/escrow-interest.
- **Journey:** eligibility (share/value) → calculator (rent + share purchase) → application +
  KYC → property valuation → **partnership/lease + promise-to-purchase (wa'ad)** contracts →
  Shariah disclosures → e-sign → funding. **Manage:** ownership-share progress, rent vs.
  equity split per payment, outstanding bank share, early buyout, statements.

### 8c) Tawarruq / Commodity Murabaha Personal Finance: equivalent of the personal loan
- **Structure:** to provide **cash** compliantly, the bank buys a commodity (e.g. metals/palm
  oil, never gold/silver), sells it to the customer on deferred **cost-plus-profit** terms, then
  (as agent) sells the commodity in the market to deliver cash to the customer. The customer
  repays the deferred sale price in installments. (Common in KSA: e.g. Riyad Bank Tawarruq;
  scrutinized/less used in the UAE.)
- **UI shows:** finance amount (cash received), commodity purchase/sale price, **fixed profit
  amount** and **profit rate**, term, fixed installment, total payable: plus a clear
  explanation of the commodity-trade mechanism and Shariah approval; no interest/APR.
- **Journey:** prequalify → choose amount/term → application + KYC → **commodity purchase &
  Murabaha sale + agency (wakala) to sell** → cash disbursement → Shariah disclosures →
  e-sign. **Manage:** fixed installment schedule, outstanding sale price, early settlement
  with rebate (ibra), statements.

---

## Notes for the UI kit

- Every product needs a distinct **pre-qualify (soft pull)** entry that clearly differs from
  the binding **application (hard pull)**, with a consent/impact notice between them.
- Conventional products center on an **interest-rate / APR / amortization** mental model;
  Islamic products center on **profit / rent / ownership-share** models and must never surface
  the words interest/APR: but may still need an effective-rate comparator disclosure.
- Disclosure and e-sign are their own gated steps (Loan Estimate/Closing Disclosure for
  mortgages, TILA for others; rescission windows for home-secured lending; Shariah/fatwa
  references and Takaful options for Islamic products).


---

## Part 2: Deposit, card, and wealth products

Scope: A production reference for a banking app UI kit covering 15 products across Deposits, Cards, and Wealth. For each product: (a) one-line definition, (b) key terminology and metrics a UI must display, (c) the OPEN/APPLY journey as an ordered set of screens, (d) the MANAGE/servicing views. Islamic (Shariah-compliant) equivalents are noted where relevant.

Figures verified July 2026 from Chase, Bank of America, Ally, Marcus by Goldman Sachs, American Express, Fidelity, Emirates NBD, DBS, plus CFPB, FDIC, IRS, the Federal Reserve, Investopedia, NerdWallet, and Bankrate. All rates and limits are point-in-time and must be treated as data (never hard-coded) in the UI.

Key current reference values (July 2026):
- FDIC insurance: $250,000 per depositor, per insured bank, per ownership category (unchanged since 2008). Trust accounts with 5+ beneficiaries: up to $1,250,000 per owner.
- IRA contribution limit 2026: $7,500 (under 50), plus $1,100 catch-up (50+) = $8,600. Roth phase-out (single): $153,000 to $168,000; (married filing jointly): $242,000 to $252,000.
- 401(k) elective deferral 2026: $24,500.
- HYSA APY range: roughly 3.75% to 4.20%; national savings average ~0.38%.
- Average credit card APR: ~21% (Fed, all accounts, Q1 2026); ~25% on new-card offers. Prime rate: 6.75%.
- CD early-withdrawal penalty: commonly 90 days interest (terms <= 12 mo) to 365 days interest (longer terms); federal minimum 7 days simple interest. Typical 10-day post-maturity grace period.
- Robo-advisor management fee: typically 0.25% annual (Betterment, Wealthfront).

Cross-cutting note on regulated disclosures the UI must surface: Truth in Savings (Reg DD) requires APY, APY-earned, and fee disclosures for deposits. Truth in Lending (Reg Z) requires the Schumer box (APR, fees, grace period) for cards. Securities accounts require prospectus delivery, risk disclosures, and the "investments are not FDIC insured / may lose value" banner.

---

## DEPOSITS

### 1. Checking / Current Account

(a) Definition: A transactional demand-deposit account for everyday spending, bill pay, and direct deposit, with unlimited access via debit card, checks, ACH, and transfers.

(b) Key terminology and metrics the UI must show:
- Available balance vs. current/ledger balance (the distinction matters: pending holds).
- Account number and routing number (with copy/reveal controls; masked by default).
- Pending transactions, posted transactions, running balance.
- Monthly maintenance fee and the fee-waiver conditions (minimum balance, qualifying direct deposit, linked accounts).
- Minimum opening deposit and minimum daily balance.
- Overdraft status: opted-in/out, overdraft fee, overdraft protection transfer link, overdraft limit/buffer (e.g., no fee under a threshold).
- Direct deposit / early direct deposit indicator (e.g., "up to 2 days early").
- Statement cycle date and e-statement toggle.
- APY if interest-bearing (many checking accounts are 0%).
- Zelle/P2P enrollment status, external linked accounts.
- Debit card status (active, locked, shipped).
- FDIC-insured badge.
Islamic equivalent: Current Account on a Qard (interest-free loan) or Wadiah (safekeeping) basis: no interest paid or charged; funds guaranteed. Emirates NBD offers an Islamic Current Account.

(c) OPEN/APPLY journey (ordered screens):
1. Product selection / compare accounts (fees, perks, minimums).
2. Eligibility and residency check.
3. Personal details (name, DOB, SSN/national ID, address).
4. Identity verification (KYC): document capture + selfie/liveness, or knowledge-based.
5. Contact + credentials (email, mobile, OTP verification).
6. Account preferences (paperless, overdraft opt-in/out choice with Reg E disclosure, debit card design).
7. Fund the account (initial deposit: linked bank, card, transfer, or mobile check).
8. Disclosures and agreements (Truth in Savings, fee schedule, e-sign consent).
9. Review and submit.
10. Confirmation (account/routing number, next steps, card-on-the-way, set up direct deposit CTA).

(d) MANAGE / servicing views:
- Account dashboard: balance, spendable, recent activity, insights.
- Transactions list with search, filter, category tags, receipt attach, dispute a charge.
- Transfer money (internal, external/ACH, wire), scheduled/recurring transfers.
- Bill pay and payees.
- Move money / Zelle / P2P.
- Statements and documents; download/export.
- Direct deposit setup (prefilled form / instant switch).
- Overdraft settings and coverage.
- Card controls (lock/unlock, travel notice, limits, PIN, replace).
- Account details (numbers, ownership, beneficiaries/POD).
- Alerts and notifications (low balance, large transaction, deposit posted).
- Stop payment, order checks, close account.

---

### 2. Savings Account

(a) Definition: An interest-bearing deposit account for setting money aside, with limited transactional use, paying a stated APY.

(b) Key terminology and metrics the UI must show:
- APY (annual percentage yield) and interest rate; APY-earned on statements.
- Interest accrued this period / paid year-to-date; next interest payment date and compounding frequency.
- Current balance and available balance.
- Minimum opening deposit, minimum balance to earn APY, monthly fee and waiver.
- Withdrawal / transfer limits (historically Reg D six/month; now often institution-imposed) and excessive-withdrawal fee.
- Savings goals / buckets progress (many modern apps).
- Round-up / automatic-save rules status.
- FDIC-insured badge.
Islamic equivalent: Mudaraba Savings Account: profit-sharing rather than interest. UI shows expected/indicative profit rate, the Mudarib/Rabb-ul-mal profit-sharing ratio (e.g., 60:40), and distributed profit (not guaranteed).

(c) OPEN/APPLY journey:
1. Product select / rate display.
2. Choose owner or open under existing profile (often 1-click for existing customers).
3. Personal + KYC (or reuse verified identity).
4. Set account nickname and optional savings goal.
5. Fund initial deposit.
6. Disclosures (Truth in Savings, rate sheet).
7. Review and confirm.

(d) MANAGE / servicing views:
- Balance + interest earned summary; projected annual interest.
- Transactions and interest postings.
- Transfer in/out; set up recurring automatic savings.
- Savings goals/buckets create/edit, progress rings.
- Round-up settings.
- Rate history / current APY.
- Statements, tax documents (1099-INT).
- Withdrawal-limit counter/warnings.
- Alerts (goal reached, interest posted).

---

### 3. High-Yield Savings Account (HYSA)

(a) Definition: A savings account, usually online/direct-bank, paying a market-leading APY well above the national average, often with balance tiers.

(b) Key terminology and metrics the UI must show:
- Headline APY (prominent), and comparison to national average ("X times the national average").
- Tiered rate table: balance bands and the APY per band (e.g., $0-$4,999, $5,000-$24,999, $25,000+), and whether the tier rate applies to the whole balance or marginally.
- Variable-rate disclosure (rate can change at any time).
- Interest earned this month / YTD; projected annual earnings calculator.
- Minimum to open ($0 common) and minimum to earn top APY.
- No monthly fee badge; withdrawal method/limits.
- Rate as-of date.
- FDIC insurance and, where applicable, sweep/partner-bank network coverage above $250k.
Islamic equivalent: Higher indicative profit-rate Mudaraba/Wakala investment deposit with tiered expected profit rates.

(c) OPEN/APPLY journey:
1. Rate landing / tier table and earnings calculator.
2. Product select.
3. Personal + KYC (or reuse).
4. Nickname / goal.
5. Fund (external ACH pull common; show funding limits and hold period).
6. Disclosures (variable rate, Truth in Savings).
7. Review and confirm; funding timeline.

(d) MANAGE / servicing views:
- Balance + current tier indicator + APY, earnings this month.
- Rate-change history and alerts.
- Projected earnings calculator/what-if.
- Transfers and linked external accounts management.
- Automatic savings rules.
- Statements, 1099-INT.
- Multi-bucket goals (if supported).

---

### 4. Money Market Account (MMA)

(a) Definition: An interest-bearing deposit account blending savings-like yields (often tiered) with limited checking features such as check-writing or a debit card.

(b) Key terminology and metrics the UI must show:
- APY (often tiered by balance) and interest earned.
- Check-writing availability and per-cycle transaction/withdrawal limits.
- Debit/ATM card availability.
- Minimum balance to open, to earn APY, and to avoid fee; monthly fee.
- Available vs. current balance.
- Distinction disclosure: MMA (FDIC-insured deposit) vs. money market fund (a security, not FDIC-insured): the UI must not conflate them.
- FDIC-insured badge.

(c) OPEN/APPLY journey:
1. Product select / tier table.
2. Personal + KYC.
3. Choose features (checks, debit card).
4. Fund initial deposit (often higher minimum).
5. Disclosures (Truth in Savings, tier terms).
6. Review and confirm.

(d) MANAGE / servicing views:
- Balance, tier, APY, interest earned.
- Transactions incl. checks written; withdrawal-limit counter.
- Order checks / card controls.
- Transfers and bill pay (if enabled).
- Statements, 1099-INT.
- Tier-threshold and low-balance alerts.

---

### 5. Certificate of Deposit (CD) / Term Deposit

(a) Definition: A time deposit locking a fixed principal for a fixed term at a fixed (usually) APY, with a penalty for early withdrawal and a maturity date.

(b) Key terminology and metrics the UI must show:
- Term length (e.g., 3, 6, 9, 12, 18, 24, 36, 60 months).
- APY and interest rate; fixed vs. variable (bump-up/step-up CDs).
- Principal / deposit amount; minimum to open.
- Open date and maturity date (with countdown/days remaining).
- Interest payout schedule (compound and credit at maturity, or periodic payout/transfer).
- Projected interest at maturity and total value at maturity.
- Early-withdrawal penalty (EWP): expressed in days/months of interest (e.g., 90 days for <=12 mo, 365 days for longer) with the plain-language rule and the note that penalty can reach principal if interest earned is less.
- Grace period at maturity (commonly 10 days) and auto-renew setting (renew same term at then-current rate vs. transfer to linked account).
- Maturity instructions (renew, withdraw, change term, add/withdraw funds during grace).
- CD ladder view: multiple CDs staggered by maturity so a rung matures periodically; show rungs, individual maturities, blended yield, next maturity, reinvest plan.
- Special types to label: No-penalty CD, Bump-up CD, Add-on CD, Callable CD, Brokered CD, IRA CD.
- FDIC-insured badge.
Islamic equivalent: Mudaraba Fixed/Term Deposit or Wakala Deposit: fixed tenor with an expected profit rate (not guaranteed interest); early redemption reduces the profit-sharing tier rather than a stated interest penalty.

(c) OPEN/APPLY journey:
1. Choose term (rate-by-term grid) and see APY.
2. Enter deposit amount; live projected interest and maturity value + maturity date.
3. Select funding source.
4. Set maturity/auto-renew instruction and interest-payout preference.
5. Beneficiary/ownership (optional).
6. Disclosures (fixed term, EWP schedule, grace period, Truth in Savings).
7. Review and confirm (lock-in summary).
8. Confirmation with maturity date and calendar reminder.
Laddering variant: a "Build a CD ladder" wizard: choose total amount + number of rungs + interval; system splits into multiple CDs with staggered terms; single review/confirm.

(d) MANAGE / servicing views:
- CD detail: principal, APY, accrued interest, open/maturity dates, days to maturity, EWP estimate.
- Maturity center: upcoming maturities, edit renewal instructions before grace ends.
- Ladder dashboard: all rungs, maturity timeline, next rung maturing, blended APY, auto-reinvest toggle.
- Early-withdrawal flow with penalty preview and confirmation (net proceeds after penalty).
- Interest history / payout tracking.
- Statements, 1099-INT.
- Maturity and grace-period alerts.

---

### 6. Retirement Account / IRA

(a) Definition: A tax-advantaged account for retirement savings (Traditional IRA: pre-tax/tax-deferred; Roth IRA: after-tax with tax-free qualified withdrawals), which can hold cash (IRA CD/savings) or investments (IRA brokerage).

(b) Key terminology and metrics the UI must show:
- Account type: Traditional, Roth, Rollover, SEP, SIMPLE, Inherited/Beneficiary IRA.
- Annual contribution limit and remaining room for the tax year (2026: $7,500 + $1,100 catch-up at 50+).
- Tax year selector for contributions (current or prior year until the deadline).
- Contributions year-to-date, employer contributions (SEP/SIMPLE).
- Roth income eligibility / MAGI phase-out (single $153k-$168k; MFJ $242k-$252k for 2026).
- Deductibility status (Traditional) given income and workplace-plan coverage.
- Balance, holdings/allocation (if invested), cash available to invest.
- RMD (Required Minimum Distribution): required beginning age (73), current-year RMD amount, deadline, satisfied/remaining (not for Roth IRA owners).
- Early-withdrawal warning: 10% penalty before 59.5 plus taxes; exceptions list.
- Beneficiary designations (primary/contingent, percentages).
- 5-year rule indicator for Roth qualified distributions.
- Tax documents: 5498 (contributions), 1099-R (distributions).
- Vesting (for employer plans/SEP where relevant).

(c) OPEN/APPLY journey:
1. Choose IRA type (Traditional vs. Roth guidance/quiz; rollover path).
2. Eligibility + income/MAGI check (Roth) and deductibility estimate (Traditional).
3. Personal + KYC.
4. Beneficiary designation.
5. Investment choice: self-directed vs. managed/robo (or cash/IRA CD).
6. Fund: contribution (with tax-year selection), rollover/transfer (from employer plan or another custodian), or recurring contribution.
7. Disclosures (IRA custodial agreement, fee schedule, risk disclosure if invested).
8. Review and confirm.
9. Confirmation + set recurring contribution CTA.

(d) MANAGE / servicing views:
- Retirement dashboard: balance, contribution progress bar (used vs. remaining limit), tax-year toggle.
- Contribute now / recurring contribution setup.
- Holdings, allocation, performance (if invested); trade/rebalance.
- Rollover/transfer center and status tracking.
- RMD center (calc, schedule, distribute).
- Withdrawal/distribution flow with tax-withholding and penalty warnings.
- Beneficiaries management.
- Retirement projection / on-track indicator.
- Tax documents (5498, 1099-R).
- Statements and confirmations.

---

## CARDS

### 7. Credit Card

(a) Definition: A revolving unsecured line of credit for purchases up to a credit limit, repayable in full (grace period, no interest) or over time (interest at APR), typically earning rewards.

(b) Key terminology and metrics the UI must show:
- Current balance, statement balance, minimum payment due, payment due date, and days remaining.
- Credit limit, available credit, and utilization (% of limit used) with health indicator.
- Purchase APR, and separately cash-advance APR, balance-transfer APR, penalty APR (all variable, tied to prime).
- Intro/promotional APR: rate, what it applies to (purchases and/or balance transfers), and expiration date (with countdown).
- Grace period explanation (no interest if statement paid in full by due date).
- Rewards: cashback/points/miles balance, earn rates by category, redemption options, rotating/activated categories, caps.
- Annual fee and when it posts; other fees (late, foreign transaction, cash advance, balance-transfer fee %).
- Balance transfer: promo rate, fee, and how much can be transferred.
- Statement/billing cycle dates, last statement, next statement date.
- Minimum interest charge; interest accrued this cycle.
- Autopay status (min, statement balance, or fixed) and paperless.
- Card status (active/locked), virtual card number, expiration/CVV (secure reveal).
- Credit score widget (many issuers embed FICO/VantageScore).
- Pay-over-time / installment plan eligibility on eligible purchases.
- The Schumer box (Reg Z) content accessible.
Islamic equivalent: Shariah-compliant credit card structured on Ujrah (fixed service fee), Murabaha, or Tawarruq instead of interest; UI shows a fixed monthly fee/profit and no riba, with a spending limit.

(c) OPEN/APPLY journey:
1. Card selection / compare (rewards, APR, annual fee, intro offer).
2. Offer detail and Schumer box / terms.
3. Prequalification (soft pull, no impact) with estimated approval odds and terms.
4. Personal + income/housing details.
5. Identity verification (KYC), SSN.
6. Optional: request a specific credit line, balance-transfer request (amount + source card).
7. Consent to hard credit inquiry and cardholder agreement.
8. Review and submit.
9. Decision: instant approval (with assigned credit limit and APR), pending/manual review, or decline (adverse-action notice).
10. Post-approval: add to mobile wallet / virtual card for immediate use; physical card shipping.

(d) MANAGE / servicing views:
- Card home: balance, available credit, utilization ring, min due, due date, quick "Pay".
- Make a payment (one-time/scheduled) and Autopay setup.
- Transactions: pending/posted, category tags, dispute, recurring merchants, statement filter.
- Statements and billing history; interest/fee breakdown.
- Rewards center: balance, earn history, redeem (cash, travel, statement credit, gift cards), activate categories.
- Balance transfer and pay-over-time/installment offers.
- Credit-line increase request; APR/utilization insights; embedded credit score.
- Card controls: lock/unlock, report lost/stolen, replace, travel notice, merchant/category controls, set alerts, manage authorized users.
- Card details: virtual number, expiry/CVV reveal, add to wallet, update PIN.
- Alerts: payment due, large purchase, over-limit, statement ready, foreign transaction.
- Manage account: credit limit, benefits/insurance, close card.

---

### 8. Secured Credit Card

(a) Definition: A credit card backed by a refundable cash security deposit that typically sets the credit limit, designed to build or rebuild credit.

(b) Key terminology and metrics the UI must show (superset of credit card, plus):
- Security deposit amount held and its refundable status.
- Credit limit relationship to deposit (often equal; some allow limit > deposit).
- Option to increase the deposit to raise the limit.
- Graduation status: progress toward upgrade to an unsecured card (issuers often review at 6-12 months of on-time payments) and deposit-refund conditions.
- Credit-building progress: on-time payment streak, reporting to bureaus indicator, credit score trend.
- Deposit refund method (statement credit, check, or account credit) on graduation/closure.

(c) OPEN/APPLY journey:
1. Card select (emphasize credit-building, reports to 3 bureaus).
2. Personal + KYC (approval odds high; often no minimum credit score).
3. Choose deposit amount (sets credit limit) within min/max.
4. Fund the security deposit (linked bank).
5. Cardholder agreement + deposit disclosure (refundable terms).
6. Review and submit; decision.
7. Confirmation: limit = deposit, graduation criteria explained.

(d) MANAGE / servicing views:
- All credit-card management views, plus:
- Deposit center: amount held, add to deposit to raise limit, refund status/eligibility.
- Graduation tracker: months of on-time payments, review date, upgrade offer.
- Credit-building dashboard: score trend, payment history, utilization coaching.

---

### 9. Charge Card

(a) Definition: A card with (traditionally) no preset spending limit that must be paid in full each billing cycle, carrying no revolving balance or standard APR (late/penalty fees apply); often premium with an annual fee.

(b) Key terminology and metrics the UI must show:
- "No preset spending limit" language (spending power adapts, not unlimited) and current spending power / check-spending-power tool.
- Balance due in full and payment due date; pay-in-full requirement.
- Late fee / penalty structure (no ongoing purchase APR; may offer optional Pay Over Time for eligible charges with an interest rate).
- Annual fee (often premium) and the benefits/credits that offset it (travel credits, lounge access, insurance).
- Rewards points balance and earn rates; membership benefits.
- Pay Over Time / Plan It: enroll eligible charges into fixed monthly plans with a fee/APR.
- Statement cycle and due date.
Note: Amex has blended charge and credit features; UI should reflect whichever applies to the specific card.

(c) OPEN/APPLY journey:
1. Card select (premium benefits, annual fee, no preset limit).
2. Benefits and terms detail.
3. Prequalify (soft) where offered.
4. Personal + income + KYC.
5. Consent to credit inquiry and agreement.
6. Review and submit; decision.
7. Onboarding: benefits activation, add to wallet, enroll credits.

(d) MANAGE / servicing views:
- Card home: balance due in full, due date, spending power / check spending power.
- Pay in full / make payment; Autopay.
- Pay Over Time / Plan It: choose charges, view plan fee and term, active plans.
- Rewards and Membership benefits hub (credits, lounges, offers, insurance).
- Transactions, statements, disputes.
- Card controls, add authorized users, alerts.
- Annual-fee and benefits value tracker.

---

### 10. Debit Card

(a) Definition: A payment card linked to a checking/current account that draws directly from available balance (not credit), for purchases and ATM access.

(b) Key terminology and metrics the UI must show:
- Linked account and available balance drawn from.
- Card status (active/locked/frozen), last 4 digits, expiry, virtual card.
- Daily ATM withdrawal limit and daily purchase (POS) limit; remaining today.
- PIN management.
- ATM network / fee-free ATM finder and any out-of-network/foreign fees.
- Overdraft opt-in status for one-time debit transactions (Reg E) and any overdraft fee.
- Contactless/wallet provisioning status.
- Recent card transactions (mirror of checking activity).
- Rewards, if a rewards debit card.

(c) OPEN/APPLY journey (usually bundled with the checking account):
1. Issued automatically at checking-account opening, or "Order a debit card".
2. Choose design/type; confirm mailing address.
3. Set PIN.
4. Add to mobile wallet (virtual card for instant use).
5. Activate physical card on arrival (app or call).

(d) MANAGE / servicing views:
- Card controls: lock/unlock, report lost/stolen, replace, freeze.
- Limits: view/adjust daily ATM and purchase limits.
- PIN change; travel notice.
- Merchant/category controls and spending controls (e.g., online, international toggles).
- Add to wallet; view virtual card number/CVV securely.
- ATM/branch finder.
- Overdraft opt-in/out for debit transactions.
- Transaction alerts; dispute a transaction.

---

## WEALTH

### 11. Brokerage / Investing Account

(a) Definition: A taxable (or tax-advantaged) account for buying and selling securities (stocks, ETFs, mutual funds, options, bonds) held at a broker-dealer.

(b) Key terminology and metrics the UI must show:
- Total account value, cash balance, and buying power (incl. margin buying power if margin-enabled).
- Holdings/positions: symbol, quantity, market value, cost basis, unrealized gain/loss ($ and %), day change.
- Portfolio performance: time-weighted return, period selectors, benchmark comparison.
- Asset allocation breakdown (stocks/bonds/cash/sectors).
- Order entry fields: symbol, buy/sell, quantity or dollar (fractional), order type (market, limit, stop, stop-limit), time-in-force (day, GTC), estimated cost.
- Bid/ask, last price, day range, volume (quote panel).
- Settled vs. unsettled cash; T+1 settlement; good-faith/free-riding warnings.
- Margin details: maintenance requirement, margin used, margin interest rate, margin call status.
- Dividends and interest received; dividend reinvestment (DRIP) toggle.
- Realized gains/losses and tax lots; wash-sale flags.
- Fees/commissions (often $0 for US stocks/ETFs), regulatory fees.
- "Not FDIC insured, may lose value" and SIPC coverage disclosure.
Islamic equivalent: Shariah-compliant/Islamic investing account that screens out non-compliant sectors (alcohol, gambling, conventional finance, etc.) and interest income; may include purification calculation.

(c) OPEN/APPLY journey:
1. Account type select (individual/joint/IRA/custodial; cash vs. margin).
2. Personal + KYC + SSN.
3. Investor profile/suitability: employment, income, net worth, investment objectives, experience, risk tolerance (FINRA suitability).
4. Regulatory questions (control person, broker affiliation, politically exposed).
5. Elections: margin agreement, options level (with approval), dividend reinvestment, sweep/cash management.
6. Disclosures (customer agreement, Reg BI/Form CRS, fee schedule, risk disclosures).
7. Fund account (ACH, wire, transfer/ACATS from another broker).
8. Review and submit; approval.
9. Onboarding: watchlist setup, first-trade guidance.

(d) MANAGE / servicing views:
- Portfolio dashboard: value, day change, total return, allocation.
- Positions detail with cost basis and gain/loss.
- Trade ticket / order entry and order status/history (open, filled, canceled).
- Quotes, charts, watchlists, research, screeners.
- Transfers and funding; ACATS transfer status.
- Dividends/income and DRIP settings.
- Tax center: realized gains, 1099-B/DIV/INT, tax-lot selection.
- Statements, trade confirmations, documents.
- Margin dashboard and margin calls.
- Recurring investments/auto-invest.
- Alerts (price, order filled, margin).

---

### 12. Mutual Funds / ETFs

(a) Definition: Pooled investment vehicles holding diversified baskets of securities; mutual funds price once daily at NAV, ETFs trade intraday like stocks.

(b) Key terminology and metrics the UI must show:
- Fund name, ticker, and type (index/active, ETF/mutual fund).
- NAV (mutual funds, end-of-day) or market price + intraday quote (ETFs); premium/discount to NAV (ETFs).
- Expense ratio (net/gross) and any load (front-end/back-end) or "no-load" label; 12b-1 fees.
- Yield (SEC 30-day yield / distribution yield) and distribution frequency.
- Total return over 1M/YTD/1Y/3Y/5Y/10Y/since-inception vs. benchmark.
- Holdings/top-10, sector and geographic allocation, number of holdings.
- Risk metrics: standard deviation, beta, Morningstar rating/style box.
- Minimum initial/subsequent investment (mutual funds); fractional/dollar investing (ETFs).
- Dividend/capital-gains distribution dates and reinvestment option.
- Trading rules: cutoff time (mutual funds), settlement, early-redemption fee, no intraday for mutual funds.
- Prospectus/summary prospectus and fact sheet links.
Islamic equivalent: Shariah-compliant funds and Islamic ETFs screened by a Shariah board; purification ratio and screening methodology shown.

(c) OPEN/APPLY / BUY journey (assumes a brokerage/fund account exists):
1. Fund discovery/screener (by category, expense ratio, rating, ESG/Shariah).
2. Fund detail: performance, holdings, fees, prospectus.
3. Buy ticket: dollar or shares, one-time or recurring; ETFs add order type/TIF.
4. Review costs (expense ratio disclosure, any load/fee).
5. Prospectus acknowledgment.
6. Confirm order; confirmation (mutual funds fill at next NAV).
(If no account: complete brokerage/fund-account opening first, as in #11.)

(d) MANAGE / servicing views:
- Position detail: value, cost basis, gain/loss, yield, distributions received.
- Performance vs. benchmark; allocation contribution.
- Buy more / sell / exchange (switch funds within family).
- Automatic investment plan (recurring buys) and DRIP toggle.
- Distribution settings (reinvest vs. cash).
- Documents: prospectus, annual/semiannual report, fact sheet, 1099.
- Fee/expense transparency view.

---

### 13. Robo-Advisor / Managed Portfolio

(a) Definition: An automated, algorithm-managed investment service that builds and rebalances a diversified portfolio matched to the client's goals and risk profile for a low annual advisory fee.

(b) Key terminology and metrics the UI must show:
- Risk profile / risk score (from the questionnaire) and the resulting portfolio (conservative to aggressive).
- Target asset allocation (stocks/bonds/alt %, by fund/ETF) shown as a chart, and current vs. target drift.
- Advisory/management fee (e.g., 0.25% annual) and underlying fund expense ratios.
- Goal setup: goal type (retirement, house, general), target amount, target date, monthly contribution.
- Projection: projected balance over time with best/expected/poor case (probability bands) and likelihood of reaching goal.
- Glide path indicator (allocation grows more conservative as goal/retirement nears).
- Automatic rebalancing status and last rebalance date.
- Tax-loss harvesting toggle/status (taxable accounts).
- Dividend reinvestment, automatic deposits.
- Performance/return, contributions vs. earnings.
- Minimum to invest.
Islamic equivalent: Shariah-compliant managed portfolios built from screened funds/Sukuk; the questionnaire and allocation exclude non-compliant assets.

(c) OPEN/APPLY journey:
1. Goal selection (what are you investing for).
2. Risk-tolerance questionnaire (age, timeline, income, reaction-to-loss scenarios).
3. Recommended portfolio + allocation + fee, with projection chart and goal-likelihood.
4. Account type (taxable/IRA) + personal + KYC.
5. Elections (tax-loss harvesting, dividend reinvestment).
6. Set contribution: initial deposit + recurring amount.
7. Disclosures (advisory agreement/ADV, fee, risk).
8. Review and confirm; portfolio activation.

(d) MANAGE / servicing views:
- Portfolio dashboard: value, allocation vs. target, performance, projection to goal.
- Goals overview: each goal's progress ring, on-track/off-track status, edit target/contribution.
- Adjust risk / change portfolio (re-take questionnaire) with impact preview.
- Contributions: manage recurring deposits, one-time add, withdraw.
- Rebalance history and tax-loss-harvesting activity/savings.
- Fee statement and underlying holdings drill-down.
- Documents (statements, ADV, tax forms).
- Advice/messaging (hybrid human advisor upsell where offered).

---

### 14. Bonds / Fixed Income

(a) Definition: Debt securities paying periodic interest (coupon) and returning principal (par) at maturity; issued by governments, municipalities, agencies, and corporations.

(b) Key terminology and metrics the UI must show:
- Issuer, security type (Treasury, municipal, corporate, agency, CD-brokered), and CUSIP.
- Coupon rate and payment frequency; accrued interest.
- Maturity date and time-to-maturity; call date/callable flag and call schedule.
- Price (as % of par, e.g., 98.50), par/face value, and whether at premium/par/discount.
- Yield metrics: current yield, yield to maturity (YTM), yield to worst (YTW), yield to call.
- Credit rating (Moody's/S&P/Fitch) and investment-grade vs. high-yield label.
- Duration and modified duration (interest-rate sensitivity); convexity for advanced.
- Minimum quantity/increment (e.g., $1,000 par) and quantity held.
- Bid/ask spread and markup/markdown disclosure.
- Tax treatment (Treasury: state-tax-exempt; municipal: often federal-tax-exempt; taxable-equivalent yield tool).
- For Treasuries/new issue: auction date, settlement.
Islamic equivalent: Sukuk (asset-backed/asset-based Islamic certificates). UI shows expected profit/rental (not interest/coupon), underlying asset/structure (Ijara, Mudaraba), tenor, and profit-distribution schedule; no fixed guaranteed interest and returns tied to asset performance.

(c) OPEN/APPLY / BUY journey (within brokerage):
1. Bond search/screener: by type, maturity, rating, yield, coupon, tax status.
2. Bond detail: yields, rating, call schedule, price, disclosures.
3. Buy ticket: quantity (par), price/limit, review estimated yield and total cost incl. accrued interest and markup.
4. Suitability/risk acknowledgment (esp. high-yield, callable).
5. Confirm order; confirmation.
(New-issue/Treasury auction variant: place non-competitive bid, review auction terms, confirm.)

(d) MANAGE / servicing views:
- Fixed-income holdings: position, par, market value, cost, gain/loss, YTM, next coupon, maturity.
- Income/coupon calendar and cash flow projection (upcoming interest and maturities).
- Bond ladder view (staggered maturities, reinvestment).
- Interest-received history; reinvestment settings.
- Call/maturity alerts.
- Tax documents (1099-INT/OID), taxable-equivalent yield tool.
- Sell/redeem flow.

---

### 15. Bancassurance / Insurance Products

(a) Definition: Insurance policies (life, auto, home, travel) distributed through the bank, providing financial protection in exchange for premiums, with defined coverage and terms.

(b) Key terminology and metrics the UI must show (common):
- Product type and one-line coverage summary.
- Premium: amount and frequency (monthly/annual), and total cost.
- Coverage amount / sum assured / policy limits and sublimits.
- Deductible / excess (auto, home, travel).
- Policy term / duration and renewal date; effective (start) date.
- Beneficiaries (life); insured persons/assets.
- Exclusions and waiting periods.
- Riders / add-ons and their premium impact.
- Claim status and payout details.
- Free-look/cancellation period.
Per-product specifics:
- Term life: sum assured/death benefit, term length (e.g., 10/20/30 years), premium (level/increasing), convertibility/renewability, medical underwriting status.
- Auto: coverage types (liability, collision, comprehensive), limits per person/per accident, deductible, vehicle details, no-claims discount, premium.
- Home: dwelling/contents/liability coverage amounts, deductible, perils covered, replacement cost vs. actual cash value, premium.
- Travel: trip dates, destinations, coverage (medical, trip cancellation, baggage, evacuation) limits, single-trip vs. annual multi-trip, premium.
Islamic equivalent: Takaful (cooperative/mutual protection). UI reflects contribution (tabarru donation) instead of premium, a shared risk pool, surplus-sharing/rebate to participants, and Wakala/Mudaraba operator fee model rather than conventional premium/insurer profit. Family Takaful (life), General Takaful (auto/home/travel).

(c) OPEN/APPLY (quote-to-bind) journey:
1. Product/needs selection (what to protect) and optional needs calculator (e.g., life cover amount).
2. Quote inputs: for life (age, gender, smoker, sum assured, term); auto (vehicle, driver, usage, history); home (property value, contents, location); travel (dates, destinations, travelers, coverage tier).
3. Coverage customization: limits, deductible, riders/add-ons with live premium update.
4. Quote summary: premium, coverage, term, exclusions.
5. Applicant details + KYC; for life/health, health questionnaire/underwriting (may branch to medical exam).
6. Beneficiary designation (life) / asset details.
7. Disclosures (policy wording, exclusions, free-look period, key facts).
8. Payment setup (premium schedule) and consent.
9. Bind/issue: decision (instant issue, refer to underwriting, or decline).
10. Confirmation: policy number, documents, coverage start date.

(d) MANAGE / servicing views:
- Policy dashboard: coverage summary, premium and next due date, term/renewal date, status (active/lapsed).
- Policy documents (schedule, certificate, wording).
- Premium payments and autopay; payment history.
- File a claim: guided intake, document upload, claim tracker/status, payout details.
- Update policy: change coverage/limits, add/remove riders, update beneficiaries or insured assets (endorsements) with premium impact.
- Renewal center: renew, adjust, or cancel; no-claims discount.
- Coverage gap / recommendation insights.
- Cancel/surrender (with free-look and cash-value where applicable for permanent life).
- Takaful variant: contribution ledger, surplus-distribution statement.

---

## Cross-product UI patterns worth centralizing

- Money movement: transfer/pay flows are shared across deposits, cards, and wealth (source/destination picker, amount, schedule, review, confirm).
- Statements and documents hub: universal across all products.
- Alerts/notifications engine: thresholds differ per product but the pattern is shared.
- KYC/identity verification: reused at every account opening.
- Disclosures/e-sign consent: required at every open flow; content varies (Reg DD, Reg Z, Reg BI/prospectus, insurance key facts).
- Rate/fee "as-of" data: all APY/APR/fee values are dynamic and dated, never static in UI.
- Compliance badges: FDIC-insured (deposits) vs. "not FDIC insured, may lose value / SIPC" (investments) vs. insurance regulator disclosures; the UI must never show FDIC on investment/insurance products.


---

## Part 3: Flagship app architecture

Scope: a production-grade, CEO-approvable flagship retail banking app built around the
full PRODUCT SUITE (accounts, cards, loans, mortgages, investments, insurance) and the
apply / manage journeys. Grounded in how Chase, Bank of America, Wells Fargo, Revolut,
Emirates NBD, and DBS structure product discovery, application, and servicing.

---

## 0. How leading banks structure this (research synthesis)

- **Chase / BofA / Wells Fargo (US incumbents):** logged-in home is an account tiles list.
  "Explore products" / "Open an account" / "Apply" lives both as a dedicated tab/section and as
  contextual cross-sell cards inside the dashboard. Loans surface as pre-qualified offers
  ("My Chase Loan", "borrow from your available credit") with a fixed APR shown up front. Heavy
  emphasis on rate/APR/APY transparency and legal disclosure gating because of Reg Z / TILA.
  Pre-qualification with a **soft pull** ("won't affect your credit score") is the front door for
  cards and loans; the specific offer (limit, APR) is shown before the hard-pull application.
- **Revolut (super-app):** dark, gradient, precise. A **Hub / directory page** lists every service
  as color-categorized tiles, so "products" is a browsable shelf, not buried in menus. Segmented
  controls and partially-revealed horizontal tabs signal "there is more to scroll".
- **DBS digibank:** award-winning; lets users **apply for accounts, loans and credit cards in-app**,
  bundles multiple products via "Starter Packs", and pairs the flow with a 24/7 assistant (digibot).
  Backed by a mature design system (135-person design org, Figma-based tokens).
- **Emirates NBD (ENBD X):** Middle-East flagship; product catalog spans conventional + Islamic
  (Shariah) variants, so product cards must carry a compliance/variant badge and profit-rate
  language alongside conventional APR. (This kit already ships `bank_shariah_badge`.)

Common denominators worth copying: a **product shelf** with category tiles + rich product cards,
**pre-qual soft-check badges**, a **reusable multi-step application wizard** with a progress
indicator, **rate/APR transparency + representative example**, disclosure/consent gating, e-sign,
a clear **submitted/decision/funded** terminus, and a **"My products" servicing area** distinct
from the marketing catalog.

---

## 1. FULL SCREEN MAP

### Primary tabs (bottom nav)
| Tab | Screen | Purpose | Key components |
|---|---|---|---|
| Home | **Dashboard / Home** | At-a-glance net position, account tiles, alerts, and *contextual* product offers ("recommended for you"). | Account balance tiles, net-worth summary, quick actions grid, offers rail, pre-qual offer card, alerts banner |
| Explore | **Products / Explore (catalog root)** | The marketing shelf: browse the whole suite by category, featured + personalized products, compare. | Category tile grid, featured product carousel, "recommended for you" rail, product cards, compare tray, search/filter |
| Move Money | **Move Money hub** | Transfers, pay, request, Zelle-style P2P, bill pay, FX. (Servicing, not product sales.) | Transfer flow, payee list, amount input, scheduled payments, FX rate card |
| Insights | **Insights / Spending** | Cashflow, budgets, credit score, net worth trend; a natural cross-sell surface. | Spending charts, budget rings, credit score gauge, category breakdown, savings projection |
| Profile | **Profile / More** | Identity, security, documents, settings, support, legal. | Profile header, security center, device sessions, document vault, disclosures archive, support entry |

### Under Explore: product catalog tree
- **Catalog root (category tiles):** Accounts · Cards · Loans · Mortgages · Investments · Insurance.
- **Category landing (per line)** e.g. `Cards`:
  - filterable list of product cards (credit, debit, secured, rewards, travel, Islamic variant)
  - "Featured" and "Recommended for you" rails, compare toggle.
- **Product detail** (one per product): hero, headline rate (APR/APY/profit rate), key features,
  fees table, eligibility summary, representative example, reviews/ratings, FAQ, sticky "Check
  eligibility" / "Apply" CTA.
- **Compare screen:** side-by-side of 2 to 3 products, differences highlighted.
- **Application wizard** (shared, see §3) launched from product detail.

### My Products (servicing area): reachable from Home tiles and Profile
- **My Products overview:** grouped list of everything the user holds (accounts, cards, loans,
  mortgage, investment account, policies) with status chips.
- **Product servicing detail** per holding: balance/limit/rate, statements, controls
  (freeze card, change limit, extra repayment, redraw), documents, "manage" actions.
- **Applications tracker:** in-flight applications with status timeline (Submitted → In review →
  Decision → Funded) and required-action prompts.

### Full screen list (with purpose + key components)
1. **Splash / secure login**: biometric/PIN, device trust. Components: PIN keypad, biometric prompt, device trust banner.
2. **Home Dashboard**: see table above.
3. **Products/Explore catalog root**: category tiles + featured + recommended.
4. **Category landing**: product-card list, filters, compare toggle, pre-qual badges.
5. **Product detail**: rate hero, features, fees, representative example, eligibility, sticky CTA.
6. **Compare products**: 2 to 3 column diff.
7. **Eligibility / pre-qualification (soft check)**: short form, "no impact to credit score" badge, instant result.
8. **Application wizard (multi-step)**: see §3 (customize → offer → KYC → docs → disclosures → e-sign → submitted).
9. **Application submitted / decision**: status, reference number, next steps.
10. **Funding / activation**: fund new account, activate card, set repayment.
11. **My Products overview**: servicing list.
12. **Product servicing detail**: holding management.
13. **Applications tracker**: in-flight status timeline.
14. **Move Money hub + transfer flow**: servicing.
15. **Insights**: spending, budgets, credit score, net worth.
16. **Profile / Security / Documents / Disclosures archive**: identity, controls, legal.
17. **Support / help**: chat/assistant, FAQ, dispute entry.
18. **Empty / error / offline / maintenance states**: reusable state screens.

---

## 2. PRODUCT CATALOG UX (the shelf)

How to present a shelf of products so it reads as a real bank, not a demo:

- **Category tiles** at the root: 6 large tappable tiles (Accounts, Cards, Loans, Mortgages,
  Investments, Insurance), each with icon, one-line value prop, and item count. Optional Revolut-style
  color-coding per category for fast scanning.
- **Product cards** are the atomic unit. Each card carries:
  - Product name + short descriptor and a product-type/brand glyph.
  - **Headline rate**, prominent and single: `APR` for borrowing, `APY`/`profit rate` for deposits,
    `%` return band for investments. Always with an **"as of" date** and a `Representative` qualifier
    where the rate is illustrative.
  - Fee highlight (e.g. "No annual fee", "0% intro 15 mo") and 2 to 3 key features as chips.
  - **Badges:** `Featured`, `Recommended for you`, `Pre-qualified` / `You're likely eligible`
    (soft-check), `New`, `Shariah-compliant`, `Limited time`.
  - Micro-CTA: `Check eligibility` (soft) primary, `Details` secondary. Never lead borrowing cards
    with a raw "Apply" that implies a hard pull.
- **Featured carousel:** 1 to 3 hero products (bank's strategic push), larger card with imagery.
- **"Recommended for you" rail:** personalized from held products + eligibility signals; each item
  states *why* ("Based on your balance", "You may qualify"). Stating the reason plainly helps build trust.
- **Eligibility / pre-qual badges:** the soft-pull front door. Card shows `Won't affect your credit
  score`; tapping runs a short pre-qual form and returns an **instant likelihood** plus the specific
  offer (limit, APR band) *before* the hard-pull application. Pre-qual is explicitly "not a guarantee".
- **Compare:** a select-to-compare toggle adds up to 3 products to a **compare tray**; the compare
  screen aligns rows (rate, fees, features, eligibility) and highlights differences.
- **Filter / sort:** by rate, fee, purpose, term; and a variant switch (Conventional / Islamic) where relevant.

---

## 3. APPLICATION WIZARD PATTERN (reusable)

One flow component, parameterized per product line. Progress indicator (stepper) always visible;
each step is a single focused task (progressive disclosure); back/save-and-exit always available.

**Steps (canonical order):**
1. **Start / eligibility (soft check)**: minimal fields (amount/purpose, income, residency);
   `no impact to credit score` badge; instant pre-qual result.
2. **Customize / calculator**: sliders for amount, term, deposit; live recomputed monthly
   repayment / APR / total cost / payoff date. For cards: choose card + limit band. For investments:
   risk profile + contribution. Live "representative example" recalculates as they move sliders.
3. **Your offer**: the concrete personalized offer: rate (APR/APY), limit/amount, term, monthly
   payment, total repayable, fees. Clear "this is a firm offer valid until <date>" vs "indicative".
4. **About you / KYC**: identity, contact, employment, income; pre-filled for existing customers.
5. **Verify identity & documents**: ID capture, selfie/liveness, proof of income/address upload,
   with per-item checklist and upload states (pending/uploaded/verifying/failed).
6. **Disclosures & consent**: short, scannable, chunked (not one wall of text): key facts document,
   APR & fees summary, **representative example**, terms, privacy/data-sharing consent, marketing opt-in
   (unbundled). Each is an explicit checkbox/accordion, not pre-ticked.
7. **Review & e-sign**: full summary, edit affordances per section, agreement statement, e-signature
   (typed/drawn/checkbox-attested), timestamp.
8. **Submitted / decision**: reference number, expected timeline, status tracker; instant-decision
   products show approved/referred/declined inline with reasons and next steps.
9. **Funding / activation**: fund the account, activate the card, confirm first repayment / direct
   debit, add to wallet. Ends in a "Welcome / it's ready" success state that deep-links into servicing.

**Post-submit / lifecycle:** a **cooling-off / right-to-cancel** notice for regulated credit (state
the window and how to cancel); withdrawal path; and the application appears in the **Applications tracker**.

**What makes it feel trustworthy & compliant:**
- **Rate transparency up front**: headline APR/APY on the card and again on the offer; never buried.
- **Representative example**: the "X borrowed at Y% APR = £Z/mo, £T total" statement, shown before consent.
- **APR / fees disclosure**: full cost breakdown (interest, fees, total repayable) on the offer and review steps.
- **As-of dating** and "indicative vs firm" labeling on every rate.
- **Eligibility stated up front**, not hidden in fine print; soft vs hard credit-check clearly distinguished.
- **Unbundled, un-pre-ticked consents**; plain-language data-sharing permissions (Starling-style).
- **Cooling-off period** and cancellation rights clearly stated for credit products.
- **Save & resume**, session timeout with re-auth, and no dark patterns (no fake scarcity, no buried opt-outs).

---

## 4. WHAT MAKES IT PRODUCTION-GRADE / CEO-APPROVABLE (vs a demo)

- **Content realism:** real product names, plausible rates with as-of dates, real fee tables, proper
  legal microcopy, representative examples, realistic balances and transaction histories: no
  "Lorem ipsum", no "$1,234.56" everywhere, no placeholder logos.
- **Complete states:** every screen has loading (skeletons), empty ("no products yet" with a helpful
  CTA), error, offline, and edge cases (declined, referred, pending verification, expired offer,
  ineligible). Demos only ship the happy path; production ships the unhappy paths.
- **Accessibility:** WCAG AA contrast, dynamic type / scalable text, semantic labels for screen
  readers, 44×44 min touch targets, focus order, no color-only meaning (badges have text/icon too),
  reduced-motion support.
- **Trust signals:** security center, device/session management, biometric gate, "money protection"
  / deposit-insurance banner, masked data with reveal, clear regulator/licensing footer, padlock and
  privacy overlay on app switch. (Kit already has `bank_money_protection_banner`, `bank_app_switcher_privacy_overlay`.)
- **Consistency:** one design system: tokens for color/type/spacing/radius/elevation, one component
  library, consistent iconography, consistent CTA hierarchy and error patterns across all flows.
- **Motion restraint:** subtle, purposeful transitions (shared-element hero, stepper progress, success
  check); no bouncy or gratuitous animation; respects reduced-motion; nothing that delays a banking task.
- **Numbers & formatting:** locale-aware currency, correct rounding, thousands separators, negative
  styling, right-to-left support where relevant (ENBD/Arabic), Hijri date support (kit has `bank_hijri_date`).
- **Compliance surface:** disclosures archive, statements/documents vault, consent history: proof the
  bank keeps records, which is what a CEO/legal review demands before go-live.

---

## 5. CONCRETE BUILD PLAN (priority order for the sample app)

Impressive but achievable. Reuses existing kit components where possible; each tier is shippable.

**Tier 1: the spine (must-have, tells the whole product-suite story):**
1. Products/Explore catalog root (category tiles + featured + recommended rails).
2. Category landing (Cards or Loans) with product cards, pre-qual badges, filter, compare toggle.
3. Product detail (rate hero, features, fees, representative example, eligibility, sticky CTA).
4. Application wizard shell (stepper + save/exit) driving: eligibility → customize/calculator →
   offer → KYC → documents → disclosures/consent → e-sign → submitted.
5. Application submitted / decision state.
6. My Products overview (servicing list) + Applications tracker.

**Tier 2: depth & realism:**
7. Home Dashboard with contextual pre-qual offer card + offers rail.
8. Compare products screen.
9. Product servicing detail (one holding, e.g. loan or card management).
10. Funding / activation success screen.
11. Full state set: loading skeletons, empty, error, offline, ineligible, expired offer, declined.

**Tier 3: polish & breadth:**
12. Second product line end-to-end (e.g. Mortgage with affordability calculator, or Investments with risk profile) to prove the wizard is reusable.
13. Insights cross-sell surface + credit score gauge feeding recommendations.
14. Disclosures archive + document vault in Profile.
15. Accessibility + reduced-motion pass, RTL/Islamic (Shariah) variant demonstration.

---

## 6. COMPONENTS NEEDED (distinct UI widgets)

Catalog/discovery: category tile, product card (rate/APR/APY highlight), featured hero card,
recommended-for-you rail, eligibility/pre-qual badge, "no credit impact" badge, compare tray,
compare table, filter/sort sheet, rate + as-of chip, representative-example block.

Wizard: step progress indicator (stepper), save-&-exit bar, calculator sliders + live result card,
offer summary card, KYC form fields, document/ID upload tile (with states), consent checkbox group,
disclosure accordion, e-signature capture, decision/status result card, funding/activation success card.

Servicing: my-products list tile, holding status chip, application status timeline (tracker),
manage-action row.

Cross-cutting / trust & states: skeleton loaders, empty-state, error-state, offline banner,
money-protection / deposit-insurance banner, masked-value reveal, security/session tiles, currency
formatter, badge set (Featured/New/Limited/Shariah), sticky CTA bar, bottom nav.

(Reusable from existing kit: `bank_bottom_nav_bar`, `bank_quick_actions_grid`, `bank_offers_rail`,
`bank_credit_score_gauge`, `bank_status_tracker`, `bank_money_protection_banner`, `bank_shariah_badge`,
`bank_amount_input_field`, `bank_otp_input`, `bank_kyc_flow_controller`, `bank_savings_projection_card`.)
