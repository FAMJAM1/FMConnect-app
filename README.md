# FMConnect

🇷🇺 Форк [Hiddify](https://github.com/hiddify/hiddify-app) — VPN-клиент для Android, iOS, Linux и Windows
🇺🇸 A fork of [Hiddify](https://github.com/hiddify/hiddify-app) — a VPN client for Android, iOS, Linux and Windows

---

## Ребрендинг / Rebranding

🇷🇺 Название «FMConnect» вместо «Hiddify», свои иконки, сплеши и лаунчер-иконки на всех платформах (Android/iOS/Linux/Web), шрифты Inter и Unbounded, иконки трея, ссылки на поддержку
🇺🇸 Name "FMConnect" instead of "Hiddify", custom icons, splashes and launcher icons for all platforms (Android/iOS/Linux/Web), Inter and Unbounded fonts, tray icons, support links

---

## Тема / Theme

🇷🇺 Добавлена цветовая палитра «Console/Black» — вручную подобранная тёмная схема, не через seed-цвет
🇺🇸 Added "Console/Black" color palette — a hand-crafted dark scheme, not a seed color

---

## Безопасность локального прокси / Local proxy security

🇷🇺 Для встроенного mixed-порта генерируется случайный токен-пароль (`generateSecureToken`). Dio-клиент авторизуется на нём — раньше прокси был полностью открыт и любое приложение на телефоне могло узнать реальный IP VPN-сервера
🇺🇸 A random token password is now generated for the built-in mixed port (`generateSecureToken`). The Dio client authenticates against it — previously the proxy was fully open and any app on the device could discover the real VPN server IP

---

## Экран логов / Logs screen

🇷🇺 Переключатель «логи приложения / логи ядра», порядок строк сверху вниз, кнопка «Обновить», тап по строке — подробный просмотр с кнопкой «Поделиться»
🇺🇸 Toggle between app logs / core logs, top-to-bottom order, Refresh button, tap a line to view details with a Share button

---

## Уведомления / Notifications

🇷🇺 **Reset Connections** сбрасывает активные соединения без перезапуска ядра. **Switch** открывает нативное диалоговое окно со списком серверов без открытия приложения — тема подстраивается под настройки. Иконка уведомления заменена на логотип FMConnect
🇺🇸 **Reset Connections** resets active connections without restarting the core. **Switch** opens a native dialog with the server list without opening the app — theme follows app settings. Notification icon replaced with FMConnect logo

---

## Диалог ошибок / Error dialog

🇷🇺 Постоянный диалог с кнопкой «Поделиться» — копирует текст ошибки для отправки в поддержку
🇺🇸 Persistent dialog with a Share button — copies the error text to send to support

---

## Предвыбор сервера / Offline server pre-selection

🇷🇺 Починен баг, из-за которого выбор сервера до подключения не применялся
🇺🇸 Fixed a bug where server selection before connecting was ignored

---

## Прочее / Other

🇷🇺 Проверка обновлений отключена (стучалась в GitHub Releases оригинального Hiddify — для форка бессмысленно, оставлен TODO для своего фида). LAN sharing убран
🇺🇸 Update checker disabled (was hitting original Hiddify's GitHub Releases — pointless for a fork; TODO: connect own update feed). LAN sharing removed

---

## Сборка / Build

```bash
# Зависимости / Dependencies
flutter pub get

# Android
flutter build apk --release

# Linux
make linux-prepare
flutter build linux --release
```

---

## Поддержка / Support

🇷🇺 Telegram: [@fmconnect_support](https://t.me/fmconnect_support)
🇺🇸 Telegram: [@fmconnect_support](https://t.me/fmconnect_support)
