import 'package:analytics_event/analytics_event.dart';
import 'package:logging/logging.dart';
import 'package:logging_appenders/logging_appenders.dart';

part 'example.g.dart';

final _logger = Logger('example');

/// Create an abstract class which implements [AnalyticsEventStubs]
/// and has stub methods for all events you want to track.
@AnalyticsEventConfig(
  eventNameCase: Case.snakeCase,
  parameterNameCase: Case.snakeCase,
)
abstract class Events implements AnalyticsEventStubs {
  /// will be 'app_launch' with parameter 'date' and 'user_id'
  void trackAppLaunch({required String date, required userId});
  void trackExample(String myRequiredParameter, {String withDefault = 'test'});

  /// enums will be correctly transformed
  /// i.e. 'action' will be 'launch', 'remove' or 'share'
  void trackItem(ItemAction action, String someParameterName);

  void trackNullableItem(ItemAction? action);
}

enum ItemAction {
  launch,
  remove,
  share,
}

/// A analytics service which is responsible for sending events to
/// your analytics provider (e.g. firebase analytics).
class AnalyticsService {
  AnalyticsService();

  // Instantiate the generated Events implementation.
  late final Events events = _$Events(_trackEvent);

  void _trackEvent(String event, Map<String, Object?> params) {
    // Here you would send the event to your analytics service.
    _logger.info('We have to track event $event with parameters: $params');
  }

  void dispose() => events.removeTracker(_trackEvent);
}

void main() {
  PrintAppender.setupLogging();

  final myAnalytics = AnalyticsService();

  // Now you have a typesafe way to send events to your analytics service.
  myAnalytics.events.trackAppLaunch(date: DateTime.now().toString(), userId: 1);

  myAnalytics.dispose();
}
