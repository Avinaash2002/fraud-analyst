/// FraudX Analyst - Train Screen
/// =================================

import 'package:flutter/material.dart';

class TrainScreen extends StatefulWidget {
  const TrainScreen({super.key});
  @override
  State<TrainScreen> createState() => _TrainScreenState();
}

class _TrainScreenState extends State<TrainScreen> {
  String? _selectedDataset = 'creditcard';
  bool _isTraining = false;
  String? _trainingStatus;
  bool _showResults = false;

  // Mock results after training completes
  final List<Map<String, dynamic>> _trainingResults = [
    {'name': 'LightGBM', 'accuracy': 0.9995, 'precision': 0.8732, 'recall': 0.8378, 'f1': 0.8552, 'auc': 0.9660, 'color': const Color(0xFF3B82F6), 'best': true},
    {'name': 'XGBoost', 'accuracy': 0.9995, 'precision': 0.8696, 'recall': 0.8108, 'f1': 0.8392, 'auc': 0.9637, 'color': const Color(0xFFF59E0B), 'best': false},
    {'name': 'Autoencoder', 'accuracy': 0.9982, 'precision': 0.4795, 'recall': 0.4730, 'f1': 0.4762, 'auc': 0.9495, 'color': const Color(0xFFEF4444), 'best': false},
  ];

  final List<Map<String, String>> _datasets = [
    {'id': 'creditcard', 'name': 'Credit Card\nFraud', 'description': 'European cardholders, Sept 2013', 'count': '284,807'},
  ];

  final List<Map<String, dynamic>> _models = [
    {'name': 'XGBoost', 'color': const Color(0xFFF59E0B)},
    {'name': 'LightGBM', 'color': const Color(0xFF3B82F6)},
    {'name': 'Autoencoder', 'color': const Color(0xFFEF4444)},
  ];

