class ApiConstants {
  // ── Backend API Endpoints ───────────────────────────────────────────────────
  // Legacy direct AWS endpoint (for reference/comparison)
  static const String apiBaseAWS = 'https://micriaxflf.execute-api.us-east-1.amazonaws.com/api/v1';

  // Production custom domain endpoint (backend)
  static const String apiBaseCustom = 'https://api.digikavach.net/api/v1';

  // Active backend endpoint selector
  static const String apiBase = apiBaseCustom;

  // ── Frontend App URLs ───────────────────────────────────────────────────────
  // Old Angular app (DO NOT CHANGE — still live)
  static const String oldAppUrl = 'https://app.digikavach.net';

  // New Flutter 2.0 app (this app)
  static const String flutterAppUrl = 'https://app2.digikavach.net';

  // Storage Keys
  static const String tokenKey = 'dk_access_token';
  static const String refreshKey = 'dk_refresh_token';
  static const String roleKey = 'dk_role';
  static const String userKey = 'dk_user';
  static const String languageKey = 'dk_language';
  static const String onboardedKey = 'dk_onboarded';
  static const String termsAcceptedKey = 'dk_terms_accepted';
  static const String permissionsDoneKey = 'dk_permissions_done';
  static const String familyNumbersKey = 'dk_family_numbers';
  static const String darkModeKey = 'dk_dark_mode';
}
