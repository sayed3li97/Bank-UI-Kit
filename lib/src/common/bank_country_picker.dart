import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../theme/bank_theme_data.dart';
import '../theme/tokens.dart';
import 'bank_icon_spec.dart';
import 'bank_text_field.dart';

/// An immutable country descriptor used by [BankCountryPicker].
///
/// Flags are rendered as emoji (regional-indicator pairs) so the kit ships
/// no image assets. A bundled list of the world's countries and major
/// territories is available via [BankCountry.all]; hosts that need
/// localised display names can supply their own list through
/// `countriesOverride` on [BankCountryPicker].
@immutable
class BankCountry {
  /// Creates a country descriptor.
  const BankCountry({
    required this.isoCode,
    required this.name,
    required this.flagEmoji,
    required this.dialCode,
    required this.currencyCode,
  });

  /// Compact internal constructor used by the bundled [all] list.
  const BankCountry._(
    this.isoCode,
    this.name,
    this.flagEmoji,
    this.dialCode,
    this.currencyCode,
  );

  /// ISO 3166-1 alpha-2 code, upper-case (e.g. `AE`).
  final String isoCode;

  /// English display name (e.g. `United Arab Emirates`).
  final String name;

  /// Flag emoji built from regional-indicator symbols (e.g. 🇦🇪).
  final String flagEmoji;

  /// International dialling prefix including the `+` (e.g. `+971`).
  final String dialCode;

