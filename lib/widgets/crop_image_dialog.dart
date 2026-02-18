import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A circular crop dialog with reliable pan + pinch-zoom using GestureDetector.
/// Works on all platforms (web + mobile).
class CropImageDialog extends StatefulWidget {
  final Uint8List imageBytes;

  const CropImageDialog({super.key, required this.imageBytes});

  @override
  State<CropImageDialog> createState() => _CropImageDialogState();
}

class _CropImageDialogState extends State<CropImageDialog> {
  final GlobalKey _repaintKey = GlobalKey();
  bool _isCropping = false;

  // Transform state
  Offset _offset = Offset.zero;
  double _scale = 1.0;

  // Gesture tracking
  Offset? _startFocalPoint;
  Offset _startOffset = Offset.zero;
  double _startScale = 1.0;

  void _onScaleStart(ScaleStartDetails details) {
    _startFocalPoint = details.localFocalPoint;
    _startOffset = _offset;
    _startScale = _scale;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _scale = (_startScale * details.scale).clamp(0.5, 5.0);
      if (_startFocalPoint != null) {
        final delta = details.localFocalPoint - _startFocalPoint!;
        _offset = _startOffset + delta;
      }
    });
  }

  Future<void> _crop() async {
    setState(() => _isCropping = true);
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null && mounted) {
        Navigator.of(context).pop(byteData.buffer.asUint8List());
      }
    } finally {
      if (mounted) setState(() => _isCropping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cropSize = (size.width * 0.65).clamp(180.0, 300.0);

    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Crop Photo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pinch to zoom • Drag to reposition',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 16),

            // Crop area: Stack with capture layer + border overlay
            SizedBox(
              width: cropSize,
              height: cropSize,
              child: Stack(
                children: [
                  // ── Capture layer ──────────────────────────────────────
                  RepaintBoundary(
                    key: _repaintKey,
                    child: ClipOval(
                      child: SizedBox(
                        width: cropSize,
                        height: cropSize,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onScaleStart: _onScaleStart,
                          onScaleUpdate: _onScaleUpdate,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(color: Colors.black),
                              Transform(
                                transform: Matrix4.identity()
                                  ..translate(_offset.dx, _offset.dy)
                                  ..scale(_scale),
                                alignment: Alignment.center,
                                child: Image.memory(
                                  widget.imageBytes,
                                  fit: BoxFit.cover,
                                  width: cropSize,
                                  height: cropSize,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Circle border overlay (not captured) ───────────────
                  IgnorePointer(
                    child: CustomPaint(
                      size: Size(cropSize, cropSize),
                      painter: _CircleBorderPainter(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton.icon(
                  onPressed: _isCropping ? null : _crop,
                  icon: _isCropping
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_rounded),
                  label: const Text('Use Photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0175C2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2 - 1,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
