import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shop_ledger/features/auth/presentation/providers/auth_provider.dart';
import 'package:shop_ledger/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:shop_ledger/features/settings/presentation/providers/settings_provider.dart';

import 'package:shop_ledger/core/theme/app_colors.dart';
import 'package:shop_ledger/core/widgets/common_error_widget.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardStatsProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth state to rebuild when user metadata updates (e.g. from Profile page)
    ref.watch(authStateProvider);
    final hideSensitive = ref.watch(settingsProvider).hideSensitiveData;

    final statsAsync = ref.watch(dashboardStatsProvider);
    final user = ref.read(authRepositoryProvider).getCurrentUser();
    final shopName =
        user?.userMetadata?['shop_name'] ??
        user?.userMetadata?['username'] ??
        'Raju Traders'; // Default from design
    final dateStr = DateFormat('EEE, d MMM').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) {
          return CommonErrorWidget(
            error: err,
            onRetry: () {
              ref.read(dashboardStatsProvider.notifier).refresh();
            },
            fullScreen: false,
          );
        },
        data: (stats) {
          // final pendingAmount = stats.todaysSale - stats.todaysCollection;

          return Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.of(context).padding.top + 16,
                  20,
                  16,
                ),
                decoration: const BoxDecoration(
                  color: Color(
                    0xFFFFFFFC,
                  ), // Slightly off-white/blur simulation
                  border: Border(bottom: BorderSide(color: Color(0xFFF8FAFC))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.go('/home/profile'),
                          child: Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withOpacity(0.1),
                              border: Border.all(color: AppColors.slate200),
                            ),
                            child: Center(
                              child: Text(
                                shopName.isNotEmpty
                                    ? shopName[0].toUpperCase()
                                    : 'S',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shopName,
                              style: GoogleFonts.inter(
                                color: AppColors.textMain,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                height: 1.25,
                              ),
                            ),
                            Text(
                              dateStr,
                              style: GoogleFonts.inter(
                                color: AppColors.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                offset: const Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.settings, size: 20),
                            color: AppColors.slate600,
                            onPressed: () => context.go('/home/settings'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                offset: const Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.notifications, size: 20),
                            color: AppColors.slate600,
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    return ref.read(dashboardStatsProvider.notifier).refresh();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Today's Cashflow Header
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Today's Sales",
                              style: GoogleFonts.inter(
                                color: AppColors.textMain,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Real-time daily transaction tracking",
                              style: GoogleFonts.inter(
                                color: AppColors.textMuted,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 24,
                        ), // Reduced from gap-8 (32) purely for mobile fit? No, gap-1 in header, gap-8 in main. 32px.
                        // Today's Cashflow Grid
                        Row(
                          children: [
                            Expanded(
                              child: _buildGaugeCard(
                                context,
                                amount: stats.todaysSale,
                                label: "Sales",
                                icon: Icons.storefront,
                                color: AppColors.primary,
                                percent: 1.0,
                                hide: hideSensitive,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildGaugeCard(
                                context,
                                amount: stats.todaysCollection,
                                label: "Received",
                                icon: Icons.payments,
                                color: AppColors.emerald500,
                                percent: stats.todaysSale > 0
                                    ? (stats.todaysCollection /
                                          stats.todaysSale)
                                    : 0,
                                hide: hideSensitive,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Today's Purchase Header
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Today's Purchase",
                              style: GoogleFonts.inter(
                                color: AppColors.textMain,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Real-time daily purchase tracking",
                              style: GoogleFonts.inter(
                                color: AppColors.textMuted,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Today's Purchase Grid
                        Row(
                          children: [
                            Expanded(
                              child: _buildGaugeCard(
                                context,
                                amount: stats.todaysPurchase,
                                label: "Purchase",
                                icon: Icons.shopping_cart,
                                color: Colors.blue[600]!,
                                percent: 1.0,
                                hide: hideSensitive,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildGaugeCard(
                                context,
                                amount: stats.todaysPaymentOut,
                                label: "Paid",
                                icon: Icons.outbox,
                                color: Colors.orange[500]!,
                                percent: stats.todaysPurchase > 0
                                    ? (stats.todaysPaymentOut /
                                          stats.todaysPurchase)
                                    : 0,
                                hide: hideSensitive,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Ledger Section
                        Text(
                          "Ledger",
                          style: GoogleFonts.inter(
                            color: AppColors.textMain,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Ledger Grid
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final width = (constraints.maxWidth - 12) / 2;
                            return Column(
                              children: [
                                Row(
                                  children: [
                                    _buildLedgerCard(
                                      width: width,
                                      title: "Total Sales",
                                      amount: stats.totalSales,
                                      subtitle:
                                          "+12% this week", // Static for now as per design
                                      subtitleColor: const Color(
                                        0xFF059669,
                                      ), // Emerald 600
                                      icon: Icons.trending_up,
                                      iconBg: const Color(
                                        0xFFECFDF5,
                                      ), // Emerald 50
                                      iconColor: const Color(0xFF059669),
                                      gradientColor: const Color(0xFFECFDF5),
                                      hide: hideSensitive,
                                    ),
                                    const SizedBox(width: 12),
                                    _buildLedgerCard(
                                      width: width,
                                      title: "Total Purchase",
                                      amount: stats.totalPurchases,
                                      subtitle: "Current period",
                                      subtitleColor: AppColors.textMain,
                                      icon: Icons.shopping_bag,
                                      iconBg: const Color(0xFFFEF2F2), // Red 50
                                      iconColor: const Color(
                                        0xFFEF4444,
                                      ), // Red 500
                                      gradientColor: const Color(0xFFFEF2F2),
                                      hide: hideSensitive,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    _buildActionLedgerCard(
                                      width: width,
                                      title: "Receivables",
                                      amount: stats.toGet,
                                      subtitle: "To collect",
                                      icon:
                                          Icons.arrow_circle_down, // Rotate -45
                                      iconColor: const Color(
                                        0xFF10B981,
                                      ), // Emerald 500
                                      hoverBorderColor: const Color(
                                        0xFFA7F3D0,
                                      ), // Emerald 200
                                      isRotateNegative: true,
                                      onTap: () => context.push('/customers'),
                                      hide: hideSensitive,
                                    ),
                                    const SizedBox(width: 12),
                                    _buildActionLedgerCard(
                                      width: width,
                                      title: "Payables",
                                      amount: stats.toGive,
                                      subtitle: "To pay",
                                      icon: Icons.arrow_circle_up, // Rotate 45
                                      iconColor: const Color(
                                        0xFFF87171,
                                      ), // Red 400
                                      hoverBorderColor: const Color(
                                        0xFFFECACA,
                                      ), // Red 200
                                      isRotateNegative: false,
                                      onTap: () => context.push('/suppliers'),
                                      hide: hideSensitive,
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 32),

                        // Business Insight
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC), // Slate 50
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                            ), // Slate 200
                            boxShadow: const [
                              BoxShadow(
                                color: Color.fromRGBO(
                                  0,
                                  0,
                                  0,
                                  0.05,
                                ), // shadow-sm
                                offset: Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFF1F5F9),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      offset: const Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.lightbulb_outline,
                                  color: Colors.amber,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Business Insight",
                                      style: GoogleFonts.inter(
                                        color: AppColors.textMain,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    RichText(
                                      text: TextSpan(
                                        style: GoogleFonts.inter(
                                          color: AppColors.slate600,
                                          fontSize: 12,
                                          height: 1.5,
                                        ),
                                        children: [
                                          const TextSpan(text: "You have "),
                                          TextSpan(
                                            text:
                                                "${stats.highDueCustomerCount} customers",
                                            style: GoogleFonts.inter(
                                              color: AppColors.textMain,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          TextSpan(
                                            text:
                                                " with pending dues exceeding ${_formatCurrency(stats.creditLimit)}. Follow up today to improve cashflow.",
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
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGaugeCard(
    BuildContext context, {
    required double amount,
    required String label,
    required IconData icon,
    required Color color,
    required double percent,
    bool hide = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate100),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            offset: Offset(0, 1),
            blurRadius: 3,
          ),
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.01),
            offset: Offset(0, 1),
            blurRadius: 2,
            spreadRadius: -1,
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(56, 56),
                  painter: GaugePainter(
                    color: color,
                    percent: percent.clamp(0.0, 1.0),
                    backgroundColor: AppColors.slate100,
                  ),
                ),
                Icon(
                  icon,
                  color: color,
                  size: 20,
                ), // Reduced size to fit inside gauge
              ],
            ),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _formatCurrency(amount, hide: hide),
              style: GoogleFonts.inter(
                color: AppColors.textMain,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              color: const Color(0xFF94a3b8), // Slate 400
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerCard({
    required double width,
    required String title,
    required double amount,
    required String subtitle,
    required Color subtitleColor,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required Color gradientColor,
    bool hide = false,
  }) {
    return Container(
      width: width,
      height: 112, // 28 * 4 = 112
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate100),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            offset: Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: GoogleFonts.inter(
                      color: const Color(0xFF94a3b8), // Slate 400
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 14),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _formatCurrency(amount, hide: hide),
                      style: GoogleFonts.inter(
                        color: AppColors.textMain,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: subtitleColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: -16,
            right: -16,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [gradientColor, gradientColor.withOpacity(0)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionLedgerCard({
    required double width,
    required String title,
    required double amount,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color
    hoverBorderColor, // Note: Hover effects in mobile are limited to InkWell ripples usually
    required bool isRotateNegative,
    required VoidCallback onTap,
    bool hide = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: width,
          height: 112,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.slate100),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.05),
                offset: Offset(0, 1),
                blurRadius: 3,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: GoogleFonts.inter(
                      color: const Color(0xFF94a3b8), // Slate 400
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Transform.rotate(
                    angle: isRotateNegative ? -math.pi / 4 : math.pi / 4,
                    child: Icon(icon, color: iconColor, size: 18),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _formatCurrency(amount, hide: hide),
                      style: GoogleFonts.inter(
                        color: AppColors.textMain,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF94a3b8), // Slate 400
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCurrency(double amount, {bool hide = false}) {
    if (hide) return '****';
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    ).format(amount);
  }
}

class GaugePainter extends CustomPainter {
  final Color color;
  final double percent;
  final Color backgroundColor;

  GaugePainter({
    required this.color,
    required this.percent,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 3) / 2; // Subtract stroke width / 2
    const strokeWidth = 3.0;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    if (percent > 0) {
      final fgPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      // Start from top (-pi/2)
      // Sweep angle is 2*pi * percent
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * percent,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant GaugePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.percent != percent;
  }
}
