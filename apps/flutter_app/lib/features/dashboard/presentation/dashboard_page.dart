import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/models/auto_trade_status.dart';
import '../../../core/models/broker_health.dart';
import '../../../core/state/app_controller.dart';
import '../../../core/theme/app_theme.dart';
import 'preview_data.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedNav = 0;
  String _selectedPair = 'EUR/USD';
  String _timeframe = 'M5';
  bool _scannerRefreshing = false;

  AppController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        return Scaffold(
          backgroundColor: AppTheme.background,
          drawer: wide ? null : _mobileDrawer(),
          bottomNavigationBar: wide ? null : _bottomNavigation(),
          body: SafeArea(
            bottom: wide,
            child: Column(
              children: [
                _Header(wide: wide, controller: controller, onOpenMenu: wide ? null : () => Scaffold.of(context).openDrawer()),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (wide) _Sidebar(selected: _selectedNav, onSelected: _selectNav),
                      Expanded(child: _dashboardBody(wide)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _dashboardBody(bool wide) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.65, -1.2),
          radius: 1.4,
          colors: [Color(0x18216D9A), AppTheme.background],
        ),
      ),
      child: ListView(
        padding: EdgeInsets.fromLTRB(wide ? 16 : 12, 14, wide ? 16 : 12, 28),
        children: [
          _NoticeBanner(controller: controller),
          const SizedBox(height: 12),
          _TopGrid(controller: controller, wide: wide),
          const SizedBox(height: 12),
          _Workspace(
            controller: controller,
            wide: wide,
            selectedPair: _selectedPair,
            timeframe: _timeframe,
            onPairChanged: (pair) => setState(() => _selectedPair = pair),
            onTimeframeChanged: () => setState(() => _timeframe = _timeframe == 'M5' ? 'M1' : 'M5'),
            scannerRefreshing: _scannerRefreshing,
            onRefreshScanner: _refreshScanner,
          ),
          const SizedBox(height: 12),
          _SignalFocus(pair: _selectedPair),
          const SizedBox(height: 12),
          _AnalyticsGrid(wide: wide),
          const SizedBox(height: 12),
          _AutoTradePanel(controller: controller),
        ],
      ),
    );
  }

  void _selectNav(int index) {
    setState(() => _selectedNav = index);
    if (index != 0) {
      controller.setNotice('${_navItems[index].label} siap dibuka setelah modul backend tersedia.');
    }
  }

  void _refreshScanner() {
    if (_scannerRefreshing) return;
    setState(() => _scannerRefreshing = true);
    Future<void>.delayed(const Duration(milliseconds: 650), () {
      if (mounted) setState(() => _scannerRefreshing = false);
    });
  }

  Drawer _mobileDrawer() {
    return Drawer(
      backgroundColor: AppTheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 16, 18),
              child: Text('BM FUTURE', style: TextStyle(color: AppTheme.text, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
            ),
            ...List.generate(_navItems.length, (index) => _NavButton(item: _navItems[index], selected: _selectedNav == index, onTap: () { Navigator.pop(context); _selectNav(index); })),
          ],
        ),
      ),
    );
  }

  NavigationBar _bottomNavigation() {
    return NavigationBar(
      height: 68,
      backgroundColor: const Color(0xF00B1119),
      indicatorColor: const Color(0x3330B7FF),
      selectedIndex: _selectedNav > 4 ? 0 : _selectedNav,
      onDestinationSelected: _selectNav,
      destinations: _navItems.take(5).map((item) => NavigationDestination(icon: Icon(item.icon), selectedIcon: Icon(item.icon, color: AppTheme.cyan), label: item.label)).toList(),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.wide, required this.controller, this.onOpenMenu});

  final bool wide;
  final AppController controller;
  final VoidCallback? onOpenMenu;

  @override
  Widget build(BuildContext context) {
    final health = controller.health;
    return Container(
      padding: EdgeInsets.fromLTRB(wide ? 20 : 12, 10, wide ? 18 : 12, 10),
      decoration: const BoxDecoration(
        color: Color(0xF0060C12),
        border: Border(bottom: BorderSide(color: Color(0x2B7AB5E4))),
      ),
      child: Row(
        children: [
          if (!wide) ...[
            IconButton(onPressed: onOpenMenu, icon: const Icon(Icons.menu_rounded, color: AppTheme.text)),
            const SizedBox(width: 2),
          ],
          const _Brand(),
          if (wide) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  const Spacer(),
                  _ModeSwitcher(controller: controller),
                  const SizedBox(width: 12),
                  Flexible(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _RealWarning(),
                          const SizedBox(width: 12),
                          _HeaderStatus(label: 'CONNECTION', value: controller.connectionLabel, tone: _statusTone(controller.connectionState), dot: true),
                          _HeaderStatus(label: 'BALANCE', value: _balanceText(health), tone: AppTheme.text),
                          _HeaderStatus(label: 'SERVER', value: controller.isDemoConnected ? 'DEMO BROKER' : 'NOT CONNECTED', tone: controller.isDemoConnected ? AppTheme.green : AppTheme.amber, dot: true),
                          _HeaderStatus(label: 'AI ENGINE', value: _aiLabel(controller), tone: controller.aiHealth?.available == true ? AppTheme.green : AppTheme.amber, dot: true),
                          _HeaderStatus(label: 'AUTO TRADE', value: controller.autoTradeStatus?.label ?? 'LOCKED', tone: _autoTradeTone(controller), dot: true),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const Spacer(),
            _ModeSwitcher(controller: controller),
          ],
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            gradient: const LinearGradient(colors: [Color(0xFF9658FF), Color(0xFF1878FF), Color(0xFF36D7FF)]),
            boxShadow: const [BoxShadow(color: Color(0x423B8CFF), blurRadius: 18)],
          ),
          child: const Text('BM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: -1.6, fontSize: 17)),
        ),
        const SizedBox(width: 10),
        const Text('BM FUTURE', style: TextStyle(color: AppTheme.text, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: .5)),
        if (MediaQuery.sizeOf(context).width >= 500) const Text('  PO AUTOTRADE AI', style: TextStyle(color: Color(0xFFA8B6C9), fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: .3)),
      ],
    );
  }
}

