//
// ignore_for_file: depend_on_referenced_packages, lines_longer_than_80_chars

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart'
    hide Source; // Hide Source from Firestore
import 'package:ht_preferences_client/ht_preferences_client.dart';

/// {@template ht_preferences_firestore}
/// A Firestore implementation of the [HtPreferencesClient].
///
/// This client interacts with a Firestore database to manage user preferences.
/// It assumes a structure where user preferences are stored in a single
/// document per user within a dedicated 'preferences' collection.
/// {@endtemplate}
class HtPreferencesFirestore implements HtPreferencesClient {
  /// {@macro ht_preferences_firestore}
  ///
  /// Requires a [FirebaseFirestore] instance and the [userId] of the user
  /// whose preferences are being managed.
  const HtPreferencesFirestore({
    required FirebaseFirestore firestore,
    required String userId,
  }) : _firestore = firestore,
       _userId = userId;

  final FirebaseFirestore _firestore;
  final String _userId;

  // Collection name
  static const String _preferencesCollection = 'preferences';

  // Document field names
  static const String _appSettingsField = 'app_settings';
  static const String _articleSettingsField = 'article_settings';
  static const String _themeSettingsField = 'theme_settings';
  static const String _feedSettingsField = 'feed_settings';
  static const String _notificationSettingsField = 'notification_settings';
  static const String _followedSourcesField = 'followed_sources';
  static const String _followedCategoriesField = 'followed_categories';
  static const String _followedEventCountriesField = 'followed_event_countries';
  static const String _bookmarkedHeadlinesField = 'bookmarked_headlines';
  static const String _headlineReadingHistoryField = 'headline_reading_history';

  /// Returns the [DocumentReference] for the current user's preferences document.
  DocumentReference<Map<String, dynamic>> _getPreferencesDocRef() {
    return _firestore.collection(_preferencesCollection).doc(_userId);
  }

  /// Fetches the user's preferences document data.
  ///
  /// Returns the document data as a Map or null if the document doesn't exist.
  /// Throws a [PreferenceUpdateException] if a Firestore error occurs.
  Future<Map<String, dynamic>?> _getPreferencesData() async {
    try {
      final snapshot = await _getPreferencesDocRef().get();
      if (!snapshot.exists) {
        return null; // Or potentially throw a specific "NotFound" here?
        // Let's handle field-specific NotFound in each getter.
      }
      return snapshot.data();
    } on FirebaseException catch (e) {
      // Consider logging the error and stack trace
      throw PreferenceUpdateException(
        'Failed to fetch preferences data: ${e.message}',
      );
    } catch (e) {
      // Catch any other unexpected errors
      // Consider logging the error and stack trace
      throw PreferenceUpdateException('An unexpected error occurred: $e');
    }
  }

  /// Helper to extract and deserialize a specific field from the preferences data.
  T _extractField<T>(
    Map<String, dynamic>? data,
    String fieldName,
    T Function(Map<String, dynamic> json) fromJson,
    PreferenceNotFoundException notFoundException,
  ) {
    if (data == null ||
        !data.containsKey(fieldName) ||
        data[fieldName] == null) {
      throw notFoundException;
    }
    try {
      // Ensure the data is in the expected Map format
      if (data[fieldName] is! Map<String, dynamic>) {
        throw FormatException('Field "$fieldName" is not a valid Map.');
      }
      return fromJson(data[fieldName] as Map<String, dynamic>);
    } catch (e) {
      // Consider logging the error and stack trace
      throw PreferenceUpdateException(
        'Failed to deserialize field "$fieldName": $e',
      );
    }
  }

  /// Helper to extract and deserialize a list field.
  List<T> _extractListField<T>(
    Map<String, dynamic>? data,
    String fieldName,
    T Function(Map<String, dynamic> json) fromJson,
    PreferenceNotFoundException notFoundException,
  ) {
    if (data == null ||
        !data.containsKey(fieldName) ||
        data[fieldName] == null) {
      // Return empty list if field doesn't exist, common for lists
      return [];
      // Or throw notFoundException if an empty list isn't desired on first load
      // throw notFoundException;
    }
    try {
      final listData = data[fieldName] as List<dynamic>?;
      if (listData == null) {
        return []; // Return empty list if field is null
      }
      return listData
          .whereType<Map<String, dynamic>>() // Filter out non-map items
          .map(fromJson)
          .toList();
    } catch (e) {
      // Consider logging the error and stack trace
      throw PreferenceUpdateException(
        'Failed to deserialize list field "$fieldName": $e',
      );
    }
  }

