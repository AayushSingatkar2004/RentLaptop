// lib/screens/laptops/add_laptop_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/router/app_router.dart';
import '../../data/repositories/laptop_repository.dart';
import '../../providers/laptop_provider.dart';

class AddLaptopScreen extends ConsumerStatefulWidget {
  const AddLaptopScreen({super.key});

  @override
  ConsumerState<AddLaptopScreen> createState() => _AddLaptopScreenState();
}

class _AddLaptopScreenState extends ConsumerState<AddLaptopScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _uuidCtrl    = TextEditingController();
  final _serialCtrl  = TextEditingController();
  final _modelCtrl   = TextEditingController();
  final _brandCtrl   = TextEditingController();
  final _notesCtrl   = TextEditingController();
  String _status     = 'available';
  bool _loading      = false;
  String? _uuidError;
  String? _serialError;

  @override
  void initState() {
    super.initState();
    // Auto-generate a UUID
    _uuidCtrl.text = const Uuid().v4();
  }

  @override
  void dispose() {
    _uuidCtrl.dispose(); _serialCtrl.dispose();
    _modelCtrl.dispose(); _brandCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkUniqueness() async {
    final repo = ref.read(laptopRepositoryProvider);
    final uuidOk = await repo.isUuidUnique(_uuidCtrl.text.trim());
    final serialOk = await repo.isSerialUnique(_serialCtrl.text.trim());
    setState(() {
      _uuidError   = uuidOk ? null : 'This UUID is already used';
      _serialError = serialOk ? null : 'This serial number already exists';
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await _checkUniqueness();
    if (_uuidError != null || _serialError != null) return;

    setState(() => _loading = true);
    try {
      await ref.read(laptopRepositoryProvider).addLaptop(
        uuid:         _uuidCtrl.text.trim(),
        serialNumber: _serialCtrl.text.trim(),
        model:        _modelCtrl.text.trim(),
        brand:        _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
        status:       _status,
        notes:        _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      ref.read(laptopsNotifierProvider.notifier).refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Laptop added successfully!')));
        context.go(AppRoutes.laptops);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'), backgroundColor: AppColors.damaged));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.addLaptop)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(children: [
            // UUID
            TextFormField(
              controller: _uuidCtrl,
              decoration: InputDecoration(
                labelText: AppStrings.laptopUUID,
                errorText: _uuidError,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Generate new UUID',
                  onPressed: () => setState(() => _uuidCtrl.text = const Uuid().v4()),
                ),
              ),
              validator: (v) => v == null || v.isEmpty ? 'UUID is required' : null,
            ),
            const SizedBox(height: 14),

            // Serial number
            TextFormField(
              controller: _serialCtrl,
              decoration: InputDecoration(
                labelText: AppStrings.serialNumber,
                errorText: _serialError,
              ),
              validator: (v) => v == null || v.isEmpty ? 'Serial number is required' : null,
            ),
            const SizedBox(height: 14),

            // Model
            TextFormField(
              controller: _modelCtrl,
              decoration: const InputDecoration(labelText: AppStrings.model),
              validator: (v) => v == null || v.isEmpty ? 'Model is required' : null,
            ),
            const SizedBox(height: 14),

            // Brand
            TextFormField(
              controller: _brandCtrl,
              decoration: const InputDecoration(labelText: AppStrings.brand),
            ),
            const SizedBox(height: 14),

            // Initial status
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Initial Status'),
              items: [
                const DropdownMenuItem(value: 'available', child: Text('Available')),
                const DropdownMenuItem(value: 'damaged',   child: Text('Damaged')),
                const DropdownMenuItem(value: 'under_repair', child: Text('Under Repair')),
              ],
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 14),

            // Notes
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: AppStrings.notes),
            ),
            const SizedBox(height: 28),

            ElevatedButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text(AppStrings.save),
            ),
          ]),
        ),
      ),
    );
  }
}