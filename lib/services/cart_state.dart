import 'package:flutter/foundation.dart';
import '../models/models.dart';

// The task asked for Context API or Redux — those are React/React Native
// concepts. Flutter's direct, widely-used equivalent for scalable shared
// state is the `provider` package: a ChangeNotifier holds the state and
// business logic in one place, and ANY widget anywhere in the tree can read
// it or listen for changes, without it being passed down manually screen
// to screen (no prop drilling) — same goal as Context API/Redux.
class CartState extends ChangeNotifier {
  final List<CartItem> _items = [];
  List<CartItem> get items => List.unmodifiable(_items);

  int get totalItems => _items.fold(0, (sum, i) => sum + i.quantity);
  int get totalPrice => _items.fold(0, (sum, i) => sum + i.price * i.quantity);

  void addProduct(String name, int price) {
    final existing = _items.where((i) => i.name == name).toList();
    if (existing.isNotEmpty) {
      existing.first.quantity++;
    } else {
      _items.add(CartItem(name: name, price: price));
    }
    notifyListeners();
  }

  void removeProduct(String name) {
    _items.removeWhere((i) => i.name == name);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
