# Release 배포 가이드

`release` 브랜치에 push 하면 `.github/workflows/release.yml` 워크플로우가
자동으로:
- **Android** `.aab` 빌드 → Play Console **내부 테스트** 트랙 업로드
- **iOS** `.ipa` 빌드 → **TestFlight** 업로드

빌드 번호는 GitHub Actions run 번호를 그대로 사용하므로 매번 단조 증가.

## 앱 식별자

| 플랫폼 | Identifier |
|---|---|
| iOS Bundle ID | `com.coby.jlpt.n1` |
| Android applicationId | `com.coby.jlpt.n1` |
| Apple Team ID | `3Y8YH8GWMM` |

## GitHub Secrets 상태

Repository → Settings → Secrets and variables → Actions.

### ✅ 이미 등록됨 (CLI 로 일괄 세팅 완료)

| Secret 이름 | 출처 |
|---|---|
| `CERTIFICATE_BASE64` | `distribution.p12` (Apple Distribution: doyoung kim) |
| `CERTIFICATE_PASSWORD` | `king9205` |
| `KEYCHAIN_PASSWORD` | 랜덤 hex 16 |
| `APP_STORE_CONNECT_KEY_ID` | `37U6ZHL4T2` |
| `APP_STORE_CONNECT_ISSUER_ID` | `bf885471-be9d-4c59-a418-bb0324c74837` |
| `APP_STORE_CONNECT_PRIVATE_KEY` | `AuthKey_37U6ZHL4T2.p8` base64 |
| `IOS_TEAM_ID` | `3Y8YH8GWMM` |
| `ANDROID_KEYSTORE_BASE64` | `keystore.rtf` 추출 (taba-key alias) |
| `ANDROID_KEYSTORE_PASSWORD` | `king9205` |
| `ANDROID_KEY_ALIAS` | `taba-key` |
| `ANDROID_KEY_PASSWORD` | `king9205` |

### ❌ 아직 필요 (사람이 직접 해야 하는 것)

| Secret 이름 | 만드는 법 |
|---|---|
| `PROVISIONING_PROFILE_BASE64` | developer.apple.com → Profiles → New (App Store, Bundle ID `com.coby.jlpt.n1` 매칭, Distribution 인증서 선택) → 다운로드 → `base64 -i profile.mobileprovision \| pbcopy` 후 `gh secret set PROVISIONING_PROFILE_BASE64 -R CobyApp/jlpt-app` 에 붙여넣기 |
| `PLAY_SERVICE_ACCOUNT_JSON` | Google Cloud → IAM → 서비스 계정 생성 → JSON 키 발급 → Play Console → 사용자 및 권한 → 새 사용자 → 해당 서비스 계정 이메일에 "Release apps to testing tracks" 권한 부여. JSON 전체 내용을 그대로 secret 값으로 |

## 초기 셋업 체크리스트

### Android Play Console
1. Play Console 에서 앱 등록 (applicationId `com.coby.jlpt.n1`)
2. 첫 릴리스 (.aab) 는 수동 업로드 — 이후부터 CI 가 인계
3. 내부 테스트 트랙 활성화 + 테스터 그룹 지정
4. 서비스 계정에 publishing 권한 부여 → `PLAY_SERVICE_ACCOUNT_JSON` secret 등록

### Apple App Store Connect
1. App Store Connect → My Apps → "+" → New App (Bundle ID `com.coby.jlpt.n1`)
2. developer.apple.com → Identifiers 에 동일 ID 등록 (없으면 자동 생성 됨)
3. Profiles → 새 App Store Distribution Profile 생성 → Bundle ID 매칭 → 다운로드
4. 다운로드한 `.mobileprovision` 을 base64 로 인코딩 → `PROVISIONING_PROFILE_BASE64` secret 등록
5. (선택) TestFlight → 내부 테스터 그룹 만들기

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
