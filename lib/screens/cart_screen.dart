import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cart_state.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartState>();

    return Scaffold(
      body: Column(
        children: [
          AppTopBar(title: 'Cart', subtitle: 'Rs ${cart.totalPrice} total', showBack: true),
          Expanded(
            child: cart.items.isEmpty
                ? const Center(child: Text('Cart is empty — add items from Browse Products.', style: TextStyle(color: AppTheme.slate)))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cart.items.length,
              itemBuilder: (context, i) {
                final item = cart.items[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    child: Row(
                      children: [
                        AppBadge(label: 'x${item.quantity}', color: AppTheme.steelAccent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.ink)),
                              Text('Rs ${item.price} each', style: const TextStyle(fontSize: 11, color: AppTheme.slate)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed, size: 18),
                          onPressed: () => context.read<CartState>().removeProduct(item.name),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (cart.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: AppButton(label: 'Clear Cart', onPressed: () => context.read<CartState>().clear(), variant: AppButtonVariant.secondary, icon: Icons.remove_shopping_cart),
            ),
        ],
      ),
    );
  }
}