class _ModeSwitcher extends StatelessWidget {
  const _ModeSwitcher({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: AppTheme.surfaceAlt, borderRadius: BorderRadius.circular(7), border: Border.all(color: const Color(0x3D77AED9))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeButton(key: const ValueKey('demo-mode-button'), label: 'DEMO', selected: controller.mode == AccountMode.demo, onTap: () => controller.selectMode(AccountMode.demo)),
          _ModeButton(key: const ValueKey('real-mode-button'), label: 'REAL', selected: controller.mode == AccountMode.real, danger: true, onTap: () => controller.selectMode(AccountMode.real)),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({super.key, required this.label, required this.selected, required this.onTap, this.danger = false});

  final String label;
  final bool selected;
  final bool danger;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: const BoxConstraints(minWidth: 62, minHeight: 29),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? (danger ? const Color(0xFFD33D4C) : const Color(0xFF2188DF)) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          boxShadow: selected ? [BoxShadow(color: (danger ? AppTheme.red : AppTheme.cyan).withValues(alpha: .22), blurRadius: 12)] : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Text(label, style: TextStyle(color: selected ? Colors.white : AppTheme.muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: .6)), if (danger) ...[const SizedBox(width: 4), Icon(Icons.warning_amber_rounded, size: 13, color: AppTheme.red)]]),
      ),
    );
  }
}

class _RealWarning extends StatelessWidget {
  const _RealWarning();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.warning_amber_rounded, color: AppTheme.red, size: 19),
        SizedBox(width: 5),
        Text('REAL TRADING\nNOT ACTIVATED', style: TextStyle(color: AppTheme.red, fontSize: 9, height: 1.1, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _HeaderStatus extends StatelessWidget {
  const _HeaderStatus({required this.label, required this.value, required this.tone, this.dot = false});

  final String label;
  final String value;
  final Color tone;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 80),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(border: Border(left: BorderSide(color: Color(0x2175A6CD)))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF9AAABD), fontSize: 9, letterSpacing: .4)),
          const SizedBox(height: 4),
          Row(mainAxisSize: MainAxisSize.min, children: [if (dot) Container(width: 6, height: 6, margin: const EdgeInsets.only(right: 6), decoration: BoxDecoration(color: tone, shape: BoxShape.circle, boxShadow: [BoxShadow(color: tone, blurRadius: 8)])), Flexible(child: Text(value, overflow: TextOverflow.ellipsis, style: TextStyle(color: tone, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: .3))) ]),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 188,
      decoration: const BoxDecoration(color: Color(0xE6070D14), border: Border(right: BorderSide(color: Color(0x297AB5E4)))),
      child: Column(
        children: [
          Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(10, 18, 10, 10), children: List.generate(_navItems.length, (index) => _NavButton(item: _navItems[index], selected: selected == index, onTap: () => onSelected(index))))),
          const Padding(padding: EdgeInsets.fromLTRB(18, 12, 18, 18), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('16:45:21 UTC', style: TextStyle(color: AppTheme.text, fontSize: 10, fontWeight: FontWeight.w600)), SizedBox(height: 3), Text('01 SEP 2026', style: TextStyle(color: AppTheme.muted, fontSize: 9))]), _StatusDot(color: AppTheme.green)])),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon);

  final String label;
  final IconData icon;
}

