# HermesEnabler 2
[English](README.md) · [한국어](README.ko.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português](README.pt.md)

HermesEnabler는 Apple Watch가 보고하는 MobileGestalt 기능과 기기 속성을 변경하는 앱입니다. iPhone 동반 앱으로 Watch 앱을 설치할 수 있습니다. 기능 플래그로 없는 하드웨어나 서비스 이용 자격을 추가할 수는 없습니다.

> watchOS 27.0부터 27.3 beta 1까지만 지원합니다.

![Apple Watch](image.png)

## Xcode에서 빌드 및 설치

1. iOS 및 watchOS SDK가 포함된 Xcode를 설치합니다. 대상 Apple Watch와 페어링된 iPhone을 연결하고 신뢰한 뒤, Xcode에서 요청하면 개발자 모드를 켭니다.
2. 저장소를 복제하고 Xcode에서 [HermesEnabler2.xcodeproj](HermesEnabler2.xcodeproj)를 엽니다.
3. **Signing & Capabilities**에서 **HermesCompanion**과 **HermesEnabler2**에 본인의 Apple Development 팀을 선택합니다. `COMPANION_BUNDLE_IDENTIFIER`를 본인이 관리하는 고유한 iPhone Bundle ID로 변경합니다. Watch 앱 ID에는 `.watchkitapp`이 추가됩니다.
4. 두 타깃과 프로비저닝 프로파일에 일치하는 App Group을 설정합니다. Watch entitlement는 `group.$(COMPANION_BUNDLE_IDENTIFIER)`를 사용합니다. App Group이 없으면 MobileGestalt 접근이나 백업이 실패할 수 있습니다.
5. **HermesCompanion** 스킴과 페어링된 iPhone을 선택한 뒤 **Product → Run**을 실행합니다. Watch 앱이 자동 설치되지 않으면 iPhone의 Watch 앱에서 **나의 시계 → 앱 / 사용 가능한 앱**을 통해 설치합니다.
6. Apple Watch에서 HermesEnabler를 열고 초기 MobileGestalt 백업을 생성합니다. 여러 설정을 시험하기 전에 정상 백업을 보관하세요.

서명 없이 컴파일만 확인하려면:

```sh
xcodebuild -project HermesEnabler2.xcodeproj \
  -scheme HermesEnabler2 -configuration Debug \
  -destination 'generic/platform=watchOS' \
  CODE_SIGNING_ALLOWED=NO build
```

`scripts/create_ipa.sh`는 Watch 앱이 포함된 **서명되지 않은** iPhone IPA를 만듭니다. 설치 전 두 앱 모두 적절한 인증서와 프로파일로 서명해야 합니다.

## 릴리스 IPA 설치

