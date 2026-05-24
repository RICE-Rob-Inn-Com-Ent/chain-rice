import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

enum VisionSurfaceMode {
  /// QR / barcode stream via mobile_scanner.
  barcodeScan,

  /// Plain preview via the camera plugin.
  cameraPreview,
}

/// Single surface that swaps between decode-heavy scanning and passive preview.
class VisionSurface extends StatefulWidget {
  const VisionSurface({
    super.key,
    required this.mode,
    this.onBarcode,
    this.cameraLensDirection = CameraLensDirection.back,
  });

  final VisionSurfaceMode mode;
  final ValueChanged<String>? onBarcode;
  final CameraLensDirection cameraLensDirection;

  @override
  State<VisionSurface> createState() => _VisionSurfaceState();
}

class _VisionSurfaceState extends State<VisionSurface> {
  MobileScannerController? _scanner;
  CameraController? _camera;
  bool _busy = true;
  Object? _error;

  CameraFacing _scannerFacing() {
    return widget.cameraLensDirection == CameraLensDirection.front
        ? CameraFacing.front
        : CameraFacing.back;
  }

  @override
  void initState() {
    super.initState();
    unawaited(_prepare());
  }

  @override
  void didUpdateWidget(covariant VisionSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mode != oldWidget.mode ||
        widget.cameraLensDirection != oldWidget.cameraLensDirection) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _teardown();
        if (mounted) {
          setState(() {
            _busy = true;
            _error = null;
          });
        }
        await _prepare();
      });
    }
  }

  Future<void> _teardown() async {
    final s = _scanner;
    _scanner = null;
    final c = _camera;
    _camera = null;
    if (s != null) {
      await s.dispose();
    }
    if (c != null) {
      await c.dispose();
    }
  }

  Future<void> _prepare() async {
    try {
      if (widget.mode == VisionSurfaceMode.barcodeScan) {
        _scanner = MobileScannerController(
          facing: _scannerFacing(),
          detectionSpeed: DetectionSpeed.normal,
        );
        if (mounted) {
          setState(() => _busy = false);
        }
        return;
      }

      final cams = await availableCameras();
      CameraDescription? pick;
      for (final c in cams) {
        if (c.lensDirection == widget.cameraLensDirection) {
          pick = c;
          break;
        }
      }
      pick ??= cams.isNotEmpty ? cams.first : null;
      if (pick == null) {
        if (mounted) {
          setState(() {
            _error = StateError('No camera available');
            _busy = false;
          });
        }
        return;
      }

      final cam = CameraController(
        pick,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await cam.initialize();
      if (!mounted) {
        await cam.dispose();
        return;
      }
      setState(() {
        _camera = cam;
        _busy = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _busy = false;
        });
      }
    }
  }

  @override
  void dispose() {
    final s = _scanner;
    _scanner = null;
    final c = _camera;
    _camera = null;
    if (s != null) {
      unawaited(s.dispose());
    }
    if (c != null) {
      unawaited(c.dispose());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) {
      return const Center(child: CircularProgressIndicator());
    }
    final err = _error;
    if (err != null) {
      return Center(child: Text('Vision error: $err'));
    }

    if (widget.mode == VisionSurfaceMode.barcodeScan) {
      final ctrl = _scanner;
      if (ctrl == null) {
        return const SizedBox.shrink();
      }
      return MobileScanner(
        controller: ctrl,
        onDetect: (capture) {
          for (final code in capture.barcodes) {
            final raw = code.rawValue;
            if (raw != null) {
              widget.onBarcode?.call(raw);
            }
          }
        },
      );
    }

    final cam = _camera;
    if (cam == null || !cam.value.isInitialized) {
      return const Center(child: Text('Camera not ready'));
    }
    return CameraPreview(cam);
  }
}