const _navItems = <_NavItem>[
  _NavItem('Dashboard', Icons.dashboard_outlined),
  _NavItem('Market', Icons.candlestick_chart_outlined),
  _NavItem('Signals', Icons.bolt_outlined),
  _NavItem('Trade', Icons.swap_vert_rounded),
  _NavItem('Auto Trade', Icons.smart_toy_outlined),
  _NavItem('Backtest', Icons.history_toggle_off_rounded),
  _NavItem('Journal', Icons.menu_book_outlined),
  _NavItem('Statistics', Icons.insights_outlined),
  _NavItem('AI Engine', Icons.auto_awesome_outlined),
  _NavItem('Strategies', Icons.account_tree_outlined),
  _NavItem('Connection', Icons.link_rounded),
  _NavItem('Settings', Icons.settings_outlined),
  _NavItem('Logs', Icons.receipt_long_outlined),
];

class _NavButton extends StatelessWidget {
  const _NavButton({required this.item, required this.selected, required this.onTap});

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? const Color(0x332081B8) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(border: selected ? Border.all(color: const Color(0x6130B7FF)) : null, borderRadius: BorderRadius.circular(6)),
            child: Row(children: [Icon(item.icon, size: 18, color: selected ? AppTheme.cyan : AppTheme.muted), const SizedBox(width: 12), Text(item.label, style: TextStyle(color: selected ? AppTheme.text : const Color(0xFFA4B2C4), fontSize: 11, fontWeight: selected ? FontWeight.w600 : FontWeight.w400))]),
          ),
        ),
      ),
    );
  }
}

class _NoticeBanner extends StatelessWidget {
  const _NoticeBanner({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final connected = controller.isDemoConnected;
    final real = controller.mode == AccountMode.real;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(color: real ? const Color(0x18FF4E55) : const Color(0x10F5B83F), border: Border.all(color: real ? const Color(0x4DFF4E55) : const Color(0x3DF5B83F)), borderRadius: BorderRadius.circular(6)),
      child: Row(
        children: [
          Icon(real ? Icons.warning_amber_rounded : Icons.info_outline_rounded, color: real ? AppTheme.red : AppTheme.amber, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text('${real ? 'REAL LOCKED' : connected ? 'DEMO CONNECTED' : controller.connectionLabel} · ${controller.notice}', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: real ? const Color(0xFFFFA3A6) : const Color(0xFFB5BFCC), fontSize: 10, height: 1.3))),
          const SizedBox(width: 8),
          if (!real)
            FilledButton.tonal(
              onPressed: controller.connectionState == BrokerConnectionState.connecting ? null : () { if (connected) { controller.disconnectDemo(); } else { controller.connectDemo(); } },
              style: FilledButton.styleFrom(backgroundColor: const Color(0x2630B7FF), foregroundColor: AppTheme.cyan, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), textStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: .4)),
              child: Text(controller.connectionState == BrokerConnectionState.connecting ? 'CONNECTING…' : connected ? 'DISCONNECT' : 'CONNECT DEMO'),
            ),
        ],
      ),
    );
  }
}

class _TopGrid extends StatelessWidget {
  const _TopGrid({required this.controller, required this.wide});

  final AppController controller;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return wide
        ? Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Expanded(child: _AccountPanel(controller: controller)), const SizedBox(width: 12), Expanded(child: _AiPanel(controller: controller))])
        : Column(children: [_AccountPanel(controller: controller), const SizedBox(height: 12), _AiPanel(controller: controller)]);
  }
}

