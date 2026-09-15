import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../controllers/shop_owner_controller.dart';
import '../models/shop_models.dart';

class ShopProductsScreen extends ConsumerStatefulWidget {
  const ShopProductsScreen({super.key});

  @override
  ConsumerState<ShopProductsScreen> createState() => _ShopProductsScreenState();
}

class _ShopProductsScreenState extends ConsumerState<ShopProductsScreen> {
  final _searchController = TextEditingController();
  String _filter = 'ALL';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shopOwnerControllerProvider.notifier).loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shopOwnerControllerProvider);
    final products = state.products;

    final query = _searchController.text.trim().toLowerCase();
    final filtered = products.where((p) {
      if (query.isNotEmpty &&
          !p.rawProductName.toLowerCase().contains(query) &&
          !(p.brand?.toLowerCase().contains(query) ?? false)) {
        return false;
      }
      if (_filter == 'AVAILABLE' && p.availabilityStatus != 'AVAILABLE') return false;
      if (_filter == 'LIMITED' && p.availabilityStatus != 'LIMITED') return false;
      if (_filter == 'OUT_OF_STOCK' && p.availabilityStatus != 'OUT_OF_STOCK') return false;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Inventory'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(shopOwnerControllerProvider.notifier).loadProducts(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filters Bar
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search products by name or brand...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('ALL', 'All (${products.length})'),
                      const SizedBox(width: 8),
                      _filterChip('AVAILABLE', 'In Stock (${products.where((p) => p.availabilityStatus == 'AVAILABLE').length})'),
                      const SizedBox(width: 8),
                      _filterChip('LIMITED', 'Low Stock (${products.where((p) => p.availabilityStatus == 'LIMITED').length})'),
                      const SizedBox(width: 8),
                      _filterChip('OUT_OF_STOCK', 'Out of Stock (${products.where((p) => p.availabilityStatus == 'OUT_OF_STOCK').length})'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Product List
          Expanded(
            child: state.isLoading && products.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              query.isNotEmpty ? 'No products match "$query"' : 'No products added yet',
                              style: const TextStyle(fontSize: 16, color: Colors.black54),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => context.push('/shop/products/add'),
                              icon: const Icon(Icons.add),
                              label: const Text('Add First Product'),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref.read(shopOwnerControllerProvider.notifier).loadProducts(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final product = filtered[index];
                            return _buildProductCard(context, product);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/shop/products/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _filterChip(String key, String label) {
    final selected = _filter == key;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : Colors.black87)),
      selected: selected,
      selectedColor: AppColors.primary,
      backgroundColor: Colors.grey.shade100,
      onSelected: (_) => setState(() => _filter = key),
    );
  }

  Widget _buildProductCard(BuildContext context, ShopProductModel product) {
    final hasDiscount = product.mrp != null && product.mrp! > product.price;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Icon Container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
                ),
                const SizedBox(width: AppSpacing.md),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.rawProductName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      if (product.brand != null && product.brand!.isNotEmpty)
                        Text(
                          product.brand!,
                          style: const TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                      if (product.packageSize != null)
                        Text(
                          '${product.packageSize} ${product.unit}',
                          style: const TextStyle(color: Colors.black45, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                // Status Badge
                _statusBadge(product.availabilityStatus),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Price section
                Row(
                  children: [
                    Text(
                      '₹${product.effectivePrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                    ),
                    if (hasDiscount) ...[
                      const SizedBox(width: 8),
                      Text(
                        '₹${product.mrp!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.black45,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    if (product.stockQuantity != null) ...[
                      const SizedBox(width: 12),
                      Text(
                        'Qty: ${product.stockQuantity!.toInt()}',
                        style: const TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ],
                  ],
                ),
                // Actions
                Row(
                  children: [
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20, color: Colors.black54),
                      onSelected: (value) async {
                        if (value == 'AVAILABLE' || value == 'LIMITED' || value == 'OUT_OF_STOCK') {
                          await ref.read(shopOwnerControllerProvider.notifier).updateProduct(
                            product.id,
                            {'availabilityStatus': value},
                          );
                        } else if (value == 'DELETE') {
                          _confirmDelete(product);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'AVAILABLE', child: Text('Mark In Stock')),
                        const PopupMenuItem(value: 'LIMITED', child: Text('Mark Low Stock')),
                        const PopupMenuItem(value: 'OUT_OF_STOCK', child: Text('Mark Out of Stock')),
                        const PopupMenuDivider(),
                        const PopupMenuItem(value: 'DELETE', child: Text('Delete Product', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color bg;
    Color fg;
    String label;

    if (status == 'AVAILABLE') {
      bg = Colors.green.shade50;
      fg = Colors.green.shade700;
      label = 'In Stock';
    } else if (status == 'LIMITED') {
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade700;
      label = 'Low Stock';
    } else {
      bg = Colors.red.shade50;
      fg = Colors.red.shade700;
      label = 'Out of Stock';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withOpacity(0.3)),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
    );
  }

  void _confirmDelete(ShopProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product?'),
        content: Text('Are you sure you want to remove "${product.rawProductName}" from your shop catalog?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(shopOwnerControllerProvider.notifier).deleteProduct(product.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