  /// ISO 4217 code of the primary local currency (e.g. `AED`).
  final String currencyCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BankCountry &&
        other.isoCode == isoCode &&
        other.name == name &&
        other.flagEmoji == flagEmoji &&
        other.dialCode == dialCode &&
        other.currencyCode == currencyCode;
  }

  @override
  int get hashCode =>
      Object.hash(isoCode, name, flagEmoji, dialCode, currencyCode);

  @override
  String toString() => 'BankCountry($isoCode, $name)';

  /// The bundled list of countries and major territories.
  ///
  /// Names are in English; supply `countriesOverride` on
  /// [BankCountryPicker] for localised names.
  static const List<BankCountry> all = <BankCountry>[
    BankCountry._('AF', 'Afghanistan', '🇦🇫', '+93', 'AFN'),
    BankCountry._('AL', 'Albania', '🇦🇱', '+355', 'ALL'),
    BankCountry._('DZ', 'Algeria', '🇩🇿', '+213', 'DZD'),
    BankCountry._('AS', 'American Samoa', '🇦🇸', '+1684', 'USD'),
    BankCountry._('AD', 'Andorra', '🇦🇩', '+376', 'EUR'),
    BankCountry._('AO', 'Angola', '🇦🇴', '+244', 'AOA'),
    BankCountry._('AI', 'Anguilla', '🇦🇮', '+1264', 'XCD'),
    BankCountry._('AG', 'Antigua and Barbuda', '🇦🇬', '+1268', 'XCD'),
    BankCountry._('AR', 'Argentina', '🇦🇷', '+54', 'ARS'),
    BankCountry._('AM', 'Armenia', '🇦🇲', '+374', 'AMD'),
    BankCountry._('AW', 'Aruba', '🇦🇼', '+297', 'AWG'),
    BankCountry._('AU', 'Australia', '🇦🇺', '+61', 'AUD'),
    BankCountry._('AT', 'Austria', '🇦🇹', '+43', 'EUR'),
    BankCountry._('AZ', 'Azerbaijan', '🇦🇿', '+994', 'AZN'),
    BankCountry._('BS', 'Bahamas', '🇧🇸', '+1242', 'BSD'),
    BankCountry._('BH', 'Bahrain', '🇧🇭', '+973', 'BHD'),
    BankCountry._('BD', 'Bangladesh', '🇧🇩', '+880', 'BDT'),
    BankCountry._('BB', 'Barbados', '🇧🇧', '+1246', 'BBD'),
    BankCountry._('BY', 'Belarus', '🇧🇾', '+375', 'BYN'),
    BankCountry._('BE', 'Belgium', '🇧🇪', '+32', 'EUR'),
    BankCountry._('BZ', 'Belize', '🇧🇿', '+501', 'BZD'),
    BankCountry._('BJ', 'Benin', '🇧🇯', '+229', 'XOF'),
    BankCountry._('BM', 'Bermuda', '🇧🇲', '+1441', 'BMD'),
    BankCountry._('BT', 'Bhutan', '🇧🇹', '+975', 'BTN'),
    BankCountry._('BO', 'Bolivia', '🇧🇴', '+591', 'BOB'),
    BankCountry._('BA', 'Bosnia and Herzegovina', '🇧🇦', '+387', 'BAM'),
    BankCountry._('BW', 'Botswana', '🇧🇼', '+267', 'BWP'),
    BankCountry._('BR', 'Brazil', '🇧🇷', '+55', 'BRL'),
    BankCountry._('VG', 'British Virgin Islands', '🇻🇬', '+1284', 'USD'),
    BankCountry._('BN', 'Brunei', '🇧🇳', '+673', 'BND'),
    BankCountry._('BG', 'Bulgaria', '🇧🇬', '+359', 'BGN'),
    BankCountry._('BF', 'Burkina Faso', '🇧🇫', '+226', 'XOF'),
    BankCountry._('BI', 'Burundi', '🇧🇮', '+257', 'BIF'),
    BankCountry._('KH', 'Cambodia', '🇰🇭', '+855', 'KHR'),
    BankCountry._('CM', 'Cameroon', '🇨🇲', '+237', 'XAF'),
    BankCountry._('CA', 'Canada', '🇨🇦', '+1', 'CAD'),
    BankCountry._('CV', 'Cape Verde', '🇨🇻', '+238', 'CVE'),
    BankCountry._('KY', 'Cayman Islands', '🇰🇾', '+1345', 'KYD'),
    BankCountry._('CF', 'Central African Republic', '🇨🇫', '+236', 'XAF'),
    BankCountry._('TD', 'Chad', '🇹🇩', '+235', 'XAF'),
    BankCountry._('CL', 'Chile', '🇨🇱', '+56', 'CLP'),
    BankCountry._('CN', 'China', '🇨🇳', '+86', 'CNY'),
    BankCountry._('CO', 'Colombia', '🇨🇴', '+57', 'COP'),
    BankCountry._('KM', 'Comoros', '🇰🇲', '+269', 'KMF'),
    BankCountry._('CG', 'Congo - Brazzaville', '🇨🇬', '+242', 'XAF'),
    BankCountry._('CD', 'Congo - Kinshasa', '🇨🇩', '+243', 'CDF'),
    BankCountry._('CK', 'Cook Islands', '🇨🇰', '+682', 'NZD'),
    BankCountry._('CR', 'Costa Rica', '🇨🇷', '+506', 'CRC'),
    BankCountry._('CI', 'Côte d\'Ivoire', '🇨🇮', '+225', 'XOF'),
    BankCountry._('HR', 'Croatia', '🇭🇷', '+385', 'EUR'),
    BankCountry._('CU', 'Cuba', '🇨🇺', '+53', 'CUP'),
    BankCountry._('CW', 'Curaçao', '🇨🇼', '+599', 'ANG'),
    BankCountry._('CY', 'Cyprus', '🇨🇾', '+357', 'EUR'),
    BankCountry._('CZ', 'Czechia', '🇨🇿', '+420', 'CZK'),
    BankCountry._('DK', 'Denmark', '🇩🇰', '+45', 'DKK'),
    BankCountry._('DJ', 'Djibouti', '🇩🇯', '+253', 'DJF'),
    BankCountry._('DM', 'Dominica', '🇩🇲', '+1767', 'XCD'),
    BankCountry._('DO', 'Dominican Republic', '🇩🇴', '+1809', 'DOP'),
    BankCountry._('EC', 'Ecuador', '🇪🇨', '+593', 'USD'),
    BankCountry._('EG', 'Egypt', '🇪🇬', '+20', 'EGP'),
    BankCountry._('SV', 'El Salvador', '🇸🇻', '+503', 'USD'),
    BankCountry._('GQ', 'Equatorial Guinea', '🇬🇶', '+240', 'XAF'),
    BankCountry._('ER', 'Eritrea', '🇪🇷', '+291', 'ERN'),
    BankCountry._('EE', 'Estonia', '🇪🇪', '+372', 'EUR'),
    BankCountry._('SZ', 'Eswatini', '🇸🇿', '+268', 'SZL'),
    BankCountry._('ET', 'Ethiopia', '🇪🇹', '+251', 'ETB'),
    BankCountry._('FK', 'Falkland Islands', '🇫🇰', '+500', 'FKP'),
    BankCountry._('FO', 'Faroe Islands', '🇫🇴', '+298', 'DKK'),
    BankCountry._('FJ', 'Fiji', '🇫🇯', '+679', 'FJD'),
    BankCountry._('FI', 'Finland', '🇫🇮', '+358', 'EUR'),
    BankCountry._('FR', 'France', '🇫🇷', '+33', 'EUR'),
    BankCountry._('GF', 'French Guiana', '🇬🇫', '+594', 'EUR'),
    BankCountry._('PF', 'French Polynesia', '🇵🇫', '+689', 'XPF'),
    BankCountry._('GA', 'Gabon', '🇬🇦', '+241', 'XAF'),
    BankCountry._('GM', 'Gambia', '🇬🇲', '+220', 'GMD'),
    BankCountry._('GE', 'Georgia', '🇬🇪', '+995', 'GEL'),
    BankCountry._('DE', 'Germany', '🇩🇪', '+49', 'EUR'),
    BankCountry._('GH', 'Ghana', '🇬🇭', '+233', 'GHS'),
    BankCountry._('GI', 'Gibraltar', '🇬🇮', '+350', 'GIP'),
    BankCountry._('GR', 'Greece', '🇬🇷', '+30', 'EUR'),
    BankCountry._('GL', 'Greenland', '🇬🇱', '+299', 'DKK'),
    BankCountry._('GD', 'Grenada', '🇬🇩', '+1473', 'XCD'),
    BankCountry._('GP', 'Guadeloupe', '🇬🇵', '+590', 'EUR'),
    BankCountry._('GU', 'Guam', '🇬🇺', '+1671', 'USD'),
    BankCountry._('GT', 'Guatemala', '🇬🇹', '+502', 'GTQ'),
    BankCountry._('GG', 'Guernsey', '🇬🇬', '+44', 'GBP'),
    BankCountry._('GN', 'Guinea', '🇬🇳', '+224', 'GNF'),
    BankCountry._('GW', 'Guinea-Bissau', '🇬🇼', '+245', 'XOF'),
    BankCountry._('GY', 'Guyana', '🇬🇾', '+592', 'GYD'),
    BankCountry._('HT', 'Haiti', '🇭🇹', '+509', 'HTG'),
    BankCountry._('HN', 'Honduras', '🇭🇳', '+504', 'HNL'),
    BankCountry._('HK', 'Hong Kong', '🇭🇰', '+852', 'HKD'),
    BankCountry._('HU', 'Hungary', '🇭🇺', '+36', 'HUF'),
    BankCountry._('IS', 'Iceland', '🇮🇸', '+354', 'ISK'),
    BankCountry._('IN', 'India', '🇮🇳', '+91', 'INR'),
    BankCountry._('ID', 'Indonesia', '🇮🇩', '+62', 'IDR'),
    BankCountry._('IR', 'Iran', '🇮🇷', '+98', 'IRR'),
    BankCountry._('IQ', 'Iraq', '🇮🇶', '+964', 'IQD'),
    BankCountry._('IE', 'Ireland', '🇮🇪', '+353', 'EUR'),
    BankCountry._('IM', 'Isle of Man', '🇮🇲', '+44', 'GBP'),
    BankCountry._('IL', 'Israel', '🇮🇱', '+972', 'ILS'),
    BankCountry._('IT', 'Italy', '🇮🇹', '+39', 'EUR'),
    BankCountry._('JM', 'Jamaica', '🇯🇲', '+1876', 'JMD'),
    BankCountry._('JP', 'Japan', '🇯🇵', '+81', 'JPY'),
    BankCountry._('JE', 'Jersey', '🇯🇪', '+44', 'GBP'),
    BankCountry._('JO', 'Jordan', '🇯🇴', '+962', 'JOD'),
    BankCountry._('KZ', 'Kazakhstan', '🇰🇿', '+7', 'KZT'),
    BankCountry._('KE', 'Kenya', '🇰🇪', '+254', 'KES'),
    BankCountry._('KI', 'Kiribati', '🇰🇮', '+686', 'AUD'),
    BankCountry._('XK', 'Kosovo', '🇽🇰', '+383', 'EUR'),
    BankCountry._('KW', 'Kuwait', '🇰🇼', '+965', 'KWD'),
    BankCountry._('KG', 'Kyrgyzstan', '🇰🇬', '+996', 'KGS'),
    BankCountry._('LA', 'Laos', '🇱🇦', '+856', 'LAK'),
    BankCountry._('LV', 'Latvia', '🇱🇻', '+371', 'EUR'),
    BankCountry._('LB', 'Lebanon', '🇱🇧', '+961', 'LBP'),
    BankCountry._('LS', 'Lesotho', '🇱🇸', '+266', 'LSL'),
    BankCountry._('LR', 'Liberia', '🇱🇷', '+231', 'LRD'),
    BankCountry._('LY', 'Libya', '🇱🇾', '+218', 'LYD'),
    BankCountry._('LI', 'Liechtenstein', '🇱🇮', '+423', 'CHF'),
    BankCountry._('LT', 'Lithuania', '🇱🇹', '+370', 'EUR'),
    BankCountry._('LU', 'Luxembourg', '🇱🇺', '+352', 'EUR'),
    BankCountry._('MO', 'Macao', '🇲🇴', '+853', 'MOP'),
    BankCountry._('MG', 'Madagascar', '🇲🇬', '+261', 'MGA'),
    BankCountry._('MW', 'Malawi', '🇲🇼', '+265', 'MWK'),
    BankCountry._('MY', 'Malaysia', '🇲🇾', '+60', 'MYR'),
    BankCountry._('MV', 'Maldives', '🇲🇻', '+960', 'MVR'),
    BankCountry._('ML', 'Mali', '🇲🇱', '+223', 'XOF'),
    BankCountry._('MT', 'Malta', '🇲🇹', '+356', 'EUR'),
    BankCountry._('MH', 'Marshall Islands', '🇲🇭', '+692', 'USD'),
    BankCountry._('MQ', 'Martinique', '🇲🇶', '+596', 'EUR'),
    BankCountry._('MR', 'Mauritania', '🇲🇷', '+222', 'MRU'),
    BankCountry._('MU', 'Mauritius', '🇲🇺', '+230', 'MUR'),
    BankCountry._('YT', 'Mayotte', '🇾🇹', '+262', 'EUR'),
    BankCountry._('MX', 'Mexico', '🇲🇽', '+52', 'MXN'),
    BankCountry._('FM', 'Micronesia', '🇫🇲', '+691', 'USD'),
    BankCountry._('MD', 'Moldova', '🇲🇩', '+373', 'MDL'),
    BankCountry._('MC', 'Monaco', '🇲🇨', '+377', 'EUR'),
    BankCountry._('MN', 'Mongolia', '🇲🇳', '+976', 'MNT'),
    BankCountry._('ME', 'Montenegro', '🇲🇪', '+382', 'EUR'),
    BankCountry._('MS', 'Montserrat', '🇲🇸', '+1664', 'XCD'),
    BankCountry._('MA', 'Morocco', '🇲🇦', '+212', 'MAD'),
    BankCountry._('MZ', 'Mozambique', '🇲🇿', '+258', 'MZN'),
    BankCountry._('MM', 'Myanmar', '🇲🇲', '+95', 'MMK'),
    BankCountry._('NA', 'Namibia', '🇳🇦', '+264', 'NAD'),
    BankCountry._('NR', 'Nauru', '🇳🇷', '+674', 'AUD'),
    BankCountry._('NP', 'Nepal', '🇳🇵', '+977', 'NPR'),
    BankCountry._('NL', 'Netherlands', '🇳🇱', '+31', 'EUR'),
    BankCountry._('NC', 'New Caledonia', '🇳🇨', '+687', 'XPF'),
    BankCountry._('NZ', 'New Zealand', '🇳🇿', '+64', 'NZD'),
    BankCountry._('NI', 'Nicaragua', '🇳🇮', '+505', 'NIO'),
    BankCountry._('NE', 'Niger', '🇳🇪', '+227', 'XOF'),
    BankCountry._('NG', 'Nigeria', '🇳🇬', '+234', 'NGN'),
    BankCountry._('NU', 'Niue', '🇳🇺', '+683', 'NZD'),
    BankCountry._('KP', 'North Korea', '🇰🇵', '+850', 'KPW'),
    BankCountry._('MK', 'North Macedonia', '🇲🇰', '+389', 'MKD'),
    BankCountry._('MP', 'Northern Mariana Islands', '🇲🇵', '+1670', 'USD'),
    BankCountry._('NO', 'Norway', '🇳🇴', '+47', 'NOK'),
    BankCountry._('OM', 'Oman', '🇴🇲', '+968', 'OMR'),
    BankCountry._('PK', 'Pakistan', '🇵🇰', '+92', 'PKR'),
    BankCountry._('PW', 'Palau', '🇵🇼', '+680', 'USD'),
    BankCountry._('PS', 'Palestine', '🇵🇸', '+970', 'ILS'),
    BankCountry._('PA', 'Panama', '🇵🇦', '+507', 'PAB'),
    BankCountry._('PG', 'Papua New Guinea', '🇵🇬', '+675', 'PGK'),
    BankCountry._('PY', 'Paraguay', '🇵🇾', '+595', 'PYG'),
    BankCountry._('PE', 'Peru', '🇵🇪', '+51', 'PEN'),
    BankCountry._('PH', 'Philippines', '🇵🇭', '+63', 'PHP'),
    BankCountry._('PL', 'Poland', '🇵🇱', '+48', 'PLN'),
    BankCountry._('PT', 'Portugal', '🇵🇹', '+351', 'EUR'),
    BankCountry._('PR', 'Puerto Rico', '🇵🇷', '+1787', 'USD'),
    BankCountry._('QA', 'Qatar', '🇶🇦', '+974', 'QAR'),
    BankCountry._('RE', 'Réunion', '🇷🇪', '+262', 'EUR'),
    BankCountry._('RO', 'Romania', '🇷🇴', '+40', 'RON'),
    BankCountry._('RU', 'Russia', '🇷🇺', '+7', 'RUB'),
    BankCountry._('RW', 'Rwanda', '🇷🇼', '+250', 'RWF'),
    BankCountry._('BL', 'Saint Barthélemy', '🇧🇱', '+590', 'EUR'),
    BankCountry._('SH', 'Saint Helena', '🇸🇭', '+290', 'SHP'),
    BankCountry._('KN', 'Saint Kitts and Nevis', '🇰🇳', '+1869', 'XCD'),
    BankCountry._('LC', 'Saint Lucia', '🇱🇨', '+1758', 'XCD'),
    BankCountry._('MF', 'Saint Martin', '🇲🇫', '+590', 'EUR'),
    BankCountry._('PM', 'Saint Pierre and Miquelon', '🇵🇲', '+508', 'EUR'),
    BankCountry._(
      'VC',
      'Saint Vincent and the Grenadines',
      '🇻🇨',
      '+1784',
      'XCD',
    ),
    BankCountry._('WS', 'Samoa', '🇼🇸', '+685', 'WST'),
    BankCountry._('SM', 'San Marino', '🇸🇲', '+378', 'EUR'),
    BankCountry._('ST', 'São Tomé and Príncipe', '🇸🇹', '+239', 'STN'),
    BankCountry._('SA', 'Saudi Arabia', '🇸🇦', '+966', 'SAR'),
    BankCountry._('SN', 'Senegal', '🇸🇳', '+221', 'XOF'),
    BankCountry._('RS', 'Serbia', '🇷🇸', '+381', 'RSD'),
    BankCountry._('SC', 'Seychelles', '🇸🇨', '+248', 'SCR'),
    BankCountry._('SL', 'Sierra Leone', '🇸🇱', '+232', 'SLL'),
    BankCountry._('SG', 'Singapore', '🇸🇬', '+65', 'SGD'),
    BankCountry._('SX', 'Sint Maarten', '🇸🇽', '+1721', 'ANG'),
    BankCountry._('SK', 'Slovakia', '🇸🇰', '+421', 'EUR'),
    BankCountry._('SI', 'Slovenia', '🇸🇮', '+386', 'EUR'),
    BankCountry._('SB', 'Solomon Islands', '🇸🇧', '+677', 'SBD'),
    BankCountry._('SO', 'Somalia', '🇸🇴', '+252', 'SOS'),
    BankCountry._('ZA', 'South Africa', '🇿🇦', '+27', 'ZAR'),
    BankCountry._('KR', 'South Korea', '🇰🇷', '+82', 'KRW'),
    BankCountry._('SS', 'South Sudan', '🇸🇸', '+211', 'SSP'),
    BankCountry._('ES', 'Spain', '🇪🇸', '+34', 'EUR'),
    BankCountry._('LK', 'Sri Lanka', '🇱🇰', '+94', 'LKR'),
    BankCountry._('SD', 'Sudan', '🇸🇩', '+249', 'SDG'),
    BankCountry._('SR', 'Suriname', '🇸🇷', '+597', 'SRD'),
    BankCountry._('SE', 'Sweden', '🇸🇪', '+46', 'SEK'),
    BankCountry._('CH', 'Switzerland', '🇨🇭', '+41', 'CHF'),
    BankCountry._('SY', 'Syria', '🇸🇾', '+963', 'SYP'),
    BankCountry._('TW', 'Taiwan', '🇹🇼', '+886', 'TWD'),
    BankCountry._('TJ', 'Tajikistan', '🇹🇯', '+992', 'TJS'),
    BankCountry._('TZ', 'Tanzania', '🇹🇿', '+255', 'TZS'),
    BankCountry._('TH', 'Thailand', '🇹🇭', '+66', 'THB'),
    BankCountry._('TL', 'Timor-Leste', '🇹🇱', '+670', 'USD'),
    BankCountry._('TG', 'Togo', '🇹🇬', '+228', 'XOF'),
    BankCountry._('TK', 'Tokelau', '🇹🇰', '+690', 'NZD'),
    BankCountry._('TO', 'Tonga', '🇹🇴', '+676', 'TOP'),
    BankCountry._('TT', 'Trinidad and Tobago', '🇹🇹', '+1868', 'TTD'),
    BankCountry._('TN', 'Tunisia', '🇹🇳', '+216', 'TND'),
    BankCountry._('TR', 'Türkiye', '🇹🇷', '+90', 'TRY'),
    BankCountry._('TM', 'Turkmenistan', '🇹🇲', '+993', 'TMT'),
    BankCountry._('TC', 'Turks and Caicos Islands', '🇹🇨', '+1649', 'USD'),
    BankCountry._('TV', 'Tuvalu', '🇹🇻', '+688', 'AUD'),
    BankCountry._('VI', 'U.S. Virgin Islands', '🇻🇮', '+1340', 'USD'),
    BankCountry._('UG', 'Uganda', '🇺🇬', '+256', 'UGX'),
    BankCountry._('UA', 'Ukraine', '🇺🇦', '+380', 'UAH'),
    BankCountry._('AE', 'United Arab Emirates', '🇦🇪', '+971', 'AED'),
    BankCountry._('GB', 'United Kingdom', '🇬🇧', '+44', 'GBP'),
    BankCountry._('US', 'United States', '🇺🇸', '+1', 'USD'),
    BankCountry._('UY', 'Uruguay', '🇺🇾', '+598', 'UYU'),
    BankCountry._('UZ', 'Uzbekistan', '🇺🇿', '+998', 'UZS'),
    BankCountry._('VU', 'Vanuatu', '🇻🇺', '+678', 'VUV'),
    BankCountry._('VA', 'Vatican City', '🇻🇦', '+379', 'EUR'),
    BankCountry._('VE', 'Venezuela', '🇻🇪', '+58', 'VES'),
    BankCountry._('VN', 'Vietnam', '🇻🇳', '+84', 'VND'),
    BankCountry._('WF', 'Wallis and Futuna', '🇼🇫', '+681', 'XPF'),
    BankCountry._('EH', 'Western Sahara', '🇪🇭', '+212', 'MAD'),
    BankCountry._('YE', 'Yemen', '🇾🇪', '+967', 'YER'),
    BankCountry._('ZM', 'Zambia', '🇿🇲', '+260', 'ZMW'),
    BankCountry._('ZW', 'Zimbabwe', '🇿🇼', '+263', 'ZWL'),
  ];
}