class _AccountPanel extends StatelessWidget {
  const _AccountPanel({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final balance = controller.isDemoConnected && controller.health?.balance != null ? '\$${controller.health!.balance!.toStringAsFixed(2)}' : '—';
    return _Panel(
      title: 'ACCOUNT',
      meta: '${controller.mode.label} · ${controller.isDemoConnected ? 'BROKER DATA' : 'DATA PREVIEW'}',
      child: Wrap(spacing: 8, runSpacing: 8, children: [
        _Metric(label: 'BALANCE (${controller.mode.label})', value: balance, note: controller.isDemoConnected ? 'Broker DEMO' : 'No live data', icon: Icons.account_balance_wallet_outlined, tone: controller.isDemoConnected ? AppTheme.text : AppTheme.muted),
        const _Metric(label: 'PROFIT TODAY', value: '—', note: 'Journal pending'),
        const _Metric(label: 'LOSS TODAY', value: '—', note: 'Journal pending'),
        const _Metric(label: 'NET P/L', value: '—', note: 'Journal pending', icon: Icons.track_changes_outlined),
        const _Metric(label: 'WIN RATE', value: '—', note: 'Journal pending', icon: Icons.emoji_events_outlined),
      ]),
    );
  }
}

class _AiPanel extends StatelessWidget {
  const _AiPanel({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'AI ENGINE',
      titleColor: AppTheme.purple,
      meta: 'SAFE MODE',
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(color: const Color(0x26080C16), border: Border.all(color: const Color(0x2FAE76FF)), borderRadius: BorderRadius.circular(5)),
        child: Row(children: [
          Expanded(child: _AiStat(label: 'PROVIDER', value: controller.aiHealth?.provider ?? (controller.config.hasApi ? 'CHECKING' : 'NOT CONFIGURED'))),
          Expanded(child: _AiStat(label: 'MODEL', value: controller.aiHealth?.model ?? '—')),
          const Expanded(child: _AiStat(label: 'CONFIDENCE', value: '—', tone: AppTheme.purple)),
          const _AiOrbit(),
        ]),
      ),
    );
  }
}

class _Workspace extends StatelessWidget {
  const _Workspace({required this.controller, required this.wide, required this.selectedPair, required this.timeframe, required this.onPairChanged, required this.onTimeframeChanged, required this.scannerRefreshing, required this.onRefreshScanner});

  final AppController controller;
  final bool wide;
  final String selectedPair;
  final String timeframe;
  final ValueChanged<String> onPairChanged;
  final VoidCallback onTimeframeChanged;
  final bool scannerRefreshing;
  final VoidCallback onRefreshScanner;

  @override
  Widget build(BuildContext context) {
    final chart = _ChartPanel(pair: selectedPair, timeframe: timeframe, onTimeframeChanged: onTimeframeChanged);
    final scanner = _ScannerPanel(selectedPair: selectedPair, onPairChanged: onPairChanged, refreshing: scannerRefreshing, onRefresh: onRefreshScanner);
    return wide ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 6, child: chart), const SizedBox(width: 10), Expanded(flex: 5, child: scanner)]) : Column(children: [chart, const SizedBox(height: 12), scanner]);
  }
}

class _ChartPanel extends StatelessWidget {
  const _ChartPanel({required this.pair, required this.timeframe, required this.onTimeframeChanged});

  final String pair;
  final String timeframe;
  final VoidCallback onTimeframeChanged;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Column(children: [
        Row(children: [const Text('🇺🇸', style: TextStyle(fontSize: 16)), const SizedBox(width: 7), Text(pair, style: const TextStyle(color: AppTheme.text, fontWeight: FontWeight.w700, fontSize: 12)), const Icon(Icons.chevron_right_rounded, color: AppTheme.muted, size: 14), const SizedBox(width: 8), _ToolButton(label: timeframe, onTap: onTimeframeChanged), _ToolButton(icon: Icons.tune_rounded, label: 'Indicators'), const Spacer(), _ToolIcon(icon: Icons.candlestick_chart_rounded, active: true), _ToolIcon(icon: Icons.show_chart_rounded), _ToolIcon(icon: Icons.fullscreen_rounded)]),
        const Divider(height: 15, color: Color(0x2175A7D0)),
        Align(alignment: Alignment.centerLeft, child: Text('DESIGN PREVIEW · LIVE CANDLES MENUNGGU MARKET DATA ENGINE', style: TextStyle(color: AppTheme.amber, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: .3))),
        const SizedBox(height: 5),
        SizedBox(height: 292, child: Stack(children: [const Positioned.fill(child: CustomPaint(painter: _ChartGridPainter())), Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: const Color(0xE60D151F), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0x4230B7FF))), child: const Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.candlestick_chart_outlined, color: AppTheme.cyan, size: 24), SizedBox(height: 7), Text('NO LIVE CANDLE DATA', style: TextStyle(color: AppTheme.text, fontSize: 11, fontWeight: FontWeight.w700)), SizedBox(height: 3), Text('WebSocket backend belum aktif', style: TextStyle(color: AppTheme.muted, fontSize: 10))])))])),
        const Divider(height: 15, color: Color(0x2175A7D0)),
        Row(children: [const Text('1D', style: TextStyle(color: AppTheme.cyan, fontSize: 10, fontWeight: FontWeight.w700)), const SizedBox(width: 14), const Text('1W', style: TextStyle(color: AppTheme.muted, fontSize: 10)), const SizedBox(width: 14), const Text('1M', style: TextStyle(color: AppTheme.muted, fontSize: 10)), const Spacer(), Text('UTC · ${timeframe.toLowerCase()}', style: const TextStyle(color: AppTheme.muted, fontSize: 9)), const SizedBox(width: 10), const Icon(Icons.sync_rounded, size: 13, color: AppTheme.amber), const SizedBox(width: 4), const Text('auto', style: TextStyle(color: AppTheme.amber, fontSize: 9))]),
      ]),
    );
  }
}

