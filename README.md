# ht_preferences_firestore

[![coverage badge](coverage_badge.svg)](https://github.com/VeryGoodOpenSource/very_good_coverage) [![style: very good analysis](https://img.shields.io/badge/style-very_good_analysis-B22C89.svg)](https://pub.dev/packages/very_good_analysis) [![License: PolyForm Free Trial 1.0.0](https://img.shields.io/badge/License-PolyForm%20Free%20Trial%201.0.0-blue)](https://polyformproject.org/licenses/free-trial/1.0.0)

A Firestore implementation of the [HtPreferencesClient](https://github.com/headlines-toolkit/ht-preferences-client). Manages user preferences in Firestore.

**Important:** This package is intended for private use within the Headlines Toolkit ecosystem and is hosted on GitHub. It is **not** published on `pub.dev`.

## Installation

Since this package is not on `pub.dev`, add it as a Git dependency in your `pubspec.yaml`:

```yaml
dependencies:
  ht_preferences_client: # Required interface package
    git:
      url: https://github.com/headlines-toolkit/ht-preferences-client.git
      # Optionally specify a ref (branch, tag, commit hash)
      # ref: main
  ht_preferences_firestore:
    git:
      url: https://github.com/headlines-toolkit/ht-preferences-firestore.git
      # Optionally specify a ref (branch, tag, commit hash)
      # ref: main
```

Then run `flutter pub get`.

## Usage

Import the package and the client interface:

```dart
import 'package:ht_preferences_client/ht_preferences_client.dart';
import 'package:ht_preferences_firestore/ht_preferences_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Required dependency
```

Instantiate the client with a `FirebaseFirestore` instance and the user's ID:

```dart
// Assuming you have initialized Firebase and have a user ID
final firestore = FirebaseFirestore.instance;
final userId = 'your_user_id'; // Replace with the actual user ID

final preferencesClient = HtPreferencesFirestore(
  firestore: firestore,
  userId: userId,
);
```

Now you can use the client to manage preferences:

```dart
try {
  // Get settings
  final appSettings = await preferencesClient.getAppSettings();
  print('Current theme mode: ${appSettings.themeMode}');

  // Update settings
  final newThemeSettings = ThemeSettings(primaryColorValue: 0xFF0000FF); // Example
  await preferencesClient.setThemeSettings(newThemeSettings);

  // Add a bookmarked headline
  final headlineToBookmark = Headline(/* ... headline data ... */);
  await preferencesClient.addBookmarkedHeadline(headlineToBookmark);

  // Get followed sources
  final followedSources = await preferencesClient.getFollowedSources();
  print('Followed ${followedSources.length} sources.');

} on PreferenceNotFoundException catch (e) {
  print('Preference not found: $e');
  // Handle cases where a specific preference hasn't been set yet
} on PreferenceUpdateException catch (e) {
  print('Failed to update preference: $e');
  // Handle errors during updates (e.g., network issues)
} catch (e) {
  print('An unexpected error occurred: $e');
  // Handle other potential errors
}
```

## API Overview

`HtPreferencesFirestore` implements the `HtPreferencesClient` interface, providing methods to get and set various user preferences stored in a single Firestore document per user.

**Methods:**

*   `Future<AppSettings> getAppSettings()`
*   `Future<void> setAppSettings(AppSettings settings)`
*   `Future<ArticleSettings> getArticleSettings()`
*   `Future<void> setArticleSettings(ArticleSettings settings)`
*   `Future<ThemeSettings> getThemeSettings()`
*   `Future<void> setThemeSettings(ThemeSettings settings)`
*   `Future<FeedSettings> getFeedSettings()`
*   `Future<void> setFeedSettings(FeedSettings settings)`
*   `Future<NotificationSettings> getNotificationSettings()`
*   `Future<void> setNotificationPreferences(NotificationSettings preferences)`
*   `Future<List<Headline>> getBookmarkedHeadlines()`
*   `Future<void> addBookmarkedHeadline(Headline headline)`
*   `Future<void> removeBookmarkedHeadline(String headlineId)`
*   `Future<List<Source>> getFollowedSources()`
*   `Future<void> setFollowedSources(List<Source> sources)`
*   `Future<List<Category>> getFollowedCategories()`
*   `Future<void> setFollowedCategories(List<Category> categories)`
*   `Future<List<Country>> getFollowedEventCountries()`
*   `Future<void> setFollowedEventCountries(List<Country> countries)`
*   `Future<List<Headline>> getHeadlineReadingHistory()`
*   `Future<void> addHeadlineToHistory(Headline headline)`
*   `Future<void> removeHeadlineToHistory(String headlineId)`

Refer to the `ht_preferences_client` package for details on the data models (`AppSettings`, `Headline`, `Source`, etc.) and specific exception types (`PreferenceNotFoundException`, `PreferenceUpdateException`, etc.).

## Dependencies

*   [cloud_firestore](https://pub.dev/packages/cloud_firestore): For interacting with Firestore.
*   [ht_preferences_client](https://github.com/headlines-toolkit/ht-preferences-client): Defines the interface and data models.

## License

This software is licensed under the **PolyForm Free Trial License 1.0.0**.

Please review the full [LICENSE](LICENSE) file for detailed terms and conditions before using this package.
