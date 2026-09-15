import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../controllers/discovery_controller.dart';
import '../../shop_owner/models/shop_models.dart';

class ProductSearchResultsScreen extends ConsumerStatefulWidget {
  final String? initialQuery;

  const ProductSearchResultsScreen({super.key, this.initialQuery});

  @override
  ConsumerState<ProductSearchResultsScreen> createState() => _ProductSearchResultsScreenState();
}

class _ProductSearchResultsScreenState extends ConsumerState<ProductSearchResultsScreen> {
  late final TextEditingController _searchController;
  String _sortBy = 'NEAREST';

  // Default coordinate (Bangalore center / user location preference)
  double _lat = 12.9716;
  double _lon = 77.5946;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    if (_searchController.text.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    ref.read(discoveryControllerProvider.notifier).searchProducts(
      query,
      latitude: _lat,
      longitude: _lon,
      radiusKm: 5.0,
      sortBy: _sortBy,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(discoveryControllerProvider);
    final results = state.searchResults;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Products Nearby'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search & Sort bar
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _performSearch(),
                  decoration: InputDecoration(
                    hintText: 'Search milk, rice, oil, fruits...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: _performSearch,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Text('Sort by:', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    const SizedBox(width: 8),
                    _sortChip('NEAREST', 'Nearest'),
                    const SizedBox(width: 6),
                    _sortChip('LOWEST_PRICE', 'Lowest Price'),
                    const SizedBox(width: 6),
                    _sortChip('BEST_DEAL', 'Best Deal'),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Results
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off_outlined, size: 64, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'No verified shops nearby have "${_searchController.text}"'
                                  : 'Search for any grocery item to compare local prices',
                              style: const TextStyle(fontSize: 15, color: Colors.black54),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: results.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final item = results[index];
                          return _buildResultCard(context, item);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _sortChip(String key, String label) {
    final selected = _sortBy == key;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11, color: selected ? Colors.white : Colors.black87)),
      selected: selected,
      selectedColor: AppColors.primary,
      backgroundColor: Colors.grey.shade100,
      onSelected: (_) {
        setState(() => _sortBy = key);
        _performSearch();
      },
    );
  }

  Widget _buildResultCard(BuildContext context, ShopProductModel item) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (item.shopId != null) {
            context.push('/discovery/shop/${item.shopId}');
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.storefront, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.rawProductName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    if (item.brand != null && item.brand!.isNotEmpty)
                      Text(item.brand!, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (item.shopName != null) ...[
                          Text(
                            item.shopName!,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                          ),
                          const SizedBox(width: 4),
                        ],
                        if (item.distanceKm != null)
                          Text('• ${item.distanceKm!.toStringAsFixed(1)} km', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${item.effectivePrice.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                  ),
                  if (item.mrp != null && item.mrp! > item.price)
                    Text(
                      '₹${item.mrp!.toStringAsFixed(2)}',
                      style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.black45, fontSize: 12),
                    ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: item.availabilityStatus == 'AVAILABLE' ? Colors.green.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.availabilityStatus == 'AVAILABLE' ? 'In Stock' : 'Low Stock',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: item.availabilityStatus == 'AVAILABLE' ? Colors.green.shade700 : Colors.orange.shade700,
                      ),
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
}