class _ScannerPanel extends StatelessWidget {
  const _ScannerPanel({required this.selectedPair, required this.onPairChanged, required this.refreshing, required this.onRefresh});

  final String selectedPair;
  final ValueChanged<String> onPairChanged;
  final bool refreshing;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'MARKET SCANNER',
      meta: 'PREVIEW DATA · NO EXECUTION',
      trailing: IconButton(onPressed: onRefresh, tooltip: 'Refresh scanner', icon: Icon(Icons.refresh_rounded, color: refreshing ? AppTheme.cyan : AppTheme.muted, size: 18)),
      child: Column(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7), decoration: BoxDecoration(color: const Color(0x1AF5B83F), borderRadius: BorderRadius.circular(4)), child: const Row(children: [Icon(Icons.info_outline_rounded, color: AppTheme.amber, size: 14), SizedBox(width: 6), Expanded(child: Text('Data preview untuk desain. Auto Trade tidak dapat memakai baris ini.', style: TextStyle(color: AppTheme.amber, fontSize: 9)))])),
        const SizedBox(height: 6),
        ...previewSignals.map((signal) => _ScannerRow(signal: signal, selected: signal.pair == selectedPair, onTap: () => onPairChanged(signal.pair))),
      ]),
    );
  }
}

class _ScannerRow extends StatelessWidget {
  const _ScannerRow({required this.signal, required this.selected, required this.onTap});

  final PreviewSignal signal;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final call = signal.direction == 'CALL';
    return Material(color: selected ? const Color(0x192081B8) : Colors.transparent, child: InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: const Color(0x1875A7D0))), borderRadius: BorderRadius.circular(4)), child: Row(children: [SizedBox(width: 20, child: Text('${previewSignals.indexOf(signal) + 1}', style: const TextStyle(color: AppTheme.muted, fontSize: 10))), Expanded(flex: 3, child: Text(signal.pair, style: const TextStyle(color: AppTheme.text, fontSize: 10, fontWeight: FontWeight.w600))), Expanded(flex: 2, child: _DirectionTag(direction: signal.direction)), Expanded(child: Text('${signal.confidence}%', style: const TextStyle(color: AppTheme.cyan, fontSize: 10))), Expanded(child: Text('${signal.payout}%', style: const TextStyle(color: AppTheme.cyan, fontSize: 10))), Expanded(child: Icon(call ? Icons.trending_up_rounded : Icons.trending_down_rounded, size: 15, color: call ? AppTheme.green : AppTheme.red)), Expanded(child: Text(signal.expiration, style: const TextStyle(color: AppTheme.muted, fontSize: 10))), Expanded(child: Text(signal.consensus, style: const TextStyle(color: AppTheme.purple, fontSize: 10))), Expanded(child: Text(signal.score.toStringAsFixed(1), style: TextStyle(color: signal.score >= 80 ? AppTheme.green : AppTheme.amber, fontSize: 10, fontWeight: FontWeight.w600)))]))));
  }
}

class _SignalFocus extends StatelessWidget {
  const _SignalFocus({required this.pair});

  final String pair;

