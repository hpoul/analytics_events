// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'example.dart';

// **************************************************************************
// AnalyticsEventGenerator
// **************************************************************************

// ignore_for_file: unnecessary_statements

class _$Events extends Events with AnalyticsEventStubsImpl {
  _$Events([TrackAnalytics tracker]) {
    tracker != null ? registerTracker(tracker) : null;
  }

  @override
  void trackAppLaunch({String date}) =>
      trackEvent('appLaunch', <String, dynamic>{'date': date});
}
