// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AI Image Analyst';

  @override
  String get navAnalyze => 'Analyze';

  @override
  String get navHistory => 'History';

  @override
  String get navSettings => 'Settings';

  @override
  String get fabNewAnalysis => 'New analysis';

  @override
  String get sheetAddPhoto => 'Add a photo';

  @override
  String get sheetTakePhoto => 'Take a photo';

  @override
  String get sheetChooseGallery => 'Choose from gallery';

  @override
  String get initialHeadline => 'Understand any image instantly';

  @override
  String get initialSubtitle =>
      'Capture or upload a photo to get an AI description, detected objects, and answers to your questions about it.';

  @override
  String get consentNotice =>
      'By continuing, images you submit are sent to our server and a third-party AI service for analysis. See Settings for privacy details.';

  @override
  String get previewRetake => 'Retake';

  @override
  String get previewAnalyze => 'Analyze image';

  @override
  String get loadingAnalyzing => 'Analyzing your image...';

  @override
  String get loadingAnalyzingSubtitle => 'Usually takes just a few seconds.';

  @override
  String imageDetailsDimensions(int width, int height) {
    return '$width × $height px';
  }

  @override
  String imageDetailsSize(int size) {
    return '$size KB';
  }

  @override
  String get errorImageInvalidTitle => 'That image can\'t be used';

  @override
  String get errorAnalyzeFailedTitle => 'We couldn\'t analyze that image';

  @override
  String get btnStartOver => 'Start over';

  @override
  String get btnTryAgain => 'Try again';

  @override
  String get resultAppBarTitle => 'Analysis';

  @override
  String get tooltipShare => 'Share';

  @override
  String get sectionDescription => 'Description';

  @override
  String get sectionObjects => 'Detected objects & features';

  @override
  String get noObjectsFound =>
      'No distinct objects were confidently identified.';

  @override
  String get sectionOcr => 'Text found in image (OCR)';

  @override
  String get demoBannerText =>
      'Demo mode: this is placeholder analysis. Configure GEMINI_API_KEY (free) or ANTHROPIC_API_KEY on the backend for live results.';

  @override
  String get askAboutImage => 'Ask about this image';

  @override
  String get askHint => 'e.g. How many people are in this image?';

  @override
  String get tooltipSendQuestion => 'Send question';

  @override
  String get previousQuestions => 'Previous questions';

  @override
  String get previousQuestionsNote =>
      'The original image is no longer available, so new questions can\'t be asked from history — analyze the photo again to ask more.';

  @override
  String get questionTooShort =>
      'Please enter a more specific question (3+ characters).';

  @override
  String get shareHeader => 'AI Image Analysis';

  @override
  String get shareDetectedObjectsHeader => 'Detected objects:';

  @override
  String get shareTextFoundHeader => 'Text found in image:';

  @override
  String get shareQaHeader => 'Questions & answers:';

  @override
  String shareObjectLine(String name, String band) {
    return '- $name ($band confidence)';
  }

  @override
  String get settingsSectionConnection => 'Connection';

  @override
  String get settingsBackendApiTitle => 'Backend API';

  @override
  String get settingsAiProcessingTitle => 'AI processing';

  @override
  String get settingsAiProcessingSubtitle =>
      'Images are analyzed by a third-party AI vision service, called only through our backend. Your API keys are never stored on this device.';

  @override
  String get settingsSectionPrivacy => 'Privacy';

  @override
  String get settingsWhatWeStoreTitle => 'What we store';

  @override
  String get settingsWhatWeStoreSubtitle =>
      'We keep a small thumbnail, the AI-generated description, detected objects, and your questions — not the original full-resolution photo.';

  @override
  String get settingsPeopleTitle => 'Images with people';

  @override
  String get settingsPeopleSubtitle =>
      'The AI is instructed to describe people factually (count, activity) and never attempt facial identification or biometric inference.';

  @override
  String get settingsSectionData => 'Data';

  @override
  String get settingsClearHistoryTitle => 'Clear all history';

  @override
  String get settingsClearHistorySubtitle =>
      'Removes every saved analysis from this device and the server.';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsAboutTitle => 'AI Image Analyst';

  @override
  String get settingsAboutSubtitle =>
      'v1.0.0 — description, object detection, and visual Q&A powered by Google Gemini (or Claude Vision), with a documented demo mode for offline development.';

  @override
  String get settingsSectionLanguage => 'Language';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageKhmer => 'ខ្មែរ';

  @override
  String get dialogClearAllTitle => 'Clear all history?';

  @override
  String get dialogClearAllContent =>
      'This deletes every saved analysis on this device and on the server. This cannot be undone.';

  @override
  String get btnCancel => 'Cancel';

  @override
  String get btnClearAll => 'Clear all';

  @override
  String get tooltipClearAllHistory => 'Clear all';

  @override
  String get emptyHistoryTitle => 'No analyses yet';

  @override
  String get emptyHistorySubtitle => 'Photos you analyze will show up here.';

  @override
  String get btnRetry => 'Retry';

  @override
  String get confidenceHighFull => 'High confidence';

  @override
  String get confidenceMediumFull => 'Medium confidence';

  @override
  String get confidenceLowFull => 'Low confidence';

  @override
  String get confidenceHighShort => 'High';

  @override
  String get confidenceMediumShort => 'Medium';

  @override
  String get confidenceLowShort => 'Low';

  @override
  String get errorTimeout =>
      'This is taking longer than expected. Check your connection and try again.';

  @override
  String get errorConnection =>
      'Couldn\'t reach the server. Check your internet connection.';

  @override
  String get errorSessionExpired => 'Your session expired. Please try again.';

  @override
  String get errorImageTooLarge =>
      'That image is too large. Please use an image under 8MB.';

  @override
  String get errorRateLimited =>
      'Too many requests right now. Please wait a moment and try again.';

  @override
  String get errorServerError =>
      'The server had a problem analyzing your image. Please try again.';

  @override
  String get errorImageEmpty => 'That image appears to be empty or corrupted.';

  @override
  String get errorImageTooLargeClient =>
      'That image is larger than 8MB even after compression. Please choose a smaller image.';

  @override
  String get errorAnalysisFailed =>
      'Something went wrong analyzing your image. Please try again.';

  @override
  String get errorQuestionFailed =>
      'Could not get an answer right now. Please try again.';

  @override
  String get errorHistoryRefreshFailed =>
      'Could not refresh history right now.';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';
}
