# Release 배포 가이드

`release` 브랜치에 push 하면 `.github/workflows/release.yml` 워크플로우가
자동으로:
- **Android** `.aab` 빌드 → Play Console **내부 테스트** 트랙 업로드
- **iOS** `.ipa` 빌드 → **TestFlight** 업로드

빌드 번호는 GitHub Actions run 번호를 그대로 사용하므로 매번 단조 증가.

## 필요한 GitHub Secrets

Repository → Settings → Secrets and variables → Actions → New repository secret.

### Android (Play Store)

| Secret 이름 | 설명 | 만드는 법 |
|---|---|---|
| `ANDROID_KEYSTORE_BASE64` | 업로드 keystore 의 base64 | `keytool -genkey -v -keystore upload-keystore.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000` 후 `base64 -i upload-keystore.jks \| pbcopy` |
| `ANDROID_KEYSTORE_PASSWORD` | keystore 비밀번호 | 위 생성 시 입력한 store password |
| `ANDROID_KEY_ALIAS` | 키 alias | 위에서 정한 `upload` |
| `ANDROID_KEY_PASSWORD` | key 비밀번호 | key password |
| `PLAY_SERVICE_ACCOUNT_JSON` | Play API 서비스 계정 JSON 전체 내용 | Google Cloud → IAM → 서비스 계정 생성 → JSON 키 발급 → Play Console → 사용자 및 권한 → 새 사용자 → 해당 서비스 계정 이메일로 "Release apps to testing tracks" 권한 부여 |

### iOS (App Store Connect)

| Secret 이름 | 설명 | 만드는 법 |
|---|---|---|
| `IOS_TEAM_ID` | Apple Developer Team ID (10자리) | developer.apple.com → Membership |
| `IOS_BUILD_CERT_BASE64` | Apple Distribution .p12 의 base64 | Keychain Access → 인증서 → Export `.p12` → `base64 -i cert.p12 \| pbcopy` |
| `IOS_BUILD_CERT_PASSWORD` | .p12 export 시 설정한 비밀번호 | export 시 입력한 값 |
| `IOS_KEYCHAIN_PASSWORD` | CI 에서 임시 keychain 만들 때 쓸 비번 (아무거나) | 랜덤 문자열 |
| `IOS_PROVISIONING_PROFILE_BASE64` | App Store provisioning profile `.mobileprovision` 의 base64 | developer.apple.com → Profiles → 생성 (App Store distribution, com.minamidx.jlptApp 매칭) → 다운로드 → `base64 -i profile.mobileprovision \| pbcopy` |
| `APPSTORE_KEY_ID` | App Store Connect API Key ID | App Store Connect → Users and Access → Keys → 생성 (Admin 또는 App Manager) |
| `APPSTORE_ISSUER_ID` | API Key Issuer ID | 같은 페이지 상단 |
| `APPSTORE_PRIVATE_KEY` | `.p8` 키 파일의 base64 | 위 키 발급 시 한 번만 다운로드 가능 → `base64 -i AuthKey_XXXX.p8 \| pbcopy` |

## 초기 셋업 체크리스트

### Android Play Console
1. Play Console 에서 앱 등록 (`com.minamidx.jlpt_app`)
2. 첫 릴리스 (.aab) 는 수동 업로드 — 이후부터 CI 가 인계
3. 내부 테스트 트랙 활성화 + 테스터 그룹 지정
4. 서비스 계정에 publishing 권한 부여

### Apple App Store Connect
1. App Store Connect 에서 앱 등록 (Bundle ID `com.minamidx.jlptApp`)
2. 첫 빌드도 CI 가 올려도 OK — TestFlight 가 자동 처리
3. TestFlight 그룹 만들고 테스터 초대
4. API 키 발급 시 권한 `Developer` 또는 `App Manager`

## 트리거

```bash
# main 에서 안정화된 변경을 release 로 푸시
git checkout -b release
git merge main
git push origin release
```

또는 GitHub Actions 탭에서 **Run workflow** 수동 실행 (release 브랜치 기준).

## 빌드 번호

워크플로우는 `--build-number=$GITHUB_RUN_NUMBER` 를 자동 주입하므로
`pubspec.yaml` 의 `+N` 부분을 직접 안 올려도 됨. 단, `version` 의 `x.y.z`
부분 (semver) 은 사람이 직접 올려야 함.

## 빌드 산출물

CI 가 실패해도 .aab / .ipa 는 Actions 의 Artifacts 에 업로드되어 다운로드
가능 (디버깅용).

## 로컬에서 동일 빌드 재현

```bash
# Android
flutter build appbundle --release --build-number=999

# iOS (서명은 Xcode 가 설정한 dev 인증서 사용)
flutter build ipa --release --build-number=999
```
