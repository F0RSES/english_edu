import 'package:english_edu/core/localization/strings.dart';
import 'package:english_edu/domain/value_objects/achievement_type.dart';
import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:english_edu/domain/value_objects/daily_challenge_type.dart';
import 'package:test/test.dart';

void main() {
  group('S', () {
    // Все параметризованные методы: вывод не должен содержать плейсхолдеров.
    final parameterized = <String Function(AppLanguage)>[
      (l) => S.weakWords(3, l),
      (l) => S.smartReview(2, l),
      (l) => S.wordCount(5, l),
      (l) => S.daysInARow(5, l),
      (l) => S.milestoneFire(30, l),
      (l) => S.untilMilestone(2, l),
      (l) => S.wordsToday(5, 10, l),
      (l) => S.claimReward(50, l),
      (l) => S.challengeStreak(3, l),
      (l) => S.bestStreak(7, l),
      (l) => S.xpGained(10, l),
      (l) => S.levelLabel('B1', l),
      (l) => S.achievementsHeader(2, 30, l),
      (l) => S.lapsesCount(5, l),
      (l) => S.projectionDate('01.01.2027', l),
      (l) => S.categoryCreated('IT', l),
      (l) => S.syncResult(3, 2, l),
      (l) => S.linkSent('a@b.c', l),
      (l) => S.remindersDaily('09:00', l),
      (l) => S.wordExists('apple', l),
      (l) => S.invalidJson('oops', l),
      (l) => S.unsupportedVersion(99, l),
      (l) => S.sessionCorrect(3, 5, l),
      (l) => S.sessionXp(40, l),
      (l) => S.removeConfirmBody('apple', l),
      (l) => S.scrambleCorrectCount(3, l),
      (l) => S.typingAccuracy(95, l),
      (l) => S.typingScore(120, l),
      (l) => S.typingWpm(40, l),
      (l) => S.memoryVictoryBody(12, l),
      (l) => S.memoryMoves(7, l),
      (l) => S.achievementsUnlocked(3, l),
      (l) => S.achievementsInProgress(27, l),
      (l) => S.readingAddedWords(2, l),
      (l) => S.readingAddWords(5, l),
      (l) => S.listeningWrongAnswer('I eat an apple.', l),
      (l) => S.aiWordPrompt('could', 'мог', 'verb', l),
      (l) => S.aiWordPrompt('could', 'мог', null, l),
    ];

    test('parameterized strings leave no placeholders in either language', () {
      for (final build in parameterized) {
        for (final lang in AppLanguage.values) {
          final value = build(lang);
          expect(value, isNotEmpty, reason: '$lang');
          expect(value.contains('{'), isFalse, reason: '$lang: $value');
        }
      }
    });

    test('every achievement has a title and description in both languages', () {
      for (final type in AchievementType.values) {
        for (final lang in AppLanguage.values) {
          final title = S.achievementTitle(type, lang);
          final description = S.achievementDescription(type, lang);
          expect(title, isNotEmpty, reason: '${type.key} $lang');
          expect(description, isNotEmpty, reason: '${type.key} $lang');
          // Fallback вернул бы ключ — значит перевода нет.
          expect(title, isNot(contains('achievement.')));
          expect(description, isNot(contains('achievementDesc.')));
        }
      }
    });

    test('every challenge type has a label in both languages', () {
      for (final type in DailyChallengeType.values) {
        for (final lang in AppLanguage.values) {
          final label = S.challengeLabel(type, lang);
          expect(label, isNotEmpty);
          expect(label, isNot(contains('challenge.')));
        }
      }
    });

    test('simple strings are non-empty in both languages', () {
      final simple = <String Function(AppLanguage)>[
        S.home,
        S.dictionary,
        S.profile,
        S.settings,
        S.back,
        S.startLesson,
        S.words,
        S.sectionStudy,
        S.sectionGames,
        S.check,
        S.next,
        S.incorrect,
        S.correct,
        S.explain,
        S.cancel,
        S.retry,
        S.loading,
        S.saveFailed,
        S.language,
        S.levelTooltip,
        S.assistant,
        S.allWordsLearned,
        S.streakStart,
        S.milestone7,
        S.milestone365,
        S.freezeUsed,
        S.challengeDone,
        S.claimFailed,
        S.learner,
        S.statStreak,
        S.statWords,
        S.statXp,
        S.allAchievements,
        S.allAchievementsTooltip,
        S.noAchievements,
        S.analyticsFailed,
        S.metricTotal,
        S.metricMastered,
        S.metricLearning,
        S.metricNew,
        S.last7Days,
        S.hardWords,
        S.noLapses,
        S.projectionNone,
        S.dailyLimits,
        S.newPerDay,
        S.reviewsPerDay,
        S.ttsSection,
        S.voice,
        S.speechRate,
        S.ttsFailed,
        S.backupSection,
        S.achievementsTile,
        S.achievementsSubtitle,
        S.categoriesTile,
        S.categoriesSubtitle,
        S.exportTile,
        S.exportSubtitle,
        S.importTile,
        S.importSubtitle,
        S.importDone,
        S.cloudSection,
        S.cloudUnavailable,
        S.cloudNoKeys,
        S.signIn,
        S.signInSubtitle,
        S.syncNow,
        S.signOut,
        S.syncFailed,
        S.linkFailed,
        S.dangerZone,
        S.resetTile,
        S.resetSubtitle,
        S.resetConfirmTitle,
        S.resetConfirmBody,
        S.resetConfirm,
        S.resetDone,
        S.resetFailed,
        S.howItWorks,
        S.onboardingTile,
        S.analyticsSection,
        S.remindersSection,
        S.remindersToggle,
        S.remindersOff,
        S.reminderTime,
        S.reminderFailed,
        S.settingsLoadFailed,
        S.emailTitle,
        S.emailLabel,
        S.emailCheck,
        S.emailSend,
        S.searchHint,
        S.addWordTooltip,
        S.wordAdded,
        S.tabAll,
        S.tabLearning,
        S.tabMastered,
        S.allCategories,
        S.allLevels,
        S.resetFilters,
        S.addToLearning,
        S.markMastered,
        S.resetWord,
        S.emptySearch,
        S.emptyCategory,
        S.emptyLevel,
        S.emptyTab,
        S.emptyDictionary,
        S.dictionaryLoadFailed,
        S.statusNew,
        S.statusLearning,
        S.statusMastered,
        S.noExample,
        S.noCategory,
        S.addWordTitle,
        S.fieldTerm,
        S.fieldTranslation,
        S.fieldTranscription,
        S.fieldPartOfSpeech,
        S.fieldCategory,
        S.fieldLevel,
        S.fieldExample,
        S.addWordAction,
        S.enterTerm,
        S.enterTranslation,
        S.wordSaveFailed,
        S.existingSenses,
        S.addAnotherSense,
        S.addAsNew,
        S.createCategoryOption,
        S.copiedToClipboard,
        S.copyFailed,
        S.close,
        S.copy,
        S.exportBuildFailed,
        S.importConfirmBody,
        S.importContinue,
        S.importPaste,
        S.importAction,
        S.importFailed,
        S.newCategory,
        S.categoryName,
        S.categoryColor,
        S.categoryCreate,
        S.categoryExists,
        S.categoryCreateFailed,
        S.lessonTitle,
        S.lessonWeak,
        S.lessonSmart,
        S.exitTitle,
        S.exitBody,
        S.exitAction,
        S.answerSaveFailed,
        S.queueLoadFailed,
        S.allDoneForToday,
        S.dontKnow,
        S.know,
        S.sessionDone,
        S.sessionFinish,
        S.achievementToast,
        S.tapToReveal,
        S.speakTooltip,
        S.hint,
        S.hintFailed,
        S.askAssistant,
        S.gotIt,
        S.explainFailed,
        S.aiHelperTitle,
        S.addToDictionary,
        S.removeFromDictionary,
        S.dontKnowWord,
        S.wordRemoved,
        S.removeConfirmTitle,
        S.changeAvatar,
        S.removeAvatar,
        S.gallery,
        S.enterNickname,
        S.nicknameSaved,
        S.saveNickname,
        S.personalization,
        S.changeNickname,
        S.gameSentenceBuilder,
        S.sentenceInstruction,
        S.gameListeningV2,
        S.listeningInstruction,
        S.listeningShowTranslation,
        S.listeningHint,
      ];
      for (final build in simple) {
        for (final lang in AppLanguage.values) {
          expect(build(lang), isNotEmpty);
        }
      }
    });

    test('every game tile and weekday is translated', () {
      const games = [
        'errorHunter',
        'cloze',
        'scramble',
        'memory',
        'typing',
        'phrasebook',
        'dictation',
        'reading',
        'sentenceBuilder',
        'listeningV2',
      ];
      for (final game in games) {
        for (final lang in AppLanguage.values) {
          expect(S.gameTitle(game, lang), isNot(contains('game.')));
        }
      }
      for (var day = 1; day <= 7; day++) {
        for (final lang in AppLanguage.values) {
          expect(S.weekday(day, lang), isNot(contains('weekday.')));
        }
      }
    });

    test('russian plurals decline day forms', () {
      expect(S.daysInARow(1, AppLanguage.ru), 'день подряд');
      expect(S.daysInARow(2, AppLanguage.ru), 'дня подряд');
      expect(S.daysInARow(5, AppLanguage.ru), 'дней подряд');
    });

    test('english plurals use day/days', () {
      expect(S.daysInARow(1, AppLanguage.en), 'day in a row');
      expect(S.daysInARow(5, AppLanguage.en), 'days in a row');
    });

    test('spot checks translate key strings', () {
      expect(S.home(AppLanguage.ru), 'Главная');
      expect(S.home(AppLanguage.en), 'Home');
      expect(S.startLesson(AppLanguage.en), 'Start lesson');
      expect(S.wordsToday(5, 10, AppLanguage.en), '5 / 10 words today');
      expect(S.sessionCorrect(3, 5, AppLanguage.en), 'Correct: 3 of 5');
      expect(S.sectionStudy(AppLanguage.ru), 'Обучение');
      expect(S.sectionStudy(AppLanguage.en), 'Study');
      expect(S.sectionGames(AppLanguage.ru), 'Тренировки');
      expect(S.sectionGames(AppLanguage.en), 'Practice');
    });

    test('flags and game titles are localized (Phase 28a)', () {
      expect(S.flagFor(AppLanguage.ru), '🇷🇺');
      expect(S.flagFor(AppLanguage.en), '🇬🇧');
      expect(S.gameTitle('errorHunter', AppLanguage.ru), 'Охота на ошибки');
      expect(S.gameTitle('typing', AppLanguage.ru), 'Скорость печати');
      expect(S.gameTitle('memory', AppLanguage.ru), 'Мемори');
      expect(S.gameTitle('errorHunter', AppLanguage.en), 'Error Hunter');
      expect(S.allAchievementsTooltip(AppLanguage.ru), 'Все достижения');
      expect(S.allAchievementsTooltip(AppLanguage.en), 'All achievements');
    });

    test('word helper strings are localized (Phase 28b)', () {
      expect(S.dontKnowWord(AppLanguage.ru), 'Не знаю слово');
      expect(S.dontKnowWord(AppLanguage.en), "I don't know this word");
      expect(S.aiHelperTitle(AppLanguage.en), 'Word helper');
      expect(S.wordRemoved(AppLanguage.ru), 'Слово удалено');
      expect(S.removeConfirmBody('apple', AppLanguage.ru), contains('apple'));
      expect(S.removeConfirmBody('apple', AppLanguage.en), contains('apple'));
    });

    test('game titles match screen names (Phase 29a)', () {
      expect(S.gameTitle('cloze', AppLanguage.ru), 'Заполни пропуск');
      expect(S.gameTitle('dictation', AppLanguage.ru), 'Аудио-диктант');
      expect(S.gameTitle('typing', AppLanguage.en), 'Typing Speed');
      expect(S.gameTitle('cloze', AppLanguage.en), 'Gap fill');
    });

    test('every Phase 31 key has ru and en translations (BL-94)', () {
      final entries = <String, String Function(AppLanguage)>{
        'common.nextTask': S.commonNextTask,
        'common.loadFailed': S.commonLoadFailed,
        'common.emptyDictionary': S.commonEmptyDictionary,
        'common.again': S.commonAgain,
        'common.exit': S.commonExit,
        'game.errorHunter.instruction': S.errorHunterInstruction,
        'game.errorHunter.howCorrect': S.errorHunterHowCorrect,
        'game.errorHunter.generateFailed': S.errorHunterGenerateFailed,
        'game.scramble.instruction': S.scrambleInstruction,
        'game.scramble.clear': S.scrambleClear,
        'game.scramble.correctCount': (l) => S.scrambleCorrectCount(3, l),
        'game.scramble.preparing': S.scramblePreparing,
        'game.dictation.ttsUnavailable': S.dictationTtsUnavailable,
        'game.dictation.repeatHint': S.dictationRepeatHint,
        'game.dictation.nextWord': S.dictationNextWord,
        'game.dictation.hint': S.dictationHint,
        'game.typing.saveFailed': S.typingSaveFailed,
        'game.typing.runDone': S.typingRunDone,
        'game.typing.accuracy': (l) => S.typingAccuracy(95, l),
        'game.typing.score': (l) => S.typingScore(120, l),
        'game.typing.wpm': (l) => S.typingWpm(40, l),
        'game.memory.victory': S.memoryVictory,
        'game.memory.victoryBody': (l) => S.memoryVictoryBody(12, l),
        'game.memory.moves': (l) => S.memoryMoves(7, l),
        'game.memory.restart': S.memoryRestart,
        'game.phrasebook.notLoaded': S.phrasebookNotLoaded,
        'game.phrasebook.loadFailed': S.phrasebookLoadFailed,
        'game.phrasebook.search': S.phrasebookSearch,
        'game.phrasebook.all': S.phrasebookAll,
        'game.phrasebook.nothingFound': S.phrasebookNothingFound,
        'game.reading.notLoaded': S.readingNotLoaded,
        'game.reading.loadFailed': S.readingLoadFailed,
        'game.reading.showTranslation': S.readingShowTranslation,
        'game.reading.hideTranslation': S.readingHideTranslation,
        'game.reading.unknownWords': S.readingUnknownWords,
        'game.reading.addFailed': S.readingAddFailed,
        'game.reading.parseFailed': S.readingParseFailed,
        'game.reading.allInDictionary': S.readingAllInDictionary,
        'game.reading.addedWords': (l) => S.readingAddedWords(2, l),
        'game.reading.addWords': (l) => S.readingAddWords(5, l),
        'achievements.title': S.achievementsTitle,
        'achievements.loadFailed': S.achievementsLoadFailed,
        'achievements.unlocked': (l) => S.achievementsUnlocked(3, l),
        'achievements.inProgress': (l) => S.achievementsInProgress(27, l),
        'achievements.emptyUnlocked': S.achievementsEmptyUnlocked,
        'achievements.allUnlocked': S.achievementsAllUnlocked,
        'chat.historyLoadFailed': S.chatHistoryLoadFailed,
        'chat.replyFailed': S.chatReplyFailed,
        'chat.clearTitle': S.chatClearTitle,
        'chat.clearBody': S.chatClearBody,
        'chat.clear': S.chatClear,
        'chat.clearHistory': S.chatClearHistory,
        'chat.hint': S.chatHint,
        'chat.greeting': S.chatGreeting,
        'onboarding.slide1Title': S.onboardingSlide1Title,
        'onboarding.slide1Body': S.onboardingSlide1Body,
        'onboarding.slide2Title': S.onboardingSlide2Title,
        'onboarding.slide2Body': S.onboardingSlide2Body,
        'onboarding.slide3Title': S.onboardingSlide3Title,
        'onboarding.slide3Body': S.onboardingSlide3Body,
        'onboarding.howItWorks': S.onboardingHowItWorks,
        'onboarding.skip': S.onboardingSkip,
        'onboarding.start': S.onboardingStart,
        'onboarding.levelTitle': S.onboardingLevelTitle,
        'onboarding.levelBody': S.onboardingLevelBody,
      };
      for (final entry in entries.entries) {
        for (final lang in AppLanguage.values) {
          final value = entry.value(lang);
          expect(value, isNotEmpty, reason: '${entry.key} $lang');
          // Без перевода fallback вернул бы сам ключ.
          expect(value, isNot(equals(entry.key)), reason: '${entry.key} $lang');
        }
      }
    });

    test(
      'every category filter key has ru and en translations (Phase 39a)',
      () {
        final categoryKeys = <String Function(AppLanguage)>[
          S.filterAll,
          S.filterCategories,
          S.categoryAnimals,
          S.categoryNature,
          S.categoryFood,
          S.categoryVerbs,
          S.categoryAdverbs,
          S.categoryAdjectives,
          S.categoryHome,
          S.categoryClothes,
          S.categoryHobbies,
          S.categoryDatetime,
          S.categoryLanguages,
          S.categoryCountries,
          S.categoryColors,
          S.categoryTransport,
          S.categoryComputers,
          S.categoryTravel,
          S.categoryHealth,
          S.categoryBody,
          S.categoryWeather,
          S.categorySchool,
          S.categoryProfessions,
          S.categoryFamily,
        ];
        for (final build in categoryKeys) {
          for (final lang in AppLanguage.values) {
            final value = build(lang);
            expect(value, isNotEmpty);
            // Fallback вернул бы ключ — значит перевода нет.
            expect(value, isNot(contains('dictionary.')));
          }
        }
      },
    );

    test('readingWordUnit declines Russian word forms', () {
      expect(S.readingWordUnit(1, AppLanguage.ru), 'слово');
      expect(S.readingWordUnit(3, AppLanguage.ru), 'слова');
      expect(S.readingWordUnit(5, AppLanguage.ru), 'слов');
    });

    test('readingWordUnit uses word/words in English', () {
      expect(S.readingWordUnit(1, AppLanguage.en), 'word');
      expect(S.readingWordUnit(2, AppLanguage.en), 'words');
      expect(S.readingWordUnit(5, AppLanguage.en), 'words');
    });

    test('typingLetterHint declines Russian letter forms', () {
      expect(S.typingLetterHint(1, 'm', AppLanguage.ru), '1 буква, m...');
      expect(S.typingLetterHint(2, 'm', AppLanguage.ru), '2 буквы, m...');
      expect(S.typingLetterHint(4, 'm', AppLanguage.ru), '4 буквы, m...');
      expect(S.typingLetterHint(5, 'a', AppLanguage.ru), '5 букв, a...');
    });

    test('typingLetterHint uses letter/letters in English', () {
      expect(S.typingLetterHint(1, 'm', AppLanguage.en), '1 letter, m...');
      expect(S.typingLetterHint(4, 'm', AppLanguage.en), '4 letters, m...');
    });
  });
}
