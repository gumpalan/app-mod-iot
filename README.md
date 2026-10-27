# mod_iot

Modul IoT untuk super app Gumpalan. Mengimplementasikan kontrak `AppModule` dari `core_ui` dengan dashboard visual dinamis ala Blynk yang dapat dikustomisasi oleh pengguna secara bebas, terhubung langsung ke `svc-iot` melalui REST API dan WebSocket stream real-time.

## Fitur Utama

- **Dashboard Kustom Ala Blynk**:
  - Tampilan awal jika belum diatur mengarahkan pengguna untuk membuat dashboard baru atau memakai layout pengguna lain.
  - Kanvas widget fleksibel: saklar (toggle), pengatur nilai (slider dimmer/speed), meteran lingkaran (gauge telemetri), kartu metrik (value card), dan tombol pulsa (push button).
  - Editor visual interaktif: tambah widget berdasarkan channel perangkat, ubah urutan (drag-and-drop reorderable), dan hapus widget.
- **Kloning & Jelajah Layout**:
  - Jelajahi tata letak publik yang dibagikan pengguna lain.
  - Sistem otomatis menyaring hanya layout yang perangkatnya dapat diakses oleh akun pengguna saat ini.
  - Kloning satu ketukan untuk langsung mengadopsi layout orang lain.
- **Real-Time WebSocket**:
  - Sinkronisasi perubahan state sensor dan saklar secara instan tanpa perlu memuat ulang halaman (`/iot/v1/ws`).
  - Kirim perintah latensi rendah langsung via WebSocket atau fallback ke REST API.

## Struktur Repositori

```
lib/
├── mod_iot.dart                      # Implementasi AppModule & rute GoRouter
└── src/
    ├── capabilities/
    │   └── registry.dart             # Registry builder widget kapabilitas
    ├── data/
    │   ├── models/
    │   │   └── iot_models.dart       # Model perangkat, channel, widget, & dashboard
    │   └── iot_service.dart          # Klien REST API dan WebSocket stream
    ├── screens/
    │   ├── iot_dashboard_screen.dart # Layar utama kanvas dashboard
    │   ├── dashboard_editor_screen.dart # Editor visual tata letak widget
    │   ├── explore_dashboards_screen.dart # Layar jelajah layout publik
    │   └── device_list_screen.dart   # Layar inspeksi daftar seluruh perangkat
    └── widgets/
        └── iot_widgets.dart          # Komponen widget Blynk (Toggle, Slider, Gauge, dll.)
```

## Menjalankan Pengujian

Jalankan seluruh pengujian widget dan model modul:

```bash
flutter test
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

## Lisensi dan Dependensi

- `go_router` (BSD-3-Clause)
- `core_api` (internal)
- `core_ui` (internal)
