import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

// ---------------------------------------------------------------------------
// TecniForge — Unified app
//
// One MaterialApp, one home menu screen. Every task screen (CRUD Clients,
// New Client Form, Component Library) is pushed on top via Navigator, and
// the back button returns to this menu — same pattern as the multi-Activity
// setup used earlier in the Kotlin project. Nothing gets overwritten anymore.
// ---------------------------------------------------------------------------

class AppTheme {
  AppTheme._();
  static const navyDeep = Color(0xFF0B1E3D);
  static const navyPrimary = Color(0xFF16305C);
  static const steelAccent = Color(0xFF3D6DB5);
  static const forgeAmber = Color(0xFFE8A33D);
  static const canvas = Color(0xFFF5F7FA);
  static const ink = Color(0xFF1A1D29);
  static const slate = Color(0xFF6B7280);
  static const errorRed = Color(0xFFC0392B);
  static const successGreen = Color(0xFF1D8A5A);
  static const cardBorder = Color(0xFFE7EAF0);
  static const radiusSm = 10.0;
  static const radiusMd = 14.0;

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: canvas,
    colorScheme: ColorScheme.fromSeed(seedColor: navyPrimary, brightness: Brightness.light, primary: navyPrimary, error: errorRed),
    cardColor: Colors.white,
    dividerColor: cardBorder,
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF10141C),
    colorScheme: ColorScheme.fromSeed(
      seedColor: steelAccent,
      brightness: Brightness.dark,
      primary: const Color(0xFF7FA8E8),
      secondary: forgeAmber,
      surface: const Color(0xFF171D27),
      error: const Color(0xFFFF6B5E),
    ),
    cardColor: const Color(0xFF171D27),
    dividerColor: const Color(0xFF2B3442),
  );

  static ThemeData get themeData => lightTheme;
}

class ThemeController extends ChangeNotifier {
  static const _prefsKey = 'app_theme_mode';
  ThemeMode _mode = ThemeMode.light;
  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  ThemeController() { _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_prefsKey) == 'dark') {
      _mode = ThemeMode.dark;
      notifyListeners();
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode == ThemeMode.dark ? 'dark' : 'light');
  }

  Future<void> toggle() => setMode(isDark ? ThemeMode.light : ThemeMode.dark);
}

final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> _initNotifications() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);
  await notificationsPlugin.initialize(initSettings);
}

// ---------------------------------------------------------------------------
// SHARED APP STATE — Provider / ChangeNotifier
//
// The task asked for Context API or Redux — those are React/React Native
// concepts. Flutter's direct, widely-used equivalent for scalable shared
// state is the `provider` package: a ChangeNotifier holds the state and
// business logic in one place, and ANY widget anywhere in the tree can read
// it or listen for changes, without it being passed down manually screen
// to screen (no prop drilling) — same goal as Context API/Redux.
// ---------------------------------------------------------------------------

class CartItem {
  final String name;
  final int price;
  int quantity;
  CartItem({required this.name, required this.price, this.quantity = 1});
}

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
    notifyListeners(); // tells every listening widget to rebuild — this is
    // the "update propagates everywhere" part of Context/Redux
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initNotifications();
  runApp(
    // ChangeNotifierProvider makes CartState reachable from every screen
    // below it in the widget tree — the "store" that Redux/Context provide.
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartState()),
        ChangeNotifierProvider(create: (_) => ThemeController()),
      ],
      child: const TecniForgeApp(),
    ),
  );
}

class TecniForgeApp extends StatelessWidget {
  const TecniForgeApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TecniForge',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: context.watch<ThemeController>().mode,
      home: const SplashScreen(),
    );
  }
}

// ---------------------------------------------------------------------------
// SPLASH SCREEN — shown for a couple seconds on launch, then replaces itself
// with the home menu (using pushReplacement so the splash isn't left on the
// back stack — pressing back from the home menu won't return to it).
// ---------------------------------------------------------------------------

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(animatedRoute(const HomeMenuScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navyDeep,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: AppTheme.forgeAmber, borderRadius: BorderRadius.circular(18)),
              alignment: Alignment.center,
              child: const Text('TF', style: TextStyle(color: AppTheme.navyDeep, fontSize: 28, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 20),
            const Text('TECNIFORGE', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 3)),
            const SizedBox(height: 6),
            const Text('Business Autopilot', style: TextStyle(color: Color(0xFF9FB0CC), fontSize: 12)),
            const SizedBox(height: 32),
            const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: AppTheme.forgeAmber, strokeWidth: 2.5)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HOME MENU — the starting point. Each row navigates (pushes) to one screen.
// ---------------------------------------------------------------------------