  Future<void> _startTraining() async {
    setState(() { _isTraining = true; _trainingStatus = 'Preparing data…'; _showResults = false; });
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _trainingStatus = 'Training XGBoost…');
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _trainingStatus = 'Training LightGBM…');
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _trainingStatus = 'Training Autoencoder…');
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _trainingStatus = 'Computing metrics…');
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() { _isTraining = false; _trainingStatus = null; _showResults = true; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Row(children: [
                Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)]),
                  child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Color(0xFF1A1A2E))),
                const SizedBox(width: 16),
                const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Train Models', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
                  SizedBox(height: 2),
                  Text('Select dataset & run all models', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
                ]),
              ]),
            ),

            // ── Show Results or Selection ────────────────────────
            if (_showResults)
              _buildResults()
            else
              _buildSelection(),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelection() {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── Select Dataset ───────────────────────────────────
      Row(children: [
        const Icon(Icons.storage, size: 20, color: Color(0xFF2A9D8F)),
        const SizedBox(width: 8),
        const Text('Select Dataset', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
      ]),
      const SizedBox(height: 14),
      ..._datasets.map((ds) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GestureDetector(
          onTap: () => setState(() => _selectedDataset = ds['id']),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _selectedDataset == ds['id'] ? const Color(0xFF2A9D8F) : Colors.transparent, width: 2),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
            child: Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFE0F2F1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.storage, size: 20, color: Color(0xFF2A9D8F))),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(ds['name']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E), height: 1.2)),
                const SizedBox(height: 2),
                Text(ds['description']!, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(ds['count']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF2A9D8F))),
                const Text('transactions', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
              ]),
            ]),
          ),
        ),
      )),

      // Custom Dataset
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
        child: Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.upload_file, size: 20, color: Color(0xFF6B7280))),
          const SizedBox(width: 14),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Custom\nDataset', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E), height: 1.2)),
            SizedBox(height: 2),
            Text('CSV format supported', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          ])),
          const Text('Upload your\nown', textAlign: TextAlign.end, style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        ]),
      ),
      const SizedBox(height: 28),

      // ── Models to Train ──────────────────────────────────
      Row(children: [
        const Icon(Icons.bar_chart, size: 20, color: Color(0xFF2A9D8F)),
        const SizedBox(width: 8),
        const Text('Models to Train', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
      ]),
      const SizedBox(height: 14),
      Wrap(spacing: 12, runSpacing: 12, children: _models.map((m) => Container(
        width: (MediaQuery.of(context).size.width - 52) / 2,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))]),
        child: Row(children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: m['color'] as Color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text(m['name'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)))),
        ]),
      )).toList()),
      const SizedBox(height: 32),

      // ── Training Status ──────────────────────────────────
      if (_isTraining && _trainingStatus != null)
        Container(
          width: double.infinity, padding: const EdgeInsets.all(16), margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: const Color(0xFFE0F2F1), borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2A9D8F))),
            const SizedBox(width: 12),
            Text(_trainingStatus!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2A9D8F))),
          ]),
        ),

      // ── Start Training Button ────────────────────────────
      SizedBox(width: double.infinity, height: 56,
        child: ElevatedButton(
          onPressed: _isTraining ? null : _startTraining,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2A9D8F), foregroundColor: Colors.white, disabledBackgroundColor: const Color(0xFF2A9D8F).withOpacity(0.5), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.play_arrow, size: 22), SizedBox(width: 8),
            Text('Start Training', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
      const SizedBox(height: 24),
    ]));
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  Training Results Screen
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildResults() {
    final best = _trainingResults.firstWhere((m) => m['best'] == true);
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── Success Banner ────────────────────────────────────
      Container(
        width: double.infinity, padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 24),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Training Complete!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32))),
            Text('All 3 models evaluated on test set', style: TextStyle(fontSize: 13, color: Colors.green.shade700)),
          ])),
        ]),
      ),
      const SizedBox(height: 16),

      // ── Best Model Badge ──────────────────────────────────
      Container(
        width: double.infinity, padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF2A9D8F), Color(0xFF4ECDC4)]),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.emoji_events, size: 24, color: Colors.white)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Best Model', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white70)),
            Text(best['name'] as String, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            const Text('F1 Score', style: TextStyle(fontSize: 11, color: Colors.white70)),
            Text('${((best['f1'] as double) * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
          ]),
        ]),
      ),
      const SizedBox(height: 20),

      // ── Metrics Table ─────────────────────────────────────
      const Text('Model Performance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
      const SizedBox(height: 12),
      ..._trainingResults.map((m) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: (m['best'] as bool) ? Border.all(color: const Color(0xFF2A9D8F), width: 2) : null,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: m['color'] as Color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(m['name'] as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
            if (m['best'] as bool) ...[
              const SizedBox(width: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFE0F2F1), borderRadius: BorderRadius.circular(8)),
                child: const Text('BEST', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF2A9D8F)))),
            ],
          ]),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _MiniMetric('Accuracy', ((m['accuracy'] as double) * 100).toStringAsFixed(1)),
            _MiniMetric('Precision', ((m['precision'] as double) * 100).toStringAsFixed(1)),
            _MiniMetric('Recall', ((m['recall'] as double) * 100).toStringAsFixed(1)),
            _MiniMetric('F1', ((m['f1'] as double) * 100).toStringAsFixed(1)),
            _MiniMetric('AUC', (m['auc'] as double).toStringAsFixed(3)),
          ]),
        ]),
      )),
      const SizedBox(height: 16),

      // ── Comparison Bars ───────────────────────────────────
      const Text('F1 Score Comparison', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
      const SizedBox(height: 12),
      ..._trainingResults.map((m) {
        final f1 = m['f1'] as double;
        return Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [
          SizedBox(width: 80, child: Text(m['name'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)))),
          const SizedBox(width: 8),
          Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: f1, minHeight: 16, backgroundColor: const Color(0xFFF3F4F6), color: m['color'] as Color))),
          const SizedBox(width: 10),
          SizedBox(width: 50, child: Text('${(f1 * 100).toStringAsFixed(1)}%', textAlign: TextAlign.end, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)))),
        ]));
      }),
      const SizedBox(height: 20),

      // ── Action Buttons ────────────────────────────────────
      Row(children: [
        Expanded(child: SizedBox(height: 50, child: OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF export coming soon!'), backgroundColor: Color(0xFF2A9D8F)));
          },
          icon: const Icon(Icons.picture_as_pdf, size: 20),
          label: const Text('Download PDF', style: TextStyle(fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF2A9D8F), side: const BorderSide(color: Color(0xFF2A9D8F)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        ))),
        const SizedBox(width: 12),
        Expanded(child: SizedBox(height: 50, child: ElevatedButton.icon(
          onPressed: () => setState(() => _showResults = false),
          icon: const Icon(Icons.refresh, size: 20),
          label: const Text('Train Again', style: TextStyle(fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2A9D8F), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        ))),
      ]),
      const SizedBox(height: 24),
    ]));
  }
}

class _MiniMetric extends StatelessWidget {
  final String label, value;
  const _MiniMetric(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF2A9D8F))),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
    ]);
  }
}
