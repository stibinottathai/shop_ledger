import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shop_ledger/core/theme/app_colors.dart';
import 'package:shop_ledger/features/inventory/domain/entities/item.dart';

class StockItemCard extends StatelessWidget {
  final Item item;
  final VoidCallback onTap;

  const StockItemCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, isDark ? 0.2 : 0.05),
            offset: const Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.slate50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Center(
                    child: Text(
                      item.name.isNotEmpty ? item.name[0].toUpperCase() : '?',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.currency_rupee,
                            size: 14,
                            color: context.textMuted,
                          ),
                          Text(
                            '${item.pricePerKg.toStringAsFixed(2)} / ${item.unit == 'pcs' ? 'pc' : item.unit}',
                            style: GoogleFonts.inter(
                              color: context.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Qty Badge with dynamic color based on stock level
                if (item.totalQuantity != null) _buildStockBadge(item, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build stock badge with dynamic color based on stock level
  Widget _buildStockBadge(Item item, bool isDark) {
    final stockStatus = _getStockStatus(item);
    final qty = item.totalQuantity ?? 0;

    // Define colors based on stock status
    Color bgColor;
    Color borderColor;
    Color textColor;

    switch (stockStatus) {
      case StockStatus.outOfStock:
        bgColor = isDark
            ? Colors.red.shade900.withAlpha(77)
            : Colors.red.shade50;
        borderColor = Colors.red.shade300.withAlpha(128);
        textColor = Colors.red.shade700;
        break;
      case StockStatus.lowStock:
        bgColor = isDark
            ? Colors.orange.shade900.withAlpha(77)
            : Colors.orange.shade50;
        borderColor = Colors.orange.shade300.withAlpha(128);
        textColor = Colors.orange.shade700;
        break;
      case StockStatus.goodStock:
        bgColor = isDark
            ? AppColors.emerald600.withAlpha(38)
            : AppColors.emerald50;
        borderColor = AppColors.emerald200.withAlpha(128);
        textColor = AppColors.emerald600;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            qty.toStringAsFixed(qty % 1 == 0 ? 0 : 1),
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: textColor,
            ),
          ),
          Text(
            item.unit.toUpperCase(),
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 8,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Determine stock status based on quantity and threshold
  StockStatus _getStockStatus(Item item) {
    final qty = item.totalQuantity ?? 0;
    final threshold =
        item.lowStockThreshold ?? 10.0; // Default to 10 if not set

    // Debug: Print to console to verify values
    print(
      'DEBUG Stock: ${item.name} | Qty=$qty | Threshold=$threshold | RawThreshold=${item.lowStockThreshold}',
    );

    if (qty <= 0) {
      return StockStatus.outOfStock;
    } else if (qty <= threshold) {
      return StockStatus.lowStock;
    } else {
      return StockStatus.goodStock;
    }
  }
}

/// Stock status enum
enum StockStatus { outOfStock, lowStock, goodStock }