[Releases](https://github.com/pookjw/HermesEnabler/releases)에서 IPA를 내려받아 서명 설정에 맞는 방법으로 설치합니다. 필요하면 iPhone의 Watch 앱에서 Watch 앱을 설치합니다.

## 기능 목록

| 항목 | 메뉴 | 동작 및 제한 |
|---|---|---|
| Hermès | 시계 페이스 | 보고되는 ‘Hermès’을 전환합니다. |
| Ultra 시계 페이스 | 시계 페이스 | Ultra 시계 페이스 기능을 전환합니다. 켜면 Hermès Faubourg Party 시계 페이스를 사용할 수 없습니다. Watch를 다시 시작하세요. |
| 화면 상시표시 | 디스플레이 및 컨트롤 | 보고되는 ‘화면 상시표시’을 전환합니다. |
| 화면 상시표시 1Hz | 디스플레이 및 컨트롤 | 보고되는 ‘화면 상시표시 1Hz’을 전환합니다. |
| 화면 상시표시 선명도 | 디스플레이 및 컨트롤 | 보고되는 ‘화면 상시표시 선명도’을 전환합니다. |
| 주변광 주기적 업데이트 | 디스플레이 및 컨트롤 | 보고되는 ‘주변광 주기적 업데이트’을 전환합니다. |
| 화면 해상도 | 디스플레이 및 컨트롤 | 보고되는 화면 크기를 선택하거나 원래 크기로 복원합니다. 실제 픽셀은 바뀌지 않으며 화면이 잘릴 수 있습니다. Watch를 다시 시작하세요. |
| 동작 버튼 | 디스플레이 및 컨트롤 | 보고되는 ‘동작 버튼’을 전환합니다. |
| 두 번 탭 | 디스플레이 및 컨트롤 | 보고되는 ‘두 번 탭’을 전환합니다. |
| 화면 키보드 | 디스플레이 및 컨트롤 | 보고되는 ‘화면 키보드’을 전환합니다. |
| 손목 올려 깨우기 | 디스플레이 및 컨트롤 | 보고되는 ‘손목 올려 깨우기’을 전환합니다. |
| 들어서 말하기 | 디스플레이 및 컨트롤 | 보고되는 ‘들어서 말하기’을 전환합니다. |
| Siri 듣기 기능 | 디스플레이 및 컨트롤 | 보고되는 ‘Siri 듣기 기능’을 전환합니다. |
| 수심 센서 | 센서 및 운동 | 보고되는 ‘수심 센서’을 전환합니다. |
| 절대 고도계 | 센서 및 운동 | 보고되는 ‘절대 고도계’을 전환합니다. |
| 상시 표시 나침반 | 센서 및 운동 | 보고되는 ‘상시 표시 나침반’을 전환합니다. |
| 나침반 방향 탐색 | 센서 및 운동 | 보고되는 ‘나침반 방향 탐색’을 전환합니다. |
| 연속 심박수 측정 | 센서 및 운동 | 보고되는 ‘연속 심박수 측정’을 전환합니다. |
| 소음 노출 | 센서 및 운동 | 보고되는 ‘소음 노출’을 전환합니다. |
| 배터리 정보 | 센서 및 운동 | 보고되는 ‘배터리 정보’을 전환합니다. |
| 수영 운동 | 센서 및 운동 | 보고되는 ‘수영 운동’을 전환합니다. |
| 지역 코드 | Siri 및 인텔리전스 | RegionCode만 변경하며 판매 지역 접미사는 그대로 둡니다. |
| 판매 지역 | Siri 및 인텔리전스 | 판매 지역 접미사만 변경합니다. 제조 정보 도구에서 불일치를 표시할 수 있습니다. |
| Apple Intelligence / Siri AI | Siri 및 인텔리전스 | 기능을 전환합니다. Siri AI에는 watchOS 27, 지원되는 Watch 및 페어링된 Apple Intelligence iPhone이 필요합니다. |
| 온디바이스 Siri | Siri 및 인텔리전스 | 보고되는 ‘온디바이스 Siri’을 전환합니다. |
| 오디오 지능 | Siri 및 인텔리전스 | 오디오 지능 기능을 전환합니다. 앱에서는 Series 12 / Ultra 4 하드웨어가 필요하다고 안내합니다. |
| 초기 백업 | MG 백업 | 덮어쓸 수 없는 초기 백업을 생성합니다. |
| 수동 백업 | MG 백업 | 현재 MobileGestalt를 수동으로 백업합니다. |
| 자동 백업 | MG 백업 | MG 쓰기 또는 복원 전에 자동 백업을 만듭니다. |
| MG 복원 | MG 백업 | 현재 MG를 먼저 백업하고 선택한 백업을 복원합니다. Watch를 다시 시작하세요. |
| Carousel을 다시 시작하세요. | 유틸리티 | Watch 화면 프로세스를 다시 시작하여 관련 변경 사항을 다시 불러옵니다. |

기능 플래그는 없는 디스플레이, 센서, 오디오 하드웨어나 서비스 이용 자격을 추가하지 않습니다. 지역 및 화면 해상도에는 사전 설정이 있으며 쓰기 오류는 앱에 표시됩니다.

## 크레딧

이 프로젝트에는 [Gester](https://github.com/sasobhabha/Gester)의 코드가 포함되어 있습니다. 모든 사용은 본인 책임하에 이루어집니다.
