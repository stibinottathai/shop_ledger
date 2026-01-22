import 'package:flutter/material.dart';
import 'package:shop_ledger/core/theme/app_colors.dart';
import 'package:shop_ledger/features/customer/presentation/pages/add_customer_page.dart';
import 'package:shop_ledger/features/customer/presentation/pages/customer_detail_page.dart';

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Customers',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {},
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.analytics, color: Colors.black, size: 20),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddCustomerPage()),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  hintText: 'Search customers...',
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
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  'ACTIVE LEDGERS (24)',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _buildCustomerItem(
                  'Rajesh Kumar',
                  'Last: 2 hours ago',
                  '₹12,500',
                  'Due Now',
                  AppColors.accentRed,
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuD9_OOZ2DcpL2B_DtTXrD8_c4iiqEhGLgR-dAV9WVLwHfH8CXwM1I_QShsw5RaeVTI32blv2SwvwHSYm9nafJsHtrDIVpU6-2r6VcjW5Y1gfriCfT2RicVMDQhbyLKcsXyGYSF29WFgs0Lxr5vgZnCjkewcK-rKG7cZdXDe5fDT1OoUuF6SKCcap2Xd9psSTyE3Pptmenij3Rod49MMK0c4XurC25GazZe9P5Ic0xHmEvk_MY9zdh6OxOoJvY3UEJrfHdyFlszK8ZpL',
                ),
                _buildCustomerItem(
                  'Suresh Fruit Mart',
                  'Last: Yesterday',
                  '₹8,200',
                  'Pending',
                  AppColors.accentOrange,
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuCfoKgW8zemCs7oJJFgiPFI1SfPQKvRN-3ZY7aIWcezZbuzX0jLwOXrVBr7HRnnHo7UwJaF3cm-_nMDOIeossZoG9kaPSQPOkCpRpHhHJfgOrT1PjZ2jfS07GLJC_AHOk1MycNHp-HZEE6_ezYTK5lCO7lTNU1fJ8mnyax2vAiAvPbP9G8Z6VSrM9CipOY5A9PiMpPhsT3dlXXM_l4bA-jZEyiD8f5chQrM4YgL86rojB1HvLFVcoWFIcpM0KXYETA3CVTeW2A899M3',
                ),
                _buildCustomerItem(
                  'Anil Verma',
                  'Last: 3 days ago',
                  '₹1,450',
                  'Due Now',
                  AppColors.accentRed,
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuBaXPgQ3IVJy5VlvVwVJEq6R0HkeXpfn9tnjCG2lRYCBfJpmlYUI41RzT3own6bBs0Fu53WuntRX-zz-X8D07Z9fIbpc2G_IeFmKmGh1q_ljM_qu5m0BIsQTSKQWyFN7ELLtFGL51r6_fMMbnHIVvrYbRzUDoNkfzra7yPkXsMzwLH7s4fSYv-Xl4mIoIdFiGK70a_h5Sku6tmbOXx8Oe8nbPuXaA7TGGddocKCCHyV0gwhupBNzvi8cQBVxiVgPlR7a-jIj5N2YXtJ',
                ),
                _buildCustomerItem(
                  'Kunal Brothers',
                  'Last: 4 days ago',
                  '₹24,000',
                  'Overdue',
                  AppColors.accentRed,
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuCCctO1coi9oFjnornLrHyexnN-hDOdo6xMIxdGc04WyF7uKCDjJtjwKQJ_GypvsAlTfxvPjMtIydDeLuFsMa10aC9bs9oj2HeLx4Y3ApbbNvY7BPO2khouqZAUHnS7v0RCnuvVGf6VK_MOEYLqbbM-Ia5P9-Xtc-7WLXAXn9w-LgMPAzkWjrZxD8e6EvBHHNOTrrL81L5BuHoRgLNDMehbAQVOXC__6oEnMb8U7rsyq8i_N9yCB-H7NOvYwb1T_QuHKI3Sg_kB0LMZ',
                ),
                _buildCustomerItem(
                  'Green Leaf Organic',
                  'Last: 1 week ago',
                  '₹450',
                  'Pending',
                  AppColors.accentOrange,
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuDXe5DiUy0QlDd0aDD_Sw0XF-PMD0LrpruRAO8dSPP91Y0Rxqi6GDgO4R77M2dj8AbOM7O05RHnhHL0rjhP6orG0FXJIACUKSXQgT0AfVxW2-KLamKvAiN5-nMyPydao795yoeGeCcVRpz-kG0v00d2guT8Vg3oN-PuXkbTreVkAgsmIttWQm_KviRFKXeJcxyP4YIq8cdWAyecpXofrZsHFnipOV17gPcyvlaz6suNICmDwQamqi2P50VK8YbDQ1WdaLUoy1JgnpT6',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerItem(
    String name,
    String lastActive,
    String amount,
    String status,
    Color statusColor,
    String imageUrl,
  ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CustomerDetailPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                  width: 2,
                ),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lastActive,
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amount,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor.withOpacity(0.8),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
