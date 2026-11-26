import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'main.dart';

const minimumDonation = 5000;

class DonationAmountSheet extends StatefulWidget {
  const DonationAmountSheet({super.key});

  @override
  State<DonationAmountSheet> createState() => _DonationAmountSheetState();
}

class _DonationAmountSheetState extends State<DonationAmountSheet> {
  final customAmount = TextEditingController();
  int? selected;
  bool custom = false;

  int? get amount => custom ? int.tryParse(customAmount.text) : selected;

  @override
  void dispose() {
    customAmount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = amount;
    final valid = value != null && value >= minimumDonation;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Pilih nominal donasi', style: Theme.of(context).textTheme.titleLarge),
            const Text('Donasi diambil dari saldo aplikasi.'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final preset in [5000, 10000, 25000, 50000, 75000, 100000])
                  ChoiceChip(
                    label: Text(rp(preset)),
                    selected: !custom && selected == preset,
                    onSelected: (_) => setState(() {
                      FocusScope.of(context).unfocus();
                      custom = false;
                      selected = preset;
                    }),
                  ),
                ChoiceChip(
                  label: const Text('Nominal lain'),
                  selected: custom,
                  onSelected: (_) => setState(() => custom = true),
                ),
              ],
            ),
            if (custom) ...[
              const SizedBox(height: 12),
              TextField(
                autofocus: true,
                controller: customAmount,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
                decoration: InputDecoration(
                  labelText: 'Nominal donasi',
                  prefixText: 'Rp ',
                  helperText: 'Minimum ${rp(minimumDonation)}',
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: valid ? () => Navigator.of(context).pop(value) : null,
              icon: const Icon(Icons.favorite),
              label: Text(valid ? 'Donasi ${rp(value)}' : 'Donasi'),
            ),
          ],
        ),
      ),
    );
  }
}
