/// annotation for classes defining analytics events.
class AnalyticsEvents {
  const AnalyticsEvents();
}

typedef TrackAnalytics = void Function(String event, Map<String, dynamic> params);

//abstract class AnalyticsTracker {
//  void track(String event, Map<String, dynamic> params);
//}
