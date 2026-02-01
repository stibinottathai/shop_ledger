import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shop_ledger/core/theme/app_colors.dart';

class CommonErrorWidget extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  final bool fullScreen;

  const CommonErrorWidget({
    super.key,
    required this.error,
    required this.onRetry,
    this.fullScreen = true,
  });

  @override
  Widget build(BuildContext context) {
    final isNetworkError =
        error.toString().contains('SocketException') ||
        error.toString().contains('ClientException') ||
        error.toString().contains('Failed host lookup');

    final content = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isNetworkError ? Icons.wifi_off_rounded : Icons.error_outline,
            size: 64,
            color: AppColors.slate400,
          ),
          const SizedBox(height: 16),
          Text(
            isNetworkError ? 'No Internet Connection' : 'Something went wrong',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              isNetworkError
                  ? 'Please check your network settings and try again.'
                  : 'We encountered an error. Please try again.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          if (!isNetworkError) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                error
                    .toString(), // Show technical error for debugging if not network
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.slate400,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (fullScreen) {
      return Scaffold(backgroundColor: AppColors.background, body: content);
    }

    return content;
  }
}
