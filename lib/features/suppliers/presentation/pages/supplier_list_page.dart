import 'package:flutter/material.dart';
import 'package:shop_ledger/core/theme/app_colors.dart';
import 'package:shop_ledger/features/suppliers/presentation/pages/add_supplier_page.dart';
import 'package:shop_ledger/features/suppliers/presentation/pages/supplier_ledger_page.dart';

class SupplierListPage extends StatelessWidget {
  const SupplierListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            floating: true,
            backgroundColor: Colors.white.withOpacity(0.9),
            title: const Text(
              'Suppliers',
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    hintText: 'Search suppliers...',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Stats Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[100]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'TOTAL PAYABLE',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '\$23,570.00',
                          style: TextStyle(
                            color: AppColors.accentOrange,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: const [
                        Text(
                          'ACTIVE',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '12 Suppliers',
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Supplier List
          SliverList(
            delegate: SliverChildListDelegate([
              _buildSupplierItem(
                context,
                'Green Earth Farms',
                'Ecuador • Direct Import',
                '\$4,250.00',
                true,
                'https://lh3.googleusercontent.com/aida-public/AB6AXuDBwKTEOUKDmwARp4Xoj7lbL9y4TnsonVIUikTXIqL9e7Fc9J9wWJ4v6UcF3N4LGMf7FW6ajGnfc-2GUt6EV52HTsg01wSdQqaiBdq5XW9O_EGLUDLGWJ7Z0Eld6j3t7uOK7VW0_vFKCdJ1CfKNOn00J6Aro_HfvGR8W245v1xrw4SqJjfS6un-ZUtcNhQ1c2J_Ai2mvLEpoLJKOswvMpV4A6SsSKmrFULhN9kHZAdhafp5l-_wJuYVbqZpfaOGZE_BmFxLf4J61M8k',
              ),
              _buildSupplierItem(
                context,
                'Golden Peel Wholesales',
                'Local Warehouse • Central District',
                '\$120.00',
                true,
                'https://lh3.googleusercontent.com/aida-public/AB6AXuB8ev4evzVGh9STn3cxZvqHmQ75FmqUYzgke8Su-aZwqGgUKR5ThJq_v2MzyE18ausrjvoJ3U4mFH5TlItXNazhZAIa0tcVRatMxVKYFngCpYJC2fSVSUwVCpZGxD00VJa8UPZdxskc596YuOIyP-gBLAPfxGveHxIdPb-yfj-uz9UwGlZuNoWqkelluQbr8ojrNCjEaUS2-SprIyLO_445Oo7ewGREJqhoOvQBAbLeK0MbUw2JocKQgnIRzx9rvPGlefeZ9CCfy-Rg',
              ),
              _buildSupplierItem(
                context,
                'Bana-Premium Co.',
                'Port Authority • Terminal 4',
                '\$15,800.00',
                true,
                'https://lh3.googleusercontent.com/aida-public/AB6AXuCvVRJ8M93aqiqX_u7rFfPvWXH8_DnsS_ontuwwfRZhBg1DcaZli3xaE64n3UAKyHJ_jkKpwC-6Ti1WQeBQ8cGqS8gnhF8vu0xmEoHDwoUHN2TD9qRXj4hNmIpoWG_IdIMdUpKoicDVNQUyOjCHoop4e_TaTGVgnCAGnlKgdbA7wcFE99NDimBRcQoqkxO0CZOCzQbMp1oJSHwZ3JP5Aq1wI8mITv9al_y9gfiPLNMw1_LX8qnfiFibIlEk8YJFGeZb_Sc70HZ0tjvi',
              ),
              _buildSupplierItem(
                context,
                'Sunshine Exports',
                'Costa Rica • Coastal Farm',
                '\$3,400.00',
                true,
                'https://lh3.googleusercontent.com/aida-public/AB6AXuCtennAYD0xt7d1BwM9fNJxGHeMEO-lXgSjvE7SrUVGubi2Tm3uZc1IGkAOR5P4H24iYHIHS3l7-z6l0L93amihKw3hUCQLVeh1h168QGg9ZW7wWFm1u2nrVPcvADEPjObmBnuLRZlqCm5hISBQjNsSEEvmYGURNw5-mG4Edj_XSldd3WCY9JuWqYOedesufhh8xdnDbCJwodgItrG7HPGlKP2EQgK4e_wSvNChuyh4ApD6iVPHsef_HR7VY1bCwkt-ayEeAqrBn9il',
              ),
              _buildSupplierItem(
                context,
                'Metro Banana Mart',
                'Regional Distribution Center',
                '\$0.00',
                false,
                'https://lh3.googleusercontent.com/aida-public/AB6AXuBgy8dFYK7xwfI4doKb3XiEqDIroKDBZEhSnOTFVmU5HZoT8DHK-l5V5bMBHo67A_ZA2Sm0k_jw-kI7P6DGuD2qFH80UWGAnrByhAMEAxM6l6yOJ4R3ZB8rKOzKW7wGR7RxapK2RiMmZfxwURMYDECz08--gZXNCSODkwX7YQ5jpxuDhuk_Li1FBpI1vMXa4Ky4cMbx4OLDChf61WSNhBZrcrE_BNbPn7yBaEk_xNhvyVwwv6ccaSs-AZfBk1xCUWbfqa5wxDrXuLH7',
              ),
              _buildSupplierItem(
                context,
                'Island Tropics',
                'Philippines • South Hub',
                '\$1,250.00',
                true,
                'https://lh3.googleusercontent.com/aida-public/AB6AXuDJNMjyDY4SztuAmMMDjZIXaMgzVLesw0kwJNM73MXcyUsQmA5J7u_hGrnekgdUqDnPHxLBjruHS_DQWj73b_wKwGTmiE2X6FXwWWfx4UNd7Vo5yFjtCmlocnHnSxxD9EnAz7KE69oRTG7MaBk4WCsCt9gKPyGwZRob8sgAn1pfdsqkNjO9zx9U_sihfwwFbjWuP3-Dxb0OMKWKh_AllnZcrYtWjpb9CXemDiFN1etKak_TzpuVqu9VdHyUkkl2rXSsuJYvLCdNkADe',
              ),
            ]),
          ),
          // Bottom padding for navigation
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddSupplierPage()),
            );
          },
          heroTag: 'supplier_fab',
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: Colors.white, size: 32),
        ),
      ),
    );
  }

  Widget _buildSupplierItem(
    BuildContext context,
    String name,
    String subtitle,
    String amount,
    bool isPayable,
    String imageUrl,
  ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SupplierLedgerPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey[50]!)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amount,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isPayable
                        ? AppColors.accentOrange
                        : Colors.grey[400],
                  ),
                ),
                Text(
                  isPayable ? 'PAYABLE' : 'SETTLED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[400],
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
