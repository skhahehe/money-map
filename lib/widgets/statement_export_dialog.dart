import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../services/pdf_service.dart';
import '../widgets/bounce_button.dart';

class StatementExportDialog extends StatefulWidget {
  const StatementExportDialog({super.key});

  @override
  State<StatementExportDialog> createState() => _StatementExportDialogState();
}

class _StatementExportDialogState extends State<StatementExportDialog> {
  String _selectedPreset = '3m'; // Default to Last 3 Months
  late DateTime _fromDate;
  late DateTime _toDate;
  late DateTime _today;
  late DateTime _maxBackDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _maxBackDate = _today.subtract(const Duration(days: 365 * 5));
    _updateDatesFromPreset('3m');
  }

  void _updateDatesFromPreset(String preset) {
    setState(() {
      _selectedPreset = preset;
      _toDate = _today;
      if (preset == '2m') {
        _fromDate = DateTime(_today.year, _today.month - 2, _today.day);
      } else if (preset == '3m') {
        _fromDate = DateTime(_today.year, _today.month - 3, _today.day);
      } else if (preset == '6m') {
        _fromDate = DateTime(_today.year, _today.month - 6, _today.day);
      } else if (preset == '1y') {
        _fromDate = DateTime(_today.year - 1, _today.month, _today.day);
      }
      
      // Normalize _fromDate after calculation
      _fromDate = DateTime(_fromDate.year, _fromDate.month, _fromDate.day);
    });
  }

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final initialDate = isFrom ? _fromDate : _toDate;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: _maxBackDate,
      lastDate: _today,
    );

    if (picked != null) {
      setState(() {
        final normalized = DateTime(picked.year, picked.month, picked.day);
        if (isFrom) {
          _fromDate = normalized;
        } else {
          _toDate = normalized;
        }
        _selectedPreset = 'other';
      });
    }
  }

  bool get _isValidRange {
    return (_fromDate.isBefore(_toDate) || _fromDate.isAtSameMomentAs(_toDate)) &&
           (_fromDate.isBefore(_today) || _fromDate.isAtSameMomentAs(_today)) &&
           (_toDate.isBefore(_today) || _toDate.isAtSameMomentAs(_today));
  }

  String? get _errorText {
    if (_fromDate.isAfter(_toDate)) return 'From date must be before To date';
    if (_fromDate.isBefore(_maxBackDate)) return 'Maximum range is 5 years';
    return null;
  }

  Future<void> _handleExport({required bool isPrint}) async {
    if (!_isValidRange) return;

    final finance = context.read<FinanceProvider>();
    final transactions = finance.getTransactionsInRange(_fromDate, _toDate);

    if (transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions found in this range')),
      );
      return;
    }

    double income = 0;
    double expense = 0;
    for (var t in transactions) {
      if (t.isIncome) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }

    final rangeTitle = _selectedPreset == 'other'
        ? '${_fromDate.day}/${_fromDate.month}/${_fromDate.year} - ${_toDate.day}/${_toDate.month}/${_toDate.year}'
        : _getPresetLabel(_selectedPreset);

    Navigator.pop(context); // Close dialog

    if (isPrint) {
      await PdfService.printTransactionReport(
        transactions: transactions,
        totalIncome: income,
        totalExpense: expense,
        netBalance: income - expense,
        periodTitle: rangeTitle,
      );
    } else {
      await PdfService.saveTransactionReport(
        transactions: transactions,
        totalIncome: income,
        totalExpense: expense,
        netBalance: income - expense,
        periodTitle: rangeTitle,
      );
    }
  }

  String _getPresetLabel(String preset) {
    switch (preset) {
      case '2m': return 'Last 2 Months';
      case '3m': return 'Last 3 Months';
      case '6m': return 'Last 6 Months';
      case '1y': return 'Last 1 Year';
      default: return 'Custom Range';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Export Statement',
                style: TextStyle(
                  fontSize: 22, 
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Text(
            'Select Period', 
            style: TextStyle(
              fontWeight: FontWeight.w600, 
              color: theme.textTheme.bodySmall?.color ?? Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPresetChip(context, '2m', 'Last 2 Months'),
              _buildPresetChip(context, '3m', 'Last 3 Months'),
              _buildPresetChip(context, '6m', 'Last 6 Months'),
              _buildPresetChip(context, '1y', 'Last 1 Year'),
              _buildPresetChip(context, 'other', 'Custom'),
            ],
          ),
          
          if (_selectedPreset == 'other') ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildDatePickerField(context, 'From', _fromDate, () => _selectDate(context, true))),
                const SizedBox(width: 16),
                Expanded(child: _buildDatePickerField(context, 'To', _toDate, () => _selectDate(context, false))),
              ],
            ),
            if (_errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(_errorText!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
          ],
          
          const SizedBox(height: 32),
          
          Row(
            children: [
              Expanded(
                child: BounceButton(
                  onTap: _isValidRange ? () => _handleExport(isPrint: true) : null,
                  child: IgnorePointer(
                    ignoring: _isValidRange,
                    child: ElevatedButton.icon(
                      onPressed: _isValidRange ? () {} : null, // Enabled visually if range is valid
                      icon: const Icon(Icons.print),
                      label: const Text('Print'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BounceButton(
                  onTap: _isValidRange ? () => _handleExport(isPrint: false) : null,
                  child: IgnorePointer(
                    ignoring: _isValidRange,
                    child: ElevatedButton.icon(
                      onPressed: _isValidRange ? () {} : null, // Enabled visually if range is valid
                      icon: const Icon(Icons.save_alt),
                      label: const Text('Save PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPresetChip(BuildContext context, String value, String label) {
    final theme = Theme.of(context);
    final isSelected = _selectedPreset == value;
    final isDark = theme.brightness == Brightness.dark;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          if (value == 'other') {
            setState(() => _selectedPreset = 'other');
          } else {
            _updateDatesFromPreset(value);
          }
        }
      },
      selectedColor: Colors.blue.withValues(alpha: isDark ? 0.3 : 0.1),
      checkmarkColor: Colors.blue,
      labelStyle: TextStyle(
        color: isSelected 
            ? (isDark ? Colors.white : Colors.blue) 
            : (isDark ? Colors.white70 : Colors.black87),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected 
              ? Colors.blue 
              : (isDark ? Colors.white24 : Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildDatePickerField(BuildContext context, String label, DateTime date, VoidCallback onTap) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, 
          style: TextStyle(
            fontSize: 12, 
            color: theme.textTheme.bodySmall?.color ?? Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05),
              border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${date.day}/${date.month}/${date.year}', 
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Icon(Icons.calendar_today, size: 18, color: isDark ? Colors.blue.shade300 : Colors.blue),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
