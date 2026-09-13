import 'package:flutter/material.dart';
import '../location_deals_models.dart';
import '../location_service.dart';

/// Modal dialog for manually selecting or searching a shopping area/pincode.
class ManualLocationDialog extends StatefulWidget {
  final UserLocationContext currentContext;
  final Future<List<AreaSearchResult>> Function(String query) onSearchAreas;

  const ManualLocationDialog({
    super.key,
    required this.currentContext,
    required this.onSearchAreas,
  });

  @override
  State<ManualLocationDialog> createState() => _ManualLocationDialogState();
}

class _ManualLocationDialogState extends State<ManualLocationDialog> {
  final TextEditingController _controller = TextEditingController();
  List<AreaSearchResult> _results = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String text) async {
    final query = text.trim();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
      return;
    }

    if (query.length < 2) return;

    setState(() => _isLoading = true);
    try {
      final res = await widget.onSearchAreas(query);
      if (mounted) {
        setState(() {
          _results = res;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _results = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.store_mall_directory_rounded,
                    color: Color(0xFF10B981),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose Shopping Location',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      Text(
                        'Discover local store prices in your area',
                        style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search city, area, or pincode...',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 20),
                suffixIcon: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (_results.isNotEmpty) ...[
              Text(
                'Search Results (${_results.length})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: _results.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  itemBuilder: (ctx, index) {
                    final area = _results[index];
                    final isCurrent = widget.currentContext.approximateArea.toLowerCase() ==
                            area.area.toLowerCase() ||
                        widget.currentContext.city.toLowerCase() == area.city.toLowerCase();

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? const Color(0xFF10B981).withValues(alpha: 0.12)
                              : const Color(0xFFF3F4F6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCurrent ? Icons.check_circle_rounded : Icons.location_on_outlined,
                          color: isCurrent ? const Color(0xFF10B981) : const Color(0xFF6B7280),
                          size: 18,
                        ),
                      ),
                      title: Text(
                        area.displayName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                          color: isCurrent ? const Color(0xFF10B981) : const Color(0xFF1F2937),
                        ),
                      ),
                      subtitle: Text(
                        '${area.city}${area.postalCode.isNotEmpty ? ' • Pincode: ${area.postalCode}' : ''}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                      ),
                      onTap: () {
                        Navigator.of(context).pop(
                          UserLocationContext(
                            latitude: area.latitude,
                            longitude: area.longitude,
                            approximateArea: area.area,
                            city: area.city,
                            postalCode: area.postalCode,
                            isManual: true,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ] else if (_controller.text.trim().isNotEmpty) ...[
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_off_rounded, size: 32, color: Color(0xFF9CA3AF)),
                        const SizedBox(height: 10),
                        Text(
                          'No locations found for "${_controller.text}"',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.search_rounded, color: Color(0xFF10B981), size: 30),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Type your city, area, or pincode',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Searches any real locality dynamically via live geolocation services.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