/// Searchable country selection field with an accompanying modal sheet.
///
/// The field renders the selected country's flag emoji and name (plus the
/// dial code when [showDialCode] is `true`) inside [BankTextField]-style
/// chrome with a trailing chevron. Tapping it opens a 70 %-height modal
/// bottom sheet (drag handle, pinned search field, alphabetically grouped
/// list with sticky letter headers, 48 px rows, checkmark on the selected
/// row). The sheet can also be presented directly via [show].
///
/// Use it for residency, nationality, dial-code, or remittance-destination
/// selection in onboarding and transfer flows.
///
/// ```dart
/// BankCountryPicker(
///   onSelected: (country) => setState(() => _country = country),
///   selected: _country,
///   label: 'Country of residence',
///   showDialCode: true,
///   recentIsoCodes: const ['AE', 'GB', 'US'],
/// )
/// ```
///
/// Hosts needing localised country names can pass [countriesOverride];
/// otherwise the bundled English [BankCountry.all] list is used.
class BankCountryPicker extends StatelessWidget {
  /// Creates a country picker field.
  const BankCountryPicker({
    required this.onSelected,
    super.key,
    this.selected,
    this.label,
    this.showDialCode = false,
    this.enabled = true,
    this.countriesOverride,
    this.recentIsoCodes = const <String>[],
    this.placeholder = 'Select country',
    this.searchHint = 'Search by name, code, or dial code',
    this.recentLabel = 'Recent',
    this.emptyLabel = 'No countries found',
  });

