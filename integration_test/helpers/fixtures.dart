import 'dart:typed_data';

/// Fixture data for integration tests.
///
/// The names are deliberately test-only strings, so a finder can never
/// accidentally match real content (or another widget on screen).

// Attraction
const fixtureAttractionId = 1001;
const fixtureAttractionName = '整合測試親子公園';
const fixtureAttractionIntro = '這是一段只存在於整合測試中的景點介紹文字。';

/// Shape matches the Taipei Travel `/Attractions/All` API, so it goes
/// through the real `AttractionModel.fromJson` mapping.
Map<String, dynamic> attractionJson({
  int id = fixtureAttractionId,
  String name = fixtureAttractionName,
  String introduction = fixtureAttractionIntro,
}) {
  return {
    'id': id,
    'name': name,
    'introduction': introduction,
    'open_time': '',
    'distric': '中正區',
    'address': '臺北市中正區整合測試路 1 號',
    'tel': '',
    'nlat': 25.0330,
    'elong': 121.5654,
    'official_site': '',
    'facebook': '',
    'ticket': '',
    'remind': '',
    'modified': '2026-09-01 10:00:00',
    'url': '',
    'category': [
      {'id': 16, 'name': '戶外踏青'},
    ],
    'target': <Map<String, dynamic>>[],
    'friendly': <Map<String, dynamic>>[],
    // No images: keeps the test free of real network image loading.
    'images': <Map<String, dynamic>>[],
  };
}

// Audio guide
const fixtureAudioGuideId = 9001;
const fixtureAudioGuideTitle = '整合測試語音導覽';
const fixtureAudioGuideUrl = 'https://fake.travel.test/audio/9001.mp3';

/// Shape matches the Taipei Travel `/Media/Audio` API.
Map<String, dynamic> audioGuideJson({
  int id = fixtureAudioGuideId,
  String title = fixtureAudioGuideTitle,
  String url = fixtureAudioGuideUrl,
}) {
  return {
    'id': id,
    'title': title,
    'summary': '整合測試用的語音導覽摘要。',
    'url': url,
    'file_ext': 'mp3',
    'modified': '2026-09-01 10:00:00',
  };
}

/// Bytes returned by the fake audio download. Starts with an "ID3" header so
/// it looks like an MP3, but playback is faked, so the content never matters.
final Uint8List fakeMp3Bytes = Uint8List.fromList(
  [0x49, 0x44, 0x33, 0x04, 0x00, 0x00, ...List<int>.filled(128, 0)],
);

// Auth
const fixtureEmail = 'guest.tester@example.com';
const fixturePassword = 'password123';
