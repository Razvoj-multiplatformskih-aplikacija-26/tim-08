abstract final class ApiRoutes {
  static const String login = '/api/v1/auth/login';
  static const String logout = '/api/v1/auth/logout';

  static const String events = '/api/v1/events';
  static String eventsPage({required int afterId, required int limit}) =>
      '$events?afterId=$afterId&limit=$limit';

  static String event(int id) => '/api/v1/events/$id';

  static String eventState(int id) => '/api/v1/events/$id/state';

  static String eventCapacity(int id) => '/api/v1/events/$id/capacity';

  static String eventRegistrations(int id) =>
      '/api/v1/events/$id/registrations';

  static String eventRegistrationCount(int id) =>
      '/api/v1/events/$id/registrations/count';

  static const String myRegistrations = '/api/v1/me/registrations';

  static String registration(int id) => '/api/v1/registrations/$id';

  static const String reviews = '/api/v1/reviews';

  static String eventReviews(int id) => '/api/v1/events/$id/reviews';

  static const String users = '/api/v1/users';

  static String user(int id) => '/api/v1/users/$id';

  static String userBan(int id) => '/api/v1/users/$id/ban';

  static String userReputation(int id) => '/api/v1/users/$id/reputation';

  static const String me = '/api/v1/me';
}