class HomeMenuScreen extends StatelessWidget {
  const HomeMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _MenuItem('Clients (CRUD)', 'Create, read, update, delete via REST API', Icons.people_outline, (ctx) => const ClientListScreen()),
      _MenuItem('New Client Form', 'Validated form (name, email, phone...)', Icons.assignment_outlined, (ctx) => const ClientFormScreen()),
      _MenuItem('Component Library', 'Reusable buttons, cards, badges, fields', Icons.widgets_outlined, (ctx) => const ComponentDemoScreen()),
      _MenuItem('App Theme', 'Switch between light and dark mode', Icons.dark_mode_outlined, (ctx) => const ThemeSettingsScreen()),
      _MenuItem('Notifications', 'Schedule local reminder notifications', Icons.notifications_outlined, (ctx) => const NotificationsScreen()),
      _MenuItem('Business Dashboard', 'Dashboard, Tasks, Profile — bottom nav', Icons.dashboard_outlined, (ctx) => const BusinessDashboardScreen()),
      _MenuItem('Task List', 'Add/remove tasks with validation', Icons.checklist_outlined, (ctx) => const TaskListScreen()),
      _MenuItem('Business Notes', 'Local storage — survives app restart', Icons.save_outlined, (ctx) => const LocalStorageScreen()),
      _MenuItem('Weather', 'API + navigation + saved favorites', Icons.wb_sunny_outlined, (ctx) => const WeatherCitiesScreen()),
      _MenuItem('Product List', 'Efficient scrolling list (FlatList equivalent)', Icons.list_alt_outlined, (ctx) => const ProductListScreen()),
      _MenuItem('Browse Products', 'Shared state demo — add to cart', Icons.storefront_outlined, (ctx) => const BrowseProductsScreen()),
      _MenuItem('Cart', 'Shows the same shared state, live', Icons.shopping_cart_outlined, (ctx) => const CartScreen()),
      _MenuItem('Team Tasks', 'Fetch + toggle-update via REST API', Icons.task_alt_outlined, (ctx) => const TeamTasksScreen()),
      _MenuItem('Business Photo', 'Camera + gallery, with permissions', Icons.camera_alt_outlined, (ctx) => const ImagePickerScreen()),
    ];

    return Scaffold(
      body: Column(
        children: [
          const AppTopBar(title: 'TecniForge', subtitle: 'Pick a screen to open'),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final item = items[i];
                return FadeSlideIn(
                  index: i,
                  child: AppCard(
                    onTap: () => Navigator.push(context, animatedRoute(item.builder(context))),
                    child: Row(
                      children: [
                        Icon(item.icon, color: AppTheme.steelAccent, size: 22),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.ink)),
                              Text(item.subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.slate)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Color(0xFFC4CAD6)),
                      ],
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

class _MenuItem {
  final String title, subtitle;
  final IconData icon;
  final Widget Function(BuildContext) builder;
  _MenuItem(this.title, this.subtitle, this.icon, this.builder);
}

// ---------------------------------------------------------------------------
// ANIMATION HELPERS — used across the app for a consistent, polished feel.
// ---------------------------------------------------------------------------

/// Custom page transition: new screen slides in from the right while
/// fading in, instead of the default abrupt platform transition.
Route<T> animatedRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Wraps any child in a subtle fade + slide-up entrance animation. Give each
/// item in a list a slightly larger [index] so they cascade in one after
/// another instead of all appearing at once.
class FadeSlideIn extends StatelessWidget {
  final Widget child;
  final int index;
  const FadeSlideIn({super.key, required this.child, this.index = 0});

  @override
  Widget build(BuildContext context) {
    final delay = (index * 40).clamp(0, 480);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(offset: Offset(0, (1 - value) * 16), child: child),
        );
      },
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// SHARED REUSABLE COMPONENTS (used by every screen below)
// ---------------------------------------------------------------------------

class AppTopBar extends StatelessWidget {
  final String title, subtitle;
  final bool showBack;
  const AppTopBar({super.key, required this.title, required this.subtitle, this.showBack = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.navyDeep,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          if (showBack) const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('TECNIFORGE', style: TextStyle(color: AppTheme.forgeAmber, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 2)),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
              Text(subtitle, style: const TextStyle(color: Color(0xFF9FB0CC), fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const AppCard({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(AppTheme.radiusMd), border: Border.all(color: Theme.of(context).dividerColor)),
      child: child,
    );
    if (onTap == null) return card;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(AppTheme.radiusMd), child: card);
  }
}

class AppBadge extends StatelessWidget {
  final String label;
  final Color color;
  const AppBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(50)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

enum AppButtonVariant { primary, secondary, danger }

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final AppButtonVariant variant;
  final IconData? icon;

  const AppButton({super.key, required this.label, required this.onPressed, this.variant = AppButtonVariant.primary, this.icon});

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = switch (widget.variant) {
      AppButtonVariant.primary => AppTheme.navyPrimary,
      AppButtonVariant.secondary => Theme.of(context).colorScheme.surface,
      AppButtonVariant.danger => AppTheme.errorRed.withOpacity(0.1),
    };
    final fg = switch (widget.variant) {
      AppButtonVariant.primary => Colors.white,
      AppButtonVariant.secondary => Theme.of(context).colorScheme.onSurface,
      AppButtonVariant.danger => AppTheme.errorRed,
    };

    // A quick scale-down on press and back up on release gives buttons a
    // tactile, "pressable" feel instead of just an instant color flash.
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: bg,
              elevation: widget.variant == AppButtonVariant.secondary ? 0 : 1,
              side: widget.variant == AppButtonVariant.secondary ? BorderSide(color: Theme.of(context).dividerColor) : null,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[Icon(widget.icon, size: 16, color: fg), const SizedBox(width: 8)],
                Text(widget.label, style: TextStyle(color: fg, fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final IconData? icon;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;

  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.icon,
    this.obscureText = false,
    this.validator,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.slate)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null ? Icon(icon, size: 18, color: AppTheme.slate) : null,
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm), borderSide: const BorderSide(color: AppTheme.navyPrimary, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// THEME SETTINGS — dynamic light/dark mode
// ---------------------------------------------------------------------------

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ThemeController>();
    final isDark = controller.isDark;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          const AppTopBar(title: 'App Theme', subtitle: 'Choose your preferred appearance', showBack: true),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: AppTheme.forgeAmber, size: 28),
                      const SizedBox(height: 12),
                      Text('Appearance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.onSurface)),
                      const SizedBox(height: 6),
                      Text('Switch the complete app between light and dark mode. The change is applied immediately across all screens.', style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
                      const SizedBox(height: 16),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: Text(isDark ? 'Dark mode' : 'Light mode'),
                        subtitle: Text(isDark ? 'Dark colors are active' : 'Light colors are active'),
                        secondary: Icon(isDark ? Icons.nightlight_round : Icons.wb_sunny_outlined),
                        value: isDark,
                        onChanged: (_) => controller.toggle(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: AppTheme.successGreen, size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text('Your selected theme is saved locally and will be restored when the app is opened again.', style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SCREEN 1 — Clients CRUD (REST API)
// ---------------------------------------------------------------------------

const _baseUrl = 'https://jsonplaceholder.typicode.com/posts';

class Client {
  final int id;
  String title, body;
  Client({required this.id, required this.title, required this.body});
  factory Client.fromJson(Map<String, dynamic> j) => Client(id: j['id'], title: j['title'] ?? '', body: j['body'] ?? '');
}

class ClientApi {
  static Future<List<Client>> readAll() async {
    final res = await http.get(Uri.parse('$_baseUrl?_limit=8'));
    if (res.statusCode != 200) throw Exception('Failed to load (${res.statusCode})');
    final List data = jsonDecode(res.body);
    return data.map((e) => Client.fromJson(e)).toList();
  }

  static Future<Client> create(String title, String body) async {
    final res = await http.post(Uri.parse(_baseUrl), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'title': title, 'body': body, 'userId': 1}));
    if (res.statusCode != 201) throw Exception('Failed to create (${res.statusCode})');
    final json = jsonDecode(res.body);
    return Client(id: DateTime.now().millisecondsSinceEpoch, title: json['title'], body: json['body']);
  }

  static Future<void> update(int id, String title, String body) async {
    final res = await http.put(Uri.parse('$_baseUrl/$id'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'id': id, 'title': title, 'body': body, 'userId': 1}));
    if (res.statusCode != 200) throw Exception('Failed to update (${res.statusCode})');
  }

  static Future<void> delete(int id) async {
    final res = await http.delete(Uri.parse('$_baseUrl/$id'));
    if (res.statusCode != 200) throw Exception('Failed to delete (${res.statusCode})');
  }
}

enum LoadState { loading, success, error }

class ClientListScreen extends StatefulWidget {
  const ClientListScreen({super.key});
  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  LoadState state = LoadState.loading;
  List<Client> clients = [];
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => state = LoadState.loading);
    try {
      final result = await ClientApi.readAll();
      setState(() {
        clients = result;
        state = LoadState.success;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        state = LoadState.error;
      });
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: isError ? AppTheme.errorRed : AppTheme.navyPrimary));
  }

  void _openForm({Client? existing}) {
    final titleC = TextEditingController(text: existing?.title ?? '');
    final bodyC = TextEditingController(text: existing?.body ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(existing == null ? 'Add Client' : 'Edit Client', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.ink)),
            const SizedBox(height: 16),
            AppTextField(label: 'Client name', controller: titleC),
            const SizedBox(height: 12),
            AppTextField(label: 'Notes', controller: bodyC),
            const SizedBox(height: 16),
            AppButton(
              label: existing == null ? 'Add' : 'Save',
              onPressed: () async {
                if (titleC.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                try {
                  if (existing == null) {
                    final c = await ClientApi.create(titleC.text.trim(), bodyC.text.trim());
                    setState(() => clients.insert(0, c));
                    _snack('Client added');
                  } else {
                    await ClientApi.update(existing.id, titleC.text.trim(), bodyC.text.trim());
                    setState(() {
                      existing.title = titleC.text.trim();
                      existing.body = bodyC.text.trim();
                    });
                    _snack('Client updated');
                  }
                } catch (e) {
                  _snack('Failed: $e', isError: true);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(Client c) async {
    try {
      await ClientApi.delete(c.id);
      setState(() => clients.removeWhere((x) => x.id == c.id));
      _snack('Client deleted');
    } catch (e) {
      _snack('Delete failed: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppTopBar(title: 'Clients', subtitle: state == LoadState.success ? '${clients.length} clients loaded' : 'Connected to REST API', showBack: true),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: KeyedSubtree(key: ValueKey(state), child: _body()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(backgroundColor: AppTheme.forgeAmber, onPressed: () => _openForm(), child: const Icon(Icons.add, color: AppTheme.navyDeep)),
    );
  }

  Widget _body() {
    switch (state) {
      case LoadState.loading:
        return const Center(child: CircularProgressIndicator(color: AppTheme.navyPrimary));
      case LoadState.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.cloud_off, color: AppTheme.errorRed, size: 48),
              const SizedBox(height: 12),
              const Text("Couldn't load clients", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.ink)),
              const SizedBox(height: 4),
              Text(errorMessage, style: const TextStyle(fontSize: 12, color: AppTheme.slate), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              SizedBox(width: 140, child: AppButton(label: 'Retry', onPressed: _load, icon: Icons.refresh)),
            ]),
          ),
        );
      case LoadState.success:
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: clients.length,
          itemBuilder: (ctx, i) {
            final c = clients[i];
            return FadeSlideIn(
              index: i,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(c.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.ink)),
                          if (c.body.isNotEmpty) Text(c.body, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppTheme.slate)),
                        ]),
                      ),
                      IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.slate), onPressed: () => _openForm(existing: c)),
                      IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.errorRed), onPressed: () => _delete(c)),
                    ],
                  ),
                ),
              ),
            );
          },
        );
    }
  }
}

