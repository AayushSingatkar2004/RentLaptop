// lib/screens/customers/add_customer_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/router/app_router.dart';
import '../../data/models/laptop_model.dart';
import '../../providers/laptop_provider.dart';
import '../../providers/rental_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/due_provider.dart';
import '../../providers/dashboard_provider.dart';

class AddCustomerScreen extends ConsumerStatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  ConsumerState<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends ConsumerState<AddCustomerScreen> {
  int _step = 0;

  // Step 1 — Personal
  final _nameCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _addressCtrl = TextEditingController();
  String _idProofType = 'Aadhaar';
  final _idNumberCtrl = TextEditingController();

  // Step 2 — Laptop
  LaptopModel? _selectedLaptop;

  // Step 3 — Rental
  String _rentalType  = 'monthly';
  int _durationCount  = 1;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  // Step 4 — Amounts
  final _rentCtrl    = TextEditingController();
  final _depositCtrl = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose(); _addressCtrl.dispose();
    _idNumberCtrl.dispose(); _rentCtrl.dispose(); _depositCtrl.dispose();
    super.dispose();
  }

  DateTime _computedEndDate() {
    if (_rentalType == 'monthly') {
      return DateTime(_startDate.year, _startDate.month + _durationCount, _startDate.day);
    } else if (_rentalType == 'weekly') {
      return _startDate.add(Duration(days: 7 * _durationCount));
    }
    return _endDate ?? _startDate.add(const Duration(days: 30));
  }

  bool _validateStep() {
    switch (_step) {
      case 0:
        return _nameCtrl.text.isNotEmpty &&
            _phoneCtrl.text.length == 10 &&
            _addressCtrl.text.isNotEmpty &&
            _idNumberCtrl.text.isNotEmpty;
      case 1:
        return _selectedLaptop != null;
      case 2:
        if (_rentalType == 'manual') return _endDate != null;
        return _durationCount > 0;
      case 3:
        return _rentCtrl.text.isNotEmpty && _depositCtrl.text.isNotEmpty;
      default:
        return false;
    }
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final endDate = _computedEndDate();
      final body = {
        'name':             _nameCtrl.text.trim(),
        'phone':            _phoneCtrl.text.trim(),
        'address':          _addressCtrl.text.trim(),
        'id_proof_type':    _idProofType,
        'id_proof_number':  _idNumberCtrl.text.trim(),
        'laptop_id':        _selectedLaptop!.id,
        'rental_type':      _rentalType,
        'duration_count':   _rentalType != 'manual' ? _durationCount : null,
        'start_date':       DateFormat('yyyy-MM-dd').format(_startDate),
        'end_date':         _rentalType == 'manual'
            ? DateFormat('yyyy-MM-dd').format(_endDate!)
            : DateFormat('yyyy-MM-dd').format(endDate),
        'rent_amount':      double.parse(_rentCtrl.text),
        'deposit_amount':   double.parse(_depositCtrl.text),
      };

      await ref.read(rentalNotifierProvider.notifier).createRental(body);
      // Refresh all affected providers after rental creation
      ref.read(customersNotifierProvider.notifier).refresh();
      ref.invalidate(availableLaptopsProvider);
      ref.read(duesNotifierProvider.notifier).refresh();
      ref.invalidate(dashboardStatsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer & rental created!')));
        context.go(AppRoutes.customers);
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
      appBar: AppBar(title: const Text(AppStrings.addCustomer)),
      body: Column(children: [
        // Step indicator
        _StepIndicator(currentStep: _step, totalSteps: 4),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: [
              _buildStep1(),
              _buildStep2(),
              _buildStep3(),
              _buildStep4(),
            ][_step],
          ),
        ),
        // Navigation buttons
        _buildNavButtons(),
      ]),
    );
  }

  Widget _buildStep1() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _StepTitle('Step 1', 'Personal Information'),
      const SizedBox(height: 20),
      TextFormField(
        controller: _nameCtrl,
        decoration: const InputDecoration(labelText: AppStrings.customerName),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 14),
      TextFormField(
        controller: _phoneCtrl,
        keyboardType: TextInputType.phone,
        maxLength: 10,
        decoration: const InputDecoration(labelText: AppStrings.phone),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 14),
      TextFormField(
        controller: _addressCtrl,
        maxLines: 2,
        decoration: const InputDecoration(labelText: AppStrings.address),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 14),
      DropdownButtonFormField<String>(
        value: _idProofType,
        decoration: const InputDecoration(labelText: AppStrings.idProofType),
        items: ['Aadhaar', 'PAN', 'Passport', 'Driving License', 'Voter ID']
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) => setState(() => _idProofType = v!),
      ),
      const SizedBox(height: 14),
      TextFormField(
        controller: _idNumberCtrl,
        decoration: const InputDecoration(labelText: AppStrings.idProofNumber),
        onChanged: (_) => setState(() {}),
      ),
    ],
  );

  Widget _buildStep2() {
    final laptopsAsync = ref.watch(availableLaptopsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle('Step 2', 'Select Laptop'),
        const SizedBox(height: 20),
        laptopsAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text('Error: $e'),
          data: (laptops) {
            if (laptops.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.damaged.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.damaged.withOpacity(0.3)),
                ),
                child: const Row(children: [
                  Icon(Icons.warning_amber, color: AppColors.damaged),
                  SizedBox(width: 8),
                  Expanded(child: Text(AppStrings.noAvailableLaptops,
                    style: TextStyle(color: AppColors.damaged))),
                ]),
              );
            }
            return Column(
              children: laptops.map((l) => RadioListTile<LaptopModel>(
                value: l,
                groupValue: _selectedLaptop,
                onChanged: (v) => setState(() => _selectedLaptop = v),
                title: Text(l.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('UUID: ${l.uuid}  |  SN: ${l.serialNumber}',
                  style: const TextStyle(fontSize: 12)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: _selectedLaptop?.id == l.id
                        ? AppColors.primary : AppColors.divider,
                  ),
                ),
              )).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStep3() {
    final fmt = DateFormat('dd MMM yyyy');
    final endDate = _rentalType != 'manual' ? _computedEndDate() : _endDate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle('Step 3', 'Rental Details'),
        const SizedBox(height: 20),
        // Rental type selector
        Row(children: ['weekly', 'monthly', 'manual'].map((t) {
          return Expanded(child: GestureDetector(
            onTap: () => setState(() { _rentalType = t; _endDate = null; }),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _rentalType == t ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _rentalType == t
                    ? AppColors.primary : AppColors.divider),
              ),
              child: Text(t.capitalize(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _rentalType == t ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w600, fontSize: 13,
                ),
              ),
            ),
          ));
        }).toList()),
        const SizedBox(height: 20),

        // Start date
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.calendar_today_outlined, color: AppColors.primary),
          title: const Text(AppStrings.startDate),
          subtitle: Text(fmt.format(_startDate)),
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: _startDate,
              firstDate: DateTime.now().subtract(const Duration(days: 30)),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (d != null) setState(() => _startDate = d);
          },
        ),

        // Duration (weekly/monthly) or end date (manual)
        if (_rentalType != 'manual') ...[
          const SizedBox(height: 8),
          Row(children: [
            const Text('Duration: ', style: TextStyle(fontWeight: FontWeight.w500)),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: _durationCount > 1
                  ? () => setState(() => _durationCount--) : null,
            ),
            Text('$_durationCount ${_rentalType == 'weekly' ? 'week(s)' : 'month(s)'}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => setState(() => _durationCount++),
            ),
          ]),
          if (endDate != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                const Icon(Icons.event, color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Text('End Date: ${fmt.format(endDate)}',
                  style: const TextStyle(color: AppColors.primary,
                      fontWeight: FontWeight.w600)),
              ]),
            ),
        ] else ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event, color: AppColors.primary),
            title: const Text(AppStrings.endDate),
            subtitle: Text(_endDate != null ? fmt.format(_endDate!) : 'Tap to select'),
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _startDate.add(const Duration(days: 1)),
                firstDate: _startDate.add(const Duration(days: 1)),
                lastDate: DateTime.now().add(const Duration(days: 730)),
              );
              if (d != null) setState(() => _endDate = d);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildStep4() {
    final fmt = DateFormat('dd MMM yyyy');
    final endDate = _computedEndDate();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle('Step 4', 'Amounts & Summary'),
        const SizedBox(height: 20),
        TextFormField(
          controller: _rentCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: AppStrings.rentAmount),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _depositCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: AppStrings.depositAmount),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 24),
        // Summary card
        if (_rentCtrl.text.isNotEmpty && _depositCtrl.text.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rental Summary',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                const Divider(height: 16),
                _SummaryRow('Customer', _nameCtrl.text),
                _SummaryRow('Phone',    _phoneCtrl.text),
                _SummaryRow('Laptop',   _selectedLaptop?.displayName ?? '-'),
                _SummaryRow('Type',     _rentalType.capitalize()),
                _SummaryRow('Start',    fmt.format(_startDate)),
                _SummaryRow('End',      fmt.format(_rentalType == 'manual' && _endDate != null
                    ? _endDate! : endDate)),
                _SummaryRow('Rent',     '₹${_rentCtrl.text}/cycle'),
                _SummaryRow('Deposit',  '₹${_depositCtrl.text}'),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildNavButtons() => Container(
    padding: const EdgeInsets.all(16),
    decoration: const BoxDecoration(
      color: AppColors.surface,
      border: Border(top: BorderSide(color: AppColors.divider)),
    ),
    child: Row(children: [
      if (_step > 0)
        Expanded(child: OutlinedButton(
          onPressed: () => setState(() => _step--),
          child: const Text(AppStrings.back),
        )),
      if (_step > 0) const SizedBox(width: 12),
      Expanded(child: ElevatedButton(
        onPressed: _validateStep()
            ? () {
                if (_step < 3) {
                  // Refresh available laptops every time step 2 is entered
                  if (_step == 0) ref.invalidate(availableLaptopsProvider);
                  setState(() => _step++);
                } else {
                  _submit();
                }
              }
            : null,
        child: _loading
            ? const SizedBox(height: 20, width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(_step < 3 ? AppStrings.next : AppStrings.save),
      )),
    ]),
  );
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  const _StepIndicator({required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.surface,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    child: Row(
      children: List.generate(totalSteps, (i) => Expanded(child: Row(children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: i <= currentStep ? AppColors.primary : AppColors.divider,
          child: Text('${i + 1}',
            style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700,
              color: i <= currentStep ? Colors.white : AppColors.textHint,
            )),
        ),
        if (i < totalSteps - 1)
          Expanded(child: Container(
            height: 2,
            color: i < currentStep ? AppColors.primary : AppColors.divider,
          )),
      ]))),
    ),
  );
}

class _StepTitle extends StatelessWidget {
  final String step;
  final String title;
  const _StepTitle(this.step, this.title);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(step, style: const TextStyle(fontSize: 12, color: AppColors.primary,
          fontWeight: FontWeight.w600)),
      Text(title, style: Theme.of(context).textTheme.headlineSmall),
    ],
  );
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      SizedBox(width: 80, child: Text(label,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
      Expanded(child: Text(value,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
            color: AppColors.textPrimary))),
    ]),
  );
}

extension StringCapExt on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}