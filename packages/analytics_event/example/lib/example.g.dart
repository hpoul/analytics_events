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
  void trackAppLaunch({
    required String date,
    required dynamic userId,
  }) =>
      trackEvent(
        'app_launch',
        <String, Object?>{
          'date': date,
          'user_id': userId.toString(),
        },
      );

  @override
  void trackExample(
    String myRequiredParameter, {
    String withDefault = 'test',
  }) =>
      trackEvent(
        'example',
        <String, Object?>{
          'my_required_parameter': myRequiredParameter,
          'with_default': withDefault,
        },
      );

  @override
  void trackItem(
    ItemAction action,
    String someParameterName,
  ) =>
      trackEvent(
        'item',
        <String, Object?>{
          'action': action.toString(),
          'some_parameter_name': someParameterName,
        },
      );

  @override
  void trackNullableItem(ItemAction? action) => trackEvent(
        'nullable_item',
        <String, Object?>{'action': action.toString()},
      );
}