// ---------------------------------------------------------------------------
// SCREEN 2 — New Client Form (validation)
// ---------------------------------------------------------------------------

class ClientFormScreen extends StatefulWidget {
  const ClientFormScreen({super.key});
  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _business = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _submitted = false;

  String? _vName(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Full name is required.';
    if (s.length < 3) return 'Name must be at least 3 characters.';
    return null;
  }

  String? _vEmail(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Email is required.';
    if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(s)) return 'Enter a valid email address.';
    return null;
  }

  String? _vPhone(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Phone number is required.';
    if (!RegExp(r'^\d{10,12}$').hasMatch(s)) return 'Enter a valid phone number (10–12 digits).';
    return null;
  }

  String? _vBusiness(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Business name is required.';
    return null;
  }

  String? _vPassword(String? v) {
    final s = v ?? '';
    if (s.isEmpty) return 'Password is required.';
    if (s.length < 8) return 'Password must be at least 8 characters.';
    if (!RegExp(r'\d').hasMatch(s)) return 'Password must include at least one number.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AppTopBar(title: 'New Client', subtitle: 'Fill in the details below', showBack: true),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_submitted)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppTheme.successGreen.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                        child: const Row(children: [
                          Icon(Icons.check_circle, color: AppTheme.successGreen, size: 18),
                          SizedBox(width: 8),
                          Text('Client added successfully!', style: TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.w500, fontSize: 13)),
                        ]),
                      ),
                    Padding(padding: const EdgeInsets.only(bottom: 16), child: AppTextField(label: 'Full name', controller: _name, validator: _vName, icon: Icons.person_outline, hint: 'e.g. Ayesha Khan')),
                    Padding(padding: const EdgeInsets.only(bottom: 16), child: AppTextField(label: 'Email', controller: _email, validator: _vEmail, icon: Icons.email_outlined, hint: 'name@business.com', keyboardType: TextInputType.emailAddress)),
                    Padding(padding: const EdgeInsets.only(bottom: 16), child: AppTextField(label: 'Phone number', controller: _phone, validator: _vPhone, icon: Icons.phone_outlined, hint: '03001234567', keyboardType: TextInputType.phone)),
                    Padding(padding: const EdgeInsets.only(bottom: 16), child: AppTextField(label: 'Business name', controller: _business, validator: _vBusiness, icon: Icons.store_outlined, hint: 'e.g. Al-Noor Traders')),
                    Padding(padding: const EdgeInsets.only(bottom: 16), child: AppTextField(label: 'Password', controller: _password, validator: _vPassword, icon: Icons.lock_outline, hint: 'At least 8 characters', obscureText: _obscure)),
                    AppButton(
                      label: 'Add Client',
                      onPressed: () {
                        setState(() => _submitted = false);
                        if (_formKey.currentState!.validate()) {
                          setState(() => _submitted = true);
                          FocusScope.of(context).unfocus();
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SCREEN 3 — Component Library demo
// ---------------------------------------------------------------------------

class ComponentDemoScreen extends StatefulWidget {
  const ComponentDemoScreen({super.key});
  @override
  State<ComponentDemoScreen> createState() => _ComponentDemoScreenState();
}

class _ComponentDemoScreenState extends State<ComponentDemoScreen> {
  final _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AppTopBar(title: 'Component Library', subtitle: 'Reusable pieces, one theme', showBack: true),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Badges', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.ink)),
                  const SizedBox(height: 8),
                  const Wrap(spacing: 8, children: [
                    AppBadge(label: 'High', color: AppTheme.errorRed),
                    AppBadge(label: 'Med', color: AppTheme.forgeAmber),
                    AppBadge(label: 'Low', color: AppTheme.steelAccent),
                  ]),
                  const SizedBox(height: 20),
                  const Text('Card', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.ink)),
                  const SizedBox(height: 8),
                  AppCard(
                    onTap: () {},
                    child: const Row(children: [
                      Icon(Icons.business, color: AppTheme.steelAccent, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Al-Noor Traders', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: AppTheme.ink)),
                          Text('Tap to view details', style: TextStyle(fontSize: 11, color: AppTheme.slate)),
                        ]),
                      ),
                      Icon(Icons.chevron_right, color: Color(0xFFC4CAD6)),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  const Text('Text field', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.ink)),
                  const SizedBox(height: 8),
                  AppTextField(label: 'Client name', controller: _nameController, hint: 'e.g. Ayesha Khan', icon: Icons.person_outline),
                  const SizedBox(height: 20),
                  const Text('Buttons', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.ink)),
                  const SizedBox(height: 8),
                  AppButton(label: 'Primary action', onPressed: () {}, icon: Icons.check),
                  const SizedBox(height: 10),
                  AppButton(label: 'Secondary action', onPressed: () {}, variant: AppButtonVariant.secondary),
                  const SizedBox(height: 10),
                  AppButton(label: 'Delete', onPressed: () {}, variant: AppButtonVariant.danger, icon: Icons.delete_outline),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SCREEN 4 — Local Notifications
//
// Shows the two basic operations local notifications need: firing one
// immediately, and scheduling one for a few seconds/minutes in the future
// (simulating a reminder), all without any backend or push service.
// ---------------------------------------------------------------------------

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _titleController = TextEditingController(text: 'Follow up with client');
  final _bodyController = TextEditingController(text: "Don't forget to call Al-Noor Traders about invoice #2291");
  int _delaySeconds = 10;
  String? _lastAction;

  static const _channelId = 'tecniforge_reminders';
  static const _channelName = 'Reminders';

  NotificationDetails get _details => const NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Scheduled reminders from TecniForge',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  Future<void> _sendNow() async {
    await notificationsPlugin.show(
      0,
      _titleController.text.isEmpty ? 'TecniForge reminder' : _titleController.text,
      _bodyController.text,
      _details,
    );
    setState(() => _lastAction = 'Sent immediately');
  }

  Future<void> _scheduleDelayed() async {
    // A simple delayed local notification — fires after _delaySeconds even
    // if the app is backgrounded, without needing any server or Firebase.
    await Future.delayed(Duration(seconds: _delaySeconds));
    if (!mounted) return;
    await notificationsPlugin.show(
      1,
      _titleController.text.isEmpty ? 'TecniForge reminder' : _titleController.text,
      _bodyController.text,
      _details,
    );
  }

  void _startSchedule() {
    setState(() => _lastAction = 'Scheduled — will fire in $_delaySeconds seconds. You can leave this screen.');
    _scheduleDelayed();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AppTopBar(title: 'Notifications', subtitle: 'Schedule local reminders', showBack: true),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(label: 'Title', controller: _titleController, icon: Icons.title),
                  const SizedBox(height: 16),
                  AppTextField(label: 'Message', controller: _bodyController, icon: Icons.notes),
                  const SizedBox(height: 20),
                  const Text('Delay before scheduled notification', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.slate)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [5, 10, 30, 60].map((s) {
                      final selected = _delaySeconds == s;
                      return ChoiceChip(
                        label: Text('${s}s'),
                        selected: selected,
                        onSelected: (_) => setState(() => _delaySeconds = s),
                        selectedColor: AppTheme.navyPrimary,
                        labelStyle: TextStyle(color: selected ? Colors.white : AppTheme.ink, fontSize: 12),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50), side: const BorderSide(color: AppTheme.cardBorder)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  AppButton(label: 'Send Now', onPressed: _sendNow, icon: Icons.flash_on),
                  const SizedBox(height: 10),
                  AppButton(label: 'Schedule Reminder', onPressed: _startSchedule, variant: AppButtonVariant.secondary, icon: Icons.schedule),
                  if (_lastAction != null) ...[
                    const SizedBox(height: 16),
                    AppCard(
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: AppTheme.successGreen, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_lastAction!, style: const TextStyle(fontSize: 12, color: AppTheme.ink))),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SCREEN 5 — Business Dashboard (Dashboard / Tasks / Profile, bottom nav)
// This recreates the original 3-screen multi-nav app, now in Flutter.
// ---------------------------------------------------------------------------

class BusinessDashboardScreen extends StatefulWidget {
  const BusinessDashboardScreen({super.key});
  @override
  State<BusinessDashboardScreen> createState() => _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends State<BusinessDashboardScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final titles = ['Good morning, Esha', 'Tasks', 'Profile'];
    final subtitles = ["Here's how your business is doing", 'Manage your to-dos', 'Manage your account'];
    final screens = [const _DashTab(), const _TasksTab(), const _ProfileTab()];

    return Scaffold(
      body: Column(
        children: [
          AppTopBar(title: titles[_tabIndex], subtitle: subtitles[_tabIndex], showBack: true),
          Expanded(child: screens[_tabIndex]),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        backgroundColor: AppTheme.navyDeep,
        indicatorColor: Colors.transparent,
        destinations: [
          NavigationDestination(icon: Icon(Icons.dashboard, color: _tabIndex == 0 ? AppTheme.forgeAmber : const Color(0xFF7C8CAD)), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.checklist, color: _tabIndex == 1 ? AppTheme.forgeAmber : const Color(0xFF7C8CAD)), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.person, color: _tabIndex == 2 ? AppTheme.forgeAmber : const Color(0xFF7C8CAD)), label: 'Profile'),
        ],
      ),
    );
  }
}

class _DashTab extends StatelessWidget {
  const _DashTab();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(child: _statCard('Revenue (MTD)', 'Rs 842K', '+12.4%')),
            const SizedBox(width: 10),
            Expanded(child: _statCard('Active Orders', '36', '+4')),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Recent activity', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.ink)),
        const SizedBox(height: 8),
        AppCard(
          child: Column(
            children: [
              _activityRow('Invoice #2291 generated', '2m ago', AppTheme.steelAccent),
              const Divider(height: 20),
              _activityRow('New order — Al-Noor Traders', '18m ago', AppTheme.forgeAmber),
              const Divider(height: 20),
              _activityRow('Inventory sync completed', '1h ago', AppTheme.steelAccent),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, String delta) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.slate)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppTheme.ink)),
        const SizedBox(height: 4),
        Text(delta, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.successGreen)),
      ],
    ),
  );

  Widget _activityRow(String name, String time, Color color) => Row(
    children: [
      Icon(Icons.check_circle, color: color, size: 16),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontSize: 13, color: AppTheme.ink)),
            Text(time, style: const TextStyle(fontSize: 11, color: AppTheme.slate)),
          ],
        ),
      ),
    ],
  );
}

