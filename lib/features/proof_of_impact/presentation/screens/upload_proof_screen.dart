import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/proof_of_impact_provider.dart';

class UploadProofScreen extends ConsumerStatefulWidget {
  const UploadProofScreen({super.key});

  @override
  ConsumerState<UploadProofScreen> createState() => _UploadProofScreenState();
}

class _UploadProofScreenState extends ConsumerState<UploadProofScreen> {
  CameraController? _cameraController;
  XFile? _capturedImage;
  Position? _position;
  bool _isLoadingLocation = false;
  bool _isUploading = false;
  String? _cameraError;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        await _startCameraController(cameras.first);
      }
    } on CameraException catch (e) {
      setState(() => _cameraError = 'Gagal menginisialisasi kamera: ${e.description}');
    }
  }

  Future<void> _startCameraController(CameraDescription camera) async {
    await _cameraController?.dispose();
    setState(() => _cameraError = null);
    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    try {
      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() {});
    } on CameraException catch (e) {
      setState(() => _cameraError = 'Gagal membuka kamera: ${e.description}');
    }
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    setState(() => _cameraError = null);
    try {
      final image = await _cameraController!.takePicture();
      setState(() => _capturedImage = image);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.photoTaken)),
        );
      }
    } on CameraException catch (e) {
      setState(() => _cameraError = 'Gagal mengambil foto: ${e.description}');
    }
  }

  Future<void> _getCurrentLocation() async {
    final status = await Permission.location.status;
    if (status.isDenied) {
      final result = await Permission.location.request();
      if (result.isDenied || result.isPermanentlyDenied) {
        setState(() => _errorMessage = AppStrings.locationPermissionDenied);
        return;
      }
    } else if (status.isPermanentlyDenied) {
      setState(() => _errorMessage = AppStrings.locationPermissionDenied);
      return;
    }

    setState(() {
      _isLoadingLocation = true;
      _errorMessage = null;
    });

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (mounted) {
        setState(() {
          _position = position;
          _isLoadingLocation = false;
        });
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          _errorMessage = 'Waktu habis saat mendeteksi lokasi. Coba lagi.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          _errorMessage = 'Gagal mendeteksi lokasi. Pastikan GPS aktif.';
        });
      }
    }
  }

  Future<void> _submitProof() async {
    if (_capturedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.noPhoto)),
      );
      return;
    }
    if (_position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.noLocation)),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    ref.read(proofOfImpactProvider.notifier).uploadProof(
      photoPath: _capturedImage!.path,
      latitude: _position!.latitude,
      longitude: _position!.longitude,
      timestamp: DateTime.now(),
    );

    if (!mounted) return;
    setState(() {
      _isUploading = false;
      _capturedImage = null;
    });
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isDenied) {
      final result = await Permission.camera.request();
      if (result.isDenied || result.isPermanentlyDenied) {
        setState(() => _cameraError = AppStrings.cameraPermissionDenied);
      }
    } else if (status.isPermanentlyDenied) {
      setState(() => _cameraError = AppStrings.cameraPermissionDenied);
    }
  }

  @override
  Widget build(BuildContext context) {
    final proofState = ref.watch(proofOfImpactProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.uploadProofTitle,
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppStrings.uploadProofSubtitle,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 16),

            // Camera Preview / Error
            _buildCameraSection(),
            const SizedBox(height: 16),

            // GPS Location
            _buildLocationSection(),
            const SizedBox(height: 16),

            // Error Message
            if (_errorMessage != null) ...[
              _buildErrorWidget(_errorMessage!),
              const SizedBox(height: 12),
            ],

            // IPFS Upload State
            if (proofState is AsyncLoading) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 12),
              Text(AppStrings.preparingUpload,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary)),
            ],
            if (proofState is AsyncData && proofState.valueOrNull != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.success, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Berhasil! IPFS: ${proofState.valueOrNull!.substring(0, 12)}...',
                        style: TextStyle(color: AppColors.success, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (proofState is AsyncError) ...[
              _buildErrorWidget(proofState.error.toString()),
              const SizedBox(height: 12),
            ],

            // Submit Button
            PrimaryButton(
              label: _isUploading ? 'Mengunggah...' : 'Kirim Bukti ke IPFS',
              icon: Icons.cloud_upload_outlined,
              isLoading: _isUploading,
              onPressed: (_capturedImage != null && _position != null && !_isUploading)
                  ? _submitProof
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraSection() {
    if (_cameraError != null && _capturedImage == null) {
      return _buildPermissionPlaceholder(
        icon: Icons.camera_alt_outlined,
        title: 'Kamera',
        subtitle: _cameraError ?? AppStrings.cameraPermissionDenied,
        onRetry: () {
          setState(() => _cameraError = null);
          _requestCameraPermission();
        },
      );
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: CameraPreview(_cameraController!),
        ),
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Center(
            child: ElevatedButton.icon(
              onPressed: _capturedImage == null ? _capturePhoto : null,
              icon: const Icon(Icons.camera_alt, color: Colors.white),
              label: Text(_capturedImage == null ? 'Ambil Foto' : 'Ambil Ulang'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _capturedImage != null
                    ? AppColors.primary.withValues(alpha: 0.6)
                    : AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ),
        ),
        if (_capturedImage != null)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('✓', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
      ],
    );
  }

  Widget _buildLocationSection() {
    if (_errorMessage != null && _errorMessage!.toLowerCase().contains('lokasi') && _position == null) {
      return _buildPermissionPlaceholder(
        icon: Icons.location_on_outlined,
        title: 'Lokasi GPS',
        subtitle: _errorMessage ?? AppStrings.locationPermissionDenied,
        onRetry: () {
          setState(() => _errorMessage = null);
          _getCurrentLocation();
        },
      );
    }

    if (_isLoadingLocation) {
      return _buildLoadingPlaceholder(
        icon: Icons.my_location_outlined,
        label: AppStrings.gettingLocation,
      );
    }

    return _buildPermissionPlaceholder(
      icon: Icons.my_location_outlined,
      title: _position != null ? AppStrings.locationFound : 'Lokasi GPS',
      subtitle: _position != null
          ? '${AppStrings.locationFound}: Lat ${_position!.latitude.toStringAsFixed(6)}, Lng ${_position!.longitude.toStringAsFixed(6)}'
          : 'Tekan untuk menandai lokasi GPS Anda',
      onRetry: _position == null ? _getCurrentLocation : null,
      child: _position != null
          ? const Icon(Icons.location_on, color: AppColors.success, size: 32)
          : const Icon(Icons.my_location_outlined, color: AppColors.primary, size: 32),
    );
  }

  Widget _buildPermissionPlaceholder({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onRetry,
    Widget? child,
  }) {
    final isSuccess = title == AppStrings.locationFound;
    final borderColor = isSuccess
        ? AppColors.success.withValues(alpha: 0.5)
        : AppColors.primary.withValues(alpha: 0.3);
    final bgColor = isSuccess
        ? AppColors.success.withValues(alpha: 0.04)
        : AppColors.primary.withValues(alpha: 0.04);

    return InkWell(
      onTap: onRetry,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(14),
          color: bgColor,
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            child ?? Icon(icon, size: 32, color: AppColors.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder({
    required IconData icon,
    required String label,
  }) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(14),
        color: AppColors.primary.withValues(alpha: 0.04),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: const TextStyle(fontSize: 12, color: AppColors.error)),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: AppColors.error),
            onPressed: () => setState(() => _errorMessage = null),
          ),
        ],
      ),
    );
  }
}
