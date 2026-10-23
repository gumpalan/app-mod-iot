# mod_iot

Modul IoT untuk super app Gumpalan. Mengimplementasikan kontrak `AppModule` dari `core_ui` dan merender antarmuka kendali perangkat secara dinamis berdasarkan kapabilitas (bukan tipe merek).

## Struktur

```
lib/
├── mod_iot.dart
└── src/
    ├── capabilities/
    │   └── registry.dart          # Registry Map<String, CapabilityWidgetBuilder>
    ├── data/
    │   └── .gitkeep
    ├── screens/
    │   └── device_list_screen.dart # Layar daftar perangkat IoT
    └── state/
        └── .gitkeep
```

## Dependensi Path Lokal

Modul ini saat ini bergantung pada `core_api` dan `core_ui` menggunakan direktori lokal:

```yaml
dependencies:
  core_api:
    path: ../app-core-api
  core_ui:
    path: ../app-core-ui
```

> **Catatan**: Dependensi `path` ini akan dialihkan ke repositori URL Git atau private pub server saat repositori didistribusikan secara terpisah.

## Prinsip Render Berbasis Kapabilitas

Antarmuka tidak membedakan apakah sebuah lampu adalah Sonoff Tasmota, Philips Hue, atau ESP32 custom. Klien memeriksa daftar `capabilities`:
- `switch` -> render toggle saklar
- `dimmer` -> render slider kecerahan
- `sensor` -> render indikator nilai
- Kapabilitas baru yang belum dikenal -> otomatis dirender sebagai kartu generik tanpa crash.

Perangkat baru yang menggunakan kapabilitas standar tidak memerlukan perubahan kode aplikasi klien.

## Lisensi dan Dependensi

Lisensi repositori ini **belum ditentukan**.

### Dependensi Langsung:
- `go_router` (BSD-3-Clause)
- `core_api` (internal)
- `core_ui` (internal)

### Memeriksa Lisensi:
Periksa berkas `pubspec.lock` atau gunakan:
```bash
flutter pub pub run -- flutter pub deps
```
