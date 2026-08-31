import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/animations.dart';
import '../widgets/shared_widgets.dart';

// The task asked for React Native's FlatList — that's a React Native
// component with no Flutter equivalent by that name. The direct Flutter
// equivalent is ListView.builder, used below. Both only build/render the
// rows currently visible on screen (plus a small buffer) instead of the
// entire dataset at once — that's what makes a list of hundreds of items
// still scroll smoothly.
final List<Product> _demoProducts = List.generate(120, (i) {
  const categories = ['Textiles', 'Electronics', 'Furniture', 'Groceries', 'Stationery'];
  return Product('Item #${i + 1}', categories[i % categories.length], 'Rs ${(i + 1) * 250}');
});

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppTopBar(title: 'Product List', subtitle: '${_demoProducts.length} items — efficiently scrolling', showBack: true),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _demoProducts.length,
              itemBuilder: (context, index) {
                final product = _demoProducts[index];
                return FadeSlideIn(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(color: AppTheme.steelAccent.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                            alignment: Alignment.center,
                            child: Text('${index + 1}', style: const TextStyle(color: AppTheme.steelAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.ink)),
                                Text(product.category, style: const TextStyle(fontSize: 11, color: AppTheme.slate)),
                              ],
                            ),
                          ),
                          Text(product.price, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.navyPrimary)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