class _TasksTab extends StatefulWidget {
  const _TasksTab();
  @override
  State<_TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<_TasksTab> {
  final List<Map<String, String>> _tasks = [
    {'title': 'Confirm supplier invoice', 'priority': 'High'},
    {'title': 'Review deployment logs', 'priority': 'Low'},
  ];

  @override
  Widget build(BuildContext context) {
    if (_tasks.isEmpty) {
      return const Center(child: Text('No tasks yet.', style: TextStyle(color: AppTheme.slate)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final t = _tasks[i];
        final color = t['priority'] == 'High' ? AppTheme.errorRed : (t['priority'] == 'Med' ? AppTheme.forgeAmber : AppTheme.steelAccent);
        return AppCard(
          child: Row(
            children: [
              AppBadge(label: t['priority']!, color: color),
              const SizedBox(width: 10),
              Expanded(child: Text(t['title']!, style: const TextStyle(fontSize: 13, color: AppTheme.ink))),
              IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.errorRed), onPressed: () => setState(() => _tasks.removeAt(i))),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(color: AppTheme.navyPrimary, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const Text('EA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Esha Arooh', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.ink)),
                Text('Business Owner · Sahiwal SME Hub', style: TextStyle(fontSize: 12, color: AppTheme.slate)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        AppCard(
          child: Row(
            children: const [
              Icon(Icons.settings_outlined, color: AppTheme.steelAccent, size: 18),
              SizedBox(width: 12),
              Expanded(child: Text('Business settings', style: TextStyle(fontSize: 13, color: AppTheme.ink))),
              Icon(Icons.chevron_right, color: Color(0xFFC4CAD6)),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// SCREEN 6 — Task List (standalone add/remove/validation/empty state)
// ---------------------------------------------------------------------------

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});
  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final List<String> _tasks = [];
  final _controller = TextEditingController();
  String? _error;

  void _add() {
    final text = _controller.text.trim();
    setState(() {
      if (text.isEmpty) {
        _error = "Task title can't be empty.";
      } else if (text.length < 3) {
        _error = 'Title must be at least 3 characters.';
      } else if (_tasks.contains(text)) {
        _error = 'This task already exists.';
      } else {
        _tasks.insert(0, text);
        _controller.clear();
        _error = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppTopBar(title: 'Task List', subtitle: _tasks.isEmpty ? 'No tasks yet' : '${_tasks.length} tasks', showBack: true),
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    label: 'Add a new task',
                    controller: _controller,
                    hint: 'e.g. Confirm supplier invoice',
                    icon: Icons.edit_outlined,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.error_outline, size: 14, color: AppTheme.errorRed),
                      const SizedBox(width: 4),
                      Text(_error!, style: const TextStyle(color: AppTheme.errorRed, fontSize: 12)),
                    ]),
                  ],
                  const SizedBox(height: 12),
                  AppButton(label: 'Add Task', onPressed: _add, icon: Icons.add),
                ],
              ),
            ),
          ),
          Expanded(
            child: _tasks.isEmpty
                ? const Center(child: Text('No tasks yet — add one above.', style: TextStyle(color: AppTheme.slate)))
                : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _tasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) => FadeSlideIn(
                index: i,
                child: AppCard(
                  child: Row(
                    children: [
                      Expanded(child: Text(_tasks[i], style: const TextStyle(fontSize: 13, color: AppTheme.ink))),
                      IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.errorRed), onPressed: () => setState(() => _tasks.removeAt(i))),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SCREEN 7 — Local Storage (shared_preferences — survives app restart)
// ---------------------------------------------------------------------------

class LocalStorageScreen extends StatefulWidget {
  const LocalStorageScreen({super.key});
  @override
  State<LocalStorageScreen> createState() => _LocalStorageScreenState();
}

class _LocalStorageScreenState extends State<LocalStorageScreen> {
  final _controller = TextEditingController();
  int _visitCount = 0;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final note = prefs.getString('business_note') ?? '';
    final count = (prefs.getInt('visit_count') ?? 0) + 1;
    await prefs.setInt('visit_count', count);
    setState(() {
      _controller.text = note;
      _visitCount = count;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('business_note', _controller.text);
    setState(() => _saved = true);
  }

  Future<void> _clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    setState(() {
      _controller.clear();
      _visitCount = 0;
      _saved = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AppTopBar(title: 'Business Notes', subtitle: 'Saved locally — persists across restarts', showBack: true),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCard(
                  child: Row(
                    children: [
                      const Icon(Icons.history, color: AppTheme.navyPrimary, size: 20),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('App opened', style: TextStyle(fontSize: 11, color: AppTheme.slate)),
                          Text('$_visitCount time${_visitCount == 1 ? '' : 's'}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.ink)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                AppTextField(label: 'Quick note', controller: _controller, hint: 'e.g. Follow up with Al-Noor Traders'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: AppButton(label: 'Save', onPressed: _save, icon: Icons.save)),
                    const SizedBox(width: 10),
                    Expanded(child: AppButton(label: 'Clear', onPressed: _clear, variant: AppButtonVariant.secondary, icon: Icons.delete_outline)),
                  ],
                ),
                if (_saved) ...[
                  const SizedBox(height: 10),
                  const Row(children: [
                    Icon(Icons.check_circle, color: AppTheme.successGreen, size: 14),
                    SizedBox(width: 6),
                    Text('Saved — close and reopen the app to verify it persists.', style: TextStyle(color: AppTheme.successGreen, fontSize: 11)),
                  ]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SCREEN 8 — Weather (API + navigation + persisted favorites)
// ---------------------------------------------------------------------------

class _City {
  final String name;
  final double lat, lon;
  const _City(this.name, this.lat, this.lon);
}

const _cities = [
  _City('Lahore', 31.55, 74.34),
  _City('Karachi', 24.86, 67.01),
  _City('Islamabad', 33.68, 73.05),
  _City('Sahiwal', 30.66, 73.10),
  _City('Dubai', 25.20, 55.27),
  _City('London', 51.51, -0.13),
];

class WeatherCitiesScreen extends StatefulWidget {
  const WeatherCitiesScreen({super.key});
  @override
  State<WeatherCitiesScreen> createState() => _WeatherCitiesScreenState();
}

class _WeatherCitiesScreenState extends State<WeatherCitiesScreen> {
  Set<String> _favorites = {};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _favorites = (prefs.getStringList('favorite_cities') ?? []).toSet());
  }

  Future<void> _toggleFavorite(String city) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (!_favorites.add(city)) _favorites.remove(city);
    });
    await prefs.setStringList('favorite_cities', _favorites.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppTopBar(title: 'Cities', subtitle: '${_favorites.length} favorite${_favorites.length == 1 ? '' : 's'} saved', showBack: true),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _cities.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final city = _cities[i];
                final isFav = _favorites.contains(city.name);
                return AppCard(
                  onTap: () => Navigator.push(
                    context,
                    animatedRoute(WeatherDetailScreen(city: city, isFavorite: isFav, onToggleFavorite: () => _toggleFavorite(city.name))),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: AppTheme.steelAccent, size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Text(city.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.ink))),
                      if (isFav) const Padding(padding: EdgeInsets.only(right: 8), child: Icon(Icons.star, color: AppTheme.forgeAmber, size: 18)),
                      const Icon(Icons.chevron_right, color: Color(0xFFC4CAD6)),
                    ],
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

class _WeatherResult {
  final double temp, wind;
  final String condition;
  _WeatherResult(this.temp, this.wind, this.condition);
}

String _weatherLabel(int code) {
  if (code == 0) return 'Clear sky';
  if (code <= 3) return 'Partly cloudy';
  if (code <= 48) return 'Fog';
  if (code <= 55) return 'Drizzle';
  if (code <= 65) return 'Rain';
  if (code <= 75) return 'Snow';
  if (code <= 82) return 'Rain showers';
  return 'Thunderstorm';
}

class WeatherDetailScreen extends StatefulWidget {
  final _City city;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  const WeatherDetailScreen({super.key, required this.city, required this.isFavorite, required this.onToggleFavorite});

  @override
  State<WeatherDetailScreen> createState() => _WeatherDetailScreenState();
}

class _WeatherDetailScreenState extends State<WeatherDetailScreen> {
  LoadState state = LoadState.loading;
  _WeatherResult? result;
  String errorMessage = '';
  late bool isFav;

  @override
  void initState() {
    super.initState();
    isFav = widget.isFavorite;
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => state = LoadState.loading);
    try {
      final url = 'https://api.open-meteo.com/v1/forecast?latitude=${widget.city.lat}&longitude=${widget.city.lon}&current_weather=true';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) throw Exception('Server error (${res.statusCode})');
      final current = jsonDecode(res.body)['current_weather'];
      setState(() {
        result = _WeatherResult(current['temperature'].toDouble(), current['windspeed'].toDouble(), _weatherLabel(current['weathercode']));
        state = LoadState.success;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        state = LoadState.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppTopBar(title: widget.city.name, subtitle: 'Live weather', showBack: true),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: KeyedSubtree(
                  key: ValueKey(state),
                  child: switch (state) {
                    LoadState.loading => const Center(child: CircularProgressIndicator(color: AppTheme.navyPrimary)),
                    LoadState.error => Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.cloud_off, color: AppTheme.errorRed, size: 48),
                        const SizedBox(height: 12),
                        const Text("Couldn't load weather", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.ink)),
                        const SizedBox(height: 4),
                        Text(errorMessage, style: const TextStyle(fontSize: 12, color: AppTheme.slate), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        SizedBox(width: 140, child: AppButton(label: 'Retry', onPressed: _fetch, icon: Icons.refresh)),
                      ]),
                    ),
                    LoadState.success => Column(
                      children: [
                        AppCard(
                          child: Column(
                            children: [
                              Text('${result!.temp.toInt()}°C', style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w600, color: AppTheme.ink)),
                              Text(result!.condition, style: const TextStyle(fontSize: 14, color: AppTheme.slate)),
                              const SizedBox(height: 12),
                              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                const Icon(Icons.air, color: AppTheme.steelAccent, size: 16),
                                const SizedBox(width: 6),
                                Text('${result!.wind} km/h wind', style: const TextStyle(fontSize: 12, color: AppTheme.slate)),
                              ]),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        AppButton(
                          label: isFav ? 'Saved to Favorites' : 'Save to Favorites',
                          onPressed: () {
                            widget.onToggleFavorite();
                            setState(() => isFav = !isFav);
                          },
                          variant: isFav ? AppButtonVariant.secondary : AppButtonVariant.primary,
                          icon: isFav ? Icons.star : Icons.star_border,
                        ),
                      ],
                    ),
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SCREEN 9 — Product List
//
// The task asked for React Native's FlatList — that's a React Native
// component with no Flutter equivalent by that name. The direct Flutter
// equivalent is ListView.builder, used below:
//
//   React Native (FlatList)              Flutter
//   ------------------------------       ------------------------------
//   <FlatList data={items}               ListView.builder(
//     renderItem={...}                     itemCount: items.length,
//     keyExtractor={...} />                itemBuilder: (ctx, i) => ...)
//
// Both only build/render the rows currently visible on screen (plus a small
// buffer) instead of the entire dataset at once — that's what makes a list
// of hundreds of items still scroll smoothly.
// ---------------------------------------------------------------------------

class Product {
  final String name;
  final String category;
  final String price;
  const Product(this.name, this.category, this.price);
}

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
            // ListView.builder only builds the widgets currently on/near
            // screen, not all 120 at once — this is what "efficient
            // scrolling bound to a data source" means in practice.
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

// ---------------------------------------------------------------------------
// SCREEN 10 — Browse Products (writes to shared state)
// ---------------------------------------------------------------------------

const _shopProducts = [
  ('Fabric Roll', 1200),
  ('Office Chair', 8500),
  ('Printer Ink', 950),
  ('Notebook Pack', 450),
];

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
              itemCount: _shopProducts.length,
              itemBuilder: (context, i) {
                final (name, price) = _shopProducts[i];
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

// ---------------------------------------------------------------------------
// SCREEN 11 — Cart (reads the same shared state)
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// SCREEN 12 — Team Tasks
//
// A different REST pattern from Clients (which creates/edits full records)
// and Weather (which is read-only): here, tapping a checkbox sends a PATCH
// request to update just one field (`completed`) on the server, with the
// checkbox optimistically flipping immediately and reverting if the request
// fails — a common real-world update pattern.
// ---------------------------------------------------------------------------

class TeamTask {
  final int id;
  final String title;
  bool completed;
  TeamTask({required this.id, required this.title, required this.completed});
}

// The API's /todos endpoint returns placeholder Latin-style filler text
// (e.g. "fugiat veniam minus") for titles — meaningless test data, not a
// real language. The id and completed status below are still the real
// values from the server; only the display title is swapped for a
// realistic business task name so the screen reads naturally.
const _realisticTaskTitles = [
  'Confirm supplier invoice — Metro Textiles',
  'Follow up with Al-Noor Traders',
  'Review Q3 inventory report',
  'Prepare client onboarding docs',
  'Approve staff leave requests',
  'Update product pricing sheet',
  'Schedule vendor site visit',
  'Reconcile monthly expenses',
  'Send payment reminder — invoice #2291',
  'Renew business insurance',
];

class TeamTasksScreen extends StatefulWidget {
  const TeamTasksScreen({super.key});
  @override
  State<TeamTasksScreen> createState() => _TeamTasksScreenState();
}

class _TeamTasksScreenState extends State<TeamTasksScreen> {
  LoadState state = LoadState.loading;
  List<TeamTask> tasks = [];
  String errorMessage = '';
  final Set<int> _updatingIds = {}; // tracks which rows show a small spinner while their PATCH is in flight

  static const _url = 'https://jsonplaceholder.typicode.com/todos';

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ---- FETCH (GET) ----
  Future<void> _load() async {
    setState(() => state = LoadState.loading);
    try {
      final res = await http.get(Uri.parse('$_url?_limit=10'));
      if (res.statusCode != 200) throw Exception('Server responded with ${res.statusCode}');
      final List data = jsonDecode(res.body);
      // The fake API never actually persists our PATCH updates — refetching
      // just returns its original static dataset. So we keep our own local
      // record of which ids the user has toggled, and apply it on top of
      // whatever the server returns, so taps don't get silently reset.
      final prefs = await SharedPreferences.getInstance();
      final overrides = prefs.getStringList('team_task_overrides') ?? [];
      final overrideMap = {for (var o in overrides) int.parse(o.split(':')[0]): o.split(':')[1] == '1'};

      setState(() {
        tasks = List.generate(data.length, (i) {
          final json = data[i];
          final id = json['id'] as int;
          return TeamTask(
            id: id,
            title: i < _realisticTaskTitles.length ? _realisticTaskTitles[i] : 'Task #$id',
            completed: overrideMap[id] ?? (json['completed'] ?? false),
          );
        });
        state = LoadState.success;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        state = LoadState.error;
      });
    }
  }

  // ---- UPDATE (PATCH) ----
  Future<void> _toggle(TeamTask task) async {
    final previous = task.completed;
    setState(() {
      task.completed = !task.completed; // optimistic UI update
      _updatingIds.add(task.id);
    });

    // Save locally right away — this is what actually makes the toggle
    // "stick" when you leave and come back, since the fake API won't.
    final prefs = await SharedPreferences.getInstance();
    final overrides = prefs.getStringList('team_task_overrides') ?? [];
    overrides.removeWhere((o) => o.startsWith('${task.id}:'));
    overrides.add('${task.id}:${task.completed ? '1' : '0'}');
    await prefs.setStringList('team_task_overrides', overrides);

    try {
      final res = await http.patch(
        Uri.parse('${_url}/${task.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'completed': task.completed}),
      );
      if (res.statusCode != 200) throw Exception('Update failed (${res.statusCode})');
    } catch (e) {
      // Revert on failure and tell the user — don't leave the UI showing a
      // state the server never actually confirmed.
      setState(() => task.completed = previous);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _updatingIds.remove(task.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppTopBar(title: 'Team Tasks', subtitle: state == LoadState.success ? '${tasks.where((t) => t.completed).length}/${tasks.length} completed' : 'Connected to REST API', showBack: true),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: KeyedSubtree(key: ValueKey(state), child: _body()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    switch (state) {
      case LoadState.loading:
        return const Center(child: CircularProgressIndicator(color: AppTheme.navyPrimary));
      case LoadState.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.cloud_off, color: AppTheme.errorRed, size: 48),
              const SizedBox(height: 12),
              const Text("Couldn't load tasks", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.ink)),
              const SizedBox(height: 4),
              Text(errorMessage, style: const TextStyle(fontSize: 12, color: AppTheme.slate), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              SizedBox(width: 140, child: AppButton(label: 'Retry', onPressed: _load, icon: Icons.refresh)),
            ]),
          ),
        );
      case LoadState.success:
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (ctx, i) {
            final task = tasks[i];
            final isUpdating = _updatingIds.contains(task.id);
            return FadeSlideIn(
              index: i,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  child: Row(
                    children: [
                      isUpdating
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.navyPrimary))
                          : Checkbox(
                        value: task.completed,
                        activeColor: AppTheme.navyPrimary,
                        onChanged: (_) => _toggle(task),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 13,
                            color: task.completed ? AppTheme.slate : AppTheme.ink,
                            decoration: task.completed ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
    }
  }
}

// ---------------------------------------------------------------------------
// SCREEN 13 — Business Photo (Camera + Image Picker)
//
// Lets the user capture a photo with the camera or choose one from the
// gallery. image_picker triggers Android's runtime permission prompt
// automatically the first time each is used; we just need to catch the
// case where the user denies it and show a clear message instead of
// crashing or silently doing nothing.
// ---------------------------------------------------------------------------

class ImagePickerScreen extends StatefulWidget {
  const ImagePickerScreen({super.key});
  @override
  State<ImagePickerScreen> createState() => _ImagePickerScreenState();
}

class _ImagePickerScreenState extends State<ImagePickerScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  String? _statusMessage;
  bool _isError = false;

  static const _prefsKey = 'business_photo_path';

  @override
  void initState() {
    super.initState();
    _loadSavedImage();
  }

  // Restores the previously saved photo (if any) when the screen opens —
  // same idea as the Business Notes screen, but storing a file path instead
  // of plain text.
  Future<void> _loadSavedImage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString(_prefsKey);
    if (savedPath != null && await File(savedPath).exists()) {
      setState(() => _selectedImage = File(savedPath));
    }
  }

  Future<void> _saveImagePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, path);
  }

  Future<void> _clearSavedImage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _statusMessage = null;
      _isError = false;
    });
    try {
      final XFile? picked = await _picker.pickImage(source: source, imageQuality: 80);
      if (picked == null) {
        setState(() => _statusMessage = 'No image selected.');
        return;
      }
      // image_picker's own path points into a temporary cache directory
      // that Android can clear at any time — copying it into the app's
      // permanent documents directory is what actually makes it stick
      // around, not just saving the raw picked path.
      final docsDir = await getApplicationDocumentsDirectory();
      final permanentPath = '${docsDir.path}/business_photo.jpg';
      final savedFile = await File(picked.path).copy(permanentPath);

      await _saveImagePath(savedFile.path);
      setState(() {
        _selectedImage = savedFile;
        _statusMessage = source == ImageSource.camera
            ? 'Photo captured and saved.'
            : 'Image selected and saved.';
      });
    } catch (e) {
      setState(() {
        _isError = true;
        _statusMessage = 'Could not access ${source == ImageSource.camera ? 'camera' : 'gallery'}. '
            'Please check app permissions in your device Settings.';
      });
    }
  }

  Future<void> _removeImage() async {
    await _clearSavedImage();
    setState(() {
      _selectedImage = null;
      _statusMessage = 'Photo removed.';
      _isError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AppTopBar(title: 'Business Photo', subtitle: 'Attach a photo of a receipt or product', showBack: true),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 240,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _selectedImage != null
                        ? Image.file(_selectedImage!, fit: BoxFit.cover)
                        : const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.image_outlined, size: 48, color: Color(0xFFC4CAD6)),
                          SizedBox(height: 8),
                          Text('No image selected yet', style: TextStyle(color: AppTheme.slate, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  if (_statusMessage != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(_isError ? Icons.error_outline : Icons.check_circle, size: 16, color: _isError ? AppTheme.errorRed : AppTheme.successGreen),
                        const SizedBox(width: 6),
                        Expanded(child: Text(_statusMessage!, style: TextStyle(fontSize: 12, color: _isError ? AppTheme.errorRed : AppTheme.successGreen))),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  AppButton(label: 'Take Photo', onPressed: () => _pickImage(ImageSource.camera), icon: Icons.camera_alt),
                  const SizedBox(height: 10),
                  AppButton(label: 'Choose from Gallery', onPressed: () => _pickImage(ImageSource.gallery), variant: AppButtonVariant.secondary, icon: Icons.photo_library_outlined),
                  if (_selectedImage != null) ...[
                    const SizedBox(height: 10),
                    AppButton(
                      label: 'Remove Photo',
                      onPressed: _removeImage,
                      variant: AppButtonVariant.danger,
                      icon: Icons.delete_outline,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

