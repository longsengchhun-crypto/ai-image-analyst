// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Khmer Central Khmer (`km`).
class AppLocalizationsKm extends AppLocalizations {
  AppLocalizationsKm([String locale = 'km']) : super(locale);

  @override
  String get appTitle => 'AI Image Analyst';

  @override
  String get navAnalyze => 'វិភាគ';

  @override
  String get navHistory => 'ប្រវត្តិ';

  @override
  String get navSettings => 'ការកំណត់';

  @override
  String get fabNewAnalysis => 'វិភាគថ្មី';

  @override
  String get sheetAddPhoto => 'បន្ថែមរូបភាព';

  @override
  String get sheetTakePhoto => 'ថតរូបភាព';

  @override
  String get sheetChooseGallery => 'ជ្រើសរើសពីវិចិត្រសាល';

  @override
  String get initialHeadline => 'យល់ដឹងអំពីរូបភាពណាមួយភ្លាមៗ';

  @override
  String get initialSubtitle =>
      'ថតរូប ឬបញ្ចូលរូបភាព ដើម្បីទទួលបានការពិពណ៌នាដោយ AI វត្ថុដែលបានរកឃើញ និងចម្លើយចំពោះសំណួររបស់អ្នកអំពីវា។';

  @override
  String get consentNotice =>
      'ដោយបន្តទៅមុខ រូបភាពដែលអ្នកបញ្ជូនត្រូវបានផ្ញើទៅម៉ាស៊ីនមេរបស់យើង និងសេវាកម្ម AI ភាគីទីបី ដើម្បីធ្វើការវិភាគ។ សូមមើលផ្នែកការកំណត់សម្រាប់ព័ត៌មានលម្អិតអំពីឯកជនភាព។';

  @override
  String get previewRetake => 'ថតម្ដងទៀត';

  @override
  String get previewAnalyze => 'វិភាគរូបភាព';

  @override
  String get uploadZoneTitle => 'ជ្រើសរើសរូបភាពដើម្បីវិភាគ';

  @override
  String get uploadZoneSubtitle => 'ចុចដើម្បីរកមើលឯកសារក្នុងឧបករណ៍របស់អ្នក';

  @override
  String get uploadZoneFormats => 'JPG · PNG · WEBP';

  @override
  String get loadingAnalyzing => 'កំពុងវិភាគរូបភាពរបស់អ្នក...';

  @override
  String get loadingAnalyzingSubtitle => 'ជាធម្មតាចំណាយពេលត្រឹមតែពីរបីវិនាទី។';

  @override
  String imageDetailsDimensions(int width, int height) {
    return '$width × $height px';
  }

  @override
  String imageDetailsSize(int size) {
    return '$size KB';
  }

  @override
  String get errorImageInvalidTitle => 'រូបភាពនោះមិនអាចប្រើបានទេ';

  @override
  String get errorAnalyzeFailedTitle => 'យើងមិនអាចវិភាគរូបភាពនោះបានទេ';

  @override
  String get btnStartOver => 'ចាប់ផ្តើមឡើងវិញ';

  @override
  String get btnTryAgain => 'ព្យាយាមម្ដងទៀត';

  @override
  String get resultAppBarTitle => 'ការវិភាគ';

  @override
  String get tooltipShare => 'ចែករំលែក';

  @override
  String get sectionDescription => 'ការពិពណ៌នា';

  @override
  String get sectionObjects => 'វត្ថុ និងលក្ខណៈពិសេសដែលបានរកឃើញ';

  @override
  String get noObjectsFound =>
      'មិនមានវត្ថុច្បាស់លាស់ណាមួយត្រូវបានកំណត់អត្តសញ្ញាណដោយទំនុកចិត្តខ្ពស់ទេ។';

  @override
  String get sectionOcr => 'អត្ថបទដែលរកឃើញក្នុងរូបភាព (OCR)';

  @override
  String get demoBannerText =>
      'របៀបសាកល្បង៖ នេះជាការវិភាគគំរូបណ្ដោះអាសន្ន។ សូមកំណត់ GEMINI_API_KEY (ឥតគិតថ្លៃ) ឬ ANTHROPIC_API_KEY នៅលើម៉ាស៊ីនមេ ដើម្បីទទួលបានលទ្ធផលពិតប្រាកដ។';

