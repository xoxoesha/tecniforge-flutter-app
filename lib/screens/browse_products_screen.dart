import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/cart_state.dart';
import '../theme/app_theme.dart';
import '../widgets/animations.dart';
import '../widgets/shared_widgets.dart';

class BrowseProductsScreen extends StatelessWidget {
  const BrowseProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // context.watch rebuilds this widget whenever CartState calls
    // notifyListeners() — that's how the badge count below stays live.
    final cart = context.watch<CartState>();

    return Scaffold(
      body: Column(
        children: [
          AppTopBar(title: 'Browse Products', subtitle: '${cart.totalItems} item${cart.totalItems == 1 ? '' : 's'} in cart', showBack: true),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: shopProducts.length,
              itemBuilder: (context, i) {
                final (name, price) = shopProducts[i];
                return FadeSlideIn(
                  index: i,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.ink)),
                                Text('Rs $price', style: const TextStyle(fontSize: 12, color: AppTheme.slate)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_shopping_cart, color: AppTheme.navyPrimary, size: 20),
                            // Writes to the SAME CartState instance the Cart
                            // screen reads from — no data is passed between
                            // the two screens directly, it flows through the
                            // shared store instead.
                            onPressed: () {
                              context.read<CartState>().addProduct(name, price);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Added $name to cart'), backgroundColor: AppTheme.navyPrimary, duration: const Duration(milliseconds: 900)),
                              );
                            },
                          ),
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
