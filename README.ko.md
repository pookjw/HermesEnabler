# HermesEnabler 2

[English](README.md) · [Tiếng Việt](README.vi.md) · [한국어](README.ko.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português](README.pt.md)

![](image.png)

> watchOS 27.0부터 27.3 beta 1까지만 지원합니다.

## 설치 방법

### macOS

macOS에서는 미리 빌드된 IPA를 Sideloadly로 설치하거나 Xcode에서 직접 빌드할 수 있습니다. 두 방법 모두 iPhone이 대상 Apple Watch와 페어링되어 있어야 하며, Watch가 지원되는 watchOS 버전을 실행 중이어야 합니다.

#### IPA 설치

1. [Releases](https://github.com/pookjw/HermesEnabler/releases)에서 IPA를 다운로드합니다.
2. Mac에 [Sideloadly](https://sideloadly.io)를 설치하고, 케이블로 iPhone을 연결한 뒤 Sideloadly에서 해당 기기를 선택합니다.
3. IPA를 Sideloadly로 끌어다 놓고 Apple ID를 입력합니다. **Use automatic bundle ID**를 끄고 고정된 Bundle Identifier를 지정한 뒤 서명을 시작합니다.
4. iPhone에서 **설정 → 일반 → VPN 및 기기 관리**를 열고 개발자 인증서를 신뢰합니다.
5. iPhone에서 **설정 → 개인정보 보호 및 보안 → 개발자 모드**를 열어 켜고, 재시동한 뒤 확인합니다.
6. iPhone의 **Watch 앱 → 나의 시계 → 앱**에서 **HermesEnabler2**를 Watch에 설치합니다.
7. Apple Watch에서 **설정 → 개인정보 보호 및 보안 → 개발자 모드**를 열어 켜고, 재시동한 뒤 확인합니다. 항목이 보이지 않으면 Watch 앱을 먼저 설치한 뒤 다시 확인합니다.
8. Apple Watch에서 **HermesEnabler2**를 열고 앱의 안내를 따릅니다.

#### Xcode로 직접 빌드

1. Xcode에서 [HermesEnabler2.xcodeproj](HermesEnabler2.xcodeproj)를 엽니다.
2. 실행 대상으로 Apple Watch를 선택하고 **Run**을 누릅니다.
3. Apple Watch에서 **HermesEnabler2**를 열고 앱의 안내를 따릅니다.

### Windows

Windows에서는 [WatchBridge](https://github.com/AdminZachary/iloader-for-windows)를 사용합니다. WatchBridge는 iPhone 호스트 앱과 Watch 앱이 함께 들어 있는 IPA를 설치하고 Apple Watch의 개발자 모드를 준비하는 커뮤니티 도구이며, Apple이나 이 프로젝트와 공식적으로 관련되어 있지 않습니다.

1. [iTunes](https://www.apple.com/itunes/) 또는 Microsoft Store의 **Apple Devices** 앱을 설치하여 **Apple Mobile Device Service**를 준비합니다. WatchBridge는 USB 및 Wi-Fi 통신에 이 서비스가 필요합니다. WebView2는 Windows 11에 기본 포함되어 있습니다.
2. iPhone이 대상 Apple Watch와 페어링되어 있는지 확인합니다. WatchBridge는 한 번에 하나의 페어링된 Watch만 지원하며, 여러 개가 페어링되어 있으면 준비 단계에서 추측하지 않고 중단합니다.
3. [WatchBridge Releases](https://github.com/AdminZachary/iloader-for-windows/releases/latest)에서 `watchbridge-windows.zip`을 내려받아 압축을 풀고 `WatchBridge.exe`를 실행합니다. 실행 파일이 서명되어 있지 않아 첫 실행 시 Windows SmartScreen 경고가 표시될 수 있습니다.
4. [Releases](https://github.com/pookjw/HermesEnabler/releases)에서 IPA를 다운로드합니다. iPhone 호스트와 `Watch/*.app`이 모두 포함된 원본 IPA를 사용해야 하며, Watch 전용 패키지는 지원되지 않습니다.
5. USB로 페어링된 iPhone을 연결하고 WatchBridge에서 해당 기기를 선택합니다.
6. Watch를 페어링하고 Watch에서 신뢰 프롬프트를 확인합니다. **개발자 모드** 스위치를 요청한 뒤, Watch에서 **설정 → 개인정보 보호 및 보안 → 개발자 모드**를 열어 켜고 재시동한 후 확인합니다. 다시 WatchBridge로 돌아와 **Check again**을 누릅니다. WatchBridge는 개발자 모드를 대신 켜거나 Watch를 재시동하지 않습니다.
7. Apple ID로 로그인하고 HermesEnabler2 IPA를 선택한 뒤 서명 및 설치를 시작합니다. WatchBridge는 iPhone 호스트 앱을 먼저 설치한 다음 Watch 앱을 설치합니다.
8. Apple Watch에서 **HermesEnabler2**를 열고 앱의 안내를 따릅니다.

> 개발자 모드 준비에는 USB 연결이 필요합니다. USB로 한 번 페어링한 뒤에는 Wi-Fi로 설치 및 갱신할 수 있습니다.

## 주의사항

- Sideloadly에서 **Use automatic bundle ID**를 끄고 고정된 Bundle Identifier를 사용하세요. 기존 앱 데이터와 백업을 유지할 수 있도록 업데이트할 때마다 같은 Bundle Identifier와 Apple ID를 사용하세요.
- **App Groups** 권한으로 인해 유료 Apple Developer 계정이 필요합니다.
- iPhone 앱은 설치됐지만 Watch 앱이 나타나지 않으면 Sideloadly 로그에서 `Watch apps will be stripped from the IPA`를 확인하세요. 이 문구는 IPA에서 Watch 앱이 제거됐다는 뜻이며, iPhone 앱만 설치해서는 Watch 앱이 설치되지 않습니다. Xcode로 Watch 앱을 설치하세요.
- 앱을 삭제하기 전에 반드시 HermesEnabler2 앱에서 MobileGestalt 백업을 복원하세요.

## 크레딧

이 프로젝트에는 [Gester](https://github.com/sasobhabha/Gester)의 코드가 포함되어 있습니다.

모든 사용은 본인 책임하에 이루어집니다.
