/// FraudX Analyst - Simulate Screen
/// ===================================

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../config/api_config.dart';

class SimulateScreen extends StatefulWidget {
  const SimulateScreen({super.key});
  @override
  State<SimulateScreen> createState() => _SimulateScreenState();
}

class _SimulateScreenState extends State<SimulateScreen> {
  final _amountController = TextEditingController(text: '1250.00');
  final _timeController = TextEditingController(text: '14:32');
  final _cardController = TextEditingController(text: 'Visa ****');
  final _locationController = TextEditingController(text: 'New York, USA');

  String _selectedModel = 'Best Model';

  final Map<String, String> _modelDescriptions = {
    'Best Model': 'Auto-select highest F1 score',
    'XGBoost': 'Gradient boosting ensemble',
    'LightGBM': 'Light gradient boosting',
    'Autoencoder': 'Deep learning anomaly',
  };

  @override
  void dispose() {
    _amountController.dispose();
    _timeController.dispose();
    _cardController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  String _resolveModelName(AppProvider provider) {
    if (_selectedModel == 'Best Model') {
      return provider.bestModel?.modelName ?? 'LightGBM';
    }
    return _selectedModel;
  }

  Future<void> _analyzeTransaction() async {
    final provider = context.read<AppProvider>();
    final timeParts = _timeController.text.split(':');
    double timeSeconds = 0;
    if (timeParts.length == 2) {
      timeSeconds = (double.tryParse(timeParts[0]) ?? 0) * 3600 + (double.tryParse(timeParts[1]) ?? 0) * 60;
    }
    final random = Random();
    final features = <String, double>{};
    for (int i = 1; i <= 28; i++) {
      features['V$i'] = (random.nextDouble() * 4) - 2;
    }
    final request = PredictRequest(
      modelName: _resolveModelName(provider),
      amount: double.tryParse(_amountController.text) ?? 0,
      time: timeSeconds,
      features: features,
      deviceId: ApiConfig.deviceId,
      cardNumber: _cardController.text,
      location: _locationController.text,
    );
    await provider.runSimulation(request);
    if (mounted) {
      if (provider.lastPrediction != null) {
        _showResultSheet(context, provider.lastPrediction!);
      } else if (provider.simulationError != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${provider.simulationError}'), backgroundColor: const Color(0xFFEF4444)));
      }
    }
  }

  void _showResultSheet(BuildContext context, PredictResponse result) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => _ResultSheet(result: result),
    );
  }

  void _showModelPicker() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Select ML Model', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 16),
          ..._modelDescriptions.entries.map((entry) => ListTile(
            onTap: () { setState(() => _selectedModel = entry.key); Navigator.pop(ctx); },
            leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFE0F2F1), borderRadius: BorderRadius.circular(12)),
              child: Icon(entry.key == 'Best Model' ? Icons.auto_awesome : Icons.psychology, size: 20, color: const Color(0xFF2A9D8F))),
            title: Text(entry.key, style: TextStyle(fontWeight: FontWeight.w600, color: _selectedModel == entry.key ? const Color(0xFF2A9D8F) : const Color(0xFF1A1A2E))),
            subtitle: Text(entry.value),
            trailing: _selectedModel == entry.key ? const Icon(Icons.check_circle, color: Color(0xFF2A9D8F)) : null,
          )),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSimulating = context.watch<AppProvider>().isSimulating;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Header ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Row(children: [
                Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)]),
                  child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Color(0xFF1A1A2E))),
                const SizedBox(width: 16),
                const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Simulate\nTransaction', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E), height: 1.15)),
                  SizedBox(height: 4),
                  Text('Test fraud detection models', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
                ]),
              ]),
            ),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── Model Selector ──────────────────────────────────
              const Text('Select ML Model', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _showModelPicker,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
                  child: Row(children: [
                    Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFE0F2F1), borderRadius: BorderRadius.circular(12)),
                      child: Icon(_selectedModel == 'Best Model' ? Icons.auto_awesome : Icons.psychology, size: 20, color: const Color(0xFF2A9D8F))),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_selectedModel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                      Text(_modelDescriptions[_selectedModel] ?? '', style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                    ])),
                    const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6B7280)),
                  ]),
                ),
              ),
              const SizedBox(height: 28),

              // ── Transaction Details ──────────────────────────────
              const Text('Transaction Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
              const SizedBox(height: 16),
              const Text('Amount', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280))),
              const SizedBox(height: 6),
              _InputField(controller: _amountController, prefixIcon: Icons.attach_money, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Time', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280))),
                  const SizedBox(height: 6),
                  _InputField(controller: _timeController, prefixIcon: Icons.access_time),
                ])),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Card', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280))),
                  const SizedBox(height: 6),
                  _InputField(controller: _cardController, prefixIcon: Icons.credit_card),
                ])),
              ]),
              const SizedBox(height: 16),
              const Text('Location', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280))),
              const SizedBox(height: 6),
              _InputField(controller: _locationController, prefixIcon: Icons.location_on_outlined),
              const SizedBox(height: 32),

              // ── Analyze Button ──────────────────────────────────
              SizedBox(width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: isSimulating ? null : _analyzeTransaction,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2A9D8F), foregroundColor: Colors.white, disabledBackgroundColor: const Color(0xFF2A9D8F).withOpacity(0.5), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: isSimulating
                      ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)), SizedBox(width: 12), Text('Analyzing…', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700))])
                      : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.play_arrow, size: 22), SizedBox(width: 8), Text('Analyze Transaction', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700))]),
                ),
              ),
              const SizedBox(height: 24),
            ])),
          ]),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller; final IconData prefixIcon; final TextInputType? keyboardType;
  const _InputField({required this.controller, required this.prefixIcon, this.keyboardType});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: TextField(controller: controller, keyboardType: keyboardType,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E)),
        decoration: InputDecoration(prefixIcon: Icon(prefixIcon, size: 20, color: const Color(0xFF9CA3AF)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14))),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Result Sheet — with Sim ID, DateTime, SHAP bars, Ask Chatbot button
