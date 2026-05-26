# Betix_Sports_Trainings — iOS build handoff (v1.0.0)

Этот архив сгенерирован сервисом **AppMint**. AppMint не собирает iOS-артефакты
(нужна macOS с Xcode), поэтому передаёт исходники команде разработки.

## Что внутри

Полный Xcode-проект приложения. Можно открыть в Xcode 16+:

```bash
unzip Betix_Sports_Trainings-v1.0.0.zip -d Betix_Sports_Trainings
cd Betix_Sports_Trainings
open *.xcodeproj
```

## Сборка через CLI (для CI или ручной)

```bash
# 1. Архив для App Store (нужен Apple Developer аккаунт + provisioning profile)
xcodebuild -project App.xcodeproj \
  -scheme App \
  -configuration Release \
  -archivePath ./build/App.xcarchive \
  archive

# 2. Экспорт .ipa из архива
xcodebuild -exportArchive \
  -archivePath ./build/App.xcarchive \
  -exportPath ./build \
  -exportOptionsPlist ExportOptions.plist
```

## Пример ExportOptions.plist

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
```

## Установка на тестовое устройство

Без Apple Developer-аккаунта: Xcode → подключить iPhone по USB → выбрать устройство как destination → Run (⌘R).

С Apple Developer-аккаунтом: TestFlight (загрузить .ipa в App Store Connect) или ad-hoc-distribution через зарегистрированный UDID.

## Версия

```
MARKETING_VERSION = 1.0.0
CURRENT_PROJECT_VERSION = 1
```

При сборке убедись что эти значения проставлены в build settings проекта (или в `Info.plist` через CFBundleShortVersionString и CFBundleVersion).

---

*Сгенерировано AppMint. Если есть вопросы — спросить у оператора, который выдал этот архив.*
