
# Akashic Records
<img src="lib/src/banner.png" width="100%">

---

An open-source, cross-platform novel reader built to offer a rich and customizable reading experience. Inspired by the mystical concept of the Akashic Records, the app organizes and presents knowledge in a user-friendly way — accessible anytime, anywhere.
<p align="center">
  <img alt="GitHub Release" src="https://img.shields.io/github/v/release/AkashicRecordsApp/akashic_records?style=for-the-badge&color=brightgreen">
  <img alt="GitHub License" src="https://img.shields.io/github/license/AkashicRecordsApp/akashic_records?style=for-the-badge&color=blue">
  <img alt="GitHub Last Commit" src="https://img.shields.io/github/last-commit/AkashicRecordsApp/akashic_records?style=for-the-badge&color=blueviolet">
  <img alt="GitHub Issues" src="https://img.shields.io/github/issues/AkashicRecordsApp/akashic_records?style=for-the-badge&color=orange">
  <img alt="PRs Welcome" src="https://img.shields.io/badge/PRs-welcome-brightgreen?style=for-the-badge">
  <img alt="GitHub Downloads" src="https://img.shields.io/github/downloads/AkashicRecordsApp/akashic_records/total?style=for-the-badge&color=%23478da7">
</p>

> Join our community on [Discord](https://discord.gg/eSuc2znz5V)

Akashic Records is a Flutter application for reading novels, webnovels and local EPUB files. It supports multiple source plugins, local EPUB import, favorites management, offline reading, and internationalization.

## Key features

- **Novel & Webnovel Reading** — Browse and read novels from multiple plugin sources, view chapters, mark favorites and track reading progress.
- **Local EPUB Import** — Import EPUB files from device storage. The app extracts metadata and chapters, attempts to extract the cover (falls back to an online search or a placeholder), and stores local EPUBs in a dedicated list with metrics and deletion support.
- **Favorites & Progress** — Save favorites and keep reading progress across sessions.
- **Internationalization (i18n)** — App strings are stored in JSON files and replicated across supported locales (en, pt_BR, es, fr, ja, it, ar).
- **Customizable Reader** — Adjust font, line height, alignment, colors, focus mode, and other reader settings; preferences are persisted.
- **Plugin-based Sources** — Multiple built-in plugins (Syosetu, Kakuyomu, Tsundoku, NovelMania, BlogDoAmonNovels, CentralNovel, LightNovelBrasil, MtlNovelMulti, ProjectGutenberg, NovelsOnline, NovelBin, RoyalRoad, ScribbleHub, Webnovel, etc.).
- **Global Search** — Search across all active plugins at once and aggregate results.
- **Modern UI** — Novel header shows a centered cover, blurred background, expandable synopsis and card-styled title/author area.
- **Cover Management** — Download or upload cover images for local novels; uploaded covers are saved locally and update the novel record.
- **Local Persistence** — Uses SQLite (sqflite) for novels, chapters, local EPUBs and app settings.
- **Cross-platform** — Targets Android, iOS, Web, Windows, macOS and Linux.

## Project structure

- `lib/`
  - `main.dart` — application entry point
  - `models/` — data models (Novel, Chapter, etc.)
  - `db/` — SQLite helpers and schema (novels, chapters, local_epubs, settings)
  - `screens/` — UI screens (home, reader, novel detail, plugin browser, local EPUBs)
  - `services/` — importers, network helpers, plugin adapters, epub processing
  - `state/` — global app state using Provider (`AppState`)
  - `widgets/` — reusable widgets (NovelHeader, loading skeletons, etc.)
  - `assets/i18n/locale/` — i18n JSON files
- `pubspec.yaml` — dependencies, assets and Flutter configuration

## Main flows

### EPUB import

- User selects an EPUB file to import.
- The importer extracts OPF metadata, builds chapter objects, and attempts to extract an embedded cover image.
- If the cover extraction fails, the importer tries an online image search via the app proxy and uses the first valid result; otherwise a placeholder image URL is used.
- Imported EPUBs are stored in a dedicated `local_epubs` table and shown in a Local EPUBs screen with metrics (count, total chapters). Users can delete imported EPUBs (removing DB row and files) or open them in the reader.

### Plugin search & reading

- Search queries are executed across all active plugins concurrently and results are aggregated.
- Users can open a novel from a plugin result, read chapters, mark chapters as read, and favorite the novel for later.

### Internationalization

- All UI strings are loaded from JSON files located in `assets/i18n/locale/`.
- When adding new strings, they should be replicated to all active locales.

## Main dependencies

- `provider`, `sqflite`, `path_provider`, `file_picker`, `http`, `archive`, `xml`, `html`, `flutter_epub_viewer`, `shimmer`, `cached_network_image`, `intl`, `permission_handler`, `package_info_plus`, and others listed in `pubspec.yaml`.

## Running the app

Install dependencies and run on a connected device or emulator:

```bash
flutter pub get
flutter run
```

## Notes

- Screenshots and badges were removed from this README by request.
- For Android/iOS builds, make sure to configure platform-specific permissions and signing keys.
- The app uses a local database for state persistence; backups and cloud sync are not enabled by default.
- When adding new user-facing text, replicate the key across i18n JSON files.

## License

See the `LICENSE` file for license details.