  /// Helper to update a specific field in the preferences document.
  Future<void> _updateField(
    String fieldName,
    dynamic value,
    PreferenceUpdateException updateException,
  ) async {
    try {
      await _getPreferencesDocRef().set(
        {fieldName: value},
        SetOptions(merge: true), // Use merge to avoid overwriting other fields
      );
    } on FirebaseException {
      // Consider logging the error and stack trace
      throw updateException; // Throw the specific update exception
    } catch (e) {
      // Consider logging the error and stack trace
      throw PreferenceUpdateException('An unexpected error occurred: $e');
    }
  }

  @override
  Future<AppSettings> getAppSettings() async {
    final data = await _getPreferencesData();
    return _extractField(
      data,
      _appSettingsField,
      AppSettings.fromJson,
      AppSettingsNotFoundException('App settings not found.'),
    );
  }

  @override
  Future<void> setAppSettings(AppSettings settings) async {
    await _updateField(
      _appSettingsField,
      settings.toJson(),
      AppSettingsUpdateException('Failed to update app settings.'),
    );
  }

  @override
  Future<ArticleSettings> getArticleSettings() async {
    final data = await _getPreferencesData();
    return _extractField(
      data,
      _articleSettingsField,
      ArticleSettings.fromJson,
      ArticleSettingsNotFoundException('Article settings not found.'),
    );
  }

  @override
  Future<void> setArticleSettings(ArticleSettings settings) async {
    await _updateField(
      _articleSettingsField,
      settings.toJson(),
      ArticleSettingsUpdateException('Failed to update article settings.'),
    );
  }

  @override
  Future<ThemeSettings> getThemeSettings() async {
    final data = await _getPreferencesData();
    return _extractField(
      data,
      _themeSettingsField,
      ThemeSettings.fromJson,
      ThemeSettingsNotFoundException('Theme settings not found.'),
    );
  }

  @override
  Future<void> setThemeSettings(ThemeSettings settings) async {
    await _updateField(
      _themeSettingsField,
      settings.toJson(),
      ThemeSettingsUpdateException('Failed to update theme settings.'),
    );
  }

  @override
  Future<List<Headline>> getBookmarkedHeadlines() async {
    final data = await _getPreferencesData();
    return _extractListField(
      data,
      _bookmarkedHeadlinesField,
      Headline.fromJson,
      BookmarkedHeadlinesNotFoundException('Bookmarked headlines not found.'),
    );
  }

  @override
  Future<void> addBookmarkedHeadline(Headline headline) async {
    try {
      final currentBookmarks = await getBookmarkedHeadlines();
      // Avoid adding duplicates
      if (currentBookmarks.any((h) => h.id == headline.id)) {
        return; // Already bookmarked
      }
      final updatedBookmarks = [...currentBookmarks, headline];
      await _updateField(
        _bookmarkedHeadlinesField,
        updatedBookmarks.map((h) => h.toJson()).toList(),
        BookmarkedHeadlinesUpdateException('Failed to add bookmark.'),
      );
    } on PreferenceNotFoundException {
      // If bookmarks don't exist yet, create the list with the new headline
      await _updateField(
        _bookmarkedHeadlinesField,
        [headline.toJson()],
        BookmarkedHeadlinesUpdateException('Failed to add initial bookmark.'),
      );
    } catch (e) {
      // Rethrow specific update exception or a generic one
      if (e is PreferenceUpdateException) rethrow;
      throw BookmarkedHeadlinesUpdateException('Failed to add bookmark: $e');
    }
  }

  @override
  Future<void> removeBookmarkedHeadline(String headlineId) async {
    try {
      final currentBookmarks = await getBookmarkedHeadlines();
      final initialLength = currentBookmarks.length;
      final updatedBookmarks =
          currentBookmarks.where((h) => h.id != headlineId).toList();

      // Only update if an item was actually removed
      if (updatedBookmarks.length < initialLength) {
        await _updateField(
          _bookmarkedHeadlinesField,
          updatedBookmarks.map((h) => h.toJson()).toList(),
          BookmarkedHeadlinesUpdateException('Failed to remove bookmark.'),
        );
      }
    } on PreferenceNotFoundException {
      // List doesn't exist, nothing to remove
      return;
    } catch (e) {
      // Rethrow specific update exception or a generic one
      if (e is PreferenceUpdateException) rethrow;
      throw BookmarkedHeadlinesUpdateException('Failed to remove bookmark: $e');
    }
  }

  @override
  Future<List<Source>> getFollowedSources() async {
    final data = await _getPreferencesData();
    return _extractListField(
      data,
      _followedSourcesField,
      Source.fromJson,
      FollowedSourcesNotFoundException('Followed sources not found.'),
    );
  }

  @override
  Future<void> setFollowedSources(List<Source> sources) async {
    await _updateField(
      _followedSourcesField,
      sources.map((s) => s.toJson()).toList(),
      FollowedSourcesUpdateException('Failed to update followed sources.'),
    );
  }

