Project ETS Pemrograman Berbasis Perangkat Bergerak (E)
Siti Zahra Ananda K | 5025231037

# 🌿 TanamLog

**A Smart Garden Management App for Plant Care Enthusiasts**

TanamLog adalah aplikasi Flutter yang dirancang untuk membantu Anda mengelola taman digital dengan mudah. Aplikasi ini menyediakan fitur untuk melacak tanaman, menjadwalkan perawatan, dan menerima pengingat pintar berdasarkan lokasi cuaca.

---

## ✨ Fitur Utama

### 🏡 Garden Management
- **Tambah Tanaman**: Kelola koleksi tanaman Anda dengan detail (nama, spesies, lokasi, periode penyiraman)
- **Galeri Tanaman**: Tampilkan tanaman dalam grid yang menarik dengan visual card
- **Catatan Kesehatan**: Catat kondisi kesehatan tanaman dengan foto dan observasi
- **Care Logs**: Dokumentasi lengkap aktivitas perawatan tanaman

### 📅 Smart Reminders
- **Penjadwalan Otomatis**: Buat jadwal perawatan berdasarkan periode penyiraman
- **Pengingat Berbasis Cuaca**: Sistem otomatis melewati tugas saat hujan berdasarkan lokasi
- **Smart GPS Skip**: Integrase GPS untuk skip task berdasarkan kondisi cuaca real-time
- **Real-time Updates**: Gunakan Firestore streams untuk update real-time

### 👤 User Profile
- **Manajemen Profil**: Edit nama, email, dan password
- **Foto Profil**: Upload dan kelola foto profil dari kamera atau galeri
- **Account Settings**: Kontrol penuh atas pengaturan akun
- **Logout Aman**: Sign out dengan navigasi otomatis

### 🔐 Authentication
- **Firebase Auth**: Registrasi dan login yang aman
- **Email Verification**: Verifikasi email saat mengubah alamat email
- **Password Management**: Update password dengan re-authentication

---

## 🚀 Tech Stack

### Frontend
- **Flutter** 3.11.4+ - UI Framework
- **Material 3** - Modern UI Design System
- **Dart** - Programming Language

### Backend & Services
- **Firebase Core** 4.7.0 - Backend Infrastructure
- **Cloud Firestore** 6.3.0 - Real-time Database
- **Firebase Auth** 6.4.0 - Authentication Service
- **Firebase Storage** 13.3.0 - Cloud Storage

### Features & Libraries
- **Camera** 0.11.0 - Ambil foto langsung
- **Image Picker** 1.1.0 - Pilih foto dari galeri
- **Geolocator** 11.0.0 - Akses lokasi pengguna
- **Awesome Notifications** 0.11.0 - Local & Push Notifications
- **Bot Toast** 4.1.3 - Toast Notifications
- **HTTP** 1.6.0 - API Requests

### Tools
- **Intl** 0.20.0 - Internalization
- **Gal** 2.3.0 - Access Photo Gallery

---

## 📁 Project Structure

```
lib/
├── main.dart                 # Entry point aplikasi
├── theme.dart               # Material 3 Theme & Color System
├── firebase_options.dart    # Firebase Configuration
├── firestore.dart           # Firestore Service Layer
│
├── screens/                 # UI Screens
│   ├── login.dart          # Login Screen
│   ├── register.dart       # Registration Screen
│   ├── homepage.dart       # Home/Garden Screen
│   ├── plant_detail.dart   # Plant Detail Screen
│   ├── form_plant.dart     # Add/Edit Plant Form
│   ├── profile.dart        # User Profile Screen
│   └── reminder.dart       # Reminders Screen
│
├── models/                  # Data Models
│   └── plant.dart          # Plant Model
│
└── services/               # Business Logic
    └── notification_services.dart  # Notification Service
```

---

## 🔧 Setup & Installation

### Prerequisites
- Flutter SDK 3.11.4 atau lebih tinggi
- Dart SDK (included dengan Flutter)
- Android Studio / Xcode (untuk build Android/iOS)
- Firebase Project (untuk backend services)

### 1. Clone Repository
```bash
git clone https://github.com/szahraak/ets-ppb-tanamLog.git
cd tanamlog
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Configure Firebase
- Buat project baru di [Firebase Console](https://console.firebase.google.com)
- Download `google-services.json` dan letakkan di `android/app/`
- Download `GoogleService-Info.plist` dan letakkan di `ios/Runner/`
- Update `lib/firebase_options.dart` dengan konfigurasi Firebase Anda

### 4. Build & Run
```bash
# Clean previous builds
flutter clean

# Run aplikasi
flutter run

# Run di device spesifik
flutter run -d <device_id>
```

---

## 📱 Screenshots

<table>
    <tr>
        <td><img width="270" height="585" alt="WhatsApp Image 2026-04-28 at 4 52 49 AM (1)" src="https://github.com/user-attachments/assets/1d91e436-dd01-4e78-bf17-8c016204a35a" /></td>
        <td><img width="270" height="585" alt="WhatsApp Image 2026-04-28 at 4 52 49 AM (2)" src="https://github.com/user-attachments/assets/4efedef2-f85e-439d-92a0-14a120e8332a" /></td>
        <td><img width="270" height="585" alt="WhatsApp Image 2026-04-28 at 4 52 49 AM (3)" src="https://github.com/user-attachments/assets/51350236-886e-493d-960d-eee9445498bd" /></td>
    </tr>
    <tr>
        <td><img width="270" height="585" alt="WhatsApp Image 2026-04-28 at 4 52 49 AM" src="https://github.com/user-attachments/assets/044ad1b1-2529-44f5-8c55-73078adad73d" /></td>
        <td><img width="270" height="585" alt="WhatsApp Image 2026-04-28 at 4 52 48 AM" src="https://github.com/user-attachments/assets/3253a458-682d-4294-8d0f-bab5866d8a2a" /></td>
    </tr>
</table>

---

## 📽️ Demo Video
[![Demo Video Click Here!!!](https://img.youtube.com/vi/8pxsHV0F1VU/0.jpg)](https://www.youtube.com/watch?v=8pxsHV0F1VU)
