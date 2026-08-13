# PDF Editor and Scan

A PDF toolkit for iOS and Android, built with Flutter. Scan pages with the
camera, import images and existing PDFs, sort them into folders, merge files,
reorder and rotate pages, split, compress, lock documents with a password,
read the text off a page, and convert to images, Word or PowerPoint.

Everything runs on the device. No API, no backend, no account, no analytics —
the app works with the network switched off.

## Running it

```
flutter pub get
flutter run
```

Requires Flutter 3.44+ and a Rust toolchain on `PATH` — `pdf_manipulator`
compiles a native engine for the iOS build.

## Layout

```
lib/
  data/       document repository, sqflite storage
  models/     Document
  screens/    documents, tools, settings, viewer, merge, split, pages, paywall
  services/   scanning, PDF building, merging, page editing, tools
  ui/         theme, shared components, bottom sheets
  providers.dart
```

The UI is one custom design system shared by both platforms — see `lib/ui/`.
No Cupertino/Material branching.

## Pricing

Free, with every tool unlocked. No purchases, no subscription, no ads.

## Text recognition

OCR runs natively, with no SDK in between: Vision on iOS
(`ios/Runner/TextRecognizer.swift`) and bundled ML Kit on Android
(`MainActivity.kt`), behind one `collate/ocr` method channel. Both models ship
inside the app, so recognition works offline.

Word and PowerPoint files are written as OOXML zips in pure Dart
(`lib/services/office_writer.dart`). Word gets the recognised text without the
original layout; PowerPoint gets one page image per slide. Anything more
faithful needs a server, which this app deliberately does not have.
