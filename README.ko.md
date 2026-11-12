# HermesEnabler 2

[English](README.md) · [한국어](README.ko.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português](README.pt.md)

![](image.png)

> watchOS 27.0부터 27.3 beta 1까지만 지원합니다.

## 설치 방법

### Xcode로 직접 빌드

#### 시작하기 전에

다음이 필요합니다.

- 기기의 iOS 및 watchOS 버전을 지원하는 Xcode가 설치된 Mac.
- iPhone과 페어링된 Apple Watch.
- Xcode에 추가한 Apple 계정.
- 프로젝트 소스 코드. **Code → Download ZIP**으로 다운로드하여 압축을 풀거나 이 저장소를 복제하세요.

[이슈 #43](https://github.com/pookjw/HermesEnabler/issues/43)에서 Sideloadly 0.72를 통한 Watch 앱 설치 문제가 보고되어, 여기서는 Xcode 설치를 권장합니다. 대안인 IPA 설치 방법도 아래에 유지했습니다.

#### 1. Xcode에 Apple 계정 추가

1. Xcode 버전에 따라 **Xcode → Settings → Accounts** 또는 **Apple Accounts**를 엽니다.
2. **+**를 누르고 Apple 계정으로 로그인합니다.
3. 유료 Apple Developer Program에 가입하지 않았다면 **본인 이름 (Personal Team)**으로 표시됩니다.

“Team”은 앱 서명에 사용하는 Apple 개발자 계정을 뜻합니다. 프로젝트 작성자의 팀에 가입할 필요는 없습니다.

Personal Team으로 개발용 앱을 설치할 수 있지만 프로파일 만료와 지원되지 않는 기능 등 제한이 있습니다. 아래 **서명 제한 및 문제 해결**을 확인하세요.

#### 2. iPhone 연결 및 개발자 모드 활성화

1. iPhone을 Mac에 연결합니다.
2. 잠금을 해제하고 요청이 나타나면 **이 컴퓨터를 신뢰**를 승인합니다.
3. Xcode의 기기 관리 화면을 엽니다. 최신 버전은 **Device Hub**, 이전 버전은 **Window → Devices and Simulators**입니다.
4. Xcode가 iPhone을 인식할 때까지 기다립니다.
5. iPhone에서 **설정 → 개인정보 보호 및 보안 → 개발자 모드**를 엽니다.
6. 개발자 모드를 켜고 재시동을 승인합니다.
7. 재시동 후 iPhone 잠금을 해제하고 개발자 모드 활성화를 확인합니다.

설정이 보이지 않으면 먼저 Xcode 연결을 완료한 다음 설정을 다시 확인하세요.

#### 3. Apple Watch 연결 및 개발자 모드 활성화

1. Watch 잠금을 해제하고 Mac 및 iPhone 가까이에 둡니다.
2. Xcode가 Watch를 찾도록 합니다. 필요하면 Device Hub에서 주변 기기 추가 또는 페어링 옵션을 사용합니다.
3. 기기에 나타나는 연결 또는 신뢰 요청을 승인합니다.
4. Watch 자체에서 **설정 → 개인정보 보호 및 보안 → 개발자 모드**를 엽니다.
5. 개발자 모드를 켜고 재시동을 승인합니다.
6. 재시동 후 Watch 잠금을 해제하고 활성화 확인 요청이 나타나면 승인합니다.
7. 필요하면 Watch를 Xcode에 다시 연결합니다.

Watch의 개발자 모드 설정은 Xcode가 연결을 시도한 후에야 나타날 수 있습니다. 보이지 않으면 초기 연결을 진행한 다음 Watch 설정을 다시 확인하세요.

자세한 내용은 Apple의 [개발자 모드 안내](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device)를 참조하세요.

##### Device Hub에서 Watch를 페어링할 수 없는 경우

페어링된 iPhone이 켜진 상태에서 페어링이나 연결에 실패하면 다음 우회 방법을 시도하세요.

1. 먼저 위의 iPhone 설정을 완료합니다.
2. **iPhone 전원을 일시적으로 끕니다.**
3. Watch는 켜고 잠금을 해제한 상태로 두며 Wi-Fi와 Bluetooth를 활성화합니다.
4. **Device Hub/Xcode**에서 Watch 페어링이나 연결을 다시 시도합니다.
5. Watch의 연결 요청을 승인합니다.
6. Watch가 연결되면 iPhone을 다시 켭니다.

이 우회 방법이 일부 환경에서 도움이 되었다는 보고가 있습니다. 켜진 iPhone이 모든 Watch 페어링 문제의 원인으로 확인된 것은 아니며, 모든 연결 문제가 해결되지는 않을 수 있습니다.

#### 4. 서명 및 고유한 Bundle Identifier 설정

1. `HermesEnabler2.xcodeproj`를 엽니다.
2. Xcode 프로젝트 탐색기에서 파란색 프로젝트 아이콘을 선택합니다.
3. **PROJECT** 아래의 **HermesEnabler2**를 선택합니다.
4. **Build Settings**를 열고 **All**을 선택한 후 다음을 검색합니다.
   ```
   COMPANION_BUNDLE_IDENTIFIER
   ```
5. `com.example.HermesEnabler`를 본인만의 고유한 식별자로 바꿉니다. 예:
   ```
   com.yourname.HermesEnabler12345
   ```
6. **Debug**와 **Release**에 같은 값을 적용합니다.
7. **TARGETS** 아래의 **HermesEnabler2**를 선택하고 **Signing & Capabilities**를 엽니다.
8. **Automatically manage signing**을 켜고 본인의 팀을 선택합니다.
9. **HermesCompanion**에서도 서명을 설정하고 같은 팀을 선택합니다.

타깃의 기존 Bundle Identifier 표현식은 변경하지 마세요.

| 타깃 | Bundle Identifier |
| --- | --- |
| HermesCompanion | `$(COMPANION_BUNDLE_IDENTIFIER)` |
| HermesEnabler2 | `$(COMPANION_BUNDLE_IDENTIFIER).watchkitapp` |

이 공통 설정으로 iPhone 및 Watch 식별자의 일관성을 유지합니다.

Xcode에서 **Failed Registering Bundle Identifier** 또는 식별자를 사용할 수 없다는 오류가 나오면 더 고유한 `COMPANION_BUNDLE_IDENTIFIER`를 지정하세요. **Signing & Capabilities**로 돌아가 **Try Again** 버튼이 있으면 누릅니다.

App Groups 오류가 남으면 아래 **App Groups 오류**를 참조하세요.

#### 5. Watch에서 빌드 및 실행

1. **HermesEnabler2** 스킴을 선택합니다.
2. 실제 **Apple Watch**를 실행 대상으로 선택합니다.
3. **▶ Run**을 누릅니다.
4. Xcode의 기기 준비와 앱 설치가 끝날 때까지 기다립니다.
5. Watch에서 HermesEnabler2가 열리면 앱 안내를 따릅니다.

**Build Succeeded**는 컴파일이 성공했다는 뜻입니다. 설치는 아직 진행 중일 수 있습니다.

**Installing built products**가 표시되면 설치가 끝날 때까지 기다리세요. 기기를 가까이 두고 연결을 유지합니다.

앱 실행 중 디버깅 세션이 유지되는 것은 정상입니다. Watch 화면에서 앱이 열렸는지 확인하세요.

### 대안: Sideloadly로 IPA 설치

> **Sideloadly 0.72의 알려진 문제:** [이슈 #43](https://github.com/pookjw/HermesEnabler/issues/43)에 따르면 이 버전은 서명 중 내장 watchOS 앱을 제거합니다. iPhone 앱은 설치되지만 HermesEnabler2는 Apple Watch나 iPhone의 Watch 앱에 나타나지 않습니다. 이 문제가 발생하면 위의 **Xcode로 직접 빌드** 안내를 사용하세요.
>
> 이 보고는 버전 0.72에 관한 것입니다. 다른 Sideloadly 버전의 호환성은 여기서 확인되지 않았습니다.

1. [Releases](https://github.com/pookjw/HermesEnabler/releases)에서 `HermesEnabler.ipa`를 다운로드합니다.
2. [Sideloadly](https://sideloadly.io)를 엽니다.
3. **Use automatic bundle ID**를 끄고 고정된 고유 Bundle Identifier를 지정합니다.
4. iPhone에 IPA를 설치합니다.
5. iPhone에서 **Watch → 나의 시계 → 앱**을 열고 **사용 가능한 앱** 아래의 **HermesEnabler2**를 찾습니다.
6. 나타나면 Watch에 설치하고 앱을 열어 안내를 따릅니다.
7. 나타나지 않으면 Xcode로 Watch 앱을 설치합니다.

기존 데이터와 백업을 유지할 수 있도록 이후 업데이트에서도 같은 Bundle Identifier와 Apple 계정을 사용하세요.

## 서명 제한 및 문제 해결

### Personal Team 만료

무료 Personal Team의 프로비저닝 프로파일은 7일 후 만료됩니다. 만료되면 Xcode에서 앱을 다시 빌드하고 설치하세요.

업데이트 시 같은 Apple 계정과 Bundle Identifier를 계속 사용하세요.

### App Groups 오류

이 프로젝트에는 **App Groups** 권한이 포함되어 있습니다. 무료 Personal Team은 이 기능의 프로비저닝을 지원하지 않습니다.

Xcode에서 App Group을 사용할 수 없다고 표시되면:

- `COMPANION_BUNDLE_IDENTIFIER`를 고유한 값으로 바꿨는지 확인하세요.
- 유료 개발자 멤버십이 있다면 해당 팀을 선택하고 관련 App Group을 등록할 수 있는지 확인하세요.
- 식별자를 바꿔도 Personal Team의 기능 제한이 해제되지는 않습니다.

App Groups 제거가 완전한 해결책이라고 가정하지 마세요. 이슈 #43에서는 Xcode 설치 성공을 보고했지만, watchOS 27.2.1에서 App Groups 없이 MobileGestalt 작업이 작동하는지는 확인하지 않았습니다.

빌드나 설치 성공만으로 앱의 주요 기능이 작동한다고 확인할 수는 없습니다.

### iPhone 앱은 설치되지만 Watch 앱이 없는 경우

Sideloadly 0.72를 사용했다면 로그에서 다음을 찾으세요.

```
Watch apps will be stripped from the IPA
```

내장 Watch 앱이 제거되었다는 뜻입니다. iPhone 앱만 설치해도 누락된 Watch 앱이 생기지는 않습니다. 위의 Xcode 설치 안내를 따르세요.

## 주의사항

- 기존 데이터와 백업을 유지할 수 있도록 업데이트 시 같은 Bundle Identifier와 Apple 계정을 사용하세요.
- 앱을 삭제하기 전에 반드시 HermesEnabler2에서 MobileGestalt 백업을 복원하세요.

## 크레딧

이 프로젝트에는 [Gester](https://github.com/sasobhabha/Gester)의 코드가 포함되어 있습니다.

모든 사용은 본인 책임하에 이루어집니다.
