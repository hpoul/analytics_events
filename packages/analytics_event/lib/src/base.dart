import 'package:meta/meta_meta.dart';

/// Interface which should be subclassed by analytics-events stubs.
abstract class AnalyticsEventStubs {
  const AnalyticsEventStubs();

  void trackEvent(String event, Map<String, Object> params);

  void registerTracker(TrackAnalytics tracker);

  void removeTracker(TrackAnalytics tracker);
}

typedef TrackAnalytics = void Function(
    String event, Map<String, Object?> params);

class _QueuedEvent {
  const _QueuedEvent(this.event, this.params);

  final String event;
  final Map<String, Object?> params;
}

mixin AnalyticsEventStubsImpl on AnalyticsEventStubs {
  final List<TrackAnalytics> _trackerList = [];

  /// as long as [registerTracker] was never called, we will queue
  /// all events. Once the first tracker is registered the queue
  /// will be emptied.
  List<_QueuedEvent>? _queuedEvents = [];

  @override
  void trackEvent(String event, Map<String, Object?> params) {
    if (_queuedEvents != null && _trackerList.isEmpty) {
      _queuedEvents!.add(_QueuedEvent(event, params));
      return;
    }
    for (final tracker in _trackerList) {
      tracker(event, params);
    }
  }

  @override
  void registerTracker(TrackAnalytics tracker) {
    _trackerList.add(tracker);
    if (_queuedEvents != null) {
      for (final event in _queuedEvents!) {
        tracker(event.event, event.params);
      }
      _queuedEvents = null;
    }
  }

  @override
  void removeTracker(TrackAnalytics tracker) => _trackerList.remove(tracker);
}

enum Case {
  unchanged,
  camelCase,
  snakeCase,
}

@Target({TargetKind.classType})
class AnalyticsEventConfig {
  const AnalyticsEventConfig({
    this.eventNameCase = Case.unchanged,
    this.parameterNameCase = Case.unchanged,
  });

  final Case eventNameCase;
  final Case parameterNameCase;
}