  @override
  Widget build(BuildContext context) {
    final signal = previewSignals.firstWhere((item) => item.pair == pair, orElse: () => previewSignals.first);
    final call = signal.direction == 'CALL';
    return _Panel(
      title: 'TOP AI SIGNAL',
      titleColor: AppTheme.purple,
      meta: 'PREVIEW ONLY · EXPIRES DISABLED',
      trailing: _DirectionTag(direction: signal.direction, strong: true),
      child: Column(children: [
        Row(children: [Text(signal.pair, style: const TextStyle(color: AppTheme.text, fontSize: 16, fontWeight: FontWeight.w700)), const SizedBox(width: 6), const Text('OTC', style: TextStyle(color: AppTheme.muted, fontSize: 9, fontWeight: FontWeight.w700)), const Spacer(), Text(call ? '↑' : '↓', style: TextStyle(color: call ? AppTheme.green : AppTheme.red, fontSize: 24, fontWeight: FontWeight.w700))]),
        const SizedBox(height: 13),
        Wrap(spacing: 25, runSpacing: 12, children: [_SignalValue(label: 'CONFIDENCE', value: '${signal.confidence}%', tone: AppTheme.purple, progress: signal.confidence / 100), _SignalValue(label: 'PAYOUT', value: '${signal.payout}%', tone: AppTheme.cyan), _SignalValue(label: 'EXPIRATION', value: signal.expiration, tone: AppTheme.amber), _SignalValue(label: 'TREND', value: signal.trend, tone: call ? AppTheme.green : AppTheme.red), _SignalValue(label: 'AI CONSENSUS', value: '${signal.consensus} APPROVE', tone: AppTheme.purple)]),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8), decoration: BoxDecoration(color: const Color(0x1225D38B), borderRadius: BorderRadius.circular(4)), child: Row(children: [const Icon(Icons.check_circle_outline_rounded, color: AppTheme.green, size: 15), const SizedBox(width: 7), const Expanded(child: Text('Reason preview: EMA alignment · momentum confirmation · payout filter.', style: TextStyle(color: AppTheme.muted, fontSize: 9))), TextButton(onPressed: () {}, child: const Text('DETAIL', style: TextStyle(color: AppTheme.cyan, fontSize: 9, fontWeight: FontWeight.w700)))])),
      ]),
    );
  }
}

class _AnalyticsGrid extends StatelessWidget {
  const _AnalyticsGrid({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      const _EmptyAnalytics(title: 'PROFIT / LOSS OVER TIME', icon: Icons.show_chart_rounded),
      const _DistributionPanel(),
      const _PerformancePanel(),
      const _RecentSignals(),
    ];
    if (!wide) return Column(children: children.map((child) => Padding(padding: const EdgeInsets.only(bottom: 12), child: child)).toList());
    return GridView.count(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.95, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), children: children);
  }
}

class _EmptyAnalytics extends StatelessWidget {
  const _EmptyAnalytics({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _Panel(title: title, meta: 'NO DATA', child: SizedBox(height: 100, child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: AppTheme.muted, size: 20), const SizedBox(height: 7), const Text('Belum ada data jurnal live', style: TextStyle(color: AppTheme.muted, fontSize: 10)), const SizedBox(height: 3), const Text('Backend Journal belum aktif.', style: TextStyle(color: Color(0xFF526173), fontSize: 9))]))));
  }
}

class _DistributionPanel extends StatelessWidget {
  const _DistributionPanel();

  @override
  Widget build(BuildContext context) {
    return _Panel(title: 'WIN / LOSS DISTRIBUTION', meta: 'NO DATA', child: Row(children: [const SizedBox(width: 104, height: 104, child: CustomPaint(painter: _EmptyDonutPainter())), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [_KeyValue(label: 'Wins', value: '—'), _KeyValue(label: 'Losses', value: '—'), Divider(color: AppTheme.border), _KeyValue(label: 'Total Trades', value: '—'), _KeyValue(label: 'Best Streak', value: '—')]))]));
  }
}

class _PerformancePanel extends StatelessWidget {
  const _PerformancePanel();

  @override
  Widget build(BuildContext context) {
    return _Panel(title: 'PERFORMANCE SUMMARY', meta: 'NO DATA', child: Column(children: const [_KeyValue(label: 'Total Trades', value: '—'), _KeyValue(label: 'Profit Factor', value: '—'), _KeyValue(label: 'Average Win', value: '—'), _KeyValue(label: 'Max Drawdown', value: '—'), _KeyValue(label: 'Expectancy', value: '—')]));
  }
}

class _RecentSignals extends StatelessWidget {
  const _RecentSignals();

  @override
  Widget build(BuildContext context) {
    return _Panel(title: 'RECENT SIGNALS', meta: 'PREVIEW', trailing: const Text('VIEW ALL ›', style: TextStyle(color: AppTheme.cyan, fontSize: 9, fontWeight: FontWeight.w700)), child: Column(children: previewSignals.take(4).map((signal) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [Icon(signal.direction == 'CALL' ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: signal.direction == 'CALL' ? AppTheme.green : AppTheme.red, size: 14), const SizedBox(width: 8), Expanded(child: Text(signal.pair, style: const TextStyle(color: AppTheme.text, fontSize: 10))), _DirectionTag(direction: signal.direction), const SizedBox(width: 10), Text('${signal.confidence}%', style: const TextStyle(color: AppTheme.cyan, fontSize: 10))]))).toList()));
  }
}

