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
        S.games,
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
    });
  });
}
