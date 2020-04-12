/// Interface which should be subclassed by analytics-events stubs.
abstract class AnalyticsEventStubs {
  const AnalyticsEventStubs();

  void trackEvent(String event, Map<String, dynamic> params);

  void registerTracker(TrackAnalytics tracker);

  void removeTracker(TrackAnalytics tracker);
}

typedef TrackAnalytics = void Function(
    String event, Map<String, dynamic> params);

mixin AnalyticsEventStubsImpl on AnalyticsEventStubs {
  final List<TrackAnalytics> _trackerList = [];

  @override
  void trackEvent(String event, Map<String, dynamic> params) {
    for (final tracker in _trackerList) {
      tracker(event, params);
    }
  }

  @override
  void registerTracker(TrackAnalytics tracker) => _trackerList.add(tracker);

  @override
  void removeTracker(TrackAnalytics tracker) => _trackerList.remove(tracker);
}
