import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart'; // Assuming standard font used
import 'package:shop_ledger/core/theme/app_colors.dart';
import 'package:shop_ledger/features/auth/presentation/providers/auth_provider.dart';
import 'package:shop_ledger/core/error/failures.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _shopNameController;
  late TextEditingController _usernameController;
  // Phone and Email are usually not editable lightly, but plan said "Update Profile".
  // Assuming Phone/Email read-only based on plan details?
  // Plan says: "Form/Fields for: Shop Name, Username, Phone, Email (Read-only)."
  // Wait, if Phone is not editable, only Shop Name and Username.
  // Actually, let's make all displayed, but only some editable as per typical flows.
  // User metadata has 'username' and 'shop_name'.
  // Phone/Email might come from User object directly.

  late TextEditingController _emailController;
  late TextEditingController _phoneController; // If we have it

  bool _isLoading = false;

  // New Design Colors
  static const _textMain = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);
  static const _borderColor = Color(0xFFF1F5F9);

  @override
  void initState() {
    super.initState();
    _shopNameController = TextEditingController();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _loadUserData();
  }

  void _loadUserData() {
    final user = ref.read(authRepositoryProvider).getCurrentUser();
    if (user != null) {
      _emailController.text = user.email ?? '';

      // Try getting phone from auth User first, then metadata
      final metadata = user.userMetadata;
      if (metadata != null) {
        _shopNameController.text = metadata['shop_name']?.toString() ?? '';
        _usernameController.text = metadata['username']?.toString() ?? '';
        final metaPhone = metadata['phone']?.toString();

        _phoneController.text = (user.phone?.isNotEmpty == true)
            ? user.phone!
            : (metaPhone?.isNotEmpty == true ? metaPhone! : '');
      } else {
        _phoneController.text = user.phone ?? '';
      }
    }
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _updateProfileData(
    String shopName,
    String username,
    String phone,
  ) async {
    setState(() => _isLoading = true);

    // Note: Phone update in Supabase usually requires OTP verification or admin privileges
    // For this context, we'll try updating just metadata, or assume phone is updateable if enabled.
    // Standard UserAttributes doesn't support generic 'phone' update without verification flow usually.
    // We will update metadata for Shop/Username.
    // If Phone is stored in metadata (uncommon but possible for non-auth phone), we'll do that.
    // If it's the auth phone, updating it is complex.
    // We'll update metadata and just show success for now as per previous logic.

    try {
      final supabase = Supabase.instance.client;
      await supabase.auth.updateUser(
        UserAttributes(
          data: {'shop_name': shopName, 'username': username, 'phone': phone},
        ),
      );

      // Update local controllers to reflect changes
      _shopNameController.text = shopName;
      _usernameController.text = username;
      _phoneController.text = phone;

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
      }
    }
  }

  void _showEditProfileDialog() {
    final editShopNameController = TextEditingController(
      text: _shopNameController.text,
    );
    final editUsernameController = TextEditingController(
      text: _usernameController.text,
    );
    final editPhoneController = TextEditingController(
      text: _phoneController.text,
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogTextField('Shop Name', editShopNameController),
                  const SizedBox(height: 16),
                  _buildDialogTextField('Owner Name', editUsernameController),
                  const SizedBox(height: 16),
                  _buildDialogTextField(
                    'Phone Number',
                    editPhoneController,
                    isPhone: true,
                  ),
                ],
              ),
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 24,
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: Colors.grey[300]!),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: _textMain,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context); // Close dialog first
                await _updateProfileData(
                  editShopNameController.text.trim(),
                  editUsernameController.text.trim(),
                  editPhoneController.text.trim(),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Update',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogTextField(
    String label,
    TextEditingController controller, {
    bool isPhone = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _textMuted,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: _textMain,
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          bool isLoading = false;

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                const Icon(Icons.power_settings_new_rounded, color: Colors.red),
                const SizedBox(width: 12),
                Text(
                  'Logout',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Text(
              'Are you sure you want to log out of your account?',
              style: GoogleFonts.inter(fontSize: 14, color: _textMain),
            ),
            actionsPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            actions: [
              OutlinedButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.grey[300]!),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    color: _textMain,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        setState(() => isLoading = true);
                        await ref
                            .read(authControllerProvider.notifier)
                            .signOut();

                        // Check for errors
                        final state = ref.read(authControllerProvider);
                        if (state.hasError) {
                          final error = state.error;
                          final message = error is Failure
                              ? error.message
                              : error.toString();

                          if (mounted) {
                            setState(() => isLoading = false);
                            Navigator.pop(context); // Close dialog
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(message),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } else {
                          if (mounted) {
                            Navigator.pop(context); // Close dialog
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Logged out successfully'),
                                backgroundColor:
                                    Colors.black, // Consistent with theme
                              ),
                            );
                            // Clear navigation stack and go to login
                            context.go('/login');
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Logout',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).iconTheme.color,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.power_settings_new_rounded,
              color: Colors.red,
            ),
            onPressed: _showLogoutConfirmation,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Header Section with Avatar
                      Column(
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 128,
                                height: 128,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary.withOpacity(0.1),
                                  border: Border.all(
                                    color: Theme.of(context).cardColor,
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 15,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    _shopNameController.text.isNotEmpty
                                        ? _shopNameController.text[0]
                                              .toUpperCase()
                                        : 'S',
                                    style: GoogleFonts.inter(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Theme.of(context).canvasColor,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color.fromRGBO(0, 0, 0, 0.05),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _usernameController.text.isNotEmpty
                                ? _usernameController.text
                                : 'User',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).textTheme.titleLarge?.color,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.store,
                                size: 18,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _shopNameController.text.isNotEmpty
                                    ? _shopNameController.text
                                    : 'Shop Name',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color
                                      ?.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Account Details Section
                      _buildSectionHeader('ACCOUNT DETAILS'),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              offset: const Offset(0, 1),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildInfoItem(
                              icon: Icons.person,
                              label: 'Owner Name',
                              controller: _usernameController,
                              readOnly: true,
                            ),
                            Divider(
                              height: 1,
                              color: Theme.of(context).dividerColor,
                            ),
                            _buildInfoItem(
                              icon: Icons.mail,
                              label: 'Email Address',
                              controller: _emailController,
                              readOnly: true,
                            ),
                            Divider(
                              height: 1,
                              color: Theme.of(context).dividerColor,
                            ),
                            _buildInfoItem(
                              icon: Icons.call,
                              label: 'Phone Number',
                              controller: _phoneController,
                              readOnly: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Shop Information Section
                      _buildSectionHeader('SHOP INFORMATION'),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              offset: const Offset(0, 1),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildInfoItem(
                              icon: Icons.storefront,
                              label: 'Shop Name',
                              controller: _shopNameController,
                              readOnly: true,
                            ),
                            Divider(
                              height: 1,
                              color: Theme.of(context).dividerColor,
                            ),
                            // Static GST for now as per design request, passing a controller with dummy data
                            _buildInfoItem(
                              icon: Icons.receipt_long,
                              label: 'GST Number',
                              controller: TextEditingController(
                                text: '22ABCDE1234F1Z5',
                              ),
                              readOnly: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Action Button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(
                  top: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _showEditProfileDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 10,
                    shadowColor: AppColors.primary.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Edit Profile',
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
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withOpacity(0.7),
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    bool readOnly = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 2),
                // Display as text now since we edit in dialog
                Text(
                  controller.text.isNotEmpty ? controller.text : 'Not Provided',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: controller.text.isNotEmpty
                        ? Theme.of(context).textTheme.bodyLarge?.color
                        : Theme.of(
                            context,
                          ).textTheme.bodyMedium?.color?.withOpacity(0.5),
                    fontStyle: controller.text.isNotEmpty
                        ? FontStyle.normal
                        : FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
