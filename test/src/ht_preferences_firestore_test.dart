//
// ignore_for_file: prefer_const_constructors, lines_longer_than_80_chars, avoid_redundant_argument_values, inference_failure_on_collection_literal

import 'package:cloud_firestore/cloud_firestore.dart' hide Source;
import 'package:flutter_test/flutter_test.dart';
import 'package:ht_preferences_client/ht_preferences_client.dart';
import 'package:ht_preferences_firestore/ht_preferences_firestore.dart';
import 'package:mocktail/mocktail.dart';

// Mocks
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

// Fake Models (using real models with sample data)
const testUserId = 'test_user_id';
final testAppSettings = AppSettings(
  appFontSize: FontSize.medium,
  appFontType: AppFontType.roboto,
);
final testArticleSettings = ArticleSettings(articleFontSize: FontSize.large);
final testThemeSettings = ThemeSettings(
  themeMode: AppThemeMode.dark,
  themeName: AppThemeName.blue,
);
final testFeedSettings = FeedSettings(
  feedListTileType: FeedListTileType.imageTop,
);
final testNotificationSettings = NotificationSettings(
  enabled: true,
  categoryNotifications: const ['cat1'],
  sourceNotifications: const ['src1'],
  followedEventCountryIds: const ['us'],
);
final testSource1 = Source(id: 'src1', name: 'Source 1');
final testSource2 = Source(id: 'src2', name: 'Source 2');
final testCategory1 = Category(id: 'cat1', name: 'Category 1');
final testCategory2 = Category(id: 'cat2', name: 'Category 2');
final testCountry1 = Country(id: 'us', isoCode: 'US', name: 'USA', flagUrl: '');
final testCountry2 = Country(id: 'gb', isoCode: 'GB', name: 'UK', flagUrl: '');
final testHeadline1 = Headline(id: 'h1', title: 'Headline 1');
final testHeadline2 = Headline(id: 'h2', title: 'Headline 2');
final testHeadline3 = Headline(id: 'h3', title: 'Headline 3');

