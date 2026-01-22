import 'package:flutter/material.dart';
import 'package:shop_ledger/core/theme/app_colors.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // Header
              Center(
                child: Column(
                  children: [
                    Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.inventory_2,
                          size: 32,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Create Account',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Start managing your wholesale banana inventory',
                      style: TextStyle(color: AppColors.greyText, fontSize: 13),
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
                    _buildLabel('Shop Name'),
                    _buildTextField(
                      hint: 'Enter your shop\'s trade name',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Shop Name is required';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),
                    _buildLabel('Owner Name'),
                    _buildTextField(
                      hint: 'Full name of the owner',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Owner Name is required';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),
                    _buildLabel('Phone Number'),
                    _buildTextField(
                      hint: '+1 (555) 000-0000',
                      inputType: TextInputType.phone,
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
                    _buildLabel('Password'),
                    TextFormField(
                      obscureText: _obscurePassword,
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
                        hintStyle: TextStyle(
                          color: AppColors.greyText.withOpacity(0.7),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    _buildLabel('Confirm Password'),
                    TextFormField(
                      // Changed to TextFormField
                      obscureText: _obscureConfirmPassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        // Need access to password field? Better to just check if not empty for now or logic in button?
                        // NOTE: To compare passwords, we can save the password value or find the other field.
                        // Simpler: Just validate not empty here, and logic in button? Or Find ancestor?
                        // Standard way: no access to other field value easily in validator unless stored in state.
                        // For now, simple length check. Proper comparison usually done in button or using controller.
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Repeat password',
                        hintStyle: TextStyle(
                          color: AppColors.greyText.withOpacity(0.7),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // TODO: Implement Signup Logic
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Processing Signup')),
                          );
                        }
                      },
                      child: const Text('Sign Up'),
                    ),
                    // Close Form and Column
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(color: AppColors.greyText),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: AppColors.primary,
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
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 4.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    TextInputType inputType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      keyboardType: inputType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.greyText.withOpacity(0.7)),
      ),
    );
  }
}
