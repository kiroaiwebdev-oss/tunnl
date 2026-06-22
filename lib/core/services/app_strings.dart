// lib/core/services/app_strings.dart
//
// Lightweight app-wide i18n (English / Hindi).
//
// Usage:  Text(tr('Home'))   →   shows "होम" when the user picked Hindi.
//
// Design notes:
//  • Keyed on the ENGLISH source string, so wrapping a literal is a one-liner
//    and there is no separate "key" to keep in sync.
//  • Falls back to the English source whenever language = English OR no Hindi
//    translation exists — it can NEVER throw and never returns an empty string.
//  • Reads the live value from LanguageService, so the same call site renders
//    the right language after the user toggles it (the widget tree rebuilds via
//    the ListenableBuilder wired into main.dart).

import 'language_service.dart';

/// Translate [en] to the active language (English source is the lookup key).
String tr(String en) {
  if (!LanguageService.instance.isHindi) return en;
  final hi = _hi[en];
  return (hi == null || hi.isEmpty) ? en : hi;
}

/// Convenience: pick between an explicit English and Hindi value.
String trPick(String en, String hi) =>
    LanguageService.instance.isHindi && hi.trim().isNotEmpty ? hi : en;

// ─────────────────────────────────────────────────────────────────────────
// English → Hindi dictionary. Add entries here to grow coverage; any string
// not present simply stays in English, so partial coverage is always safe.
// ─────────────────────────────────────────────────────────────────────────
const Map<String, String> _hi = {
  // ── Common / navigation ──
  'Home': 'होम',
  'Profile': 'प्रोफ़ाइल',
  'Dashboard': 'डैशबोर्ड',
  'Shorts': 'शॉर्ट्स',
  'Leaderboard': 'लीडरबोर्ड',
  'Login': 'लॉगिन',
  'Logout': 'लॉगआउट',
  'Language': 'भाषा',
  'English': 'अंग्रेज़ी',
  'Hindi': 'हिंदी',
  'Cancel': 'रद्द करें',
  'Continue': 'जारी रखें',
  'Exit': 'बाहर निकलें',
  'Retry': 'पुनः प्रयास',
  'Go Back': 'वापस जाएँ',
  'I Agree': 'मैं सहमत हूँ',
  'Premium Member': 'प्रीमियम सदस्य',
  'Upgrade to Premium': 'प्रीमियम में अपग्रेड करें',
  'Select Language': 'भाषा चुनें',
  'Choose the language for this test': 'इस टेस्ट की भाषा चुनें',

  // ── Hub screen ──
  'Test Your Tunnelity': 'अपनी टनलिटी जाँचें',
  'Test Your Tunnlity': 'अपनी टनलिटी जाँचें',
  'Take a quick 10-question speed test': '10 सवालों का तेज़ टेस्ट दें',
  'Your Dashboard': 'आपका डैशबोर्ड',
  'Premium unlocked — explore everything': 'प्रीमियम अनलॉक — सब कुछ देखें',
  'Ticket to Tunnl': 'टनल का टिकट',
  'Unlock full access & advanced features': 'पूरी पहुँच और उन्नत सुविधाएँ अनलॉक करें',
  '500 Free Practice MCQs': '500 मुफ़्त अभ्यास MCQ',
  'Practice unlimited questions for free': 'मुफ़्त में असीमित सवाल हल करें',
  'Enter the Tunnel. Master Speed Math.': 'टनल में आएँ। स्पीड मैथ में महारत पाएँ।',

  // ── Quiz / question screen ──
  'Quiz Terms & Conditions': 'क्विज़ नियम और शर्तें',
  'Exit Test?': 'टेस्ट छोड़ें?',
  'Your progress will be lost.\nAre you sure?':
      'आपकी प्रगति खो जाएगी।\nक्या आप निश्चित हैं?',
  'Failed to Load': 'लोड नहीं हो पाया',
  'PROGRESS': 'प्रगति',

  // ── Solve & Earn / Weekly challenge ──
  'SOLVE & EARN': 'हल करें और जीतें',
  'Solve. Compete. Win Rewards!': 'हल करें। मुक़ाबला करें। इनाम जीतें!',
  'No active challenge': 'कोई सक्रिय चैलेंज नहीं',
  'Admin will launch the next weekly challenge soon!':
      'एडमिन जल्द ही अगला साप्ताहिक चैलेंज शुरू करेगा!',
  'WEEKLY CHALLENGE': 'साप्ताहिक चैलेंज',
  'Prize Pool': 'इनाम राशि',
  'RULES': 'नियम',
  'START CHALLENGE': 'चैलेंज शुरू करें',
  'VIEW LEADERBOARD': 'लीडरबोर्ड देखें',
  'CHALLENGE CLOSED': 'चैलेंज बंद',
  'NO QUESTIONS YET': 'अभी कोई सवाल नहीं',
  "Come back tomorrow!": 'कल फिर आएँ!',
  'Challenge Ends In': 'चैलेंज समाप्त होने में',
  'Challenge Closed': 'चैलेंज बंद',
};
