/// Pure redirect rules for onboarding + protected routes.
///
/// Guest-first: everything is public by default. Only routes listed in
/// [protectedPaths] (or their sub-paths) require a signed-in user — e.g.
/// future cloud-sync / profile pages. Attraction / Activity / AudioGuide /
/// MyJourney all work with the public API + Drift, no session required.
///
/// IMPORTANT: this function intentionally does NOT redirect a signed-in
/// user away from `/login`. Leaving `/login` after a successful sign-in is
/// owned entirely by LoginPage's own post-submit navigation (see
/// login_page.dart). If this function also redirected on `signedIn &&
/// location == login`, both the router's refreshListenable and LoginPage's
/// context.go()/pop() would fire on the same auth-state change and race.
const Set<String> protectedPaths = {
  // When cloud sync / personalization features are added later, list
  // routes that require an account here, for example:
  // '/profile'
  // '/cloud-trips'
};

String? resolveAuthRedirect({
  required bool hasSeenWelcome,
  required bool signedIn,
  required String location,

  /// Full requested URI (including query string). For example
  /// `state.uri.toString()`. If omitted, location is used instead to
  /// make unit testing easier.
  String? requestedLocation,
  Set<String> protected = protectedPaths,
  String splash = '/splash',
  String welcome = '/welcome',
  String login = '/login',
  String home = '/',
}) {
  // Splash controls its own navigation timing.
  if (location == splash) {
    return null;
  }
  // First launch: redirect to welcome unless already on the welcome page.
  if (!hasSeenWelcome && location != welcome) {
    return welcome;
  }
  // After welcome completes -> enter the app as a guest and stop checking auth for welcome.
  if (hasSeenWelcome && location == welcome) {
    return home;
  }
  final requiresAuth = protected.any(
    (path) => location == path || location.startsWith('$path/'),
  );
  // Guests can access all pages except those explicitly marked as protected.
  if (!signedIn && requiresAuth && location != login) {
    final from = requestedLocation ?? location;
    return Uri(path: login, queryParameters: {'from': from}).toString();
  }
  return null;
}
