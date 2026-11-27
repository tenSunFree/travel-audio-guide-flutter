import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/core/platform/platform_support.dart';

void main() {
  group('PlatformSupport capability flags (VM, non-web)', () {
    test('reports mobile capabilities', () {
      expect(PlatformSupport.isWeb, isFalse);
      expect(PlatformSupport.supportsLocalNotifications, isTrue);
      expect(PlatformSupport.supportsNativeCalendar, isTrue);
      expect(PlatformSupport.supportsAudioDownload, isTrue);
    });

    test('webSafeUrl leaves URLs untouched outside the web', () {
      const url = 'http://www.travel.taipei/a.jpg';
      expect(PlatformSupport.webSafeUrl(url), url);
    });
  });

  test('webSafeUrl upgrades only known hosts on Web', () {
    expect(
      PlatformSupport.webSafeUrl('http://www.travel.taipei/a.jpg', isWeb: true),
      'https://www.travel.taipei/a.jpg',
    );
    expect(
      PlatformSupport.webSafeUrl('http://example.org/a.jpg', isWeb: true),
      'http://example.org/a.jpg',
    );
    expect(
      PlatformSupport.webSafeUrl(
        'http://www.travel.taipei/a.jpg',
        isWeb: false,
      ),
      'http://www.travel.taipei/a.jpg',
    );
  });

  group('PlatformSupport.upgradeKnownHttpsHost', () {
    test('upgrades confirmed hosts to https', () {
      expect(
        PlatformSupport.upgradeKnownHttpsHost('http://www.travel.taipei/a.jpg'),
        'https://www.travel.taipei/a.jpg',
      );
      expect(
        PlatformSupport.upgradeKnownHttpsHost('http://travel.taipei/x?y=1'),
        'https://travel.taipei/x?y=1',
      );
    });

    test('matches host case-insensitively and keeps the port', () {
      expect(
        PlatformSupport.upgradeKnownHttpsHost(
          'http://WWW.Travel.Taipei:8080/a',
        ),
        'https://www.travel.taipei:8080/a',
      );
    });

    test('does not rewrite unknown hosts', () {
      const url = 'http://example.org/a.jpg';
      expect(PlatformSupport.upgradeKnownHttpsHost(url), url);
    });

    test('leaves https, empty and unparsable URLs unchanged', () {
      const https = 'https://www.travel.taipei/a.jpg';
      expect(PlatformSupport.upgradeKnownHttpsHost(https), https);
      expect(PlatformSupport.upgradeKnownHttpsHost(''), '');
      expect(
        PlatformSupport.upgradeKnownHttpsHost('http://[::1'),
        'http://[::1',
      );
    });
  });
}