  @override
  String get askAboutImage => 'សួរអំពីរូបភាពនេះ';

  @override
  String get askHint => 'ឧទាហរណ៍៖ តើមានមនុស្សប៉ុន្មាននាក់នៅក្នុងរូបភាពនេះ?';

  @override
  String get tooltipSendQuestion => 'ផ្ញើសំណួរ';

  @override
  String get previousQuestions => 'សំណួរពីមុន';

  @override
  String get previousQuestionsNote =>
      'រូបភាពដើមលែងមានទៀតហើយ ដូច្នេះមិនអាចសួរសំណួរថ្មីពីប្រវត្តិបានទេ — សូមវិភាគរូបភាពនេះម្ដងទៀត ដើម្បីសួរបន្ថែម។';

  @override
  String get questionTooShort =>
      'សូមបញ្ចូលសំណួរឱ្យបានច្បាស់ជាងនេះ (យ៉ាងតិច ៣ តួអក្សរ)។';

  @override
  String get shareHeader => 'ការវិភាគរូបភាពដោយ AI';

  @override
  String get shareDetectedObjectsHeader => 'វត្ថុដែលបានរកឃើញ៖';

  @override
  String get shareTextFoundHeader => 'អត្ថបទដែលរកឃើញក្នុងរូបភាព៖';

  @override
  String get shareQaHeader => 'សំណួរ និងចម្លើយ៖';

  @override
  String shareObjectLine(String name, String band) {
    return '- $name (ទំនុកចិត្ត $band)';
  }

  @override
  String get settingsSectionConnection => 'ការតភ្ជាប់';

  @override
  String get settingsBackendApiTitle => 'Backend API';

  @override
  String get settingsAiProcessingTitle => 'ដំណើរការ AI';

  @override
  String get settingsAiProcessingSubtitle =>
      'រូបភាពត្រូវបានវិភាគដោយសេវាកម្មចក្ខុវិស័យ AI ភាគីទីបី ដែលហៅតាមរយៈម៉ាស៊ីនមេរបស់យើងតែប៉ុណ្ណោះ។ លេខសម្ងាត់ API របស់អ្នកមិនត្រូវបានផ្ទុកនៅលើឧបករណ៍នេះឡើយ។';

  @override
  String get settingsSectionPrivacy => 'ឯកជនភាព';

  @override
  String get settingsWhatWeStoreTitle => 'អ្វីដែលយើងរក្សាទុក';

  @override
  String get settingsWhatWeStoreSubtitle =>
      'យើងរក្សាទុករូបភាពតូចមួយ ការពិពណ៌នាបង្កើតដោយ AI វត្ថុដែលបានរកឃើញ និងសំណួររបស់អ្នក — មិនមែនរូបភាពដើមដែលមានគុណភាពពេញលេញនោះទេ។';

  @override
  String get settingsPeopleTitle => 'រូបភាពដែលមានមនុស្ស';

  @override
  String get settingsPeopleSubtitle =>
      'AI ត្រូវបានណែនាំឱ្យពិពណ៌នាមនុស្សដោយផ្អែកលើការពិត (ចំនួន សកម្មភាព) ហើយមិនប៉ុនប៉ងកំណត់អត្តសញ្ញាណមុខ ឬវិភាគជីវមាត្រឡើយ។';

  @override
  String get settingsSectionData => 'ទិន្នន័យ';

  @override
  String get settingsClearHistoryTitle => 'សម្អាតប្រវត្តិទាំងអស់';

  @override
  String get settingsClearHistorySubtitle =>
      'លុបការវិភាគដែលបានរក្សាទុកទាំងអស់ចេញពីឧបករណ៍នេះ និងម៉ាស៊ីនមេ។';

  @override
  String get settingsSectionAbout => 'អំពី';

  @override
  String get settingsAboutTitle => 'AI Image Analyst';

  @override
  String get settingsAboutSubtitle =>
      'កំណែ ១.០.០ — ការពិពណ៌នា ការរកឃើញវត្ថុ និងសំណួរចម្លើយអំពីរូបភាព ដោយប្រើ Google Gemini (ឬ Claude Vision) ជាមួយនឹងរបៀបសាកល្បងសម្រាប់ការអភិវឌ្ឍក្រៅបណ្ដាញ។';

