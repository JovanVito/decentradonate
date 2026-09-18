/// Semua teks statis dikumpulkan di sini.
/// Alasan: memudahkan audit copywriting dan mempersiapkan localization (i18n)
/// di masa depan tanpa menyentuh logic widget.
class AppStrings {
  AppStrings._();

  static const appName = 'Decentradonate';

  // Home / Campaign
  static const homeTitle = 'Kampanye Donasi';
  static const emptyCampaignTitle = 'Belum ada kampanye';
  static const emptyCampaignSubtitle =
      'Kampanye yang tersinkron dari blockchain akan muncul di sini.';
  static const errorCampaignTitle = 'Gagal memuat kampanye';
  static const errorCampaignSubtitle =
      'Periksa koneksi internet atau RPC endpoint, lalu coba lagi.';

  // Wallet
  static const walletTitle = 'Dompet Saya';
  static const walletEmptySubtitle =
      'Buat atau import dompet untuk mulai berdonasi.';
  static const createWallet = 'Buat Dompet Baru';
  static const importWallet = 'Import Dompet';

  // Proof of Impact
  static const uploadProofTitle = 'Bukti Dampak (Proof-of-Impact)';
  static const uploadProofSubtitle =
      'Ambil foto dan sertakan lokasi GPS sebagai bukti dana telah digunakan.';
  static const cameraPermissionDenied =
      'Izin kamera ditolak. Aktifkan di pengaturan untuk mengambil foto bukti.';
  static const locationPermissionDenied =
      'Izin lokasi ditolak. Aktifkan di pengaturan untuk menandai lokasi.';
  static const takePhoto = 'Ambil Foto';
  static const locationFound = 'Lokasi ditemukan';
  static const locationNotFound = 'Lokasi tidak ditemukan';
  static const uploadSuccess = 'Bukti berhasil diunggah!';
  static const uploadFailed = 'Gagal mengunggah bukti';
  static const photoTaken = 'Foto berhasil diambil';
  static const noPhoto = 'Belum ada foto yang diambil';
  static const noLocation = 'Belum ada lokasi yang ditandai';
  static const capturing = 'Mengambil foto...';
  static const gettingLocation = 'Mendapatkan lokasi...';
  static const preparingUpload = 'Menyiapkan unggahan...';

  // Generic states
  static const retry = 'Coba Lagi';
  static const loading = 'Memuat data...';
}
