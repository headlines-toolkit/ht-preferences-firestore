# ht_preferences_firestore

![coverage: 97%](https://img.shields.io/badge/coverage-97%-green)
[![style: very good analysis](https://img.shields.io/badge/style-very_good_analysis-B22C89.svg)](https://pub.dev/packages/very_good_analysis) 
[![License: PolyForm Free Trial 1.0.0](https://img.shields.io/badge/License-PolyForm%20Free%20Trial%201.0.0-blue)](https://polyformproject.org/licenses/free-trial/1.0.0)

A Firestore implementation of the [HtPreferencesClient](https://github.com/headlines-toolkit/ht-preferences-client). Manages user preferences in Firestore.

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
// Import necessary models and enums (adjust paths if needed)
import 'package:ht_preferences_client/ht_preferences_client.dart';
import 'package:ht_preferences_firestore/ht_preferences_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Assuming these client packages are available for model definitions
import 'package:ht_headlines_client/ht_headlines_client.dart' show Headline;
import 'package:ht_sources_client/ht_sources_client.dart' show Source;
import 'package:ht_categories_client/ht_categories_client.dart' show Category;
import 'package:ht_countries_client/ht_countries_client.dart' show Country;


// --- Inside an async function ---
try {
  // --- App Settings ---
  print('Getting App Settings...');
  final appSettings = await preferencesClient.getAppSettings();
  print('Current App Font Size: ${appSettings.appFontSize}');
  print('Current App Font Type: ${appSettings.appFontType}');

  // --- Theme Settings ---
  print('\nGetting Theme Settings...');
  final currentThemeSettings = await preferencesClient.getThemeSettings();
  print('Current Theme Mode: ${currentThemeSettings.themeMode}');
  print('Current Theme Name: ${currentThemeSettings.themeName}');

  print('\nUpdating Theme Settings...');
  final newThemeSettings = ThemeSettings(
    themeMode: AppThemeMode.dark, // Example: Set to dark mode
    themeName: AppThemeName.blue, // Example: Set to blue theme
  );
  await preferencesClient.setThemeSettings(newThemeSettings);
  print('Theme settings updated.');

  // --- Bookmarks ---
  print('\nAdding a bookmarked headline...');
  // Note: Headline, Source, Category, Country models might come from other packages.
  // Ensure you have instances of these or create placeholders.
  final sourceExample = Source(id: 'src-001', name: 'Example News');
  final categoryExample = Category(id: 'cat-001', name: 'Technology');
  final countryExample = Country(id: 'cty-001', isoCode: 'US', name: 'United States', flagUrl: 'url/to/flag.png');

  final headlineToBookmark = Headline(
    id: 'headline-123',
    title: 'New Flutter Features Announced!',
    description: 'Exciting updates for the Flutter framework.',
    url: 'https://example.com/flutter-news',
    imageUrl: 'https://example.com/flutter-image.png',
    publishedAt: DateTime.now(),
    source: sourceExample,
    category: categoryExample,
    eventCountry: countryExample,
  );
  await preferencesClient.addBookmarkedHeadline(headlineToBookmark);
  print('Headline bookmarked.');

  print('\nGetting bookmarked headlines...');
  final bookmarks = await preferencesClient.getBookmarkedHeadlines();
  print('Found ${bookmarks.length} bookmarked headlines.');
  if (bookmarks.isNotEmpty) {
    print('First bookmark title: ${bookmarks.first.title}');
  }

  // --- Followed Sources ---
  print('\nGetting followed sources...');
  final followedSources = await preferencesClient.getFollowedSources();
  print('Followed ${followedSources.length} sources.');
  if (followedSources.isNotEmpty) {
    print('First followed source: ${followedSources.first.name}');
  }

  print('\nUpdating followed sources...');
  final sourcesToFollow = [
    Source(id: 'src-002', name: 'Tech Chronicle'),
    Source(id: 'src-003', name: 'Global News Hub'),
  ];
  await preferencesClient.setFollowedSources(sourcesToFollow);
  print('Followed sources updated.');

  // --- Article Settings ---
  print('\nGetting Article Settings...');
  final articleSettings = await preferencesClient.getArticleSettings();
  print('Current Article Font Size: ${articleSettings.articleFontSize}');

  // --- Feed Settings ---
  print('\nGetting Feed Settings...');
  final feedSettings = await preferencesClient.getFeedSettings();
  print('Current Feed Tile Type: ${feedSettings.feedListTileType}');

  print('\nUpdating Feed Settings...');
  final newFeedSettings = FeedSettings(
    feedListTileType: FeedListTileType.imageStart, // Example: Image on the left
  );
  await preferencesClient.setFeedSettings(newFeedSettings);
  print('Feed settings updated.');

  // --- Notification Settings ---
  print('\nGetting Notification Settings...');
  final notificationSettings = await preferencesClient.getNotificationSettings();
  print('Notifications Enabled: ${notificationSettings.enabled}');
  print('Following ${notificationSettings.categoryNotifications.length} categories for notifications.');

  print('\nUpdating Notification Settings...');
  final newNotificationSettings = NotificationSettings(
    enabled: true,
    categoryNotifications: ['cat-001', 'cat-002'], // Example category IDs
    sourceNotifications: ['src-001'],       // Example source IDs
    followedEventCountryIds: ['cty-001'],   // Example country IDs
  );
  // Note: The method name in the client is setNotificationSettings
  await preferencesClient.setNotificationSettings(newNotificationSettings);
  print('Notification settings updated.');

  // --- Followed Categories ---
  print('\nGetting followed categories...');
  final followedCategories = await preferencesClient.getFollowedCategories();
  print('Followed ${followedCategories.length} categories.');

  // --- Followed Event Countries ---
  print('\nGetting followed event countries...');
  final followedCountries = await preferencesClient.getFollowedEventCountries();
  print('Followed ${followedCountries.length} event countries.');

  // --- Reading History ---
  print('\nAdding headline to reading history...');
  final headlineForHistory = Headline(
    id: 'headline-456',
    title: 'Dart 3.0 Released',
    source: Source(id: 'src-dart', name: 'Dart News'),
  );
  await preferencesClient.addHeadlineToHistory(headlineForHistory);
  print('Headline added to history.');

  print('\nGetting reading history...');
  final history = await preferencesClient.getHeadlineReadingHistory();
  print('Found ${history.length} headlines in history.');

} on PreferenceNotFoundException catch (e) {
  print('Preference not found: $e');
  // Handle cases where a specific preference hasn't been set yet
  // (e.g., provide default settings or prompt the user).
} on PreferenceUpdateException catch (e) {
  print('Failed to update preference: $e');
  // Handle errors during updates (e.g., network issues, Firestore permissions).
  // Consider retry logic or informing the user.
} catch (e, stackTrace) {
  print('An unexpected error occurred: $e');
  print('Stack trace: $stackTrace');
  // Handle other potential errors (e.g., issues with Firestore instance).
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
*   `Future<void> setNotificationSettings(NotificationSettings preferences)`
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

This package is licensed under the **PolyForm Free Trial License 1.0.0**.

Please review the full [LICENSE](LICENSE) file for detailed terms and conditions before using this package.
