import 'package:analytics_event/analytics_event.dart';
import 'package:logging/logging.dart';
import 'package:logging_appenders/logging_appenders.dart';

part 'example.g.dart';

final _logger = Logger('example');

/// Create an abstract class which implements [AnalyticsEventStubs]
/// and has stub methods for all events you want to track.
abstract class Events implements AnalyticsEventStubs {
  void trackAppLaunch({String date});
  void trackExample(String myRequiredParameter, {String withDefault = 'test'});

  /// enums will be correctly transformed
  /// i.e. 'action' will be 'launch', 'remove' or 'share'
  void trackItem(ItemAction action);
}

enum ItemAction {
  launch,
  remove,
  share,
}

/// A analytics service which is responsible for sending events to
/// your analytics provider (e.g. firebase analytics).
class AnalyticsService {
  AnalyticsService() {
    // Instantiate the generated Events implementation.
    events = _$Events()..registerTracker(_trackEvent);
  }

  Events events;

  void _trackEvent(String event, Map<String, dynamic> params) {
    // Here you would send the event to your analytics service.
    _logger.info('We have to track event $event with parameters: $params');
  }

  void dispose() => events.removeTracker(_trackEvent);
}

void main() {
  Logger.root.level = Level.ALL;
  PrintAppender().attachToLogger(Logger.root);

  final myAnalytics = AnalyticsService();

  // Now you have a typesafe way to send events to your analytics service.
  myAnalytics.events.trackAppLaunch(date: DateTime.now().toString());

  myAnalytics.dispose();
}