  @override
  String get settingsSectionLanguage => 'ភាសា';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageKhmer => 'ខ្មែរ';

  @override
  String get dialogClearAllTitle => 'សម្អាតប្រវត្តិទាំងអស់ឬ?';

  @override
  String get dialogClearAllContent =>
      'សកម្មភាពនេះនឹងលុបការវិភាគដែលបានរក្សាទុកទាំងអស់នៅលើឧបករណ៍នេះ និងលើម៉ាស៊ីនមេ។ សកម្មភាពនេះមិនអាចត្រឡប់វិញបានឡើយ។';

  @override
  String get btnCancel => 'បោះបង់';

  @override
  String get btnClearAll => 'សម្អាតទាំងអស់';

  @override
  String get tooltipClearAllHistory => 'សម្អាតទាំងអស់';

  @override
  String get emptyHistoryTitle => 'មិនទាន់មានការវិភាគនៅឡើយទេ';

  @override
  String get emptyHistorySubtitle => 'រូបភាពដែលអ្នកបានវិភាគនឹងបង្ហាញនៅទីនេះ។';

  @override
  String get btnRetry => 'ព្យាយាមម្ដងទៀត';

  @override
  String get confidenceHighFull => 'ទំនុកចិត្តខ្ពស់';

  @override
  String get confidenceMediumFull => 'ទំនុកចិត្តមធ្យម';

  @override
  String get confidenceLowFull => 'ទំនុកចិត្តទាប';

  @override
  String get confidenceHighShort => 'ខ្ពស់';

  @override
  String get confidenceMediumShort => 'មធ្យម';

  @override
  String get confidenceLowShort => 'ទាប';

  @override
  String get errorTimeout =>
      'សំណើនេះចំណាយពេលយូរជាងធម្មតា។ សូមពិនិត្យការតភ្ជាប់របស់អ្នក ហើយព្យាយាមម្ដងទៀត។';

  @override
  String get errorConnection =>
      'មិនអាចភ្ជាប់ទៅម៉ាស៊ីនមេបានទេ។ សូមពិនិត្យការតភ្ជាប់អ៊ីនធឺណិតរបស់អ្នក។';

  @override
  String get errorSessionExpired =>
      'សម័យរបស់អ្នកបានផុតកំណត់។ សូមព្យាយាមម្ដងទៀត។';

  @override
  String get errorImageTooLarge => 'រូបភាពនោះធំពេក។ សូមប្រើរូបភាពក្រោម ៨MB។';

  @override
  String get errorRateLimited =>
      'មានសំណើច្រើនពេកនាពេលនេះ។ សូមរង់ចាំបន្តិច ហើយព្យាយាមម្ដងទៀត។';

  @override
  String get errorServerError =>
      'ម៉ាស៊ីនមេជួបបញ្ហាក្នុងការវិភាគរូបភាពរបស់អ្នក។ សូមព្យាយាមម្ដងទៀត។';

  @override
  String get errorImageEmpty => 'រូបភាពនោះហាក់ដូចជាទទេ ឬខូច។';

  @override
  String get errorImageTooLargeClient =>
      'រូបភាពនោះនៅតែធំជាង ៨MB សូម្បីតែក្រោយបានបង្រួមក៏ដោយ។ សូមជ្រើសរើសរូបភាពតូចជាងនេះ។';

  @override
  String get errorAnalysisFailed =>
      'មានបញ្ហាកើតឡើងក្នុងការវិភាគរូបភាពរបស់អ្នក។ សូមព្យាយាមម្ដងទៀត។';

  @override
  String get errorQuestionFailed =>
      'មិនអាចទទួលបានចម្លើយឥឡូវនេះទេ។ សូមព្យាយាមម្ដងទៀត។';

  @override
  String get errorHistoryRefreshFailed => 'មិនអាចផ្ទុកប្រវត្តិឡើងវិញឥឡូវនេះទេ។';

  @override
  String get errorGeneric => 'មានបញ្ហាកើតឡើង។ សូមព្យាយាមម្ដងទៀត។';
}
