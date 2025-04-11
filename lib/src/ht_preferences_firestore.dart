//
// ignore_for_file: depend_on_referenced_packages, lines_longer_than_80_chars

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart'
    hide Source; // Hide Source from Firestore
import 'package:ht_preferences_client/ht_preferences_client.dart'; // Import base exception

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
  /// Returns the document data as a Map.
  /// Throws a [PreferenceNotFoundException] if the document doesn't exist.
  /// Throws a [PreferenceUpdateException] if a Firestore error occurs.
  Future<Map<String, dynamic>> _getPreferencesData() async {
    try {
      final snapshot = await _getPreferencesDocRef().get();
      if (!snapshot.exists || snapshot.data() == null) {
        // Throw if the document doesn't exist or has no data
        throw PreferenceNotFoundException(
          'User preferences document not found for userId: $_userId',
        );
      }
      return snapshot.data()!;
    } on FirebaseException catch (e) {
      throw PreferenceUpdateException(
        'Failed to fetch preferences data: ${e.message}',
      );
    } catch (e) {
      // Catch any other unexpected errors
      throw PreferenceUpdateException('An unexpected error occurred: $e');
    }
  }

  /// Helper to extract and deserialize a specific field from the preferences data.
  T _extractField<T>(
    Map<String, dynamic>? data,
    String fieldName,
    T Function(Map<String, dynamic> json) fromJson,
    String notFoundMessage,
  ) {
    if (data == null ||
        !data.containsKey(fieldName) ||
        data[fieldName] == null) {
      throw PreferenceNotFoundException(notFoundMessage);
    }
    try {
      // Ensure the data is in the expected Map format
      if (data[fieldName] is! Map<String, dynamic>) {
        throw FormatException('Field "$fieldName" is not a valid Map.');
      }
      return fromJson(data[fieldName] as Map<String, dynamic>);
    } catch (e) {
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
    String notFoundMessage,
  ) {
    if (data == null ||
        !data.containsKey(fieldName) ||
        data[fieldName] == null) {
      throw PreferenceNotFoundException(notFoundMessage);
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
      throw PreferenceUpdateException(
        'Failed to deserialize list field "$fieldName": $e',
      );
    }
  }

  /// Helper to update a specific field in the preferences document.
  Future<void> _updateField(
    String fieldName,
    dynamic value,
    String updateErrorMessage,
  ) async {
    try {
      await _getPreferencesDocRef().set(
        {fieldName: value},
        SetOptions(merge: true), // Use merge to avoid overwriting other fields
      );
    } on FirebaseException catch (e) {
      throw PreferenceUpdateException('$updateErrorMessage: ${e.message}');
    } catch (e) {
      throw PreferenceUpdateException('$updateErrorMessage: $e');
    }
  }

  @override
  Future<AppSettings> getAppSettings() async {
    final data = await _getPreferencesData();
    return _extractField(
      data,
      _appSettingsField,
      AppSettings.fromJson,
      'App settings not found.',
    );
  }

  @override
  Future<void> setAppSettings(AppSettings settings) async {
    await _updateField(
      _appSettingsField,
      settings.toJson(),
      'Failed to update app settings.',
    );
  }

  @override
  Future<ArticleSettings> getArticleSettings() async {
    final data = await _getPreferencesData();
    return _extractField(
      data,
      _articleSettingsField,
      ArticleSettings.fromJson,
      'Article settings not found.',
    );
  }

  @override
  Future<void> setArticleSettings(ArticleSettings settings) async {
    await _updateField(
      _articleSettingsField,
      settings.toJson(),
      'Failed to update article settings.',
    );
  }

  @override
  Future<ThemeSettings> getThemeSettings() async {
    final data = await _getPreferencesData();
    return _extractField(
      data,
      _themeSettingsField,
      ThemeSettings.fromJson,
      'Theme settings not found.',
    );
  }

  @override
  Future<void> setThemeSettings(ThemeSettings settings) async {
    await _updateField(
      _themeSettingsField,
      settings.toJson(),
      'Failed to update theme settings.',
    );
  }

  @override
  Future<List<Headline>> getBookmarkedHeadlines() async {
    final data = await _getPreferencesData();
    return _extractListField(
      data,
      _bookmarkedHeadlinesField,
      Headline.fromJson,
      'Bookmarked headlines not found.',
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
        'Failed to add bookmark.',
      );
    } on PreferenceNotFoundException {
      // If bookmarks don't exist yet, create the list with the new headline
      await _updateField(_bookmarkedHeadlinesField, [
        headline.toJson(),
      ], 'Failed to add initial bookmark.',);
    } catch (e) {
      if (e is PreferenceUpdateException) rethrow;
      throw PreferenceUpdateException('Failed to add bookmark: $e');
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
          'Failed to remove bookmark.',
        );
      }
    } on PreferenceNotFoundException {
      // List doesn't exist, nothing to remove.
      return;
    } catch (e) {
      if (e is PreferenceUpdateException) rethrow;
      throw PreferenceUpdateException('Failed to remove bookmark: $e');
    }
  }

  @override
  Future<List<Source>> getFollowedSources() async {
    final data = await _getPreferencesData();
    return _extractListField(
      data,
      _followedSourcesField,
      Source.fromJson,
      'Followed sources not found.',
    );
  }

  @override
  Future<void> setFollowedSources(List<Source> sources) async {
    await _updateField(
      _followedSourcesField,
      sources.map((s) => s.toJson()).toList(),
      'Failed to update followed sources.',
    );
  }

  @override
  Future<List<Category>> getFollowedCategories() async {
    final data = await _getPreferencesData();
    return _extractListField(
      data,
      _followedCategoriesField,
      Category.fromJson,
      'Followed categories not found.',
    );
  }

  @override
  Future<void> setFollowedCategories(List<Category> categories) async {
    await _updateField(
      _followedCategoriesField,
      categories.map((c) => c.toJson()).toList(),
      'Failed to update followed categories.',
    );
  }

  @override
  Future<List<Country>> getFollowedEventCountries() async {
    final data = await _getPreferencesData();
    return _extractListField(
      data,
      _followedEventCountriesField,
      Country.fromJson,
      'Followed event countries not found.',
    );
  }

  @override
  Future<void> setFollowedEventCountries(List<Country> countries) async {
    await _updateField(
      _followedEventCountriesField,
      countries.map((c) => c.toJson()).toList(),
      'Failed to update followed event countries.',
    );
  }

  @override
  Future<List<Headline>> getHeadlineReadingHistory() async {
    final data = await _getPreferencesData();
    return _extractListField(
      data,
      _headlineReadingHistoryField,
      Headline.fromJson,
      'Headline reading history not found.',
    );
  }

  @override
  Future<void> addHeadlineToHistory(Headline headline) async {
    // The repository layer might enforce size limits (e.g., keep last N items).
    try {
      final currentHistory = await getHeadlineReadingHistory();

      // Remove existing entry if it exists, to move it to the top
      currentHistory.removeWhere((h) => h.id == headline.id);

      // Add the new headline to the beginning of the list.
      final updatedHistory = [headline, ...currentHistory];

      // Note: Size limit enforcement should ideally happen in the Repository layer.

      await _updateField(
        _headlineReadingHistoryField,
        updatedHistory.map((h) => h.toJson()).toList(),
        'Failed to add to history.',
      );
    } on PreferenceNotFoundException {
      // If history doesn't exist yet, create the list with the new headline.
      await _updateField(_headlineReadingHistoryField, [
        headline.toJson(),
      ], 'Failed to add initial history item.',);
    } catch (e) {
      if (e is PreferenceUpdateException) rethrow;
      throw PreferenceUpdateException('Failed to add to history: $e');
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
          'Failed to remove from history.',
        );
      }
    } on PreferenceNotFoundException {
      // List doesn't exist, nothing to remove.
      return;
    } catch (e) {
      if (e is PreferenceUpdateException) rethrow;
      throw PreferenceUpdateException('Failed to remove from history: $e');
    }
  }

  @override
  Future<FeedSettings> getFeedSettings() async {
    final data = await _getPreferencesData();
    return _extractField(
      data,
      _feedSettingsField,
      FeedSettings.fromJson,
      'Feed settings not found.',
    );
  }

  @override
  Future<void> setFeedSettings(FeedSettings settings) async {
    await _updateField(
      _feedSettingsField,
      settings.toJson(),
      'Failed to update feed settings.',
    );
  }

  @override
  Future<NotificationSettings> getNotificationSettings() async {
    final data = await _getPreferencesData();
    return _extractField(
      data,
      _notificationSettingsField,
      NotificationSettings.fromJson,
      'Notification settings not found.',
    );
  }

  @override
  Future<void> setNotificationSettings(NotificationSettings settings) async {
    await _updateField(
      _notificationSettingsField,
      settings.toJson(),
      'Failed to update notification settings.',
    );
  }
}
