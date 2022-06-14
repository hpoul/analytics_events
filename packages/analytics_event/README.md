# analytics_events_gen

An easy generator for tracking analytics events via type safe methods.

## Add to pubspec.yaml

Check pub for the latest version: 
[![Pub](https://img.shields.io/pub/v/analytics_event?color=green)](https://pub.dev/packages/analytics_event/)
[![Pub](https://img.shields.io/pub/v/analytics_event_gen?color=green)](https://pub.dev/packages/analytics_event_gen/)

```yaml
dependencies:
  # ...
  analytics_event: ^1.2.0
dev_dependencies:
  analytics_event_gen: ^1.2.0
  # include build_runner, only used for code generation.
  build_runner: ^2.1.11

```

## Create AnalyticsEvents class:

```dart
// analytics.dart

import 'package:analytics_event/analytics_event.dart';

// this file will be generated.
part 'analytics.g.dart';

class MyAnalyticsBloc {
  MyAnalyticsBloc() {
    // initialize generated events class implementation.
    // the generated code will simply transform the method name
    // into an `eventName` and pass it to your callback method.
    // you can then do whatever you want with it, e.g. send to 
    // firebase analytics.
    events.registerTracker((eventName, params) {
      FirebaseAnalytics().logEvent(name: event, parameters: params);
    });
  }
  
  final events = _$AnalyticsEvents();
}

abstract class AnalyticsEvents implements AnalyticsEventStubs {
  void trackMyUserInteraction({double myProp, String yourProp});
}
```

## Run the build generator

```sh
# For flutter projects
flutter pub pub run build_runner build --delete-conflicting-outputs

# For dart projects
pub run build_runner build --delete-conflicting-outputs
```

## Configure name transformation

It is possible to rename parameter names and event names:

```dart
@AnalyticsEventConfig(
  eventNameCase: Case.snakeCase,
  parameterNameCase: Case.snakeCase,
)
abstract class AnalyticsEvents implements AnalyticsEventStubs {
  void trackMyUserInteraction({double myProp, String yourProp});
}
```

Will generate an event called `my_user_interaction` with parameter `my_prop` and `your_prop`.
