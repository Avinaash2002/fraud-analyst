/// FraudX Analyst - Home Screen
/// ===============================
/// Matches Lovable: gradient hero with decorative circles, stat cards
/// with correct colors (white/red/green/blue), staggered animations

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'user_guide_screen.dart';

// ── Lovable palette ─────────────────────────────────────────────────────────
const _kGreenTeal = Color(0xFF2A9D8F);
const _kSkyBlue = Color(0xFF38BDF8);
const _kLightGreen = Color(0xFF6BCB77);
const _kRed = Color(0xFFEF4444);
const _kGreen = Color(0xFF4CAF50);
const _kBlue = Color(0xFF3B82F6);
const _kDark = Color(0xFF1A1A2E);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..forward();
  }

  @override
  void dispose() { _entrance.dispose(); super.dispose(); }

  // Staggered slide-up animation helper
  Animation<Offset> _slideUp(double start, double end) {
    return Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _entrance, curve: Interval(start, end, curve: Curves.easeOut)));
  }
  Animation<double> _fade(double start, double end) {
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entrance, curve: Interval(start, end, curve: Curves.easeOut)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Consumer<AppProvider>(
          builder: (context, provider, _) {
            if (provider.isLoadingModels) {
              return const Center(child: CircularProgressIndicator(color: _kGreenTeal));
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────────────────────
                  SlideTransition(
                    position: _slideUp(0.0, 0.3),
                    child: FadeTransition(
                      opacity: _fade(0.0, 0.3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(children: [
                            Text('FraudX Analyst', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: _kDark)),
                            SizedBox(width: 6),
                            Text('🛡️', style: TextStyle(fontSize: 18)),
                          ]),
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const UserGuideScreen()),
                            ),
                            child: Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white, shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
                                border: Border.all(color: Colors.grey.shade200.withOpacity(0.5)),
                              ),
                              child: const Center(child: Icon(Icons.info_outline, size: 22, color: _kDark)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Hero Card ───────────────────────────────────
                  SlideTransition(
                    position: _slideUp(0.1, 0.4),
                    child: FadeTransition(
                      opacity: _fade(0.1, 0.4),
                      child: _buildHeroCard(provider),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Stats Grid ──────────────────────────────────
                  Row(children: [
                    // Safe Today — WHITE card
                    Expanded(child: SlideTransition(
                      position: _slideUp(0.2, 0.5),
                      child: FadeTransition(opacity: _fade(0.2, 0.5), child: _buildSafeTodayCard()),
                    )),
                    const SizedBox(width: 12),
                    // Fraud Blocked — RED card
                    Expanded(child: SlideTransition(
                      position: _slideUp(0.25, 0.55),
                      child: FadeTransition(opacity: _fade(0.25, 0.55), child: _buildFraudBlockedCard()),
                    )),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    // Accuracy — GREEN card
                    Expanded(child: SlideTransition(
                      position: _slideUp(0.3, 0.6),
                      child: FadeTransition(opacity: _fade(0.3, 0.6), child: _buildAccuracyCard(provider)),
                    )),
                    const SizedBox(width: 12),
                    // Model Score — BLUE card
                    Expanded(child: SlideTransition(
                      position: _slideUp(0.35, 0.65),
                      child: FadeTransition(opacity: _fade(0.35, 0.65), child: _buildModelScoreCard(provider)),
                    )),
                  ]),
                  const SizedBox(height: 24),

                  // ── Recent Transactions ─────────────────────────
                  SlideTransition(
                    position: _slideUp(0.4, 0.7),
                    child: FadeTransition(
                      opacity: _fade(0.4, 0.7),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kDark)),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pushNamed('/history'),
                          child: const Text('View All', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kGreenTeal)),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...[
                    {'id': '#7842', 'status': 'Safe', 'amount': '\$1,250.00', 'time': '2 min ago', 'risk': '2%', 'fraud': false, 'delay': 0.45},
                    {'id': '#7841', 'status': 'Fraud', 'amount': '\$89.99', 'time': '15 min ago', 'risk': '94%', 'fraud': true, 'delay': 0.5},
                    {'id': '#7840', 'status': 'Safe', 'amount': '\$432.50', 'time': '1 hour ago', 'risk': '8%', 'fraud': false, 'delay': 0.55},
                  ].map((tx) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SlideTransition(
                      position: _slideUp(tx['delay'] as double, (tx['delay'] as double) + 0.25),
                      child: FadeTransition(
                        opacity: _fade(tx['delay'] as double, (tx['delay'] as double) + 0.25),
                        child: _TransactionTile(
                          id: tx['id'] as String, status: tx['status'] as String,
                          amount: tx['amount'] as String, time: tx['time'] as String,
                          riskPercent: tx['risk'] as String, isFraud: tx['fraud'] as bool,
                        ),
                      ),
                    ),
                  )),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  HERO CARD — gradient + decorative circles
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildHeroCard(AppProvider provider) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [_kGreenTeal, _kSkyBlue, _kLightGreen],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _kGreenTeal.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(children: [
          // Decorative circles (matching Lovable)
          Positioned(right: -24, bottom: -24,
            child: Container(width: 120, height: 120, decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1), shape: BoxShape.circle))),
          Positioned(right: 40, top: -16,
            child: Container(width: 80, height: 80, decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08), shape: BoxShape.circle))),

          // Content
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.shield_outlined, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Text('Protection Active', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.85))),
              ]),
              const SizedBox(height: 14),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Text('\$24,580', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1)),
                const Padding(padding: EdgeInsets.only(bottom: 4), child: Text('.00', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400, color: Colors.white70))),
              ]),
              const SizedBox(height: 4),
              Text('Protected transactions this month', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.75))),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => provider.switchTab(1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.bolt, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    const Text('Simulate Transaction', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right, size: 16, color: Colors.white),
                  ]),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  STAT CARDS — matching Lovable exactly
  // ════════════════════════════════════════════════════════════════════════════

  // Safe Today — WHITE card, dark text
  Widget _buildSafeTodayCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.shield_outlined, size: 18, color: _kDark),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8)),
            child: const Text('+12%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF16A34A))),
          ),
        ]),
        const SizedBox(height: 14),
        const Text('147', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: _kDark)),
        const SizedBox(height: 2),
        Text('Safe Today', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade600)),
      ]),
    );
  }

  // Fraud Blocked — SOLID RED
  Widget _buildFraudBlockedCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kRed,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: _kRed.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.gpp_maybe_outlined, size: 18, color: Colors.white),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
            child: const Text('25%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ]),
        const SizedBox(height: 14),
        const Text('3', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 2),
        Text('Fraud\nBlocked', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.85), height: 1.3)),
      ]),
    );
  }

  // Accuracy — SOLID GREEN
  Widget _buildAccuracyCard(AppProvider provider) {
    final value = provider.bestModel != null
        ? '${(provider.bestModel!.accuracy * 100).toStringAsFixed(1)}%'
        : '99.2%';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kGreen,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: _kGreen.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.monitor_heart_outlined, size: 18, color: Colors.white),
        ),
        const SizedBox(height: 14),
        Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 2),
        Text('Accuracy', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.85))),
      ]),
    );
  }

  // Model Score — SOLID BLUE
  Widget _buildModelScoreCard(AppProvider provider) {
    final value = provider.bestModel != null
        ? provider.bestModel!.aucRoc.toStringAsFixed(2)
        : '0.98';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kBlue,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: _kBlue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.trending_up, size: 18, color: Colors.white),
        ),
        const SizedBox(height: 14),
        Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 2),
        Text('Model\nScore', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.85), height: 1.3)),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Transaction Tile
// ══════════════════════════════════════════════════════════════════════════════

class _TransactionTile extends StatelessWidget {
  final String id, status, amount, time, riskPercent;
  final bool isFraud;
  const _TransactionTile({required this.id, required this.status, required this.amount, required this.time, required this.riskPercent, required this.isFraud});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(width: 4, color: isFraud ? _kRed : _kGreen)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(id, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kDark)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: isFraud ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12)),
              child: Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isFraud ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32))),
            ),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Icon(Icons.access_time, size: 14, color: Colors.grey.shade400),
            const SizedBox(width: 4),
            Text(time, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            const SizedBox(width: 12),
            Text('•', style: TextStyle(color: Colors.grey.shade400)),
            const SizedBox(width: 12),
            Text(riskPercent, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isFraud ? _kRed : Colors.grey.shade500)),
          ]),
        ])),
        Text(amount, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _kDark)),
        const SizedBox(width: 8),
        Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
      ]),
    );
  }
}
