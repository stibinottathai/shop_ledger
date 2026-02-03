import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shop_ledger/core/theme/app_colors.dart';
import 'package:shop_ledger/features/auth/presentation/providers/auth_provider.dart';

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final repository = ref.read(authRepositoryProvider);
    final result = await repository.updatePassword(
      newPassword: _newPasswordController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: Colors.red,
            ),
          );
        },
        (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password changed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color primaryColor = AppColors.primary;
    final Color bgLight = Colors.white;
    final Color bgDark = AppColors.backgroundDark;
    final Color cardLight = const Color(0xFFFFFFFF);
    final Color cardDark = AppColors.cardDark;
    final Color textMainLight = const Color(0xFF121613);
    final Color textMainDark = Colors.white;
    final Color textMutedLight = const Color(0xFF6A816C);
    final Color textMutedDark = Colors.grey[400]!;
    final Color borderLight = const Color(0xFFDDE3DE);
    final Color borderDark = AppColors.slate600;

    return Scaffold(
      backgroundColor: isDark ? bgDark : bgLight,
      appBar: AppBar(
        backgroundColor: isDark ? bgDark : bgLight,
        elevation: 0,
        title: Text(
          'Change Password',
          style: GoogleFonts.inter(
            color: isDark ? textMainDark : textMainLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? textMainDark : textMainLight,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: primaryColor, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your new password must be at least 6 characters long',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark ? textMainDark : textMainLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Current Password
                _buildLabel(
                  'Current Password',
                  isDark,
                  textMainLight,
                  textMainDark,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: _obscureCurrentPassword,
                  style: GoogleFonts.inter(
                    color: isDark ? textMainDark : textMainLight,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Current password is required';
                    }
                    return null;
                  },
                  decoration: _buildInputDecoration(
                    hint: 'Enter current password',
                    icon: Icons.lock_outline,
                    isDark: isDark,
                    bgLight: bgLight,
                    bgDark: bgDark,
                    borderLight: borderLight,
                    borderDark: borderDark,
                    textMutedLight: textMutedLight,
                    primaryColor: primaryColor,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureCurrentPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: textMutedLight,
                        size: 20,
                      ),
                      onPressed: () => setState(
                        () =>
                            _obscureCurrentPassword = !_obscureCurrentPassword,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // New Password
                _buildLabel(
                  'New Password',
                  isDark,
                  textMainLight,
                  textMainDark,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNewPassword,
                  style: GoogleFonts.inter(
                    color: isDark ? textMainDark : textMainLight,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'New password is required';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    if (value == _currentPasswordController.text) {
                      return 'New password must be different from current';
                    }
                    return null;
                  },
                  decoration: _buildInputDecoration(
                    hint: 'Enter new password',
                    icon: Icons.lock_reset,
                    isDark: isDark,
                    bgLight: bgLight,
                    bgDark: bgDark,
                    borderLight: borderLight,
                    borderDark: borderDark,
                    textMutedLight: textMutedLight,
                    primaryColor: primaryColor,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNewPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: textMutedLight,
                        size: 20,
                      ),
                      onPressed: () => setState(
                        () => _obscureNewPassword = !_obscureNewPassword,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Confirm Password
                _buildLabel(
                  'Confirm New Password',
                  isDark,
                  textMainLight,
                  textMainDark,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: GoogleFonts.inter(
                    color: isDark ? textMainDark : textMainLight,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                  decoration: _buildInputDecoration(
                    hint: 'Re-enter new password',
                    icon: Icons.lock_outline,
                    isDark: isDark,
                    bgLight: bgLight,
                    bgDark: bgDark,
                    borderLight: borderLight,
                    borderDark: borderDark,
                    textMutedLight: textMutedLight,
                    primaryColor: primaryColor,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: textMutedLight,
                        size: 20,
                      ),
                      onPressed: () => setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Change Password Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Change Password',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(
    String text,
    bool isDark,
    Color textMainLight,
    Color textMainDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDark ? textMainDark : textMainLight,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
    required bool isDark,
    required Color bgLight,
    required Color bgDark,
    required Color borderLight,
    required Color borderDark,
    required Color textMutedLight,
    required Color primaryColor,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: textMutedLight.withOpacity(0.7)),
      filled: true,
      fillColor: (isDark ? bgDark : bgLight).withOpacity(0.5),
      prefixIcon: Icon(icon, color: textMutedLight, size: 20),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? borderDark : borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? borderDark : borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
    );
  }
}
