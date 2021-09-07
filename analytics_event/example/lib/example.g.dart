// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'example.dart';

// **************************************************************************
// AnalyticsEventGenerator
// **************************************************************************

// ignore_for_file: unnecessary_statements

// useNullSafetySyntax: true
class _$Events extends Events with AnalyticsEventStubsImpl {
  _$Events([TrackAnalytics? tracker]) {
    tracker != null ? registerTracker(tracker) : null;
  }

  @override
  void trackAppLaunch({required String date}) =>
      trackEvent('appLaunch', <String, Object?>{'date': date});
  @override
  void trackExample(String myRequiredParameter,
          {String withDefault = 'test'}) =>
      trackEvent('example', <String, Object?>{
        'myRequiredParameter': myRequiredParameter,
        'withDefault': withDefault
      });
  @override
  void trackItem(ItemAction action) => trackEvent(
      'item', <String, Object?>{'action': action.toString().substring(11)});
  @override
  void trackNullableItem(ItemAction? action) => trackEvent('nullableItem',
      <String, Object?>{'action': action?.toString().substring(11)});
}