// ══════════════════════════════════════════════════════════════════════════════

class _ResultSheet extends StatelessWidget {
  final PredictResponse result;
  const _ResultSheet({required this.result});

  @override
  Widget build(BuildContext context) {
    final isFraud = result.isFraud;
    return DraggableScrollableSheet(
      initialChildSize: 0.85, minChildSize: 0.5, maxChildSize: 0.95,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),

              // ── Verdict Badge ──────────────────────────────────
              Center(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(color: isFraud ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(isFraud ? Icons.warning_amber : Icons.check_circle, color: isFraud ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32)),
                  const SizedBox(width: 8),
                  Text(isFraud ? 'FRAUD DETECTED' : 'SAFE TRANSACTION', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isFraud ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32))),
                ]),
              )),
              const SizedBox(height: 20),

              // ── Simulation ID & DateTime ───────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Simulation ID', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                    const SizedBox(height: 2),
                    Text(result.simulationId.length > 12 ? result.simulationId.substring(0, 12) : result.simulationId, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
                  ])),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    const Text('Date / Time', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                    const SizedBox(height: 2),
                    Text(_formatNow(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
                  ])),
                ]),
              ),
              const SizedBox(height: 16),

              // ── Scores ─────────────────────────────────────────
              _ResultRow(label: 'Risk Score', value: '${(result.riskScore * 100).toStringAsFixed(1)}%'),
              _ResultRow(label: 'Confidence', value: '${(result.confidenceScore * 100).toStringAsFixed(1)}%'),
              _ResultRow(label: 'Processing Time', value: '${result.processingTime.toStringAsFixed(0)}ms'),
              const SizedBox(height: 20),

              // ── SHAP Feature Importance Bar Chart ──────────────
              const Text('Feature Importance (SHAP)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
              const SizedBox(height: 12),
              ...result.topFeatures.take(7).map((f) {
                final absImpact = f.impact.abs();
                final maxImpact = result.topFeatures.first.impact.abs();
                final barWidth = maxImpact > 0 ? (absImpact / maxImpact) : 0.0;
                final isPositive = f.impact > 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    SizedBox(width: 50, child: Text(f.feature, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Stack(children: [
                        Container(height: 18, decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(4))),
                        FractionallySizedBox(widthFactor: barWidth.clamp(0.0, 1.0),
                          child: Container(height: 18, decoration: BoxDecoration(
                            color: isPositive ? const Color(0xFFEF4444).withOpacity(0.7) : const Color(0xFF2A9D8F).withOpacity(0.7),
                            borderRadius: BorderRadius.circular(4)))),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(width: 55, child: Text(f.impact.toStringAsFixed(4), textAlign: TextAlign.end, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isPositive ? const Color(0xFFEF4444) : const Color(0xFF2A9D8F)))),
                  ]),
                );
              }),
              const SizedBox(height: 20),

              // ── AI Explanation ──────────────────────────────────
              const Text('AI Explanation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(12)),
                child: Text(result.aiExplanation, style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF374151))),
              ),
              const SizedBox(height: 20),

              // ── Ask Chatbot About This ─────────────────────────
              SizedBox(width: double.infinity, height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // close sheet
                    context.read<AppProvider>().askChatbotAboutSimulation(result.simulationId);
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 20),
                  label: const Text('Ask Chatbot About This', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2A9D8F),
                    side: const BorderSide(color: Color(0xFF2A9D8F), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ]),
          ),
        );
      },
    );
  }

  String _formatNow() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}

class _ResultRow extends StatelessWidget {
  final String label, value;
  const _ResultRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
      Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
    ]));
  }
}
