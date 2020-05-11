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
  @override
  void trackExample(String myRequiredParameter,
          {String withDefault = 'test'}) =>
      trackEvent('example', <String, dynamic>{
        'myRequiredParameter': myRequiredParameter,
        'withDefault': withDefault
      });
  @override
  void trackItem(ItemAction action) => trackEvent(
      'item', <String, dynamic>{'action': action?.toString()?.substring(11)});
}
