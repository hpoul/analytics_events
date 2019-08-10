# analytics_events_gen

An easy generator for tracking firebase analytics events via type safe methods.

## Add to pubspec.yaml

Right now it is not published to pub, so simply add git reference:

```yaml
dependencies:
  # ...
  analytics_event_gen:
    git:
      url: https://github.com/hpoul/analytics_events.git
      ref: master
      path: analytics_event_gen
dev_dependencies:
  # include build_runner, only used for code generation.
  build_runner: ^1.6.5

```

## Create AnalyticsEvents class:

```dart
// analytics.dart

import 'package:analytics_event_gen/analytics_event_gen.dart';

// this file will be generated.
part 'analytics.g.dart';

class MyAnalyticsBloc {
  MyAnalyticsBloc() {
    // initialize generated events class implementation.
    // the generated code will simply transform the method name
    // into an `eventName` and pass it to your callback method.
    // you can then do whatever you want with it, e.g. send to 
    // firebase analytics.
    events = AnalyticsEventImpl((eventName, params) {
      FirebaseAnalytics().logEvent(name: event, parameters: params);
    });
  }
}

@AnalyticsEvents()
abstract class AnalyticsEvent {
  void trackMyUserInteraction({double myProp, String yourProp});
}
```

## Run the build generator

```sh
flutter packages pub run build_runner build --delete-conflicting-outputs
```