class _AutoTradePanel extends StatelessWidget {
  const _AutoTradePanel({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final status = controller.autoTradeStatus;
    final running = status?.running == true || controller.autoTradeRunning;
    final label = status?.label ?? 'EXECUTION LOCKED';
    final detail = status?.reason ?? (controller.config.hasApi ? 'Backend preflight required' : 'Backend belum dikonfigurasi');
    return _Panel(
      title: 'AUTO TRADE AI',
      titleColor: AppTheme.purple,
      meta: label,
      child: Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, runSpacing: 10, children: [
        Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.smart_toy_outlined, color: AppTheme.purple, size: 20), const SizedBox(width: 8), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('BM Momentum AI v2.3', style: TextStyle(color: AppTheme.text, fontSize: 12, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text('STATUS: $label · $detail', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.muted, fontSize: 9))])]),
        Wrap(spacing: 7, children: [FilledButton.icon(onPressed: running ? null : () => controller.startAutoTrade(), icon: const Icon(Icons.play_arrow_rounded, size: 14), label: const Text('START AUTO TRADE')), OutlinedButton.icon(onPressed: () => controller.stopAutoTrade(), icon: const Icon(Icons.pause_rounded, size: 14), label: const Text('STOP')), FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: const Color(0x33FF4E55), foregroundColor: AppTheme.red), onPressed: () => controller.emergencyStop(), icon: const Icon(Icons.stop_rounded, size: 14), label: const Text('EMERGENCY STOP'))]),
      ]),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({this.title, this.meta, this.trailing, this.titleColor = AppTheme.cyan, required this.child, this.padding = const EdgeInsets.all(11)});

  final String? title;
  final String? meta;
  final Widget? trailing;
  final Color titleColor;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(color: AppTheme.surface.withValues(alpha: .96), border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(6), boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 10))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [if (title != null) ...[Row(children: [Text(title!, style: TextStyle(color: titleColor, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: .4)), const Spacer(), if (meta != null) Text(meta!, style: const TextStyle(color: Color(0xFF68798D), fontSize: 8, letterSpacing: .6)), if (trailing != null) ...[const SizedBox(width: 5), trailing!]]), const SizedBox(height: 9)], child]),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.note, this.icon, this.tone = AppTheme.text});

  final String label;
  final String value;
  final String note;
  final IconData? icon;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(width: 142, height: 88, padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: const Color(0xC909121C), border: Border.all(color: const Color(0x2E71A2C9)), borderRadius: BorderRadius.circular(4)), child: Stack(children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF97A8BA), fontSize: 8, letterSpacing: .3)), const SizedBox(height: 7), Text(value, style: TextStyle(color: tone, fontSize: 17, fontWeight: FontWeight.w600, fontFamily: 'monospace')), const SizedBox(height: 3), Text(note, overflow: TextOverflow.ellipsis, style: TextStyle(color: tone == AppTheme.text ? AppTheme.muted : tone, fontSize: 8, fontFamily: 'monospace'))]), if (icon != null) Positioned(right: 0, bottom: 0, child: Icon(icon, color: AppTheme.cyan.withValues(alpha: .7), size: 17))]));
  }
}

class _AiStat extends StatelessWidget {
  const _AiStat({required this.label, required this.value, this.tone = AppTheme.text});

  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 8, letterSpacing: .4)), const SizedBox(height: 5), Text(value, overflow: TextOverflow.ellipsis, style: TextStyle(color: tone, fontSize: 10, fontWeight: FontWeight.w600, fontFamily: 'monospace'))]);
}

class _AiOrbit extends StatelessWidget {
  const _AiOrbit();

  @override
  Widget build(BuildContext context) => Container(width: 38, height: 38, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0x2BAE76FF), border: Border.all(color: const Color(0x47AE76FF)), boxShadow: const [BoxShadow(color: Color(0x3AAE76FF), blurRadius: 18)]), child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.purple, size: 20));
}

class _SignalValue extends StatelessWidget {
  const _SignalValue({required this.label, required this.value, required this.tone, this.progress});

  final String label;
  final String value;
  final Color tone;
  final double? progress;

  @override
  Widget build(BuildContext context) => SizedBox(width: 105, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 8, letterSpacing: .3)), const SizedBox(height: 5), Text(value, style: TextStyle(color: tone, fontSize: 13, fontWeight: FontWeight.w700)), if (progress != null) ...[const SizedBox(height: 5), ClipRRect(borderRadius: BorderRadius.circular(5), child: LinearProgressIndicator(value: progress, minHeight: 4, backgroundColor: const Color(0x263A5064), color: tone))]]));
}