void main() {
  late FirebaseFirestore mockFirestore;
  late CollectionReference<Map<String, dynamic>> mockCollectionRef;
  late DocumentReference<Map<String, dynamic>> mockDocRef;
  late DocumentSnapshot<Map<String, dynamic>> mockDocSnapshot;
  late HtPreferencesFirestore client;

  // Field names from the implementation
  const appSettingsField = 'app_settings';
  const articleSettingsField = 'article_settings';
  const themeSettingsField = 'theme_settings';
  const feedSettingsField = 'feed_settings';
  const notificationSettingsField = 'notification_settings';
  const followedSourcesField = 'followed_sources';
  const followedCategoriesField = 'followed_categories';
  const followedEventCountriesField = 'followed_event_countries';
  const bookmarkedHeadlinesField = 'bookmarked_headlines';
  const headlineReadingHistoryField = 'headline_reading_history';

  setUpAll(() {
    // Register fallbacks for value types used in mocks
    registerFallbackValue(SetOptions(merge: true));
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockCollectionRef = MockCollectionReference();
    mockDocRef = MockDocumentReference();
    mockDocSnapshot = MockDocumentSnapshot();
    client = HtPreferencesFirestore(
      firestore: mockFirestore,
      userId: testUserId,
    );

    // Common stubbing for document reference
    when(
      () => mockFirestore.collection('preferences'),
    ).thenReturn(mockCollectionRef);
    when(
      () => mockFirestore.collection('preferences'),
    ).thenReturn(mockCollectionRef); // Ensure this is always stubbed
    when(
      () => mockCollectionRef.doc(testUserId),
    ).thenReturn(mockDocRef); // Ensure this is always stubbed
  });

  // Helper to stub successful document fetch with specific data
  void stubDocFetchSuccess(Map<String, dynamic> data) {
    when(() => mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
    when(() => mockDocSnapshot.exists).thenReturn(true);
    when(() => mockDocSnapshot.data()).thenReturn(data);
  }

  // Helper to stub document fetch where document doesn't exist
  void stubDocFetchNotFound() {
    when(() => mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
    when(() => mockDocSnapshot.exists).thenReturn(false);
    when(() => mockDocSnapshot.data()).thenReturn(null); // Explicitly null
  }

  // Helper to stub document fetch failure (FirebaseException)
  void stubDocFetchFailure([String message = 'Fetch failed']) {
    when(
      () => mockDocRef.get(),
    ).thenThrow(FirebaseException(plugin: 'firestore', message: message));
  }

  // Helper to stub document fetch failure (Generic Exception)
  void stubDocFetchGenericFailure() {
    when(() => mockDocRef.get()).thenThrow(Exception('Generic error'));
  }

  // Helper to stub successful document update/set
  void stubDocUpdateSuccess() {
    // Use argThat to match any Map and any SetOptions
    // Ensure the stub uses the correct mock instance (mockDocRef)
    when(
      () => mockDocRef.set(any<Map<String, dynamic>>(), any<SetOptions>()),
    ).thenAnswer((_) async {});
  }

  // Helper to stub document update/set failure (FirebaseException)
  void stubDocUpdateFailure([String message = 'Update failed']) {
    when(
      () => mockDocRef.set(any<Map<String, dynamic>>(), any<SetOptions>()),
    ).thenThrow(FirebaseException(plugin: 'firestore', message: message));
  }

  // Helper to stub document update/set failure (Generic Exception)
  void stubDocUpdateGenericFailure() {
    when(
      () => mockDocRef.set(any<Map<String, dynamic>>(), any<SetOptions>()),
    ).thenThrow(Exception('Generic update error'));
  }

  group('HtPreferencesFirestore', () {
    test('constructor assigns firestore and userId', () {
      expect(client, isA<HtPreferencesFirestore>());
      // No direct way to check private fields, but ensures constructor runs
    });

    // --- Test Internal Helpers Indirectly ---

    group('_getPreferencesData', () {
      // Tested implicitly via getter methods below
      test(
        'throws PreferenceNotFoundException when document does not exist',
        () async {
          stubDocFetchNotFound();
          await expectLater(
            client.getAppSettings(),
            throwsA(isA<PreferenceNotFoundException>()),
          );
          verify(() => mockDocRef.get()).called(1);
        },
      );

      test(
        'throws PreferenceNotFoundException when document exists but data is null',
        () async {
          when(() => mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
          when(() => mockDocSnapshot.exists).thenReturn(true);
          when(
            () => mockDocSnapshot.data(),
          ).thenReturn(null); // Explicitly null
          await expectLater(
            client.getAppSettings(),
            throwsA(isA<PreferenceNotFoundException>()),
          );
          verify(() => mockDocRef.get()).called(1);
        },
      );

      test(
        'throws PreferenceUpdateException on FirebaseException during fetch',
        () async {
          stubDocFetchFailure();
          await expectLater(
            client.getAppSettings(),
            throwsA(isA<PreferenceUpdateException>()),
          );
          verify(() => mockDocRef.get()).called(1);
        },
      );

      test(
        'throws PreferenceUpdateException on generic Exception during fetch',
        () async {
          stubDocFetchGenericFailure();
          await expectLater(
            client.getAppSettings(),
            throwsA(isA<PreferenceUpdateException>()),
          );
          verify(() => mockDocRef.get()).called(1);
        },
      );
    });

    group('_extractField', () {
      test(
        'throws PreferenceNotFoundException if data is null (tested via getter)',
        () async {
          // Simulate _getPreferencesData returning null (though our stub prevents this)
          // This path is hard to hit directly due to _getPreferencesData checks
          // We rely on testing the getters with missing fields instead.
          stubDocFetchSuccess({}); // Fetch empty doc successfully
          await expectLater(
            client.getAppSettings(),
            throwsA(isA<PreferenceNotFoundException>()),
          );
        },
      );

      test(
        'throws PreferenceNotFoundException if field is missing (tested via getter)',
        () async {
          stubDocFetchSuccess({'other_field': 'value'}); // Field not present
          await expectLater(
            client.getAppSettings(),
            throwsA(isA<PreferenceNotFoundException>()),
          );
        },
      );

      test(
        'throws PreferenceNotFoundException if field value is null (tested via getter)',
        () async {
          stubDocFetchSuccess({appSettingsField: null}); // Field is null
          await expectLater(
            client.getAppSettings(),
            throwsA(isA<PreferenceNotFoundException>()),
          );
        },
      );

      test(
        'throws PreferenceUpdateException if field is not a Map (tested via getter)',
        () async {
          stubDocFetchSuccess({
            appSettingsField: 'not a map',
          }); // Incorrect type
          await expectLater(
            client.getAppSettings(),
            throwsA(isA<PreferenceUpdateException>()),
          );
        },
      );

      test(
        'throws PreferenceUpdateException if fromJson fails (tested via getter)',
        () async {
          // Simulate fromJson throwing an error
          stubDocFetchSuccess({
            appSettingsField: {'invalid_field': true},
          });
          await expectLater(
            client.getAppSettings(),
            throwsA(isA<PreferenceUpdateException>()),
          );
        },
      );
    });

    group('_extractListField', () {
      test(
        'throws PreferenceNotFoundException if data is null (tested via getter)',
        () async {
          stubDocFetchSuccess({});
          await expectLater(
            client.getBookmarkedHeadlines(),
            throwsA(isA<PreferenceNotFoundException>()),
          );
        },
      );

      test(
        'throws PreferenceNotFoundException if field is missing (tested via getter)',
        () async {
          stubDocFetchSuccess({'other_field': 'value'});
          await expectLater(
            client.getBookmarkedHeadlines(),
            throwsA(isA<PreferenceNotFoundException>()),
          );
        },
      );

      test(
        'returns empty list if field value is null (tested via getter)',
        () async {
          stubDocFetchSuccess({bookmarkedHeadlinesField: null});
          final result = await client.getBookmarkedHeadlines();
          expect(result, isEmpty);
        },
      );

      test(
        'throws PreferenceUpdateException if field value is not a list (tested via getter)',
        () async {
          // The implementation catches this and throws PreferenceUpdateException
          stubDocFetchSuccess({bookmarkedHeadlinesField: 'not a list'});
          await expectLater(
            client.getBookmarkedHeadlines(),
            throwsA(isA<PreferenceUpdateException>()),
          );
        },
      );

      test('filters out non-map items in list (tested via getter)', () async {
        stubDocFetchSuccess({
          bookmarkedHeadlinesField: [
            testHeadline1.toJson(),
            'not a map', // Invalid item
            testHeadline2.toJson(),
          ],
        });
        final result = await client.getBookmarkedHeadlines();
        expect(result, [testHeadline1, testHeadline2]);
      });

      test(
        'throws PreferenceUpdateException if fromJson fails for an item (tested via getter)',
        () async {
          stubDocFetchSuccess({
            bookmarkedHeadlinesField: [
              testHeadline1.toJson(),
              {'invalid_field': true}, // Invalid JSON for Headline
            ],
          });
          await expectLater(
            client.getBookmarkedHeadlines(),
            throwsA(isA<PreferenceUpdateException>()),
          );
        },
      );
    });

    group('_updateField', () {
      // Tested implicitly via setter methods below
      test(
        'throws PreferenceUpdateException on FirebaseException during set',
        () async {
          stubDocUpdateFailure();
          await expectLater(
            client.setAppSettings(testAppSettings),
            throwsA(isA<PreferenceUpdateException>()),
          );
          verify(
            () =>
                mockDocRef.set(any<Map<String, dynamic>>(), any<SetOptions>()),
          ).called(1);
        },
      );

      test(
        'throws PreferenceUpdateException on generic Exception during set',
        () async {
          stubDocUpdateGenericFailure();
          await expectLater(
            client.setAppSettings(testAppSettings),
            throwsA(isA<PreferenceUpdateException>()),
          );
          verify(
            () =>
                mockDocRef.set(any<Map<String, dynamic>>(), any<SetOptions>()),
          ).called(1);
        },
      );
    });

    // --- Test Public Methods ---

    group('AppSettings', () {
      test('getAppSettings success', () async {
        stubDocFetchSuccess({appSettingsField: testAppSettings.toJson()});
        final settings = await client.getAppSettings();
        expect(settings, testAppSettings);
        verify(() => mockDocRef.get()).called(1);
      });

      test(
        'getAppSettings throws PreferenceNotFoundException if field missing',
        () async {
          stubDocFetchSuccess({});
          await expectLater(
            client.getAppSettings(),
            throwsA(isA<PreferenceNotFoundException>()),
          );
        },
      );

      test('setAppSettings success', () async {
        stubDocUpdateSuccess();
        await client.setAppSettings(testAppSettings);
        // Correct verify: SetOptions is positional
        verify(
          () => mockDocRef.set({
            appSettingsField: testAppSettings.toJson(),
          }, any(that: isA<SetOptions>())),
        ).called(1);
      });

      test(
        'setAppSettings throws PreferenceUpdateException on failure',
        () async {
          stubDocUpdateFailure();
          await expectLater(
            client.setAppSettings(testAppSettings),
            throwsA(isA<PreferenceUpdateException>()),
          );
        },
      );
    });

    group('ArticleSettings', () {
      test('getArticleSettings success', () async {
        stubDocFetchSuccess({
          articleSettingsField: testArticleSettings.toJson(),
        });
        final settings = await client.getArticleSettings();
        expect(settings, testArticleSettings);
        verify(() => mockDocRef.get()).called(1);
      });

      test(
        'getArticleSettings throws PreferenceNotFoundException if field missing',
        () async {
          stubDocFetchSuccess({});
          await expectLater(
            client.getArticleSettings(),
            throwsA(isA<PreferenceNotFoundException>()),
          );
        },
      );

      test('setArticleSettings success', () async {
        stubDocUpdateSuccess();
        await client.setArticleSettings(testArticleSettings);
        verify(
          () => mockDocRef.set(
            {articleSettingsField: testArticleSettings.toJson()},
            any(that: isA<SetOptions>()), // Correct verify
          ),
        ).called(1);
      });

      test(
        'setArticleSettings throws PreferenceUpdateException on failure',
        () async {
          stubDocUpdateFailure();
          await expectLater(
            client.setArticleSettings(testArticleSettings),
            throwsA(isA<PreferenceUpdateException>()),
          );
        },
      );
    });

    group('ThemeSettings', () {
      test('getThemeSettings success', () async {
        stubDocFetchSuccess({themeSettingsField: testThemeSettings.toJson()});
        final settings = await client.getThemeSettings();
        expect(settings, testThemeSettings);
        verify(() => mockDocRef.get()).called(1);
      });

      test(
        'getThemeSettings throws PreferenceNotFoundException if field missing',
        () async {
          stubDocFetchSuccess({});
          await expectLater(
            client.getThemeSettings(),
            throwsA(isA<PreferenceNotFoundException>()),
          );
        },
      );

      test('setThemeSettings success', () async {
        stubDocUpdateSuccess();
        await client.setThemeSettings(testThemeSettings);
        verify(
          () => mockDocRef.set(
            {themeSettingsField: testThemeSettings.toJson()},
            any(that: isA<SetOptions>()), // Correct verify
          ),
        ).called(1);
      });

      test(
        'setThemeSettings throws PreferenceUpdateException on failure',
        () async {
          stubDocUpdateFailure();
          await expectLater(
            client.setThemeSettings(testThemeSettings),
            throwsA(isA<PreferenceUpdateException>()),
          );
        },
      );
    });

    group('FeedSettings', () {
      test('getFeedSettings success', () async {
        stubDocFetchSuccess({feedSettingsField: testFeedSettings.toJson()});
        final settings = await client.getFeedSettings();
        expect(settings, testFeedSettings);
        verify(() => mockDocRef.get()).called(1);
      });

      test(
        'getFeedSettings throws PreferenceNotFoundException if field missing',
        () async {
          stubDocFetchSuccess({});
          await expectLater(
            client.getFeedSettings(),
            throwsA(isA<PreferenceNotFoundException>()),
          );
        },
      );

      test('setFeedSettings success', () async {
        stubDocUpdateSuccess();
        await client.setFeedSettings(testFeedSettings);
        verify(
          () => mockDocRef.set(
            {feedSettingsField: testFeedSettings.toJson()},
            any(that: isA<SetOptions>()), // Correct verify
          ),
        ).called(1);
      });

      test(
        'setFeedSettings throws PreferenceUpdateException on failure',
        () async {
          stubDocUpdateFailure();
          await expectLater(
            client.setFeedSettings(testFeedSettings),
            throwsA(isA<PreferenceUpdateException>()),
          );
        },
      );
    });

    group('NotificationSettings', () {
      test('getNotificationSettings success', () async {
        stubDocFetchSuccess({
          notificationSettingsField: testNotificationSettings.toJson(),
        });
        final settings = await client.getNotificationSettings();
        expect(settings, testNotificationSettings);
        verify(() => mockDocRef.get()).called(1);
      });

      test(
        'getNotificationSettings throws PreferenceNotFoundException if field missing',
        () async {
          stubDocFetchSuccess({});
          await expectLater(
            client.getNotificationSettings(),
            throwsA(isA<PreferenceNotFoundException>()),
          );
        },
      );

      test('setNotificationSettings success', () async {
        stubDocUpdateSuccess();
        await client.setNotificationSettings(testNotificationSettings);
        verify(
          () => mockDocRef.set(
            {notificationSettingsField: testNotificationSettings.toJson()},
            any(that: isA<SetOptions>()), // Correct verify
          ),
        ).called(1);
      });

      test(
        'setNotificationSettings throws PreferenceUpdateException on failure',
        () async {
          stubDocUpdateFailure();
          await expectLater(
            client.setNotificationSettings(testNotificationSettings),
            throwsA(isA<PreferenceUpdateException>()),
          );
        },
      );
    });

    group('FollowedSources', () {
      final sources = [testSource1, testSource2];
      final sourcesJson = sources.map((s) => s.toJson()).toList();

      test('getFollowedSources success', () async {
        stubDocFetchSuccess({followedSourcesField: sourcesJson});
        final result = await client.getFollowedSources();
        expect(result, sources);
        verify(() => mockDocRef.get()).called(1);
      });

      test('getFollowedSources returns empty list if field is null', () async {
        stubDocFetchSuccess({followedSourcesField: null});
        final result = await client.getFollowedSources();
        expect(result, isEmpty);
      });

      test(
        'getFollowedSources throws PreferenceNotFoundException if field missing',
        () async {
          stubDocFetchSuccess({});
          await expectLater(
            client.getFollowedSources(),
            throwsA(isA<PreferenceNotFoundException>()),
          );
        },
      );

      test('setFollowedSources success', () async {
        stubDocUpdateSuccess();
        await client.setFollowedSources(sources);
        verify(
          () => mockDocRef.set(
            {followedSourcesField: sourcesJson},
            any(that: isA<SetOptions>()), // Correct verify
          ),
        ).called(1);
      });

      test('setFollowedSources success with empty list', () async {
        stubDocUpdateSuccess();
        await client.setFollowedSources([]);
        verify(
          () => mockDocRef.set(
            {followedSourcesField: []},
            any(that: isA<SetOptions>()), // Correct verify
          ),
        ).called(1);
      });

      test(
        'setFollowedSources throws PreferenceUpdateException on failure',
        () async {
          stubDocUpdateFailure();
          await expectLater(
            client.setFollowedSources(sources),
            throwsA(isA<PreferenceUpdateException>()),
          );
        },
      );
    });

    group('FollowedCategories', () {
      final categories = [testCategory1, testCategory2];
      final categoriesJson = categories.map((c) => c.toJson()).toList();

      test('getFollowedCategories success', () async {
        stubDocFetchSuccess({followedCategoriesField: categoriesJson});
        final result = await client.getFollowedCategories();
        expect(result, categories);
        verify(() => mockDocRef.get()).called(1);
      });

      test(
        'getFollowedCategories returns empty list if field is null',
        () async {
          stubDocFetchSuccess({followedCategoriesField: null});
          final result = await client.getFollowedCategories();
          expect(result, isEmpty);
        },
      );

      test(
        'getFollowedCategories throws PreferenceNotFoundException if field missing',
        () async {
          stubDocFetchSuccess({});
          await expectLater(
            client.getFollowedCategories(),
            throwsA(isA<PreferenceNotFoundException>()),
          );
        },
      );

      test('setFollowedCategories success', () async {
        stubDocUpdateSuccess();
        await client.setFollowedCategories(categories);
        verify(
          () => mockDocRef.set(
            {followedCategoriesField: categoriesJson},
            any(that: isA<SetOptions>()), // Correct verify
          ),
        ).called(1);
      });

      test('setFollowedCategories success with empty list', () async {
        stubDocUpdateSuccess();
        await client.setFollowedCategories([]);
        verify(
          () => mockDocRef.set(
            {followedCategoriesField: []},
            any(that: isA<SetOptions>()), // Correct verify
          ),
        ).called(1);
      });

      test(
        'setFollowedCategories throws PreferenceUpdateException on failure',
        () async {
          stubDocUpdateFailure();
          await expectLater(
            client.setFollowedCategories(categories),
            throwsA(isA<PreferenceUpdateException>()),
          );
        },
      );
    });

    group('FollowedEventCountries', () {
      final countries = [testCountry1, testCountry2];
      final countriesJson = countries.map((c) => c.toJson()).toList();

      test('getFollowedEventCountries success', () async {
        stubDocFetchSuccess({followedEventCountriesField: countriesJson});
        final result = await client.getFollowedEventCountries();
        expect(result, countries);
        verify(() => mockDocRef.get()).called(1);
      });

      test(
        'getFollowedEventCountries returns empty list if field is null',
        () async {
          stubDocFetchSuccess({followedEventCountriesField: null});
          final result = await client.getFollowedEventCountries();
          expect(result, isEmpty);
        },
      );

      test(
        'getFollowedEventCountries throws PreferenceNotFoundException if field missing',
        () async {
          stubDocFetchSuccess({});
          await expectLater(
            client.getFollowedEventCountries(),
            throwsA(isA<PreferenceNotFoundException>()),
          );
        },
      );

      test('setFollowedEventCountries success', () async {
        stubDocUpdateSuccess();
        await client.setFollowedEventCountries(countries);
        verify(
          () => mockDocRef.set(
            {followedEventCountriesField: countriesJson},
            any(that: isA<SetOptions>()), // Correct verify
          ),
        ).called(1);
      });

      test('setFollowedEventCountries success with empty list', () async {
        stubDocUpdateSuccess();
        await client.setFollowedEventCountries([]);
        verify(
          () => mockDocRef.set(
            {followedEventCountriesField: []},
            any(that: isA<SetOptions>()), // Correct verify
          ),
        ).called(1);
      });

      test(
        'setFollowedEventCountries throws PreferenceUpdateException on failure',
        () async {
          stubDocUpdateFailure();
          await expectLater(
            client.setFollowedEventCountries(countries),
            throwsA(isA<PreferenceUpdateException>()),
          );
        },
      );
    });

    group('BookmarkedHeadlines', () {
      final headlines = [testHeadline1, testHeadline2];
      final headlinesJson = headlines.map((h) => h.toJson()).toList();

      test('getBookmarkedHeadlines success', () async {
        stubDocFetchSuccess({bookmarkedHeadlinesField: headlinesJson});
        final result = await client.getBookmarkedHeadlines();
        expect(result, headlines);
        verify(() => mockDocRef.get()).called(1);
      });

      test(
        'getBookmarkedHeadlines returns empty list if field is null',
        () async {
          stubDocFetchSuccess({bookmarkedHeadlinesField: null});
          final result = await client.getBookmarkedHeadlines();
          expect(result, isEmpty);
        },
      );

      test(
        'getBookmarkedHeadlines throws PreferenceNotFoundException if field missing',
        () async {
          stubDocFetchSuccess({});
          await expectLater(
            client.getBookmarkedHeadlines(),
            throwsA(isA<PreferenceNotFoundException>()),
          );
        },
      );

      test('addBookmarkedHeadline success when list exists', () async {
        stubDocFetchSuccess({bookmarkedHeadlinesField: headlinesJson});
        stubDocUpdateSuccess();
        await client.addBookmarkedHeadline(testHeadline3);
        verify(
          () => mockDocRef.set(
            {
              bookmarkedHeadlinesField: [
                ...headlinesJson,
                testHeadline3.toJson(),
              ],
            },
            any(that: isA<SetOptions>()), // Correct verify
          ),
        ).called(1);
      });

      test(
        'addBookmarkedHeadline success when list does not exist (PreferenceNotFoundException)',
        () async {
          // First get throws PreferenceNotFoundException
          stubDocFetchSuccess({}); // Simulate field missing
          stubDocUpdateSuccess(); // Stub the subsequent update

          await client.addBookmarkedHeadline(testHeadline1);

          // Verify the update call creates the list with the single item
          verify(
            () => mockDocRef.set(
              {
                bookmarkedHeadlinesField: [testHeadline1.toJson()],
              },
              any(that: isA<SetOptions>()), // Correct verify
            ),
          ).called(1);
          // Verify get was called once (inside addBookmarkedHeadline)
          await untilCalled(
            () => mockDocRef.get(),
          ); // Ensure async verify completes
          verify(() => mockDocRef.get()).called(1);
        },
      );

      test(
        'addBookmarkedHeadline does nothing if headline already exists',
        () async {
          stubDocFetchSuccess({
            bookmarkedHeadlinesField: headlinesJson,
          }); // Contains h1, h2
          await client.addBookmarkedHeadline(
            testHeadline1,
          ); // Try adding h1 again
          await untilCalled(
            () => mockDocRef.get(),
          ); // Ensure async verify completes
          verify(() => mockDocRef.get()).called(1); // Get is still called
          verifyNever(
            () =>
                mockDocRef.set(any<Map<String, dynamic>>(), any<SetOptions>()),
          ); // Set should not be called
        },
      );

      test(
        'addBookmarkedHeadline throws PreferenceUpdateException on fetch failure',
        () async {
          stubDocFetchFailure(); // Fail the initial get
          await expectLater(
            client.addBookmarkedHeadline(testHeadline3),
            throwsA(isA<PreferenceUpdateException>()),
          );
          await untilCalled(
            () => mockDocRef.get(),
          ); // Ensure async verify completes
          verify(() => mockDocRef.get()).called(1);
          verifyNever(
            () =>
                mockDocRef.set(any<Map<String, dynamic>>(), any<SetOptions>()),
          );
        },
      );

      test(
        'addBookmarkedHeadline throws PreferenceUpdateException on update failure (list exists)',
        () async {
          stubDocFetchSuccess({bookmarkedHeadlinesField: headlinesJson});
          stubDocUpdateFailure(); // Fail the set
          await expectLater(
            client.addBookmarkedHeadline(testHeadline3),
            throwsA(isA<PreferenceUpdateException>()),
          );
          await untilCalled(
            () => mockDocRef.get(),
          ); // Ensure async verify completes
          verify(() => mockDocRef.get()).called(1);
          await untilCalled(
            () =>
                mockDocRef.set(any<Map<String, dynamic>>(), any<SetOptions>()),
          ); // Ensure async verify completes
          verify(
            () =>
                mockDocRef.set(any<Map<String, dynamic>>(), any<SetOptions>()),
          ).called(1);
        },
      );

      test(
        'addBookmarkedHeadline throws PreferenceUpdateException on update failure (list not found)',
        () async {
          stubDocFetchSuccess({}); // Field missing initially
          stubDocUpdateFailure(); // Fail the set
          await expectLater(
            client.addBookmarkedHeadline(testHeadline1),
            throwsA(isA<PreferenceUpdateException>()),
          );
          await untilCalled(
            () => mockDocRef.get(),
          ); // Ensure async verify completes
          verify(() => mockDocRef.get()).called(1);
          await untilCalled(
            () =>
                mockDocRef.set(any<Map<String, dynamic>>(), any<SetOptions>()),
          ); // Ensure async verify completes
          verify(
            () =>
                mockDocRef.set(any<Map<String, dynamic>>(), any<SetOptions>()),
          ).called(1);
        },
      );

      test('removeBookmarkedHeadline success', () async {
        stubDocFetchSuccess({
          bookmarkedHeadlinesField: headlinesJson,
        }); // h1, h2
        stubDocUpdateSuccess();
        await client.removeBookmarkedHeadline(testHeadline1.id); // Remove h1
        verify(
          () => mockDocRef.set(
            {
              bookmarkedHeadlinesField: [
                testHeadline2.toJson(),
              ], // Only h2 left
            },
            any(that: isA<SetOptions>()), // Correct verify
          ),
        ).called(1);
      });

      test(
        'removeBookmarkedHeadline does nothing if list does not exist (PreferenceNotFoundException)',
        () async {
          stubDocFetchSuccess({}); // Field missing
          await client.removeBookmarkedHeadline(testHeadline1.id);
          await untilCalled(
            () => mockDocRef.get(),
          ); // Ensure async verify completes
          verify(() => mockDocRef.get()).called(1);
          verifyNever(
            () =>
                mockDocRef.set(any<Map<String, dynamic>>(), any<SetOptions>()),
          ); // No update call
        },
      );

      test(
        'removeBookmarkedHeadline does nothing if headline not in list',
        () async {
          stubDocFetchSuccess({
            bookmarkedHeadlinesField: headlinesJson,
          }); // h1, h2
          await client.removeBookmarkedHeadline('non_existent_id');
          await untilCalled(
            () => mockDocRef.get(),
          ); // Ensure async verify completes
          verify(() => mockDocRef.get()).called(1);
          verifyNever(
            () =>
                mockDocRef.set(any<Map<String, dynamic>>(), any<SetOptions>()),
          ); // No update call
        },
      );

      test(
        'removeBookmarkedHeadline throws PreferenceUpdateException on fetch failure',
        () async {
          stubDocFetchFailure(); // Fail the initial get
          await expectLater(
            client.removeBookmarkedHeadline(testHeadline1.id),
            throwsA(isA<PreferenceUpdateException>()),
          );
          await untilCalled(
            () => mockDocRef.get(),
          ); // Ensure async verify completes
          verify(() => mockDocRef.get()).called(1);
          verifyNever(
            () =>
                mockDocRef.set(any<Map<String, dynamic>>(), any<SetOptions>()),
          );
        },
      );

      test(
        'removeBookmarkedHeadline throws PreferenceUpdateException on update failure',
        () async {
          stubDocFetchSuccess({bookmarkedHeadlinesField: headlinesJson});
          stubDocUpdateFailure(); // Fail the set
          await expectLater(
            client.removeBookmarkedHeadline(testHeadline1.id),
            throwsA(isA<PreferenceUpdateException>()),
          );
          await untilCalled(
            () => mockDocRef.get(),
          ); // Ensure async verify completes
          verify(() => mockDocRef.get()).called(1);
          await untilCalled(
            () =>
                mockDocRef.set(any<Map<String, dynamic>>(), any<SetOptions>()),
          ); // Ensure async verify completes
          verify(
            () =>
                mockDocRef.set(any<Map<String, dynamic>>(), any<SetOptions>()),
          ).called(1);
        },
      );
    });

    group('HeadlineReadingHistory', () {
      final history = [
        testHeadline2,
        testHeadline1,
      ]; // Order matters: newest first
      final historyJson = history.map((h) => h.toJson()).toList();

      test('getHeadlineReadingHistory success', () async {
        stubDocFetchSuccess({headlineReadingHistoryField: historyJson});
        final result = await client.getHeadlineReadingHistory();
        expect(result, history);
        verify(() => mockDocRef.get()).called(1);
      });

      test(
        'getHeadlineReadingHistory returns empty list if field is null',
        () async {
          stubDocFetchSuccess({headlineReadingHistoryField: null});
          final result = await client.getHeadlineReadingHistory();
          expect(result, isEmpty);
        },
      );

      test(
        'getHeadlineReadingHistory throws PreferenceNotFoundException if field missing',
        () async {
          stubDocFetchSuccess({});
          await expectLater(
            client.getHeadlineReadingHistory(),
            throwsA(isA<PreferenceNotFoundException>()),
          );
        },
      );

      test(
        'addHeadlineToHistory success when list exists (new item)',
        () async {
          stubDocFetchSuccess({
            headlineReadingHistoryField: historyJson,
          }); // h2, h1
          stubDocUpdateSuccess();
          await client.addHeadlineToHistory(testHeadline3); // Add h3
          verify(
            () => mockDocRef.set(
              {
                headlineReadingHistoryField: [
                  testHeadline3.toJson(), // h3 is now first
                  ...historyJson, // h2, h1
                ],
              },
              any(that: isA<SetOptions>()), // Correct verify
            ),
          ).called(1);
        },
      );

      test(
        'addHeadlineToHistory success when list exists (existing item moves to front)',
        () async {
          stubDocFetchSuccess({
            headlineReadingHistoryField: historyJson,
          }); // h2, h1
          stubDocUpdateSuccess();
          await client.addHeadlineToHistory(testHeadline1); // Add h1 again
          verify(
            () => mockDocRef.set(
              {
                headlineReadingHistoryField: [
                  testHeadline1.toJson(), // h1 moves to front
                  testHeadline2.toJson(), // h2 remains
                ],
              },
              any(that: isA<SetOptions>()), // Correct verify
            ),
          ).called(1);
        },
      );

      test(
        'addHeadlineToHistory success when list does not exist (PreferenceNotFoundException)',
        () async {
          stubDocFetchSuccess({}); // Field missing
          stubDocUpdateSuccess();
          await client.addHeadlineToHistory(testHeadline1);
          verify(
            () => mockDocRef.set(
              {
                headlineReadingHistoryField: [testHeadline1.toJson()],
              },
              any(that: isA<SetOptions>()), // Correct verify
            ),
          ).called(1);
          await untilCalled(
            () => mockDocRef.get(),
          ); // Ensure async verify completes
          verify(() => mockDocRef.get()).called(1);
        },
      );

      test(
        'addHeadlineToHistory throws PreferenceUpdateException on fetch failure',
        () async {
          stubDocFetchFailure();
          await expectLater(
            client.addHeadlineToHistory(testHeadline3),
            throwsA(isA<PreferenceUpdateException>()),
          );
          await untilCalled(
            () => mockDocRef.get(),
          ); // Ensure async verify completes
          verify(() => mockDocRef.get()).called(1);
          verifyNever(
            () =>
                mockDocRef.set(any<Map<String, dynamic>>(), any<SetOptions>()),
          );
        },
      );

      test(
        'addHeadlineToHistory throws PreferenceUpdateException on update failure (list exists)',
        () async {
          stubDocFetchSuccess({headlineReadingHistoryField: historyJson});
          stubDocUpdateFailure();
          await expectLater(
            client.addHeadlineToHistory(testHeadline3),
            throwsA(isA<PreferenceUpdateException>()),
          );
          await untilCalled(
            () => mockDocRef.get(),
          ); // Ensure async verify completes
          verify(() => mockDocRef.get()).called(1);
          await untilCalled(
            () =>
                mockDocRef.set(any<Map<String, dynamic>>(), any<SetOptions>()),
          ); // Ensure async verify completes
          verify(
            () =>
                mockDocRef.set(any<Map<String, dynamic>>(), any<SetOptions>()),
          ).called(1);
        },
      );

      test(
        'addHeadlineToHistory throws PreferenceUpdateException on update failure (list not found)',
        () async {
          stubDocFetchSuccess({});
          stubDocUpdateFailure();
          await expectLater(
            client.addHeadlineToHistory(testHeadline1),
            throwsA(isA<PreferenceUpdateException>()),
          );
          await untilCalled(
            () => mockDocRef.get(),
          ); // Ensure async verify completes
          verify(() => mockDocRef.get()).called(1);
          await untilCalled(
            () =>
                mockDocRef.set(any<Map<String, dynamic>>(), any<SetOptions>()),
          ); // Ensure async verify completes
          verify(
            () =>
                mockDocRef.set(any<Map<String, dynamic>>(), any<SetOptions>()),
          ).called(1);
        },
      );

      test('removeHeadlineToHistory success', () async {
        stubDocFetchSuccess({
          headlineReadingHistoryField: historyJson,
        }); // h2, h1
        stubDocUpdateSuccess();
        await client.removeHeadlineToHistory(testHeadline1.id); // Remove h1
        verify(
          () => mockDocRef.set(
            {
              headlineReadingHistoryField: [
                testHeadline2.toJson(),
              ], // Only h2 left
            },
            any(that: isA<SetOptions>()), // Correct verify
          ),
        ).called(1);
      });

      test(
        'removeHeadlineToHistory does nothing if list does not exist (PreferenceNotFoundException)',
        () async {
          stubDocFetchSuccess({}); // Field missing
          await client.removeHeadlineToHistory(testHeadline1.id);
          await untilCalled(
            () => mockDocRef.get(),
          ); // Ensure async verify completes
          verify(() => mockDocRef.get()).called(1);
          verifyNever(
            () =>
                mockDocRef.set(any<Map<String, dynamic>>(), any<SetOptions>()),
          );
        },
      );

      test(
        'removeHeadlineToHistory does nothing if headline not in list',
        () async {
          stubDocFetchSuccess({
            headlineReadingHistoryField: historyJson,
          }); // h2, h1
          await client.removeHeadlineToHistory('non_existent_id');
          await untilCalled(
            () => mockDocRef.get(),
          ); // Ensure async verify completes
          verify(() => mockDocRef.get()).called(1);
          verifyNever(
            () =>
                mockDocRef.set(any<Map<String, dynamic>>(), any<SetOptions>()),
          );
        },
      );

      test(
        'removeHeadlineToHistory throws PreferenceUpdateException on fetch failure',
        () async {
          stubDocFetchFailure();
          await expectLater(
            client.removeHeadlineToHistory(testHeadline1.id),
            throwsA(isA<PreferenceUpdateException>()),
          );
          await untilCalled(
            () => mockDocRef.get(),
          ); // Ensure async verify completes
          verify(() => mockDocRef.get()).called(1);
          verifyNever(
            () =>
                mockDocRef.set(any<Map<String, dynamic>>(), any<SetOptions>()),
          );
        },
      );

      test(
        'removeHeadlineToHistory throws PreferenceUpdateException on update failure',
        () async {
          stubDocFetchSuccess({headlineReadingHistoryField: historyJson});
          stubDocUpdateFailure();
          await expectLater(
            client.removeHeadlineToHistory(testHeadline1.id),
            throwsA(isA<PreferenceUpdateException>()),
          );
          await untilCalled(
            () => mockDocRef.get(),
          ); // Ensure async verify completes
          verify(() => mockDocRef.get()).called(1);
          await untilCalled(
            () =>
                mockDocRef.set(any<Map<String, dynamic>>(), any<SetOptions>()),
          ); // Ensure async verify completes
          verify(
            () =>
                mockDocRef.set(any<Map<String, dynamic>>(), any<SetOptions>()),
          ).called(1);
        },
      );
    });
  });
}
