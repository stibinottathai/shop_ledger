import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shop_ledger/core/theme/app_colors.dart';
import 'package:shop_ledger/features/auth/presentation/providers/auth_provider.dart';
import 'package:shop_ledger/core/error/failures.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();

  final _shopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _shopNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Using Owner Name as username for now.
      ref
          .read(authControllerProvider.notifier)
          .signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            username: _ownerNameController.text.trim(),
            shopName: _shopNameController.text.trim(),
            phone: _phoneController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AuthResponse?>>(authControllerProvider, (
      previous,
      next,
    ) {
      next.when(
        data: (response) {
          if (response != null && response.session == null) {
            // Email confirmation required (OTP)
            final otpController = TextEditingController();
            final formKey = GlobalKey<FormState>();

            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text('Enter OTP'),
                content: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enter the 6-digit code sent to ${_emailController.text}.',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          hintText: '000000',
                          border: OutlineInputBorder(),
                          counterText: '',
                        ),
                        validator: (value) {
                          if (value == null || value.length != 6) {
                            return 'Enter a valid 6-digit OTP';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      context.pop(); // Close dialog
                    },
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        context.pop(); // Close dialog
                        ref
                            .read(authControllerProvider.notifier)
                            .verifyOtp(
                              email: _emailController.text.trim(),
                              token: otpController.text.trim(),
                            );
                      }
                    },
                    child: const Text('Verify'),
                  ),
                ],
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Verification Successful!')),
            );
            // Navigate to dashboard instead of popping
            context.go('/home');
          }
        },
        error: (e, stack) {
          String errorMessage;
          if (e is Failure) {
            errorMessage = e.message;
          } else {
            errorMessage = e.toString();
          }

          final lowerCaseError = errorMessage.toLowerCase();
          if (lowerCaseError.contains('rate limit') ||
              lowerCaseError.contains('too many requests') ||
              lowerCaseError.contains('email rate exceeded')) {
            errorMessage =
                'Too many sign-up attempts. Please try again in a few minutes.';
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMessage)));
        },
        loading: () {},
      );
    });

    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Design Colors (Matching LoginPage)
    final Color primaryColor = AppColors.primary;
    final Color bgLight = const Color(0xFFF6F8F6);
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      // Header
                      Center(
                        child: Column(
                          children: [
                            Container(
                              height: 56,
                              width: 56,
                              decoration: BoxDecoration(
                                color: isDark ? cardDark : cardLight,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.inventory_2,
                                size: 32,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Create Account',
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDark ? textMainDark : textMainLight,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start managing your Business More Efficiently',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: isDark ? textMutedDark : textMutedLight,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Form Fields
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildLabel(
                              'Shop Name',
                              isDark,
                              textMainLight,
                              textMainDark,
                            ),
                            _buildTextField(
                              controller: _shopNameController,
                              hint: 'Enter your shop\'s trade name',
                              icon: Icons.store_outlined,
                              isDark: isDark,
                              bgLight: bgLight,
                              bgDark: bgDark,
                              borderLight: borderLight,
                              borderDark: borderDark,
                              textMutedLight: textMutedLight,
                              primaryColor: primaryColor,
                              textMainDark: textMainDark,
                              textMainLight: textMainLight,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Shop Name is required';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 20),
                            _buildLabel(
                              'Owner Name',
                              isDark,
                              textMainLight,
                              textMainDark,
                            ),
                            _buildTextField(
                              controller: _ownerNameController,
                              hint: 'Full name of the owner',
                              icon: Icons.person_outline,
                              isDark: isDark,
                              bgLight: bgLight,
                              bgDark: bgDark,
                              borderLight: borderLight,
                              borderDark: borderDark,
                              textMutedLight: textMutedLight,
                              primaryColor: primaryColor,
                              textMainDark: textMainDark,
                              textMainLight: textMainLight,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Owner Name is required';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 20),
                            _buildLabel(
                              'Phone Number',
                              isDark,
                              textMainLight,
                              textMainDark,
                            ),
                            _buildTextField(
                              controller: _phoneController,
                              hint: '+91 9495622667',
                              icon: Icons.phone_outlined,
                              inputType: TextInputType.phone,
                              isDark: isDark,
                              bgLight: bgLight,
                              bgDark: bgDark,
                              borderLight: borderLight,
                              borderDark: borderDark,
                              textMutedLight: textMutedLight,
                              primaryColor: primaryColor,
                              textMainDark: textMainDark,
                              textMainLight: textMainLight,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Phone number is required';
                                }
                                // Basic phone regex or length check
                                if (value.length < 10) {
                                  return 'Please enter a valid phone number';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 20),
                            _buildLabel(
                              'Email Address',
                              isDark,
                              textMainLight,
                              textMainDark,
                            ),
                            _buildTextField(
                              controller: _emailController,
                              hint: 'name@shop.com',
                              icon: Icons.email_outlined,
                              inputType: TextInputType.emailAddress,
                              isDark: isDark,
                              bgLight: bgLight,
                              bgDark: bgDark,
                              borderLight: borderLight,
                              borderDark: borderDark,
                              textMutedLight: textMutedLight,
                              primaryColor: primaryColor,
                              textMainDark: textMainDark,
                              textMainLight: textMainLight,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Email is required';
                                }
                                final emailRegex = RegExp(
                                  r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                                );
                                if (!emailRegex.hasMatch(value)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 20),
                            _buildLabel(
                              'Password',
                              isDark,
                              textMainLight,
                              textMainDark,
                            ),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: GoogleFonts.inter(
                                color: isDark ? textMainDark : textMainLight,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password is required';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                hintText: 'Create password',
                                hintStyle: GoogleFonts.inter(
                                  color: textMutedLight.withOpacity(0.7),
                                ),
                                filled: true,
                                fillColor: (isDark ? bgDark : bgLight)
                                    .withOpacity(0.5),
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  color: textMutedLight,
                                  size: 20,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: textMutedLight,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 16,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: isDark ? borderDark : borderLight,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: isDark ? borderDark : borderLight,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: primaryColor,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 40),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: isLoading ? null : _submit,
                              child: isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text('Sign Up'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: GoogleFonts.inter(
                              color: isDark ? textMutedDark : textMutedLight,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              context.pop();
                            },
                            child: Text(
                              'Login',
                              style: GoogleFonts.inter(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
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
      padding: const EdgeInsets.only(bottom: 6.0, left: 4.0),
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

  Widget _buildTextField({
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    required bool isDark,
    required Color bgLight,
    required Color bgDark,
    required Color borderLight,
    required Color borderDark,
    required Color textMutedLight,
    required Color primaryColor,
    required Color textMainDark,
    required Color textMainLight,
    TextInputType inputType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      validator: validator,
      style: GoogleFonts.inter(color: isDark ? textMainDark : textMainLight),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: textMutedLight.withOpacity(0.7)),
        filled: true,
        fillColor: (isDark ? bgDark : bgLight).withOpacity(0.5),
        prefixIcon: Icon(icon, color: textMutedLight, size: 20),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
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
      ),
    );
  }
}