class _KeyValue extends StatelessWidget {
  const _KeyValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [Expanded(child: Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 9))), Text(value, style: const TextStyle(color: AppTheme.text, fontSize: 10, fontWeight: FontWeight.w600, fontFamily: 'monospace'))]));
}

class _DirectionTag extends StatelessWidget {
  const _DirectionTag({required this.direction, this.strong = false});

  final String direction;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final call = direction == 'CALL';
    return Container(padding: EdgeInsets.symmetric(horizontal: strong ? 8 : 5, vertical: strong ? 5 : 3), decoration: BoxDecoration(color: (call ? AppTheme.green : AppTheme.red).withValues(alpha: .14), borderRadius: BorderRadius.circular(4)), child: Text(strong ? 'STRONG $direction' : direction, style: TextStyle(color: call ? AppTheme.green : AppTheme.red, fontSize: strong ? 10 : 8, fontWeight: FontWeight.w700, letterSpacing: .3)));
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({this.icon, required this.label, this.onTap});

  final IconData? icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => TextButton.icon(onPressed: onTap, icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 13), label: Text(label), style: TextButton.styleFrom(foregroundColor: AppTheme.muted, padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5), textStyle: const TextStyle(fontSize: 9)));
}

class _ToolIcon extends StatelessWidget {
  const _ToolIcon({required this.icon, this.active = false});

  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) => IconButton(onPressed: () {}, icon: Icon(icon, size: 15, color: active ? AppTheme.cyan : AppTheme.muted), tooltip: 'Chart tool');
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color, blurRadius: 9)]));
}

class _ChartGridPainter extends CustomPainter {
  const _ChartGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = const Color(0x1A75A7D0)..strokeWidth = 1;
    for (var i = 1; i < 7; i++) {
      final x = size.width * i / 7;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var i = 1; i < 6; i++) {
      final y = size.height * i / 6;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final glow = Paint()..color = const Color(0x1730B7FF)..style = PaintingStyle.fill;
    final area = Path()..moveTo(0, size.height * .72);
    for (var i = 0; i <= 20; i++) {
      final x = size.width * i / 20;
      final y = size.height * (.64 - math.sin(i / 2.7) * .08 - i * .008);
      area.lineTo(x, y);
    }
    area.lineTo(size.width, size.height);
    area.lineTo(0, size.height);
    canvas.drawPath(area, glow);
    final line = Paint()..color = const Color(0x6830B7FF)..strokeWidth = 2..style = PaintingStyle.stroke;
    final path = Path();
    for (var i = 0; i <= 20; i++) {
      final x = size.width * i / 20;
      final y = size.height * (.64 - math.sin(i / 2.7) * .08 - i * .008);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EmptyDonutPainter extends CustomPainter {
  const _EmptyDonutPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()..color = const Color(0x34526A7A)..style = PaintingStyle.stroke..strokeWidth = 12;
    canvas.drawCircle(center, size.shortestSide * .34, paint);
    final inner = Paint()..color = AppTheme.surface..style = PaintingStyle.fill;
    canvas.drawCircle(center, size.shortestSide * .22, inner);
    const textStyle = TextStyle(color: AppTheme.muted, fontSize: 10, fontWeight: FontWeight.w700);
    final painter = TextPainter(text: const TextSpan(text: 'NO DATA', style: textStyle), textDirection: TextDirection.ltr)..layout();
    painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Color _statusTone(BrokerConnectionState state) {
  switch (state) {
    case BrokerConnectionState.connected:
      return AppTheme.green;
    case BrokerConnectionState.error:
      return AppTheme.red;
    case BrokerConnectionState.connecting:
    case BrokerConnectionState.offline:
    case BrokerConnectionState.notConfigured:
      return AppTheme.amber;
  }
}

String _aiLabel(AppController controller) {
  if (controller.aiHealth?.available == true) return 'READY';
  return controller.config.hasApi ? 'NOT READY' : 'NOT CONFIGURED';
}

Color _autoTradeTone(AppController controller) {
  switch (controller.autoTradeStatus?.state) {
    case AutoTradeState.running:
      return AppTheme.green;
    case AutoTradeState.degraded:
    case AutoTradeState.emergencyStop:
      return AppTheme.red;
    case AutoTradeState.starting:
    case AutoTradeState.stopped:
    case null:
      return AppTheme.amber;
  }
}

String _balanceText(BrokerHealth? health) {
  if (health?.connected != true || health?.balanceAvailable != true || health?.balance == null) return '—';
  return '\$${health!.balance!.toStringAsFixed(2)}';
}
