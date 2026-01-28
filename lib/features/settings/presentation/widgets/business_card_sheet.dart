import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shop_ledger/core/theme/app_colors.dart';
import 'package:shop_ledger/features/auth/presentation/providers/auth_provider.dart';

class BusinessCardSheet extends ConsumerStatefulWidget {
  const BusinessCardSheet({super.key});

  @override
  ConsumerState<BusinessCardSheet> createState() => _BusinessCardSheetState();
}

class _BusinessCardSheetState extends ConsumerState<BusinessCardSheet> {
  final GlobalKey _globalKey = GlobalKey();
  bool _isSharing = false;
  bool _isSaving = false;

  // Customization State
  int _selectedBgIndex = 0;
  int _selectedFontIndex = 0;
  int _selectedTextColorIndex = 0;

  // Options
  final List<Gradient> _backgrounds = [
    // 41644A
    const LinearGradient(
      colors: [Color(0xFF41644A), Color(0xFF41644A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // 001F3D
    const LinearGradient(
      colors: [Color(0xFF001F3D), Color(0xFF001F3D)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // 0C2C55
    const LinearGradient(
      colors: [Color(0xFF0C2C55), Color(0xFF0C2C55)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // 6E026F
    const LinearGradient(
      colors: [Color(0xFF6E026F), Color(0xFF6E026F)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // 30364F
    const LinearGradient(
      colors: [Color(0xFF30364F), Color(0xFF30364F)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // 6F8F72
    const LinearGradient(
      colors: [Color(0xFF6F8F72), Color(0xFF6F8F72)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // 000000
    const LinearGradient(
      colors: [Color(0xFF000000), Color(0xFF000000)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ];

  final List<TextStyle> _fonts = [
    GoogleFonts.inter(),
    GoogleFonts.roboto(),
    GoogleFonts.lato(),
    GoogleFonts.playfairDisplay(),
    GoogleFonts.lora(),
    GoogleFonts.oswald(),
  ];

  final List<String> _fontNames = [
    'Inter',
    'Roboto',
    'Lato',
    'Playfair',
    'Lora',
    'Oswald',
  ];

  final List<Color> _textColors = [
    Colors.white,
    const Color(0xFFF1F5F9), // Slate 100
    const Color(0xFFFEF08A), // Yellow 200
    const Color(0xFFBBF7D0), // Green 200
    const Color(0xFFBFDBFE), // Blue 200
  ];

  Future<void> _captureAndShare() async {
    if (!mounted) return;

    setState(() => _isSharing = true);

    try {
      // Small delay to ensure UI is rendered
      await Future.delayed(const Duration(milliseconds: 100));

      final boundary =
          _globalKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception("Could not find boundary");
      }

      if (boundary.debugNeedsPaint) {
        await Future.delayed(const Duration(milliseconds: 50));
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception("Failed to convert image to bytes");
      }

      final pngBytes = byteData.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/business_card.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(pngBytes);

      // Share with robust error handling for release builds
      // The late initialization error can occur in release mode when accessing result
      bool shareSuccess = false;
      try {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(imagePath)],
            text: 'Check out my business card!',
          ),
        );
        shareSuccess = true;
      } catch (shareError) {
        print("Checking the error $shareError");
        // In release builds, share_plus may throw LateInitializationError
        // The share dialog was shown, we just can't track the result
        final errorStr = shareError.toString().toLowerCase();
        if (errorStr.contains('lateinitializationerror') ||
            errorStr.contains('late') ||
            errorStr.contains('result')) {
          // Share was likely successful, just couldn't get result
          shareSuccess = true;
        } else {
          rethrow;
        }
      }

      // Show success message
      if (mounted && shareSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Card shared successfully!')),
        );
      }
    } catch (e) {
      print("Checking the error......... $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing card: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _saveToGallery() async {
    if (!mounted) return;

    setState(() => _isSaving = true);

    try {
      // Logic to capture the image
      await Future.delayed(const Duration(milliseconds: 100));

      final boundary =
          _globalKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) throw Exception("Could not find boundary");

      if (boundary.debugNeedsPaint) {
        await Future.delayed(const Duration(milliseconds: 50));
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) throw Exception("Failed to convert image");

      final pngBytes = byteData.buffer.asUint8List();
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/business_card.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(pngBytes);

      // Save to gallery using Gal
      await Gal.putImage(imagePath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Card saved to gallery successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving card: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // Generate vCard Data
  String _generateVCard(
    String name,
    String shopName,
    String phone,
    String email,
  ) {
    return 'BEGIN:VCARD\n'
        'VERSION:3.0\n'
        'N:$name;;;;\n'
        'FN:$name\n'
        'ORG:$shopName\n'
        'TEL;TYPE=CELL:$phone\n'
        'EMAIL:$email\n'
        'END:VCARD';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authRepositoryProvider).getCurrentUser();
    final metadata = user?.userMetadata ?? {};

    final shopName = metadata['shop_name']?.toString() ?? 'My Shop';
    final ownerName = metadata['username']?.toString() ?? 'Owner Name';

    String phone = user?.phone ?? '';
    if (phone.isEmpty) {
      phone = metadata['phone']?.toString() ?? '';
    }

    final email = user?.email ?? '';

    // Create vCard data
    final vCardData = _generateVCard(ownerName, shopName, phone, email);

    final currentFont = _fonts[_selectedFontIndex];
    final currentTextColor = _textColors[_selectedTextColorIndex];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Customize Card',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 24),

          // --- PREVIEW ---
          Center(
            child: RepaintBoundary(
              key: _globalKey,
              child: Container(
                width: 340,
                height: 200,
                decoration: BoxDecoration(
                  gradient: _backgrounds[_selectedBgIndex],
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Decorative Elements
                    Positioned(
                      top: -20,
                      right: -20,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -40,
                      left: -10,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        children: [
                          // Left Side (Text Info)
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      shopName,
                                      style: currentFont.copyWith(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: currentTextColor,
                                        height: 1.1,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Proprietor : $ownerName',
                                      style: currentFont.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: currentTextColor.withOpacity(
                                          0.8,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    _buildContactRow(
                                      Icons.phone,
                                      phone,
                                      currentTextColor,
                                      currentFont,
                                    ),
                                    const SizedBox(height: 6),
                                    _buildContactRow(
                                      Icons.email,
                                      email,
                                      currentTextColor,
                                      currentFont,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Right Side (Logo + QR)
                          Expanded(
                            flex: 1,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Shop Initials
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      shopName.isNotEmpty
                                          ? shopName[0].toUpperCase()
                                          : 'S',
                                      style: currentFont.copyWith(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: currentTextColor,
                                      ),
                                    ),
                                  ),
                                ),

                                // QR Code
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: QrImageView(
                                    data: vCardData,
                                    version: QrVersions.auto,
                                    size: 60,
                                    backgroundColor: Colors.white,
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // --- CUSTOMIZATION OPTIONS ---
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionLabel('Background'),
              const SizedBox(height: 12),
              SizedBox(
                height: 50,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _backgrounds.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final isSelected = _selectedBgIndex == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedBgIndex = index),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: _backgrounds[index],
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: AppColors.primary, width: 3)
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionLabel('Font Style'),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _fonts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final isSelected = _selectedFontIndex == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedFontIndex = index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.slate100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _fontNames[index],
                          style: _fonts[index].copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textMain,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionLabel('Text Color'),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _textColors.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final isSelected = _selectedTextColorIndex == index;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedTextColorIndex = index),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _textColors[index],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.grey[300]!,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _isSaving ? null : _saveToGallery,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : const Icon(Icons.download, color: AppColors.primary),
                    label: Text(
                      _isSaving ? 'Saving...' : 'Save',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isSharing ? null : _captureAndShare,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    icon: _isSharing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.share),
                    label: Text(
                      _isSharing ? 'Sharing...' : 'Share',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.slate500,
      ),
    );
  }

  Widget _buildContactRow(
    IconData icon,
    String text,
    Color color,
    TextStyle font,
  ) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        Icon(icon, color: color.withOpacity(0.8), size: 14),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: font.copyWith(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