  /// Called with the country the user picked from the sheet.
  final ValueChanged<BankCountry> onSelected;

  /// The currently selected country, or `null` when nothing is selected.
  final BankCountry? selected;

  /// Optional label rendered above the field.
  final String? label;

  /// Whether to render the dial code next to the country name (field and
  /// sheet rows).
  final bool showDialCode;

  /// When `false` the field is greyed out and does not open the sheet.
  final bool enabled;

  /// Replacement country list (e.g. localised names). Defaults to
  /// [BankCountry.all].
  final List<BankCountry>? countriesOverride;

  /// ISO codes rendered in a pinned "Recent" section at the top of the
  /// sheet, in the given order. Unknown codes are ignored.
  final List<String> recentIsoCodes;

  /// Placeholder text shown in the field when [selected] is `null`.
  final String placeholder;

  /// Hint for the sheet's search field.
  final String searchHint;

  /// Header label of the recently-selected section in the sheet.
  final String recentLabel;

  /// Message shown when the search query matches no country.
  final String emptyLabel;

  // ---------------------------------------------------------------------------
  // Static helper — modal presentation
  // ---------------------------------------------------------------------------

  /// Presents the country selection sheet and returns the country the user
  /// tapped, or `null` if the sheet was dismissed.
  ///
  /// The sheet occupies 70 % of the screen height and contains a drag
  /// handle, a pinned search field (filtering by name, ISO code, or dial
  /// code), and an alphabetically grouped list with sticky letter headers.
  static Future<BankCountry?> show(
    BuildContext context, {
    BankCountry? selected,
    List<BankCountry>? countriesOverride,
    List<String> recentIsoCodes = const <String>[],
    bool showDialCode = false,
    String searchHint = 'Search by name, code, or dial code',
    String recentLabel = 'Recent',
    String emptyLabel = 'No countries found',
  }) =>
      showModalBottomSheet<BankCountry>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (BuildContext sheetContext) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: _BankCountrySheet(
            countries: countriesOverride ?? BankCountry.all,
            selectedIsoCode: selected?.isoCode,
            recentIsoCodes: recentIsoCodes,
            showDialCode: showDialCode,
            searchHint: searchHint,
            recentLabel: recentLabel,
            emptyLabel: emptyLabel,
            onSelected: (BankCountry country) =>
                Navigator.of(sheetContext).pop(country),
          ),
        ),
      );

  Future<void> _openSheet(BuildContext context) async {
    final result = await show(
      context,
      selected: selected,
      countriesOverride: countriesOverride,
      recentIsoCodes: recentIsoCodes,
      showDialCode: showDialCode,
      searchHint: searchHint,
      recentLabel: recentLabel,
      emptyLabel: emptyLabel,
    );
    if (result != null) onSelected(result);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final country = selected;
    final hasValue = country != null;

    final valueColor = enabled
        ? (hasValue ? theme.onSurface : theme.onSurfaceVariant)
        : theme.onSurfaceVariant;

    final semanticLabel = StringBuffer()
      ..write(label ?? placeholder)
      ..write(
        hasValue
            ? ', ${country.name}'
                '${showDialCode ? ", ${country.dialCode}" : ""}'
            : ', $placeholder',
      );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: BankTokens.space2),
            child: Text(
              label!,
              style: BankTokens.labelMedium.copyWith(color: theme.onSurface),
            ),
          ),
        Semantics(
          label: semanticLabel.toString(),
          button: true,
          enabled: enabled,
          child: Material(
            color: enabled ? theme.surface : theme.surfaceVariant,
            shape: RoundedRectangleBorder(
              borderRadius: theme.buttonRadius,
              side: BorderSide(
                color: enabled
                    ? theme.outline
                    : theme.outline.withValues(alpha: 0.4),
              ),
            ),
            child: InkWell(
              onTap: enabled ? () => _openSheet(context) : null,
              borderRadius: theme.buttonRadius,
              splashColor: theme.primary.withValues(alpha: 0.08),
              highlightColor: theme.primary.withValues(alpha: 0.04),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: BankTokens.minTapTarget + BankTokens.space1,
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: BankTokens.space4,
                    vertical: BankTokens.space3,
                  ),
                  child: Row(
                    children: [
                      if (hasValue) ...[
                        ExcludeSemantics(
                          child: Text(
                            country.flagEmoji,
                            style: BankTokens.headlineSmall,
                          ),
                        ),
                        const SizedBox(width: BankTokens.space3),
                      ],
                      Expanded(
                        child: Text(
                          hasValue ? country.name : placeholder,
                          style: BankTokens.bodyLarge.copyWith(
                            color: valueColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasValue && showDialCode) ...[
                        const SizedBox(width: BankTokens.space3),
                        Text(
                          country.dialCode,
                          style: BankTokens.bodyMedium.copyWith(
                            color: theme.onSurfaceVariant,
                          ),
                          // Dial codes are always LTR regardless of locale.
                          textDirection: TextDirection.ltr,
                        ),
                      ],
                      const SizedBox(width: BankTokens.space2),
                      Icon(
                        BankIcons.expand,
                        color: theme.onSurfaceVariant,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Internal sheet
// ---------------------------------------------------------------------------

/// The 70 %-height selection sheet: drag handle, pinned search field, and
/// an alphabetically grouped country list with sticky letter headers.
class _BankCountrySheet extends StatefulWidget {
  const _BankCountrySheet({
    required this.countries,
    required this.recentIsoCodes,
    required this.showDialCode,
    required this.searchHint,
    required this.recentLabel,
    required this.emptyLabel,
    required this.onSelected,
    this.selectedIsoCode,
  });

  final List<BankCountry> countries;
  final List<String> recentIsoCodes;
  final bool showDialCode;
  final String searchHint;
  final String recentLabel;
  final String emptyLabel;
  final ValueChanged<BankCountry> onSelected;
  final String? selectedIsoCode;

  @override
  State<_BankCountrySheet> createState() => _BankCountrySheetState();
}

class _BankCountrySheetState extends State<_BankCountrySheet> {
  String _query = '';

  /// Countries matching the current query by name, ISO code, or dial code.
  List<BankCountry> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.countries;
    final digits = q.startsWith('+') ? q.substring(1) : q;
    return widget.countries
        .where(
          (BankCountry c) =>
              c.name.toLowerCase().contains(q) ||
              c.isoCode.toLowerCase().contains(q) ||
              (digits.isNotEmpty &&
                  c.dialCode.replaceFirst('+', '').contains(digits)),
        )
        .toList();
  }

  /// Countries for the recently-selected section, in given order.
  List<BankCountry> get _recent {
    final recent = <BankCountry>[];
    for (final iso in widget.recentIsoCodes) {
      final match = widget.countries
          .firstWhereOrNull((BankCountry c) => c.isoCode == iso);
      if (match != null) recent.add(match);
    }
    return recent;
  }

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.70;

    final filtered = _filtered;
    final queryEmpty = _query.trim().isEmpty;
    final recent = queryEmpty ? _recent : const <BankCountry>[];

    // Alphabetical groups keyed by the first letter of the name.
    final groups = SplayTreeMap<String, List<BankCountry>>();
    for (final country in filtered) {
      groups
          .putIfAbsent(
            country.name.substring(0, 1).toUpperCase(),
            () => <BankCountry>[],
          )
          .add(country);
    }
    for (final group in groups.values) {
      group.sort(
        (BankCountry a, BankCountry b) => a.name.compareTo(b.name),
      );
    }

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: theme.sheetRadius,
      ),
      child: Column(
        children: [
          // Drag handle.
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: BankTokens.space3),
              decoration: BoxDecoration(
                color: theme.outline,
                borderRadius: const BorderRadius.all(
                  Radius.circular(BankTokens.radiusFull),
                ),
              ),
            ),
          ),

          // Pinned search field.
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: BankTokens.space4,
              end: BankTokens.space4,
              bottom: BankTokens.space3,
            ),
            child: BankTextField(
              hint: widget.searchHint,
              prefixIcon: const Icon(BankIcons.search),
              onChanged: (String value) => setState(() => _query = value),
            ),
          ),

          // Country list / empty state.
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(BankTokens.space6),
                      child: Text(
                        widget.emptyLabel,
                        style: BankTokens.bodyMedium.copyWith(
                          color: theme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : CustomScrollView(
                    slivers: [
                      if (recent.isNotEmpty)
                        _group(theme, widget.recentLabel, recent),
                      for (final entry in groups.entries)
                        _group(theme, entry.key, entry.value),
                      SliverPadding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.paddingOf(context).bottom +
                              BankTokens.space4,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  /// A sticky letter header followed by its rows.
  Widget _group(
    BankThemeData theme,
    String header,
    List<BankCountry> countries,
  ) =>
      SliverMainAxisGroup(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _LetterHeaderDelegate(label: header, theme: theme),
          ),
          SliverList.builder(
            itemCount: countries.length,
            itemBuilder: (BuildContext context, int index) {
              final country = countries[index];
              return _CountryRow(
                country: country,
                isSelected: country.isoCode == widget.selectedIsoCode,
                showDialCode: widget.showDialCode,
                theme: theme,
                onTap: () => widget.onSelected(country),
              );
            },
          ),
        ],
      );
}

// ---------------------------------------------------------------------------
// Internal sticky letter header
// ---------------------------------------------------------------------------

/// Fixed-height sticky header showing a group letter (or "Recent").
class _LetterHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _LetterHeaderDelegate({required this.label, required this.theme});

  final String label;
  final BankThemeData theme;

  static const double _height = 32;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) =>
      Semantics(
        header: true,
        child: ColoredBox(
          color: theme.surface,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(
              start: BankTokens.space4,
              end: BankTokens.space4,
            ),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                label,
                style: BankTokens.labelMedium.copyWith(
                  color: theme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      );

  @override
  bool shouldRebuild(covariant _LetterHeaderDelegate oldDelegate) =>
      label != oldDelegate.label || theme != oldDelegate.theme;
}

// ---------------------------------------------------------------------------
// Internal row widget
// ---------------------------------------------------------------------------

/// A single 48 px country row: flag emoji, name, optional dial code, and a
/// checkmark when selected. Satisfies the 44 px minimum tap-target rule.
class _CountryRow extends StatelessWidget {
  const _CountryRow({
    required this.country,
    required this.isSelected,
    required this.showDialCode,
    required this.theme,
    required this.onTap,
  });

  final BankCountry country;
  final bool isSelected;
  final bool showDialCode;
  final BankThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final semanticLabel = '${country.name}, dial code ${country.dialCode}'
        '${isSelected ? ", selected" : ""}';

    return Semantics(
      label: semanticLabel,
      button: true,
      selected: isSelected,
      child: SizedBox(
        height: 48,
        child: InkWell(
          onTap: onTap,
          splashColor: theme.primary.withValues(alpha: 0.08),
          highlightColor: theme.primary.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: BankTokens.space4,
            ),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Text(
                    country.flagEmoji,
                    style: BankTokens.headlineSmall,
                  ),
                ),
                const SizedBox(width: BankTokens.space3),
                Expanded(
                  child: Text(
                    country.name,
                    style: BankTokens.bodyLarge.copyWith(
                      color: theme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (showDialCode) ...[
                  const SizedBox(width: BankTokens.space3),
                  Text(
                    country.dialCode,
                    style: BankTokens.bodyMedium.copyWith(
                      color: theme.onSurfaceVariant,
                    ),
                    // Dial codes are always LTR regardless of locale.
                    textDirection: TextDirection.ltr,
                  ),
                ],
                if (isSelected) ...[
                  const SizedBox(width: BankTokens.space2),
                  Icon(
                    Icons.check_circle,
                    color: theme.primary,
                    size: 18,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
