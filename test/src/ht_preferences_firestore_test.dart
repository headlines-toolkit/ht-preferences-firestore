//
// ignore_for_file: prefer_const_constructors, avoid_redundant_argument_values, lines_longer_than_80_chars

import 'package:cloud_firestore/cloud_firestore.dart'
    hide Source; // Hide Firestore's Source
import 'package:flutter_test/flutter_test.dart';
// Import client normally now
import 'package:ht_preferences_client/ht_preferences_client.dart';
import 'package:ht_preferences_firestore/ht_preferences_firestore.dart';
import 'package:mocktail/mocktail.dart';

// Mocks using mocktail
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  group('HtPreferencesFirestore', () {
    late FirebaseFirestore mockFirestore;
    late CollectionReference<Map<String, dynamic>> mockCollectionReference;
    late DocumentReference<Map<String, dynamic>> mockDocumentReference;
    late DocumentSnapshot<Map<String, dynamic>> mockDocumentSnapshot;
    late HtPreferencesFirestore sut; // System Under Test
    const testUserId = 'test_user_id';
    const preferencesCollection = 'preferences';

    setUp(() {
      // Create mock instances
      mockFirestore = MockFirebaseFirestore();
      mockCollectionReference = MockCollectionReference();
      mockDocumentReference = MockDocumentReference();
      mockDocumentSnapshot = MockDocumentSnapshot();

      // Define default mock behavior
      when(
        () => mockFirestore.collection(preferencesCollection),
      ).thenReturn(mockCollectionReference);
      when(
        () => mockCollectionReference.doc(testUserId),
      ).thenReturn(mockDocumentReference);

      // Instantiate the class under test
      sut = HtPreferencesFirestore(
        firestore: mockFirestore,
        userId: testUserId,
      );
    });

    // Test for successful instantiation
    test('can be instantiated', () {
      expect(sut, isNotNull);
    });

    group('getAppSettings', () {
      // Use a valid string representation of the enum for the JSON map
      final appSettingsJson = {
        'appFontSize': 'medium',
        'appFontType': 'roboto', // Corrected: Use a valid enum string
      };
      // Ensure the AppSettings object uses the correct enum value for comparison
      final appSettings = AppSettings(
        appFontSize: FontSize.medium,
        appFontType: AppFontType.roboto,
      );

      test(
        'returns AppSettings when document exists and contains data',
        () async {
          // Arrange
          when(
            () => mockDocumentReference.get(),
          ).thenAnswer((_) async => mockDocumentSnapshot);
          when(() => mockDocumentSnapshot.exists).thenReturn(true);
          when(
            () => mockDocumentSnapshot.data(),
          ).thenReturn({'app_settings': appSettingsJson});

          // Act
          final result = await sut.getAppSettings();

          // Assert
          expect(result, equals(appSettings));
          verify(() => mockDocumentReference.get()).called(1);
        },
      );

      test(
        'throws AppSettingsNotFoundException when document does not exist',
        () async {
          // Arrange
          when(
            () => mockDocumentReference.get(),
          ).thenAnswer((_) async => mockDocumentSnapshot);
          when(() => mockDocumentSnapshot.exists).thenReturn(false);
          when(
            () => mockDocumentSnapshot.data(),
          ).thenReturn(null); // Explicitly null

          // Act & Assert
          expect(
            () => sut.getAppSettings(),
            throwsA(isA<AppSettingsNotFoundException>()),
          );
          verify(() => mockDocumentReference.get()).called(1);
        },
      );

      test(
        'throws AppSettingsNotFoundException when field is missing',
        () async {
          // Arrange
          when(
            () => mockDocumentReference.get(),
          ).thenAnswer((_) async => mockDocumentSnapshot);
          when(() => mockDocumentSnapshot.exists).thenReturn(true);
          when(
            () => mockDocumentSnapshot.data(),
          ).thenReturn({'other_field': 'value'}); // Missing app_settings

          // Act & Assert
          expect(
            () => sut.getAppSettings(),
            throwsA(isA<AppSettingsNotFoundException>()),
          );
          verify(() => mockDocumentReference.get()).called(1);
        },
      );

      test('throws AppSettingsUpdateException on Firestore error', () async {
        // Arrange
        final exception = FirebaseException(
          plugin: 'test',
          message: 'Firestore error',
        );
        when(() => mockDocumentReference.get()).thenThrow(exception);

        // Act & Assert
        expect(
          () => sut.getAppSettings(),
          // Corrected: Expect the generic exception from _getPreferencesData
          throwsA(isA<PreferenceUpdateException>()),
        );
        verify(() => mockDocumentReference.get()).called(1);
      });
    });

    group('setAppSettings', () {
      final appSettings = AppSettings(
        appFontSize: FontSize.large, // Corrected: Use specific enum value
        appFontType: AppFontType.roboto, // Use valid enum from client
      );
      final appSettingsJson = appSettings.toJson();

      test('calls set with merge:true on document reference', () async {
        // Arrange
        // Need to use argThat to match the SetOptions
        when(
          () => mockDocumentReference.set(
            {'app_settings': appSettingsJson},
            any(that: isA<SetOptions>().having((o) => o.merge, 'merge', true)),
          ),
        ).thenAnswer((_) async => Future.value()); // Mock the set call

        // Act
        await sut.setAppSettings(appSettings);

        // Assert
        verify(
          () => mockDocumentReference.set(
            {'app_settings': appSettingsJson},
            any(that: isA<SetOptions>().having((o) => o.merge, 'merge', true)),
          ),
        ).called(1);
      });

      test('throws AppSettingsUpdateException on Firestore error', () async {
        // Arrange
        final exception = FirebaseException(
          plugin: 'test',
          message: 'Firestore error',
        );
        when(
          () => mockDocumentReference.set(
            {'app_settings': appSettingsJson},
            any(that: isA<SetOptions>().having((o) => o.merge, 'merge', true)),
          ),
        ).thenThrow(exception);

        // Act & Assert
        expect(
          () => sut.setAppSettings(appSettings),
          throwsA(isA<AppSettingsUpdateException>()),
        );
        verify(
          () => mockDocumentReference.set(
            {'app_settings': appSettingsJson},
            any(that: isA<SetOptions>().having((o) => o.merge, 'merge', true)),
          ),
        ).called(1);
      });
    });

    group('getArticleSettings', () {
      final articleSettingsJson = {'articleFontSize': 'small'};
      final articleSettings = ArticleSettings.fromJson(articleSettingsJson);

      test(
        'returns ArticleSettings when document exists and contains data',
        () async {
          // Arrange
          when(
            () => mockDocumentReference.get(),
          ).thenAnswer((_) async => mockDocumentSnapshot);
          when(() => mockDocumentSnapshot.exists).thenReturn(true);
          when(
            () => mockDocumentSnapshot.data(),
          ).thenReturn({'article_settings': articleSettingsJson});

          // Act
          final result = await sut.getArticleSettings();

          // Assert
          expect(result, equals(articleSettings));
          verify(() => mockDocumentReference.get()).called(1);
        },
      );

      test(
        'throws ArticleSettingsNotFoundException when document does not exist',
        () async {
          // Arrange
          when(
            () => mockDocumentReference.get(),
          ).thenAnswer((_) async => mockDocumentSnapshot);
          when(() => mockDocumentSnapshot.exists).thenReturn(false);
          when(() => mockDocumentSnapshot.data()).thenReturn(null);

          // Act & Assert
          expect(
            () => sut.getArticleSettings(),
            throwsA(isA<ArticleSettingsNotFoundException>()),
          );
          verify(() => mockDocumentReference.get()).called(1);
        },
      );

      test(
        'throws ArticleSettingsNotFoundException when field is missing',
        () async {
          // Arrange
          when(
            () => mockDocumentReference.get(),
          ).thenAnswer((_) async => mockDocumentSnapshot);
          when(() => mockDocumentSnapshot.exists).thenReturn(true);
          when(
            () => mockDocumentSnapshot.data(),
          ).thenReturn({'other_field': 'value'});

          // Act & Assert
          expect(
            () => sut.getArticleSettings(),
            throwsA(isA<ArticleSettingsNotFoundException>()),
          );
          verify(() => mockDocumentReference.get()).called(1);
        },
      );

      test('throws ArticleSettingsUpdateException on Firestore error', () async {
        // Arrange
        final exception = FirebaseException(
          plugin: 'test',
          message: 'Firestore error',
        );
        when(() => mockDocumentReference.get()).thenThrow(exception);

        // Act & Assert
        expect(
          () => sut.getArticleSettings(),
          // Corrected: Expect the generic exception thrown by _getPreferencesData
          throwsA(isA<PreferenceUpdateException>()),
        );
        verify(() => mockDocumentReference.get()).called(1);
      });
    });

    group('setArticleSettings', () {
      final articleSettings = ArticleSettings(articleFontSize: FontSize.medium);
      final articleSettingsJson = articleSettings.toJson();

      test('calls set with merge:true on document reference', () async {
        // Arrange
        when(
          () => mockDocumentReference.set(
            {'article_settings': articleSettingsJson},
            any(that: isA<SetOptions>().having((o) => o.merge, 'merge', true)),
          ),
        ).thenAnswer((_) async => Future.value());

        // Act
        await sut.setArticleSettings(articleSettings);

        // Assert
        verify(
          () => mockDocumentReference.set(
            {'article_settings': articleSettingsJson},
            any(that: isA<SetOptions>().having((o) => o.merge, 'merge', true)),
          ),
        ).called(1);
      });

      test(
        'throws ArticleSettingsUpdateException on Firestore error',
        () async {
          // Arrange
          final exception = FirebaseException(
            plugin: 'test',
            message: 'Firestore error',
          );
          when(
            () => mockDocumentReference.set(
              {'article_settings': articleSettingsJson},
              any(
                that: isA<SetOptions>().having((o) => o.merge, 'merge', true),
              ),
            ),
          ).thenThrow(exception);

          // Act & Assert
          expect(
            () => sut.setArticleSettings(articleSettings),
            throwsA(isA<ArticleSettingsUpdateException>()),
          );
          verify(
            () => mockDocumentReference.set(
              {'article_settings': articleSettingsJson},
              any(
                that: isA<SetOptions>().having((o) => o.merge, 'merge', true),
              ),
            ),
          ).called(1);
        },
      );
    });

    group('getThemeSettings', () {
      final themeSettingsJson = {'themeMode': 'dark', 'themeName': 'blue'};
      final themeSettings = ThemeSettings.fromJson(themeSettingsJson);

      test(
        'returns ThemeSettings when document exists and contains data',
        () async {
          // Arrange
          when(
            () => mockDocumentReference.get(),
          ).thenAnswer((_) async => mockDocumentSnapshot);
          when(() => mockDocumentSnapshot.exists).thenReturn(true);
          when(
            () => mockDocumentSnapshot.data(),
          ).thenReturn({'theme_settings': themeSettingsJson});

          // Act
          final result = await sut.getThemeSettings();

          // Assert
          expect(result, equals(themeSettings));
          verify(() => mockDocumentReference.get()).called(1);
        },
      );

      test(
        'throws ThemeSettingsNotFoundException when document does not exist',
        () async {
          // Arrange
          when(
            () => mockDocumentReference.get(),
          ).thenAnswer((_) async => mockDocumentSnapshot);
          when(() => mockDocumentSnapshot.exists).thenReturn(false);
          when(() => mockDocumentSnapshot.data()).thenReturn(null);

          // Act & Assert
          expect(
            () => sut.getThemeSettings(),
            throwsA(isA<ThemeSettingsNotFoundException>()),
          );
          verify(() => mockDocumentReference.get()).called(1);
        },
      );

      test(
        'throws ThemeSettingsNotFoundException when field is missing',
        () async {
          // Arrange
          when(
            () => mockDocumentReference.get(),
          ).thenAnswer((_) async => mockDocumentSnapshot);
          when(() => mockDocumentSnapshot.exists).thenReturn(true);
          when(
            () => mockDocumentSnapshot.data(),
          ).thenReturn({'other_field': 'value'});

          // Act & Assert
          expect(
            () => sut.getThemeSettings(),
            throwsA(isA<ThemeSettingsNotFoundException>()),
          );
          verify(() => mockDocumentReference.get()).called(1);
        },
      );

      test(
        'throws PreferenceUpdateException on Firestore error during get',
        () async {
          // Arrange
          final exception = FirebaseException(
            plugin: 'test',
            message: 'Firestore error',
          );
          when(() => mockDocumentReference.get()).thenThrow(exception);

          // Act & Assert
          expect(
            () => sut.getThemeSettings(),
            throwsA(isA<PreferenceUpdateException>()),
          );
          verify(() => mockDocumentReference.get()).called(1);
        },
      );
    });

    group('setThemeSettings', () {
      final themeSettings = ThemeSettings(
        themeMode: AppThemeMode.light,
        themeName: AppThemeName.red,
      );
      final themeSettingsJson = themeSettings.toJson();

      test('calls set with merge:true on document reference', () async {
        // Arrange
        when(
          () => mockDocumentReference.set(
            {'theme_settings': themeSettingsJson},
            any(that: isA<SetOptions>().having((o) => o.merge, 'merge', true)),
          ),
        ).thenAnswer((_) async => Future.value());

        // Act
        await sut.setThemeSettings(themeSettings);

        // Assert
        verify(
          () => mockDocumentReference.set(
            {'theme_settings': themeSettingsJson},
            any(that: isA<SetOptions>().having((o) => o.merge, 'merge', true)),
          ),
        ).called(1);
      });

      test(
        'throws ThemeSettingsUpdateException on Firestore error during set',
        () async {
          // Arrange
          final exception = FirebaseException(
            plugin: 'test',
            message: 'Firestore error',
          );
          when(
            () => mockDocumentReference.set(
              {'theme_settings': themeSettingsJson},
              any(
                that: isA<SetOptions>().having((o) => o.merge, 'merge', true),
              ),
            ),
          ).thenThrow(exception);

          // Act & Assert
          expect(
            () => sut.setThemeSettings(themeSettings),
            throwsA(isA<ThemeSettingsUpdateException>()),
          );
          verify(
            () => mockDocumentReference.set(
              {'theme_settings': themeSettingsJson},
              any(
                that: isA<SetOptions>().having((o) => o.merge, 'merge', true),
              ),
            ),
          ).called(1);
        },
      );
    });

    group('getBookmarkedHeadlines', () {
      final headline1Json = {'id': 'h1', 'title': 'Headline 1'};
      final headline2Json = {'id': 'h2', 'title': 'Headline 2'};
      final headline1 = Headline.fromJson(headline1Json);
      final headline2 = Headline.fromJson(headline2Json);
      final headlinesJsonList = [headline1Json, headline2Json];
      final headlinesList = [headline1, headline2];

      test(
        'returns list of Headlines when document exists and field is present',
        () async {
          // Arrange
          when(
            () => mockDocumentReference.get(),
          ).thenAnswer((_) async => mockDocumentSnapshot);
          when(() => mockDocumentSnapshot.exists).thenReturn(true);
          when(
            () => mockDocumentSnapshot.data(),
          ).thenReturn({'bookmarked_headlines': headlinesJsonList});

          // Act
          final result = await sut.getBookmarkedHeadlines();

          // Assert
          expect(result, equals(headlinesList));
          verify(() => mockDocumentReference.get()).called(1);
        },
      );

      test('returns empty list when field is missing', () async {
        // Arrange
        when(
          () => mockDocumentReference.get(),
        ).thenAnswer((_) async => mockDocumentSnapshot);
        when(() => mockDocumentSnapshot.exists).thenReturn(true);
        when(
          () => mockDocumentSnapshot.data(),
        ).thenReturn({'other_field': 'value'}); // Field missing

        // Act
        final result = await sut.getBookmarkedHeadlines();

        // Assert
        expect(result, isEmpty);
        verify(() => mockDocumentReference.get()).called(1);
      });

      test('returns empty list when document does not exist', () async {
        // Arrange
        when(
          () => mockDocumentReference.get(),
        ).thenAnswer((_) async => mockDocumentSnapshot);
        when(() => mockDocumentSnapshot.exists).thenReturn(false);
        when(() => mockDocumentSnapshot.data()).thenReturn(null);

        // Act
        final result = await sut.getBookmarkedHeadlines();

        // Assert
        expect(
          result,
          isEmpty,
        ); // Implementation returns empty list if doc missing
        verify(() => mockDocumentReference.get()).called(1);
      });

      test(
        'throws PreferenceUpdateException on Firestore error during get',
        () async {
          // Arrange
          final exception = FirebaseException(
            plugin: 'test',
            message: 'Firestore error',
          );
          when(() => mockDocumentReference.get()).thenThrow(exception);

          // Act & Assert
          expect(
            () => sut.getBookmarkedHeadlines(),
            throwsA(isA<PreferenceUpdateException>()),
          );
          verify(() => mockDocumentReference.get()).called(1);
        },
      );
    });

    group('addBookmarkedHeadline', () {
      final headline1Json = {'id': 'h1', 'title': 'Headline 1'};
      final headline2Json = {'id': 'h2', 'title': 'Headline 2'};
      final headline1 = Headline.fromJson(headline1Json);
      final headline2 = Headline.fromJson(headline2Json);
      final initialListJson = [headline1Json];
      final updatedListJson = [headline1Json, headline2Json];

      setUp(() {
        // Common setup for add/remove: mock the set call
        when(
          () => mockDocumentReference.set(
            any(), // Match any data map
            any(that: isA<SetOptions>().having((o) => o.merge, 'merge', true)),
          ),
        ).thenAnswer((_) async => Future.value());
      });

      test('adds headline to existing list', () async {
        // Arrange: Mock initial get
        when(
          () => mockDocumentReference.get(),
        ).thenAnswer((_) async => mockDocumentSnapshot);
        when(() => mockDocumentSnapshot.exists).thenReturn(true);
        when(
          () => mockDocumentSnapshot.data(),
        ).thenReturn({'bookmarked_headlines': initialListJson});

        // Act
        await sut.addBookmarkedHeadline(headline2);

        // Assert: Verify set was called with the updated list
        verify(
          () => mockDocumentReference.set(
            {'bookmarked_headlines': updatedListJson},
            any(that: isA<SetOptions>().having((o) => o.merge, 'merge', true)),
          ),
        ).called(1);
      });

      test('creates list if it does not exist', () async {
        // Arrange: Mock initial get (document exists, field missing)
        when(
          () => mockDocumentReference.get(),
        ).thenAnswer((_) async => mockDocumentSnapshot);
        when(() => mockDocumentSnapshot.exists).thenReturn(true);
        when(() => mockDocumentSnapshot.data()).thenReturn({}); // Field missing

        // Act
        await sut.addBookmarkedHeadline(headline1);

        // Assert: Verify set was called with the new list containing one item
        verify(
          () => mockDocumentReference.set(
            {
              'bookmarked_headlines': [headline1Json],
            },
            any(that: isA<SetOptions>().having((o) => o.merge, 'merge', true)),
          ),
        ).called(1);
      });

      test('creates list if document does not exist', () async {
        // Arrange: Mock initial get (document missing)
        when(
          () => mockDocumentReference.get(),
        ).thenAnswer((_) async => mockDocumentSnapshot);
        when(() => mockDocumentSnapshot.exists).thenReturn(false);
        when(() => mockDocumentSnapshot.data()).thenReturn(null);

        // Act
        await sut.addBookmarkedHeadline(headline1);

        // Assert: Verify set was called with the new list containing one item
        verify(
          () => mockDocumentReference.set(
            {
              'bookmarked_headlines': [headline1Json],
            },
            any(that: isA<SetOptions>().having((o) => o.merge, 'merge', true)),
          ),
        ).called(1);
      });

      test('does not add duplicate headline', () async {
        // Arrange: Mock initial get with headline1 already present
        when(
          () => mockDocumentReference.get(),
        ).thenAnswer((_) async => mockDocumentSnapshot);
        when(() => mockDocumentSnapshot.exists).thenReturn(true);
        when(
          () => mockDocumentSnapshot.data(),
        ).thenReturn({'bookmarked_headlines': initialListJson});

        // Act: Try to add headline1 again
        await sut.addBookmarkedHeadline(headline1);

        // Assert: Verify set was *not* called
        verifyNever(
          () => mockDocumentReference.set(
            any(),
            any(that: isA<SetOptions>().having((o) => o.merge, 'merge', true)),
          ),
        );
      });

      test(
        'throws BookmarkedHeadlinesUpdateException on Firestore error during set',
        () async {
          // Arrange: Mock initial get (can be empty or existing)
          when(
            () => mockDocumentReference.get(),
          ).thenAnswer((_) async => mockDocumentSnapshot);
          when(() => mockDocumentSnapshot.exists).thenReturn(true);
          when(
            () => mockDocumentSnapshot.data(),
          ).thenReturn({}); // Assume empty for simplicity

          // Arrange: Mock set to throw error
          final exception = FirebaseException(
            plugin: 'test',
            message: 'Firestore error',
          );
          when(
            () => mockDocumentReference.set(
              any(),
              any(
                that: isA<SetOptions>().having((o) => o.merge, 'merge', true),
              ),
            ),
          ).thenThrow(exception);

          // Act & Assert
          expect(
            () => sut.addBookmarkedHeadline(headline1),
            throwsA(isA<BookmarkedHeadlinesUpdateException>()),
          );
        },
      );
    });

    group('removeBookmarkedHeadline', () {
      final headline1Json = {'id': 'h1', 'title': 'Headline 1'};
      final headline2Json = {'id': 'h2', 'title': 'Headline 2'};
      final initialListJson = [headline1Json, headline2Json];
      final updatedListJson = [headline2Json]; // h1 removed

      setUp(() {
        // Common setup for add/remove: mock the set call
        when(
          () => mockDocumentReference.set(
            any(), // Match any data map
            any(that: isA<SetOptions>().having((o) => o.merge, 'merge', true)),
          ),
        ).thenAnswer((_) async => Future.value());
      });

      test('removes headline from existing list', () async {
        // Arrange: Mock initial get
        when(
          () => mockDocumentReference.get(),
        ).thenAnswer((_) async => mockDocumentSnapshot);
        when(() => mockDocumentSnapshot.exists).thenReturn(true);
        when(
          () => mockDocumentSnapshot.data(),
        ).thenReturn({'bookmarked_headlines': initialListJson});

        // Act
        await sut.removeBookmarkedHeadline('h1'); // Remove headline1

        // Assert: Verify set was called with the updated list
        verify(
          () => mockDocumentReference.set(
            {'bookmarked_headlines': updatedListJson},
            any(that: isA<SetOptions>().having((o) => o.merge, 'merge', true)),
          ),
        ).called(1);
      });

      test('does nothing if headline not in list', () async {
        // Arrange: Mock initial get
        when(
          () => mockDocumentReference.get(),
        ).thenAnswer((_) async => mockDocumentSnapshot);
        when(() => mockDocumentSnapshot.exists).thenReturn(true);
        when(() => mockDocumentSnapshot.data()).thenReturn({
          'bookmarked_headlines': [headline2Json],
        }); // Only h2 exists

        // Act
        await sut.removeBookmarkedHeadline('h1'); // Try to remove h1

        // Assert: Verify set was *not* called
        verifyNever(
          () => mockDocumentReference.set(
            any(),
            any(that: isA<SetOptions>().having((o) => o.merge, 'merge', true)),
          ),
        );
      });

      test('does nothing if list field does not exist', () async {
        // Arrange: Mock initial get (field missing)
        when(
          () => mockDocumentReference.get(),
        ).thenAnswer((_) async => mockDocumentSnapshot);
        when(() => mockDocumentSnapshot.exists).thenReturn(true);
        when(() => mockDocumentSnapshot.data()).thenReturn({});

        // Act
        await sut.removeBookmarkedHeadline('h1');

        // Assert: Verify set was *not* called
        verifyNever(
          () => mockDocumentReference.set(
            any(),
            any(that: isA<SetOptions>().having((o) => o.merge, 'merge', true)),
          ),
        );
      });

      test('does nothing if document does not exist', () async {
        // Arrange: Mock initial get (document missing)
        when(
          () => mockDocumentReference.get(),
        ).thenAnswer((_) async => mockDocumentSnapshot);
        when(() => mockDocumentSnapshot.exists).thenReturn(false);
        when(() => mockDocumentSnapshot.data()).thenReturn(null);

        // Act
        await sut.removeBookmarkedHeadline('h1');

        // Assert: Verify set was *not* called
        verifyNever(
          () => mockDocumentReference.set(
            any(),
            any(that: isA<SetOptions>().having((o) => o.merge, 'merge', true)),
          ),
        );
      });

      test(
        'throws BookmarkedHeadlinesUpdateException on Firestore error during set',
        () async {
          // Arrange: Mock initial get
          when(
            () => mockDocumentReference.get(),
          ).thenAnswer((_) async => mockDocumentSnapshot);
          when(() => mockDocumentSnapshot.exists).thenReturn(true);
          when(
            () => mockDocumentSnapshot.data(),
          ).thenReturn({'bookmarked_headlines': initialListJson});

          // Arrange: Mock set to throw error
          final exception = FirebaseException(
            plugin: 'test',
            message: 'Firestore error',
          );
          when(
            () => mockDocumentReference.set(
              {
                'bookmarked_headlines': updatedListJson,
              }, // Expecting updated list
              any(
                that: isA<SetOptions>().having((o) => o.merge, 'merge', true),
              ),
            ),
          ).thenThrow(exception);

          // Act & Assert
          expect(
            () => sut.removeBookmarkedHeadline('h1'),
            throwsA(isA<BookmarkedHeadlinesUpdateException>()),
          );
        },
      );
    });

    group('getFollowedSources', () {
      // Use ht_preferences_client's Source model (no prefix needed now)
      final source1Json = {'id': 's1', 'name': 'Source 1'};
      final source2Json = {'id': 's2', 'name': 'Source 2'};
      final source1 = Source.fromJson(source1Json);
      final source2 = Source.fromJson(source2Json);
      final sourcesJsonList = [source1Json, source2Json];
      final sourcesList = [source1, source2];

      test(
        'returns list of Sources when document exists and field is present',
        () async {
          // Arrange
          when(
            () => mockDocumentReference.get(),
          ).thenAnswer((_) async => mockDocumentSnapshot);
          when(() => mockDocumentSnapshot.exists).thenReturn(true);
          when(
            () => mockDocumentSnapshot.data(),
          ).thenReturn({'followed_sources': sourcesJsonList});

          // Act
          final result = await sut.getFollowedSources();

          // Assert
          expect(result, equals(sourcesList));
          verify(() => mockDocumentReference.get()).called(1);
        },
      );

      test('returns empty list when field is missing', () async {
        // Arrange
        when(
          () => mockDocumentReference.get(),
        ).thenAnswer((_) async => mockDocumentSnapshot);
        when(() => mockDocumentSnapshot.exists).thenReturn(true);
        when(
          () => mockDocumentSnapshot.data(),
        ).thenReturn({'other_field': 'value'});

        // Act
        final result = await sut.getFollowedSources();

        // Assert
        expect(result, isEmpty);
        verify(() => mockDocumentReference.get()).called(1);
      });

      test('returns empty list when document does not exist', () async {
        // Arrange
        when(
          () => mockDocumentReference.get(),
        ).thenAnswer((_) async => mockDocumentSnapshot);
        when(() => mockDocumentSnapshot.exists).thenReturn(false);
        when(() => mockDocumentSnapshot.data()).thenReturn(null);

        // Act
        final result = await sut.getFollowedSources();

        // Assert
        expect(result, isEmpty);
        verify(() => mockDocumentReference.get()).called(1);
      });

      test(
        'throws PreferenceUpdateException on Firestore error during get',
        () async {
          // Arrange
          final exception = FirebaseException(
            plugin: 'test',
            message: 'Firestore error',
          );
          when(() => mockDocumentReference.get()).thenThrow(exception);

          // Act & Assert
          expect(
            () => sut.getFollowedSources(),
            throwsA(isA<PreferenceUpdateException>()),
          );
          verify(() => mockDocumentReference.get()).called(1);
        },
      );
    });

    group('setFollowedSources', () {
      final source1Json = {'id': 's1', 'name': 'Source 1'};
      final source2Json = {'id': 's2', 'name': 'Source 2'};
      final source1 = Source.fromJson(source1Json); // No prefix needed
      final source2 = Source.fromJson(source2Json); // No prefix needed
      final sourcesList = [source1, source2];
      final sourcesJsonList = [source1Json, source2Json];

      test('calls set with merge:true on document reference', () async {
        // Arrange
        when(
          () => mockDocumentReference.set(
            {'followed_sources': sourcesJsonList},
            any(that: isA<SetOptions>().having((o) => o.merge, 'merge', true)),
          ),
        ).thenAnswer((_) async => Future.value());

        // Act
        await sut.setFollowedSources(sourcesList);

        // Assert
        verify(
          () => mockDocumentReference.set(
            {'followed_sources': sourcesJsonList},
            any(that: isA<SetOptions>().having((o) => o.merge, 'merge', true)),
          ),
        ).called(1);
      });

      test(
        'throws FollowedSourcesUpdateException on Firestore error',
        () async {
          // Arrange
          final exception = FirebaseException(
            plugin: 'test',
            message: 'Firestore error',
          );
          when(
            () => mockDocumentReference.set(
              {'followed_sources': sourcesJsonList},
              any(
                that: isA<SetOptions>().having((o) => o.merge, 'merge', true),
              ),
            ),
          ).thenThrow(exception);

          // Act & Assert
          expect(
            () => sut.setFollowedSources(sourcesList),
            throwsA(isA<FollowedSourcesUpdateException>()),
          );
          verify(
            () => mockDocumentReference.set(
              {'followed_sources': sourcesJsonList},
              any(
                that: isA<SetOptions>().having((o) => o.merge, 'merge', true),
              ),
            ),
          ).called(1);
        },
      );
    });

    group('getFollowedCategories', () {
      final category1Json = {'id': 'c1', 'name': 'Category 1'};
      final category2Json = {'id': 'c2', 'name': 'Category 2'};
      final category1 = Category.fromJson(category1Json);
      final category2 = Category.fromJson(category2Json);
      final categoriesJsonList = [category1Json, category2Json];
      final categoriesList = [category1, category2];

      test(
        'returns list of Categories when document exists and field is present',
        () async {
          // Arrange
          when(
            () => mockDocumentReference.get(),
          ).thenAnswer((_) async => mockDocumentSnapshot);
          when(() => mockDocumentSnapshot.exists).thenReturn(true);
          when(
            () => mockDocumentSnapshot.data(),
          ).thenReturn({'followed_categories': categoriesJsonList});

          // Act
          final result = await sut.getFollowedCategories();

          // Assert
          expect(result, equals(categoriesList));
          verify(() => mockDocumentReference.get()).called(1);
        },
      );

      test('returns empty list when field is missing', () async {
        // Arrange
        when(
          () => mockDocumentReference.get(),
        ).thenAnswer((_) async => mockDocumentSnapshot);
        when(() => mockDocumentSnapshot.exists).thenReturn(true);
        when(
          () => mockDocumentSnapshot.data(),
        ).thenReturn({'other_field': 'value'});

        // Act
        final result = await sut.getFollowedCategories();

        // Assert
        expect(result, isEmpty);
        verify(() => mockDocumentReference.get()).called(1);
      });

      test('returns empty list when document does not exist', () async {
        // Arrange
        when(
          () => mockDocumentReference.get(),
        ).thenAnswer((_) async => mockDocumentSnapshot);
        when(() => mockDocumentSnapshot.exists).thenReturn(false);
        when(() => mockDocumentSnapshot.data()).thenReturn(null);

        // Act
        final result = await sut.getFollowedCategories();

        // Assert
        expect(result, isEmpty);
        verify(() => mockDocumentReference.get()).called(1);
      });

      test(
        'throws PreferenceUpdateException on Firestore error during get',
        () async {
          // Arrange
          final exception = FirebaseException(
            plugin: 'test',
            message: 'Firestore error',
          );
          when(() => mockDocumentReference.get()).thenThrow(exception);

          // Act & Assert
          expect(
            () => sut.getFollowedCategories(),
            throwsA(isA<PreferenceUpdateException>()),
          );
          verify(() => mockDocumentReference.get()).called(1);
        },
      );
    });

    group('setFollowedCategories', () {
      final category1Json = {'id': 'c1', 'name': 'Category 1'};
      final category2Json = {'id': 'c2', 'name': 'Category 2'};
      final category1 = Category.fromJson(category1Json);
      final category2 = Category.fromJson(category2Json);
      final categoriesList = [category1, category2];
      final categoriesJsonList = [category1Json, category2Json];

      test('calls set with merge:true on document reference', () async {
        // Arrange
        when(
          () => mockDocumentReference.set(
            {'followed_categories': categoriesJsonList},
            any(that: isA<SetOptions>().having((o) => o.merge, 'merge', true)),
          ),
        ).thenAnswer((_) async => Future.value());

        // Act
        await sut.setFollowedCategories(categoriesList);

        // Assert
        verify(
          () => mockDocumentReference.set(
            {'followed_categories': categoriesJsonList},
            any(that: isA<SetOptions>().having((o) => o.merge, 'merge', true)),
          ),
        ).called(1);
      });

      test(
        'throws FollowedCategoriesUpdateException on Firestore error',
        () async {
          // Arrange
          final exception = FirebaseException(
            plugin: 'test',
            message: 'Firestore error',
          );
          when(
            () => mockDocumentReference.set(
              {'followed_categories': categoriesJsonList},
              any(
                that: isA<SetOptions>().having((o) => o.merge, 'merge', true),
              ),
            ),
          ).thenThrow(exception);

          // Act & Assert
          expect(
            () => sut.setFollowedCategories(categoriesList),
            throwsA(isA<FollowedCategoriesUpdateException>()),
          );
          verify(
            () => mockDocumentReference.set(
              {'followed_categories': categoriesJsonList},
              any(
                that: isA<SetOptions>().having((o) => o.merge, 'merge', true),
              ),
            ),
          ).called(1);
        },
      );
    });

    group('getFollowedEventCountries', () {
      final country1Json = {
        'id': 'co1',
        'iso_code': 'US',
        'name': 'USA',
        'flag_url': 'url1',
      };
      final country2Json = {
        'id': 'co2',
        'iso_code': 'CA',
        'name': 'Canada',
        'flag_url': 'url2',
      };
      final country1 = Country.fromJson(country1Json);
      final country2 = Country.fromJson(country2Json);
      final countriesJsonList = [country1Json, country2Json];
      final countriesList = [country1, country2];

      test(
        'returns list of Countries when document exists and field is present',
        () async {
          // Arrange
          when(
            () => mockDocumentReference.get(),
          ).thenAnswer((_) async => mockDocumentSnapshot);
          when(() => mockDocumentSnapshot.exists).thenReturn(true);
          when(
            () => mockDocumentSnapshot.data(),
          ).thenReturn({'followed_event_countries': countriesJsonList});

          // Act
          final result = await sut.getFollowedEventCountries();

          // Assert
          expect(result, equals(countriesList));
          verify(() => mockDocumentReference.get()).called(1);
        },
      );

      test('returns empty list when field is missing', () async {
        // Arrange
        when(
          () => mockDocumentReference.get(),
        ).thenAnswer((_) async => mockDocumentSnapshot);
        when(() => mockDocumentSnapshot.exists).thenReturn(true);
        when(
          () => mockDocumentSnapshot.data(),
        ).thenReturn({'other_field': 'value'});

        // Act
        final result = await sut.getFollowedEventCountries();

        // Assert
        expect(result, isEmpty);
        verify(() => mockDocumentReference.get()).called(1);
      });

      test('returns empty list when document does not exist', () async {
        // Arrange
        when(
          () => mockDocumentReference.get(),
        ).thenAnswer((_) async => mockDocumentSnapshot);
        when(() => mockDocumentSnapshot.exists).thenReturn(false);
        when(() => mockDocumentSnapshot.data()).thenReturn(null);

        // Act
        final result = await sut.getFollowedEventCountries();

        // Assert
        expect(result, isEmpty);
        verify(() => mockDocumentReference.get()).called(1);
      });

      test(
        'throws PreferenceUpdateException on Firestore error during get',
        () async {
          // Arrange
          final exception = FirebaseException(
            plugin: 'test',
            message: 'Firestore error',
          );
          when(() => mockDocumentReference.get()).thenThrow(exception);

          // Act & Assert
          expect(
            () => sut.getFollowedEventCountries(),
            throwsA(isA<PreferenceUpdateException>()),
          );
          verify(() => mockDocumentReference.get()).called(1);
        },
      );
    });

    group('setFollowedEventCountries', () {
      final country1Json = {
        'id': 'co1',
        'iso_code': 'US',
        'name': 'USA',
        'flag_url': 'url1',
      };
      final country2Json = {
        'id': 'co2',
        'iso_code': 'CA',
        'name': 'Canada',
        'flag_url': 'url2',
      };
      final country1 = Country.fromJson(country1Json);
      final country2 = Country.fromJson(country2Json);
      final countriesList = [country1, country2];
      final countriesJsonList = [country1Json, country2Json];

      test('calls set with merge:true on document reference', () async {
        // Arrange
        when(
          () => mockDocumentReference.set(
            {'followed_event_countries': countriesJsonList},
            any(that: isA<SetOptions>().having((o) => o.merge, 'merge', true)),
          ),
        ).thenAnswer((_) async => Future.value());

        // Act
        await sut.setFollowedEventCountries(countriesList);

        // Assert
        verify(
          () => mockDocumentReference.set(
            {'followed_event_countries': countriesJsonList},
            any(that: isA<SetOptions>().having((o) => o.merge, 'merge', true)),
          ),
        ).called(1);
      });

      test(
        'throws FollowedEventCountriesUpdateException on Firestore error',
        () async {
          // Arrange
          final exception = FirebaseException(
            plugin: 'test',
            message: 'Firestore error',
          );
          when(
            () => mockDocumentReference.set(
              {'followed_event_countries': countriesJsonList},
              any(
                that: isA<SetOptions>().having((o) => o.merge, 'merge', true),
              ),
            ),
          ).thenThrow(exception);

          // Act & Assert
          expect(
            () => sut.setFollowedEventCountries(countriesList),
            throwsA(isA<FollowedEventCountriesUpdateException>()),
          );
          verify(
            () => mockDocumentReference.set(
              {'followed_event_countries': countriesJsonList},
              any(
                that: isA<SetOptions>().having((o) => o.merge, 'merge', true),
              ),
            ),
          ).called(1);
        },
      );
    });

    group('getHeadlineReadingHistory', () {
      final headline1Json = {'id': 'h1', 'title': 'History 1'};
      final headline2Json = {'id': 'h2', 'title': 'History 2'};
      final headline1 = Headline.fromJson(headline1Json);
      final headline2 = Headline.fromJson(headline2Json);
      final historyJsonList = [headline1Json, headline2Json];
      final historyList = [headline1, headline2];

      test(
        'returns list of Headlines when document exists and field is present',
        () async {
          // Arrange
          when(
            () => mockDocumentReference.get(),
          ).thenAnswer((_) async => mockDocumentSnapshot);
          when(() => mockDocumentSnapshot.exists).thenReturn(true);
          when(
            () => mockDocumentSnapshot.data(),
          ).thenReturn({'headline_reading_history': historyJsonList});

          // Act
          final result = await sut.getHeadlineReadingHistory();

          // Assert
          expect(result, equals(historyList));
          verify(() => mockDocumentReference.get()).called(1);
        },
      );

      test('returns empty list when field is missing', () async {
        // Arrange
        when(
          () => mockDocumentReference.get(),
        ).thenAnswer((_) async => mockDocumentSnapshot);
        when(() => mockDocumentSnapshot.exists).thenReturn(true);
        when(
          () => mockDocumentSnapshot.data(),
        ).thenReturn({'other_field': 'value'});

        // Act
        final result = await sut.getHeadlineReadingHistory();

        // Assert
        expect(result, isEmpty);
        verify(() => mockDocumentReference.get()).called(1);
      });

      test('returns empty list when document does not exist', () async {
        // Arrange
        when(
          () => mockDocumentReference.get(),
        ).thenAnswer((_) async => mockDocumentSnapshot);
        when(() => mockDocumentSnapshot.exists).thenReturn(false);
        when(() => mockDocumentSnapshot.data()).thenReturn(null);

        // Act
        final result = await sut.getHeadlineReadingHistory();

        // Assert
        expect(result, isEmpty);
        verify(() => mockDocumentReference.get()).called(1);
      });

      test(
        'throws PreferenceUpdateException on Firestore error during get',
        () async {
          // Arrange
          final exception = FirebaseException(
            plugin: 'test',
            message: 'Firestore error',
          );
          when(() => mockDocumentReference.get()).thenThrow(exception);

          // Act & Assert
          expect(
            () => sut.getHeadlineReadingHistory(),
            throwsA(isA<PreferenceUpdateException>()),
          );
          verify(() => mockDocumentReference.get()).called(1);
        },
      );
    });

    group('addHeadlineToHistory', () {
      final headline1Json = {'id': 'h1', 'title': 'History 1'};
      final headline2Json = {'id': 'h2', 'title': 'History 2'};
      final headline1 = Headline.fromJson(headline1Json);
      final headline2 = Headline.fromJson(headline2Json);
      final initialListJson = [headline1Json];
      final updatedListJson = [headline1Json, headline2Json];

      setUp(() {
        when(
          () => mockDocumentReference.set(
            any(),
            any(that: isA<SetOptions>().having((o) => o.merge, 'merge', true)),
          ),
        ).thenAnswer((_) async => Future.value());
      });

      test('adds headline to existing history list', () async {
        // Arrange
        when(
          () => mockDocumentReference.get(),
        ).thenAnswer((_) async => mockDocumentSnapshot);
        when(() => mockDocumentSnapshot.exists).thenReturn(true);
        when(
          () => mockDocumentSnapshot.data(),
        ).thenReturn({'headline_reading_history': initialListJson});

        // Act
        await sut.addHeadlineToHistory(headline2);

        // Assert
        verify(
          () => mockDocumentReference.set(
            {'headline_reading_history': updatedListJson},
            any(that: isA<SetOptions>().having((o) => o.merge, 'merge', true)),
          ),
        ).called(1);
      });

      test('creates history list if it does not exist', () async {
        // Arrange
        when(
          () => mockDocumentReference.get(),
        ).thenAnswer((_) async => mockDocumentSnapshot);
        when(() => mockDocumentSnapshot.exists).thenReturn(true);
        when(() => mockDocumentSnapshot.data()).thenReturn({});

        // Act
        await sut.addHeadlineToHistory(headline1);

        // Assert
        verify(
          () => mockDocumentReference.set(
            {
              'headline_reading_history': [headline1Json],
            },
            any(that: isA<SetOptions>().having((o) => o.merge, 'merge', true)),
          ),
        ).called(1);
      });

      test('creates history list if document does not exist', () async {
        // Arrange
        when(
          () => mockDocumentReference.get(),
        ).thenAnswer((_) async => mockDocumentSnapshot);
        when(() => mockDocumentSnapshot.exists).thenReturn(false);
        when(() => mockDocumentSnapshot.data()).thenReturn(null);

        // Act
        await sut.addHeadlineToHistory(headline1);

        // Assert
        verify(
          () => mockDocumentReference.set(
            {
              'headline_reading_history': [headline1Json],
            },
            any(that: isA<SetOptions>().having((o) => o.merge, 'merge', true)),
          ),
        ).called(1);
      });

      // Optionally add test for duplicate handling if implemented in SUT
      // test('does not add duplicate headline to history', () async { ... });

      test(
        'throws HeadlineReadingHistoryUpdateException on Firestore error during set',
        () async {
          // Arrange
          when(
            () => mockDocumentReference.get(),
          ).thenAnswer((_) async => mockDocumentSnapshot);
          when(() => mockDocumentSnapshot.exists).thenReturn(true);
          when(() => mockDocumentSnapshot.data()).thenReturn({});

          final exception = FirebaseException(
            plugin: 'test',
            message: 'Firestore error',
          );
          when(
            () => mockDocumentReference.set(
              any(),
              any(
                that: isA<SetOptions>().having((o) => o.merge, 'merge', true),
              ),
            ),
          ).thenThrow(exception);

          // Act & Assert
          expect(
            () => sut.addHeadlineToHistory(headline1),
            throwsA(isA<HeadlineReadingHistoryUpdateException>()),
          );
        },
      );
    });

    group('removeHeadlineToHistory', () {
      final headline1Json = {'id': 'h1', 'title': 'History 1'};
      final headline2Json = {'id': 'h2', 'title': 'History 2'};
      final initialListJson = [headline1Json, headline2Json];
      final updatedListJson = [headline2Json]; // h1 removed

      setUp(() {
        when(
          () => mockDocumentReference.set(
            any(),
            any(that: isA<SetOptions>().having((o) => o.merge, 'merge', true)),
          ),
        ).thenAnswer((_) async => Future.value());
      });

      test('removes headline from existing history list', () async {
        // Arrange
        when(
          () => mockDocumentReference.get(),
        ).thenAnswer((_) async => mockDocumentSnapshot);
        when(() => mockDocumentSnapshot.exists).thenReturn(true);
        when(
          () => mockDocumentSnapshot.data(),
        ).thenReturn({'headline_reading_history': initialListJson});

        // Act
        await sut.removeHeadlineToHistory('h1');

        // Assert
        verify(
          () => mockDocumentReference.set(
            {'headline_reading_history': updatedListJson},
            any(that: isA<SetOptions>().having((o) => o.merge, 'merge', true)),
          ),
        ).called(1);
      });

      test('does nothing if headline not in history list', () async {
        // Arrange
        when(
          () => mockDocumentReference.get(),
        ).thenAnswer((_) async => mockDocumentSnapshot);
        when(() => mockDocumentSnapshot.exists).thenReturn(true);
        when(() => mockDocumentSnapshot.data()).thenReturn({
          'headline_reading_history': [headline2Json],
        });

        // Act
        await sut.removeHeadlineToHistory('h1');

        // Assert
        verifyNever(
          () => mockDocumentReference.set(
            any(),
            any(that: isA<SetOptions>().having((o) => o.merge, 'merge', true)),
          ),
        );
      });

      test('does nothing if history list field does not exist', () async {
        // Arrange
        when(
          () => mockDocumentReference.get(),
        ).thenAnswer((_) async => mockDocumentSnapshot);
        when(() => mockDocumentSnapshot.exists).thenReturn(true);
        when(() => mockDocumentSnapshot.data()).thenReturn({});

        // Act
        await sut.removeHeadlineToHistory('h1');

        // Assert
        verifyNever(
          () => mockDocumentReference.set(
            any(),
            any(that: isA<SetOptions>().having((o) => o.merge, 'merge', true)),
          ),
        );
      });

      test('does nothing if document does not exist', () async {
        // Arrange
        when(
          () => mockDocumentReference.get(),
        ).thenAnswer((_) async => mockDocumentSnapshot);
        when(() => mockDocumentSnapshot.exists).thenReturn(false);
        when(() => mockDocumentSnapshot.data()).thenReturn(null);

        // Act
        await sut.removeHeadlineToHistory('h1');

        // Assert
        verifyNever(
          () => mockDocumentReference.set(
            any(),
            any(that: isA<SetOptions>().having((o) => o.merge, 'merge', true)),
          ),
        );
      });

      test(
        'throws HeadlineReadingHistoryUpdateException on Firestore error during set',
        () async {
          // Arrange
          when(
            () => mockDocumentReference.get(),
          ).thenAnswer((_) async => mockDocumentSnapshot);
          when(() => mockDocumentSnapshot.exists).thenReturn(true);
          when(
            () => mockDocumentSnapshot.data(),
          ).thenReturn({'headline_reading_history': initialListJson});

          final exception = FirebaseException(
            plugin: 'test',
            message: 'Firestore error',
          );
          when(
            () => mockDocumentReference.set(
              {'headline_reading_history': updatedListJson},
              any(
                that: isA<SetOptions>().having((o) => o.merge, 'merge', true),
              ),
            ),
          ).thenThrow(exception);

          // Act & Assert
          expect(
            () => sut.removeHeadlineToHistory('h1'),
            throwsA(isA<HeadlineReadingHistoryUpdateException>()),
          );
        },
      );
    });

    group('getFeedSettings', () {
      final feedSettingsJson = {'feedListTileType': 'imageTop'};
      final feedSettings = FeedSettings.fromJson(feedSettingsJson);

      test(
        'returns FeedSettings when document exists and contains data',
        () async {
          // Arrange
          when(
            () => mockDocumentReference.get(),
          ).thenAnswer((_) async => mockDocumentSnapshot);
          when(() => mockDocumentSnapshot.exists).thenReturn(true);
          when(
            () => mockDocumentSnapshot.data(),
          ).thenReturn({'feed_settings': feedSettingsJson});

          // Act
          final result = await sut.getFeedSettings();

          // Assert
          expect(result, equals(feedSettings));
          verify(() => mockDocumentReference.get()).called(1);
        },
      );

      test(
        'throws FeedSettingsNotFoundException when document does not exist',
        () async {
          // Arrange
          when(
            () => mockDocumentReference.get(),
          ).thenAnswer((_) async => mockDocumentSnapshot);
          when(() => mockDocumentSnapshot.exists).thenReturn(false);
          when(() => mockDocumentSnapshot.data()).thenReturn(null);

          // Act & Assert
          expect(
            () => sut.getFeedSettings(),
            throwsA(isA<FeedSettingsNotFoundException>()),
          );
          verify(() => mockDocumentReference.get()).called(1);
        },
      );

      test(
        'throws FeedSettingsNotFoundException when field is missing',
        () async {
          // Arrange
          when(
            () => mockDocumentReference.get(),
          ).thenAnswer((_) async => mockDocumentSnapshot);
          when(() => mockDocumentSnapshot.exists).thenReturn(true);
          when(
            () => mockDocumentSnapshot.data(),
          ).thenReturn({'other_field': 'value'});

          // Act & Assert
          expect(
            () => sut.getFeedSettings(),
            throwsA(isA<FeedSettingsNotFoundException>()),
          );
          verify(() => mockDocumentReference.get()).called(1);
        },
      );

      test(
        'throws PreferenceUpdateException on Firestore error during get',
        () async {
          // Arrange
          final exception = FirebaseException(
            plugin: 'test',
            message: 'Firestore error',
          );
          when(() => mockDocumentReference.get()).thenThrow(exception);

          // Act & Assert
          expect(
            () => sut.getFeedSettings(),
            throwsA(isA<PreferenceUpdateException>()),
          );
          verify(() => mockDocumentReference.get()).called(1);
        },
      );
    });

    group('setFeedSettings', () {
      final feedSettings = FeedSettings(
        feedListTileType: FeedListTileType.imageStart,
      );
      final feedSettingsJson = feedSettings.toJson();

      test('calls set with merge:true on document reference', () async {
        // Arrange
        when(
          () => mockDocumentReference.set(
            {'feed_settings': feedSettingsJson},
            any(that: isA<SetOptions>().having((o) => o.merge, 'merge', true)),
          ),
        ).thenAnswer((_) async => Future.value());

        // Act
        await sut.setFeedSettings(feedSettings);

        // Assert
        verify(
          () => mockDocumentReference.set(
            {'feed_settings': feedSettingsJson},
            any(that: isA<SetOptions>().having((o) => o.merge, 'merge', true)),
          ),
        ).called(1);
      });

      test('throws FeedSettingsUpdateException on Firestore error', () async {
        // Arrange
        final exception = FirebaseException(
          plugin: 'test',
          message: 'Firestore error',
        );
        when(
          () => mockDocumentReference.set(
            {'feed_settings': feedSettingsJson},
            any(that: isA<SetOptions>().having((o) => o.merge, 'merge', true)),
          ),
        ).thenThrow(exception);

        // Act & Assert
        expect(
          () => sut.setFeedSettings(feedSettings),
          throwsA(isA<FeedSettingsUpdateException>()),
        );
        verify(
          () => mockDocumentReference.set(
            {'feed_settings': feedSettingsJson},
            any(that: isA<SetOptions>().having((o) => o.merge, 'merge', true)),
          ),
        ).called(1);
      });
    });

    group('getNotificationSettings', () {
      final notificationSettingsJson = {
        'enabled': true,
        'categoryNotifications': ['c1', 'c2'],
        'sourceNotifications': ['s1'],
        'followedEventCountryIds': ['US'],
      };
      final notificationSettings = NotificationSettings.fromJson(
        notificationSettingsJson,
      );

      test(
        'returns NotificationSettings when document exists and contains data',
        () async {
          // Arrange
          when(
            () => mockDocumentReference.get(),
          ).thenAnswer((_) async => mockDocumentSnapshot);
          when(() => mockDocumentSnapshot.exists).thenReturn(true);
          when(
            () => mockDocumentSnapshot.data(),
          ).thenReturn({'notification_settings': notificationSettingsJson});

          // Act
          final result = await sut.getNotificationSettings();

          // Assert
          expect(result, equals(notificationSettings));
          verify(() => mockDocumentReference.get()).called(1);
        },
      );

      test(
        'throws NotificationSettingsNotFoundException when document does not exist',
        () async {
          // Arrange
          when(
            () => mockDocumentReference.get(),
          ).thenAnswer((_) async => mockDocumentSnapshot);
          when(() => mockDocumentSnapshot.exists).thenReturn(false);
          when(() => mockDocumentSnapshot.data()).thenReturn(null);

          // Act & Assert
          expect(
            () => sut.getNotificationSettings(),
            throwsA(isA<NotificationSettingsNotFoundException>()),
          );
          verify(() => mockDocumentReference.get()).called(1);
        },
      );

      test(
        'throws NotificationSettingsNotFoundException when field is missing',
        () async {
          // Arrange
          when(
            () => mockDocumentReference.get(),
          ).thenAnswer((_) async => mockDocumentSnapshot);
          when(() => mockDocumentSnapshot.exists).thenReturn(true);
          when(
            () => mockDocumentSnapshot.data(),
          ).thenReturn({'other_field': 'value'});

          // Act & Assert
          expect(
            () => sut.getNotificationSettings(),
            throwsA(isA<NotificationSettingsNotFoundException>()),
          );
          verify(() => mockDocumentReference.get()).called(1);
        },
      );

      test(
        'throws PreferenceUpdateException on Firestore error during get',
        () async {
          // Arrange
          final exception = FirebaseException(
            plugin: 'test',
            message: 'Firestore error',
          );
          when(() => mockDocumentReference.get()).thenThrow(exception);

          // Act & Assert
          expect(
            () => sut.getNotificationSettings(),
            throwsA(isA<PreferenceUpdateException>()),
          );
          verify(() => mockDocumentReference.get()).called(1);
        },
      );
    });

    group('setNotificationPreferences', () {
      final notificationSettings = NotificationSettings(
        enabled: false,
        categoryNotifications: const ['c3'],
        sourceNotifications: const [],
        followedEventCountryIds: const ['CA', 'GB'],
      );
      final notificationSettingsJson = notificationSettings.toJson();

      test('calls set with merge:true on document reference', () async {
        // Arrange
        when(
          () => mockDocumentReference.set(
            {'notification_settings': notificationSettingsJson},
            any(that: isA<SetOptions>().having((o) => o.merge, 'merge', true)),
          ),
        ).thenAnswer((_) async => Future.value());

        // Act
        await sut.setNotificationPreferences(notificationSettings);

        // Assert
        verify(
          () => mockDocumentReference.set(
            {'notification_settings': notificationSettingsJson},
            any(that: isA<SetOptions>().having((o) => o.merge, 'merge', true)),
          ),
        ).called(1);
      });

      test(
        'throws NotificationSettingsUpdateException on Firestore error',
        () async {
          // Arrange
          final exception = FirebaseException(
            plugin: 'test',
            message: 'Firestore error',
          );
          when(
            () => mockDocumentReference.set(
              {'notification_settings': notificationSettingsJson},
              any(
                that: isA<SetOptions>().having((o) => o.merge, 'merge', true),
              ),
            ),
          ).thenThrow(exception);

          // Act & Assert
          expect(
            () => sut.setNotificationPreferences(notificationSettings),
            throwsA(isA<NotificationSettingsUpdateException>()),
          );
          verify(
            () => mockDocumentReference.set(
              {'notification_settings': notificationSettingsJson},
              any(
                that: isA<SetOptions>().having((o) => o.merge, 'merge', true),
              ),
            ),
          ).called(1);
        },
      );
    });

    // --- Add more tests for other methods following similar patterns ---
    // e.g.,
    // Remember to mock the specific document reads and writes for each test case.
  });
}
