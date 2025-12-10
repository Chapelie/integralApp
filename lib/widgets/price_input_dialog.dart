/// Dialog pour saisir un prix avec pavé numérique
library;

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';

/// Dialog pour saisir un prix avec pavé numérique
class PriceInputDialog extends StatefulWidget {
  final String productName;
  final double? currentPrice;

  const PriceInputDialog({
    super.key,
    required this.productName,
    this.currentPrice,
  });

  @override
  State<PriceInputDialog> createState() => _PriceInputDialogState();
}

class _PriceInputDialogState extends State<PriceInputDialog> {
  final TextEditingController _priceController = TextEditingController();
  String _displayPrice = '0';

  @override
  void initState() {
    super.initState();
    if (widget.currentPrice != null && widget.currentPrice! > 0) {
      _displayPrice = widget.currentPrice!.toStringAsFixed(0);
      _priceController.text = _displayPrice;
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  void _onNumberPressed(String number) {
    setState(() {
      if (_displayPrice == '0') {
        _displayPrice = number;
      } else {
        _displayPrice += number;
      }
      _priceController.text = _displayPrice;
    });
  }

  void _onBackspace() {
    setState(() {
      if (_displayPrice.length > 1) {
        _displayPrice = _displayPrice.substring(0, _displayPrice.length - 1);
      } else {
        _displayPrice = '0';
      }
      _priceController.text = _displayPrice;
    });
  }

  void _onClear() {
    setState(() {
      _displayPrice = '0';
      _priceController.text = _displayPrice;
    });
  }

  String _formatPrice(String price) {
    final priceValue = double.tryParse(price) ?? 0.0;
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'XOF',
      decimalDigits: 0,
    );
    return formatter.format(priceValue);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final priceValue = double.tryParse(_displayPrice) ?? 0.0;

    return AlertDialog(
      title: Text('Prix pour ${widget.productName}'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Affichage du prix formaté
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colors.secondary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colors.border),
              ),
              child: Text(
                _formatPrice(_displayPrice),
                style: theme.typography.xl.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colors.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Pavé numérique
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.5,
              children: [
                _buildNumberButton('1', () => _onNumberPressed('1')),
                _buildNumberButton('2', () => _onNumberPressed('2')),
                _buildNumberButton('3', () => _onNumberPressed('3')),
                _buildNumberButton('4', () => _onNumberPressed('4')),
                _buildNumberButton('5', () => _onNumberPressed('5')),
                _buildNumberButton('6', () => _onNumberPressed('6')),
                _buildNumberButton('7', () => _onNumberPressed('7')),
                _buildNumberButton('8', () => _onNumberPressed('8')),
                _buildNumberButton('9', () => _onNumberPressed('9')),
                _buildNumberButton('C', _onClear, isAction: true),
                _buildNumberButton('0', () => _onNumberPressed('0')),
                _buildNumberButton('⌫', _onBackspace, isAction: true),
              ],
            ),
          ],
        ),
      ),
      actions: [
        FButton(
          onPress: () => Navigator.of(context).pop(null),
          style: FButtonStyle.outline(),
          child: const Text('Annuler'),
        ),
        const SizedBox(width: 8),
        FButton(
          onPress: priceValue > 0
              ? () => Navigator.of(context).pop(priceValue)
              : null,
          style: FButtonStyle.primary(),
          child: const Text('Valider'),
        ),
      ],
    );
  }

  Widget _buildNumberButton(String label, VoidCallback onPressed, {bool isAction = false}) {
    final theme = FTheme.of(context);
    return FButton(
      onPress: onPressed,
      style: isAction ? FButtonStyle.outline() : FButtonStyle.primary(),
      child: Text(
        label,
        style: theme.typography.lg.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}






