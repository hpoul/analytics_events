# analytics_events_gen

An easy generator for tracking firebase analytics events via type safe methods.

## Add to pubspec.yaml

Check pub for the latest version: 
[![Pub](https://img.shields.io/pub/v/analytics_event_gen?color=green)](https://pub.dev/packages/analytics_event_gen/)

```yaml
dependencies:
  # ...
  analytics_event_gen: 0.1.0
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

By default the library will use null safety syntax. This can be disabled
using build.yaml file:

```yaml
targets:
  $default:
    builders:
      analytics_event_gen|analytics_event_builder:
        options:
          useNullSafetySyntax: true

```

## Run the build generator

```sh
# For flutter projects
flutter pub pub run build_runner build --delete-conflicting-outputs

# For dart projects
pub run build_runner build --delete-conflicting-outputs
```

