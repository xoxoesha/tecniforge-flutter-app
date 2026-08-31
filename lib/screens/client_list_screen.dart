import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/client_api.dart';
import '../theme/app_theme.dart';
import '../widgets/animations.dart';
import '../widgets/shared_widgets.dart';

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
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
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
                label: isSubmitting ? 'Saving...' : (existing == null ? 'Add' : 'Save'),
                onPressed: isSubmitting
                    ? () {}
                    : () async {
                  if (titleC.text.trim().isEmpty) return;
                  setSheetState(() => isSubmitting = true);
                  try {
                    if (existing == null) {
                      final c = await ClientApi.create(titleC.text.trim(), bodyC.text.trim());
                      if (!mounted) return;
                      Navigator.pop(ctx);
                      setState(() => clients.insert(0, c));
                      _snack('Client added');
                    } else {
                      await ClientApi.update(existing.id, titleC.text.trim(), bodyC.text.trim());
                      if (!mounted) return;
                      Navigator.pop(ctx);
                      setState(() {
                        existing.title = titleC.text.trim();
                        existing.body = bodyC.text.trim();
                      });
                      _snack('Client updated');
                    }
                  } catch (e) {
                    setSheetState(() => isSubmitting = false);
                    _snack('Failed: $e', isError: true);
                  }
                },
              ),
            ],
          ),
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
