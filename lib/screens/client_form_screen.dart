import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

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
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _business.dispose();
    _password.dispose();
    super.dispose();
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
