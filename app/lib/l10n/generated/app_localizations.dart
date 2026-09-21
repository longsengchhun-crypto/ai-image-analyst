import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_km.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('km')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Image Analyst'**
  String get appTitle;

  /// No description provided for @navAnalyze.
  ///
  /// In en, this message translates to:
  /// **'Analyze'**
  String get navAnalyze;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @fabNewAnalysis.
  ///
  /// In en, this message translates to:
  /// **'New analysis'**
  String get fabNewAnalysis;

  /// No description provided for @sheetAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get sheetAddPhoto;

  /// No description provided for @sheetTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get sheetTakePhoto;

  /// No description provided for @sheetChooseGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get sheetChooseGallery;

  /// No description provided for @initialHeadline.
  ///
  /// In en, this message translates to:
  /// **'Understand any image instantly'**
  String get initialHeadline;

  /// No description provided for @initialSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Capture or upload a photo to get an AI description, detected objects, and answers to your questions about it.'**
  String get initialSubtitle;

  /// No description provided for @consentNotice.
  ///
  /// In en, this message translates to:
  /// **'By continuing, images you submit are sent to our server and a third-party AI service for analysis. See Settings for privacy details.'**
  String get consentNotice;

  /// No description provided for @previewRetake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get previewRetake;

  /// No description provided for @previewAnalyze.
  ///
  /// In en, this message translates to:
  /// **'Analyze image'**
  String get previewAnalyze;

  /// No description provided for @uploadZoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a photo to analyze'**
  String get uploadZoneTitle;

  /// No description provided for @uploadZoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap to browse your device'**
  String get uploadZoneSubtitle;

  /// No description provided for @uploadZoneFormats.
  ///
  /// In en, this message translates to:
  /// **'JPG · PNG · WEBP'**
  String get uploadZoneFormats;

  /// No description provided for @loadingAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing your image...'**
  String get loadingAnalyzing;

  /// No description provided for @loadingAnalyzingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Usually takes just a few seconds.'**
  String get loadingAnalyzingSubtitle;

  /// No description provided for @imageDetailsDimensions.
  ///
  /// In en, this message translates to:
  /// **'{width} × {height} px'**
  String imageDetailsDimensions(int width, int height);

  /// No description provided for @imageDetailsSize.
  ///
  /// In en, this message translates to:
  /// **'{size} KB'**
  String imageDetailsSize(int size);

  /// No description provided for @errorImageInvalidTitle.
  ///
  /// In en, this message translates to:
  /// **'That image can\'t be used'**
  String get errorImageInvalidTitle;

  /// No description provided for @errorAnalyzeFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t analyze that image'**
  String get errorAnalyzeFailedTitle;

  /// No description provided for @btnStartOver.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get btnStartOver;

  /// No description provided for @btnTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get btnTryAgain;

  /// No description provided for @resultAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Analysis'**
  String get resultAppBarTitle;

  /// No description provided for @tooltipShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get tooltipShare;

  /// No description provided for @sectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get sectionDescription;

  /// No description provided for @sectionObjects.
  ///
  /// In en, this message translates to:
  /// **'Detected objects & features'**
  String get sectionObjects;

  /// No description provided for @noObjectsFound.
  ///
  /// In en, this message translates to:
  /// **'No distinct objects were confidently identified.'**
  String get noObjectsFound;

  /// No description provided for @sectionOcr.
  ///
  /// In en, this message translates to:
  /// **'Text found in image (OCR)'**
  String get sectionOcr;

  /// No description provided for @demoBannerText.
  ///
  /// In en, this message translates to:
  /// **'Demo mode: this is placeholder analysis. Configure GEMINI_API_KEY (free) or ANTHROPIC_API_KEY on the backend for live results.'**
  String get demoBannerText;

  /// No description provided for @askAboutImage.
  ///
  /// In en, this message translates to:
  /// **'Ask about this image'**
  String get askAboutImage;

  /// No description provided for @askHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. How many people are in this image?'**
  String get askHint;

  /// No description provided for @tooltipSendQuestion.
  ///
  /// In en, this message translates to:
  /// **'Send question'**
  String get tooltipSendQuestion;

  /// No description provided for @previousQuestions.
  ///
  /// In en, this message translates to:
  /// **'Previous questions'**
  String get previousQuestions;

  /// No description provided for @previousQuestionsNote.
  ///
  /// In en, this message translates to:
  /// **'The original image is no longer available, so new questions can\'t be asked from history — analyze the photo again to ask more.'**
  String get previousQuestionsNote;

  /// No description provided for @questionTooShort.
  ///
  /// In en, this message translates to:
  /// **'Please enter a more specific question (3+ characters).'**
  String get questionTooShort;

  /// No description provided for @shareHeader.
  ///
  /// In en, this message translates to:
  /// **'AI Image Analysis'**
  String get shareHeader;

  /// No description provided for @shareDetectedObjectsHeader.
  ///
  /// In en, this message translates to:
  /// **'Detected objects:'**
  String get shareDetectedObjectsHeader;

  /// No description provided for @shareTextFoundHeader.
  ///
  /// In en, this message translates to:
  /// **'Text found in image:'**
  String get shareTextFoundHeader;

  /// No description provided for @shareQaHeader.
  ///
  /// In en, this message translates to:
  /// **'Questions & answers:'**
  String get shareQaHeader;

  /// No description provided for @shareObjectLine.
  ///
  /// In en, this message translates to:
  /// **'- {name} ({band} confidence)'**
  String shareObjectLine(String name, String band);

  /// No description provided for @settingsSectionConnection.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get settingsSectionConnection;

  /// No description provided for @settingsBackendApiTitle.
  ///
  /// In en, this message translates to:
  /// **'Backend API'**
  String get settingsBackendApiTitle;

  /// No description provided for @settingsAiProcessingTitle.
  ///
  /// In en, this message translates to:
  /// **'AI processing'**
  String get settingsAiProcessingTitle;

  /// No description provided for @settingsAiProcessingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Images are analyzed by a third-party AI vision service, called only through our backend. Your API keys are never stored on this device.'**
  String get settingsAiProcessingSubtitle;

  /// No description provided for @settingsSectionPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsSectionPrivacy;

  /// No description provided for @settingsWhatWeStoreTitle.
  ///
  /// In en, this message translates to:
  /// **'What we store'**
  String get settingsWhatWeStoreTitle;

  /// No description provided for @settingsWhatWeStoreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We keep a small thumbnail, the AI-generated description, detected objects, and your questions — not the original full-resolution photo.'**
  String get settingsWhatWeStoreSubtitle;

  /// No description provided for @settingsPeopleTitle.
  ///
  /// In en, this message translates to:
  /// **'Images with people'**
  String get settingsPeopleTitle;

  /// No description provided for @settingsPeopleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The AI is instructed to describe people factually (count, activity) and never attempt facial identification or biometric inference.'**
  String get settingsPeopleSubtitle;

  /// No description provided for @settingsSectionData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsSectionData;

  /// No description provided for @settingsClearHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear all history'**
  String get settingsClearHistoryTitle;

  /// No description provided for @settingsClearHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Removes every saved analysis from this device and the server.'**
  String get settingsClearHistorySubtitle;

  /// No description provided for @settingsSectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsSectionAbout;

  /// No description provided for @settingsAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Image Analyst'**
  String get settingsAboutTitle;

  /// No description provided for @settingsAboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'v1.0.0 — description, object detection, and visual Q&A powered by Google Gemini (or Claude Vision), with a documented demo mode for offline development.'**
  String get settingsAboutSubtitle;

  /// No description provided for @settingsSectionLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsSectionLanguage;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageKhmer.
  ///
  /// In en, this message translates to:
  /// **'ខ្មែរ'**
  String get settingsLanguageKhmer;

  /// No description provided for @dialogClearAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear all history?'**
  String get dialogClearAllTitle;

  /// No description provided for @dialogClearAllContent.
  ///
  /// In en, this message translates to:
  /// **'This deletes every saved analysis on this device and on the server. This cannot be undone.'**
  String get dialogClearAllContent;

  /// No description provided for @btnCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get btnCancel;

  /// No description provided for @btnClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get btnClearAll;

  /// No description provided for @tooltipClearAllHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get tooltipClearAllHistory;

  /// No description provided for @emptyHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'No analyses yet'**
  String get emptyHistoryTitle;

  /// No description provided for @emptyHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Photos you analyze will show up here.'**
  String get emptyHistorySubtitle;

  /// No description provided for @btnRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get btnRetry;

  /// No description provided for @confidenceHighFull.
  ///
  /// In en, this message translates to:
  /// **'High confidence'**
  String get confidenceHighFull;

  /// No description provided for @confidenceMediumFull.
  ///
  /// In en, this message translates to:
  /// **'Medium confidence'**
  String get confidenceMediumFull;

  /// No description provided for @confidenceLowFull.
  ///
  /// In en, this message translates to:
  /// **'Low confidence'**
  String get confidenceLowFull;

  /// No description provided for @confidenceHighShort.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get confidenceHighShort;

  /// No description provided for @confidenceMediumShort.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get confidenceMediumShort;

  /// No description provided for @confidenceLowShort.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get confidenceLowShort;

  /// No description provided for @errorTimeout.
  ///
  /// In en, this message translates to:
  /// **'This is taking longer than expected. Check your connection and try again.'**
  String get errorTimeout;

  /// No description provided for @errorConnection.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach the server. Check your internet connection.'**
  String get errorConnection;

  /// No description provided for @errorSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session expired. Please try again.'**
  String get errorSessionExpired;

  /// No description provided for @errorImageTooLarge.
  ///
  /// In en, this message translates to:
  /// **'That image is too large. Please use an image under 8MB.'**
  String get errorImageTooLarge;

  /// No description provided for @errorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many requests right now. Please wait a moment and try again.'**
  String get errorRateLimited;

  /// No description provided for @errorServerError.
  ///
  /// In en, this message translates to:
  /// **'The server had a problem analyzing your image. Please try again.'**
  String get errorServerError;

  /// No description provided for @errorImageEmpty.
  ///
  /// In en, this message translates to:
  /// **'That image appears to be empty or corrupted.'**
  String get errorImageEmpty;

  /// No description provided for @errorImageTooLargeClient.
  ///
  /// In en, this message translates to:
  /// **'That image is larger than 8MB even after compression. Please choose a smaller image.'**
  String get errorImageTooLargeClient;

  /// No description provided for @errorAnalysisFailed.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong analyzing your image. Please try again.'**
  String get errorAnalysisFailed;

  /// No description provided for @errorQuestionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not get an answer right now. Please try again.'**
  String get errorQuestionFailed;

  /// No description provided for @errorHistoryRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh history right now.'**
  String get errorHistoryRefreshFailed;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'km'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'km':
      return AppLocalizationsKm();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
