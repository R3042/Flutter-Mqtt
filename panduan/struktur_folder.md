# Panduan Struktur Folder Flutter

Dokumen ini menjelaskan struktur folder proyek saat ini dan memberikan rekomendasi "best practice" untuk skalabilitas dan kemudahan maintenance.

## 1. Analisis Struktur Folder `flutter_mqtt` Saat Ini

Proyek ini saat ini menggunakan pola **Skeleton Template** bawaan Flutter. Ini adalah struktur yang bagus untuk memulai karena sudah memisahkan kode dari `main.dart`.

*   **`lib/main.dart`**: Titik masuk aplikasi (Entry point). Isinya minimal, hanya memanggil fungsi `main()` dan menjalankan `app.dart`.
*   **`lib/src/`**: Direktori utama untuk kode sumber aplikasi. Ini menyembunyikan detail implementasi dari root `lib`.
    *   **`app.dart`**: Mengatur `MaterialApp`, tema, routing, dan lokalisasi.
    *   **`settings/`**: Fitur pengaturan. Berisi Controller, Service, dan View untuk settings.
    *   **`sample_feature/`**: Contoh fitur daftar item.
    *   **`localization/`**: Konfigurasi bahasa (l10n).

**Kelebihan**: Rapi untuk aplikasi kecil-menengah.
**Kekurangan**: Jika fitur bertambah banyak, folder `src` bisa menjadi berantakan tanpa pemisahan `data`, `domain`, dan `presentation` yang tegas.

---

## 2. Struktur Folder Pendekatan Terbaik (Clean Arthitecture & Feature-First)

Untuk aplikasi yang lebih kompleks atau jangka panjang, sangat disarankan menggunakan pendekatan **Feature-First** (berbasis fitur) yang digabungkan dengan **Clean Architecture**.

Ini membuat setiap fitur "mandiri" dan mudah dipindahkan atau ditest.

### Contoh Struktur yang Disarankan:

```text
lib/
├── core/                   # Kode yang dibagi ke semua fitur (Shared)
│   ├── constants/          # Warna, String, API Keys
│   ├── errors/             # Custom Exceptions, Failures
│   ├── services/           # Service global (Network, Storage, Navigation)
│   ├── utils/              # Helper functions (DateFormat, Validators)
│   └── widgets/            # Widget umum (CustomButton, LoadingSpinner)
│
├── features/               # Fitur-fitur aplikasi (Modular)
│   ├── auth/               # Contoh Fitur: Otentikasi
│   │   ├── data/           # Layer Data (API, Database)
│   │   │   ├── datasources/  # Remote & Local Data Source
│   │   │   ├── models/       # Model Data (JSON parsing)
│   │   │   └── repositories/ # Implementasi Repository
│   │   │
│   │   ├── domain/         # Layer Bisnis (Aturan & Logika Murni)
│   │   │   ├── entities/     # Objek bisnis murni (tanpa JSON logic)
│   │   │   ├── repositories/ # Abstract Repository (Kontrak)
│   │   │   └── usecases/     # Logic spesifik (LoginUser, RegisterUser)
│   │   │
│   │   └── presentation/   # Layer UI
│   │       ├── bloc/       # State Management (Bloc/Provider/GetX)
│   │       ├── pages/      # Halaman utama (Screen)
│   │       └── widgets/    # Widget spesifik fitur ini
│   │
│   ├── mqtt_dashboard/     # Contoh Fitur: MQTT
│   │   ├── ... (struktur data/domain/presentation yang sama)
│
├── l10n/                   # Lokalisasi (Bahasa)
├── main.dart               # Entry point, Dependency Injection setup
└── app.dart                # Konfigurasi Root Widget
```

---

## 3. Poin Penting & Penjelasan Inti

Berikut adalah hal-hal "Wajib Tahu" agar tidak tersesat dalam struktur ini:

### A. Feature-First vs Layer-First
*   **Feature-First (Disarankan)**: Folder dikelompokkan berdasarkan *Fitur* (Auth, Home, Profile). Jika ingin menghapus fitur "Profile", hapus satu folder saja.
*   **Layer-First**: Folder dikelompokkan berdasarkan *Jenis* (Views, Controllers, Models). Ini buruk untuk project besar karena file satu fitur tersebar di mana-mana.

### B. Separation of Concerns (Pemisahan Tugas)
*   **Data Layer**: "Bagaimana data diambil?" (API, Local DB).
*   **Domain Layer**: "Apa yang aplikasi lakukan?" (Business Logic). Ini *JANGAN* ada kode UI (Widgets) atau Framework (Flutter specific). Harus Dart murni.
*   **Presentation Layer**: "Bagaimana data ditampilkan?" (UI & State Management).

### C. Dependency Injection (DI)
Jangan membuat instance objek secara langsung (misal: `new Repository()`) di dalam widget. Gunakan DI untuk menyuntikkan ketergantungan.
*   Library populer: `get_it`, `injectable`, atau `riverpod` (built-in DI).

### D. Model vs Entity
*   **Model** (`data layer`): Punya method `fromJson`, `toJson`. Ini "kotor" karena tau struktur API.
*   **Entity** (`domain layer`): Hanya data bersih yang dibutuhkan aplikasi. UI harus menggunakan Entity, bukan Model.

### E. State Management
Pilih satu dan konsisten. Jangan campur aduk.
*   **Bloc/Cubit**: Sangat terstruktur, bagus untuk enterprise.
*   **Riverpod**: Modern, aman, fleksibel.
*   **Provider**: Standar, sederhana.

## Ringkasan untuk Project `flutter_mqtt` Anda:
Untuk saat ini, Anda tidak perlu mengubah drastis struktur yang ada, tetapi mulailah mengelompokkan kode MQTT Anda ke dalam folder `src/features/mqtt/` (jika ingin mengikuti pola skeleton) atau `lib/features/mqtt/` (jika ingin refactor ke clean arch).

1.  Buat folder `panduan` ini sebagai referensi.
2.  Saat membuat fitur MQTT, pisahkan **UI** (View) dari **Logika** (Service/Controller).