  @override
  Future<List<Category>> getFollowedCategories() async {
    final data = await _getPreferencesData();
    return _extractListField(
      data,
      _followedCategoriesField,
      Category.fromJson,
      FollowedCategoriesNotFoundException('Followed categories not found.'),
    );
  }

  @override
  Future<void> setFollowedCategories(List<Category> categories) async {
    await _updateField(
      _followedCategoriesField,
      categories.map((c) => c.toJson()).toList(),
      FollowedCategoriesUpdateException(
        'Failed to update followed categories.',
      ),
    );
  }

  @override
  Future<List<Country>> getFollowedEventCountries() async {
    final data = await _getPreferencesData();
    return _extractListField(
      data,
      _followedEventCountriesField,
      Country.fromJson,
      FollowedEventCountriesNotFoundException(
        'Followed event countries not found.',
      ),
    );
  }

  @override
  Future<void> setFollowedEventCountries(List<Country> countries) async {
    await _updateField(
      _followedEventCountriesField,
      countries.map((c) => c.toJson()).toList(),
      FollowedEventCountriesUpdateException(
        'Failed to update followed event countries.',
      ),
    );
  }

  @override
  Future<List<Headline>> getHeadlineReadingHistory() async {
    final data = await _getPreferencesData();
    return _extractListField(
      data,
      _headlineReadingHistoryField,
      Headline.fromJson,
      HeadlineReadingHistoryNotFoundException(
        'Headline reading history not found.',
      ),
    );
  }

  @override
  Future<void> addHeadlineToHistory(Headline headline) async {
    // Note: This simple implementation adds to the end.
    // The repository layer might enforce size limits (e.g., keep last N items).
    try {
      final currentHistory = await getHeadlineReadingHistory();
      // Avoid adding duplicates if needed, or allow them
      // if (currentHistory.any((h) => h.id == headline.id)) {
      //   // Optionally move existing to end, or just ignore
      //   return;
      // }
      final updatedHistory = [...currentHistory, headline];
      await _updateField(
        _headlineReadingHistoryField,
        updatedHistory.map((h) => h.toJson()).toList(),
        HeadlineReadingHistoryUpdateException('Failed to add to history.'),
      );
    } on PreferenceNotFoundException {
      // If history doesn't exist yet, create the list with the new headline
      await _updateField(
        _headlineReadingHistoryField,
        [headline.toJson()],
        HeadlineReadingHistoryUpdateException(
          'Failed to add initial history item.',
        ),
      );
    } catch (e) {
      // Rethrow specific update exception or a generic one
      if (e is PreferenceUpdateException) rethrow;
      throw HeadlineReadingHistoryUpdateException(
        'Failed to add to history: $e',
      );
    }
  }

  @override
  Future<void> removeHeadlineToHistory(String headlineId) async {
    // This might not be commonly used, but included for completeness
    try {
      final currentHistory = await getHeadlineReadingHistory();
      final initialLength = currentHistory.length;
      final updatedHistory =
          currentHistory.where((h) => h.id != headlineId).toList();

      // Only update if an item was actually removed
      if (updatedHistory.length < initialLength) {
        await _updateField(
          _headlineReadingHistoryField,
          updatedHistory.map((h) => h.toJson()).toList(),
          HeadlineReadingHistoryUpdateException(
            'Failed to remove from history.',
          ),
        );
      }
    } on PreferenceNotFoundException {
      // List doesn't exist, nothing to remove
      return;
    } catch (e) {
      // Rethrow specific update exception or a generic one
      if (e is PreferenceUpdateException) rethrow;
      throw HeadlineReadingHistoryUpdateException(
        'Failed to remove from history: $e',
      );
    }
  }

  @override
  Future<FeedSettings> getFeedSettings() async {
    final data = await _getPreferencesData();
    return _extractField(
      data,
      _feedSettingsField,
      FeedSettings.fromJson,
      FeedSettingsNotFoundException('Feed settings not found.'),
    );
  }

  @override
  Future<void> setFeedSettings(FeedSettings settings) async {
    await _updateField(
      _feedSettingsField,
      settings.toJson(),
      FeedSettingsUpdateException('Failed to update feed settings.'),
    );
  }

  @override
  Future<NotificationSettings> getNotificationSettings() async {
    final data = await _getPreferencesData();
    return _extractField(
      data,
      _notificationSettingsField,
      NotificationSettings.fromJson,
      NotificationSettingsNotFoundException('Notification settings not found.'),
    );
  }

  @override
  Future<void> setNotificationPreferences(
    NotificationSettings preferences,
  ) async {
    await _updateField(
      _notificationSettingsField,
      preferences.toJson(),
      NotificationSettingsUpdateException(
        'Failed to update notification settings.',
      ),
    );
  }
}
