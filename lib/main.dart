import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const DataBridgeApp());
}

// ─────────────────────────────────────────────
// THEME
// ─────────────────────────────────────────────
class T {
  static const bg = Color(0xFFF8F9FB);
  static const white = Color(0xFFFFFFFF);
  static const border = Color(0xFFE8ECF0);
  static const borderDark = Color(0xFFD1D8E0);
  static const accent = Color(0xFF2563EB);
  static const accentLight = Color(0xFFEEF3FF);
  static const accentMid = Color(0xFFDBE8FF);
  static const success = Color(0xFF16A34A);
  static const successLight = Color(0xFFECFDF5);
  static const warning = Color(0xFFD97706);
  static const warningLight = Color(0xFFFFFBEB);
  static const danger = Color(0xFFDC2626);
  static const dangerLight = Color(0xFFFEF2F2);
  static const t1 = Color(0xFF0F172A);
  static const t2 = Color(0xFF475569);
  static const t3 = Color(0xFF94A3B8);
  static const t4 = Color(0xFFCBD5E1);

  static const fontSm = 11.0;
  static const fontBase = 13.0;
  static const fontMd = 14.0;
  static const fontLg = 16.0;
  static const fontXl = 20.0;
  static const font2xl = 24.0;

  static const r1 = 6.0;
  static const r2 = 10.0;
  static const r3 = 14.0;
  static const r4 = 20.0;

  static ThemeData theme() => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.light(
          primary: accent,
          surface: white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: white,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: t1, fontSize: fontBase),
        ),
      );
}

// ─────────────────────────────────────────────
// RESPONSIVE WRAPPER — fixes web sizing
// ─────────────────────────────────────────────
class Responsive extends StatelessWidget {
  final Widget child;
  const Responsive({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w > 500) {
      return Container(
        color: const Color(0xFFE8EDF3),
        child: Center(
          child: Container(
            width: 430,
            decoration: BoxDecoration(
              color: T.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 48,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: ClipRect(child: child),
          ),
        ),
      );
    }
    return child;
  }
}

// ─────────────────────────────────────────────
// DB STATE
// ─────────────────────────────────────────────
class DbState extends ChangeNotifier {
  bool isConnected = false;
  String dbUrl = '';
  String dbName = '';

  void connect(String url) {
    dbUrl = url;
    dbName = _parse(url);
    isConnected = true;
    notifyListeners();
  }

  void disconnect() {
    isConnected = false;
    dbUrl = '';
    dbName = '';
    notifyListeners();
  }

  String _parse(String url) {
    try {
      final uri = Uri.parse(url.replaceFirst('mysql://', 'http://'));
      final p = uri.path.replaceAll('/', '');
      return p.isEmpty ? 'database' : p;
    } catch (_) {
      return 'database';
    }
  }
}

// ─────────────────────────────────────────────
// ROOT APP
// ─────────────────────────────────────────────
class DataBridgeApp extends StatelessWidget {
  const DataBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DataBridge',
      debugShowCheckedModeBanner: false,
      theme: T.theme(),
      builder: (context, child) => Responsive(child: child!),
      home: const MainShell(),
    );
  }
}

// ─────────────────────────────────────────────
// MAIN SHELL
// ─────────────────────────────────────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _idx = 0;
  final DbState _db = DbState();

  @override
  Widget build(BuildContext context) {
    final screens = [
      UploadScreen(db: _db),
      DatabaseScreen(db: _db),
      QueryScreen(db: _db),
      SettingsScreen(db: _db),
    ];

    return Scaffold(
      backgroundColor: T.bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: _AppBar(db: _db),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: KeyedSubtree(key: ValueKey(_idx), child: screens[_idx]),
      ),
      bottomNavigationBar: _BottomBar(
        idx: _idx,
        onTap: (i) => setState(() => _idx = i),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// APP BAR
// ─────────────────────────────────────────────
class _AppBar extends StatelessWidget {
  final DbState db;
  const _AppBar({required this.db});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: db,
      builder: (ctx, _) => Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(ctx).padding.top,
          left: 16,
          right: 12,
        ),
        decoration: const BoxDecoration(
          color: T.white,
          border: Border(bottom: BorderSide(color: T.border)),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: T.accent,
                borderRadius: BorderRadius.circular(T.r1),
              ),
              child: const Icon(Icons.hub_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 9),
            const Text('DataBridge',
                style: TextStyle(
                    color: T.t1,
                    fontSize: T.fontLg,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3)),
            const Spacer(),
            TextButton(
              onPressed: () => showDialog(
                  context: ctx,
                  builder: (_) => _ConnectDialog(db: db)),
              style: TextButton.styleFrom(
                backgroundColor:
                    db.isConnected ? T.successLight : T.accentLight,
                foregroundColor:
                    db.isConnected ? T.success : T.accent,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(T.r4),
                  side: BorderSide(
                    color: db.isConnected
                        ? T.success.withValues(alpha: 0.3)
                        : T.accent.withValues(alpha: 0.25),
                  ),
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: db.isConnected ? T.success : T.accent,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    db.isConnected ? db.dbName : 'Connect DB',
                    style: TextStyle(
                        fontSize: T.fontSm,
                        fontWeight: FontWeight.w600,
                        color: db.isConnected ? T.success : T.accent),
                  ),
                  if (db.isConnected) ...[
                    const SizedBox(width: 2),
                    Icon(Icons.expand_more_rounded,
                        size: 14,
                        color: db.isConnected ? T.success : T.accent),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CONNECT DIALOG
// ─────────────────────────────────────────────
class _ConnectDialog extends StatefulWidget {
  final DbState db;
  const _ConnectDialog({required this.db});

  @override
  State<_ConnectDialog> createState() => _ConnectDialogState();
}

class _ConnectDialogState extends State<_ConnectDialog> {
  final _ctrl = TextEditingController();
  bool _hide = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.db.isConnected) _ctrl.text = widget.db.dbUrl;
  }

  @override
  Widget build(BuildContext ctx) {
    return Dialog(
      backgroundColor: T.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(T.r3),
          side: const BorderSide(color: T.border)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                    color: T.accentLight,
                    borderRadius: BorderRadius.circular(T.r1)),
                child: const Icon(Icons.storage_rounded,
                    color: T.accent, size: 16),
              ),
              const SizedBox(width: 10),
              const Text('Connect Database',
                  style: TextStyle(
                      color: T.t1,
                      fontSize: T.fontLg,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child:
                    const Icon(Icons.close_rounded, color: T.t3, size: 18),
              ),
            ]),
            const SizedBox(height: 18),
            const Text('CONNECTION URL',
                style: TextStyle(
                    color: T.t3,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2)),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                  color: T.bg,
                  borderRadius: BorderRadius.circular(T.r2),
                  border: Border.all(color: T.border)),
              child: TextField(
                controller: _ctrl,
                obscureText: _hide,
                style: const TextStyle(
                    color: T.t1,
                    fontSize: T.fontBase,
                    fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: 'mysql://user:pass@host:3306/db',
                  hintStyle:
                      const TextStyle(color: T.t4, fontSize: T.fontBase),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _hide
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: T.t3,
                        size: 16),
                    onPressed: () => setState(() => _hide = !_hide),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            const Text('mysql://username:password@hostname:3306/dbname',
                style: TextStyle(color: T.t3, fontSize: 10)),
            const SizedBox(height: 16),
            if (widget.db.isConnected)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                    color: T.successLight,
                    borderRadius: BorderRadius.circular(T.r1),
                    border: Border.all(
                        color: T.success.withValues(alpha: 0.2))),
                child: Row(children: [
                  const Icon(Icons.check_circle_rounded,
                      color: T.success, size: 14),
                  const SizedBox(width: 6),
                  Text('Connected to ${widget.db.dbName}',
                      style: const TextStyle(
                          color: T.success,
                          fontSize: T.fontSm,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            Row(children: [
              if (widget.db.isConnected) ...[
                Expanded(
                  child: _Btn(
                    label: 'Disconnect',
                    onTap: () {
                      widget.db.disconnect();
                      Navigator.pop(ctx);
                    },
                    outline: true,
                    danger: true,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                flex: 2,
                child: _Btn(
                  label: _loading ? 'Connecting…' : 'Connect',
                  onTap: _loading ? null : _connect,
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  void _connect() async {
    final url = _ctrl.text.trim();
    if (url.isEmpty) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 700));
    widget.db.connect(url);
    if (mounted) Navigator.pop(context);
  }
}

// ─────────────────────────────────────────────
// BOTTOM BAR
// ─────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final int idx;
  final ValueChanged<int> onTap;
  const _BottomBar({required this.idx, required this.onTap});

  static const _items = [
    (icon: Icons.upload_file_rounded, label: 'Upload'),
    (icon: Icons.table_rows_rounded, label: 'Database'),
    (icon: Icons.manage_search_rounded, label: 'Query'),
    (icon: Icons.settings_outlined, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: T.white,
        border: Border(top: BorderSide(color: T.border)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 4,
        top: 4,
      ),
      child: Row(
        children: List.generate(_items.length, (i) {
          final sel = i == idx;
          return Expanded(
            child: TextButton(
              onPressed: () => onTap(i),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(T.r1)),
                overlayColor: T.accentLight,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: sel ? T.accentLight : Colors.transparent,
                      borderRadius: BorderRadius.circular(T.r4),
                    ),
                    child: Icon(_items[i].icon,
                        size: 20, color: sel ? T.accent : T.t3),
                  ),
                  const SizedBox(height: 2),
                  Text(_items[i].label,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              sel ? FontWeight.w700 : FontWeight.w400,
                          color: sel ? T.accent : T.t3)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SCREEN: UPLOAD
// ─────────────────────────────────────────────
class UploadScreen extends StatelessWidget {
  final DbState db;
  const UploadScreen({super.key, required this.db});

  @override
  Widget build(BuildContext ctx) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _PageHeader(
            title: 'Import Data',
            subtitle: 'Choose a source to extract & store',
            badge: null),
        const SizedBox(height: 18),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.3,
          children: const [
            _InputTile(
                icon: Icons.image_outlined,
                label: 'Image / Photo',
                sub: 'JPG, PNG, handwritten',
                color: Color(0xFF2563EB)),
            _InputTile(
                icon: Icons.mic_none_rounded,
                label: 'Voice',
                sub: 'Speak to enter data',
                color: Color(0xFF7C3AED)),
            _InputTile(
                icon: Icons.description_outlined,
                label: 'Document',
                sub: 'PDF, Word, text',
                color: Color(0xFFD97706)),
            _InputTile(
                icon: Icons.grid_on_rounded,
                label: 'Spreadsheet',
                sub: 'CSV, Excel files',
                color: Color(0xFF16A34A)),
            _InputTile(
                icon: Icons.edit_note_rounded,
                label: 'Manual Entry',
                sub: 'Type data directly',
                color: Color(0xFFDB2777)),
            _InputTile(
                icon: Icons.link_rounded,
                label: 'Paste URL',
                sub: 'Extract from web',
                color: Color(0xFF0891B2)),
          ],
        ),
        const SizedBox(height: 22),
        const _SectionLabel('Recent Activity'),
        const SizedBox(height: 10),
        const _EmptyCard(
          icon: Icons.inbox_outlined,
          title: 'No imports yet',
          sub: 'Upload something to get started',
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
// SCREEN: DATABASE
// ─────────────────────────────────────────────
class DatabaseScreen extends StatelessWidget {
  final DbState db;
  const DatabaseScreen({super.key, required this.db});

  @override
  Widget build(BuildContext ctx) {
    return AnimatedBuilder(
      animation: db,
      builder: (ctx, _) {
        if (!db.isConnected) return const _NoDbState();
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PageHeader(
                    title: 'Database',
                    subtitle: db.dbName,
                    badge: 'Connected'),
                const SizedBox(height: 16),
                Row(children: const [
                  Expanded(
                      child: _StatBox(
                          label: 'Tables',
                          value: '0',
                          icon: Icons.table_rows_outlined)),
                  SizedBox(width: 8),
                  Expanded(
                      child: _StatBox(
                          label: 'Records',
                          value: '0',
                          icon: Icons.data_array_rounded)),
                  SizedBox(width: 8),
                  Expanded(
                      child: _StatBox(
                          label: 'Size',
                          value: '0 KB',
                          icon: Icons.storage_outlined)),
                ]),
                const SizedBox(height: 22),
                Row(children: [
                  const _SectionLabel('Tables'),
                  const Spacer(),
                  _SmallBtn(
                      icon: Icons.add_rounded,
                      label: 'New Table',
                      onTap: () {}),
                ]),
                const SizedBox(height: 10),
                const _EmptyCard(
                  icon: Icons.table_view_outlined,
                  title: 'No tables yet',
                  sub: 'Upload data to auto-generate schemas',
                ),
              ]),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// SCREEN: QUERY
// ─────────────────────────────────────────────
class QueryScreen extends StatefulWidget {
  final DbState db;
  const QueryScreen({super.key, required this.db});

  @override
  State<QueryScreen> createState() => _QueryScreenState();
}

class _QueryScreenState extends State<QueryScreen> {
  final _ctrl = TextEditingController();
  bool _showSql = false;
  String _sql = '';

  final _suggestions = const [
    'Show all records from students table',
    'Find entries with marks above 90',
    'Count total records by category',
    'Get the latest 10 entries',
  ];

  @override
  Widget build(BuildContext ctx) {
    return AnimatedBuilder(
      animation: widget.db,
      builder: (ctx, _) {
        if (!widget.db.isConnected) return const _NoDbState();
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _PageHeader(
                    title: 'Query',
                    subtitle: 'Ask in plain English',
                    badge: null),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                      color: T.white,
                      borderRadius: BorderRadius.circular(T.r2),
                      border: Border.all(color: T.border),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2))
                      ]),
                  child: Column(children: [
                    TextField(
                      controller: _ctrl,
                      maxLines: 3,
                      minLines: 2,
                      style: const TextStyle(
                          color: T.t1, fontSize: T.fontMd),
                      decoration: const InputDecoration(
                        hintText:
                            'e.g. "Show all students with marks above 80"',
                        hintStyle:
                            TextStyle(color: T.t4, fontSize: T.fontBase),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(14),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      decoration: const BoxDecoration(
                          border: Border(
                              top: BorderSide(color: T.border))),
                      child: Row(children: [
                        GestureDetector(
                          onTap: () =>
                              setState(() => _showSql = !_showSql),
                          child: Row(children: [
                            Icon(
                              _showSql
                                  ? Icons.toggle_on_rounded
                                  : Icons.toggle_off_rounded,
                              color: _showSql ? T.accent : T.t3,
                              size: 20,
                            ),
                            const SizedBox(width: 5),
                            Text('Show SQL',
                                style: TextStyle(
                                    fontSize: T.fontSm,
                                    color: _showSql ? T.accent : T.t2)),
                          ]),
                        ),
                        const Spacer(),
                        _Btn(
                          label: 'Run Query',
                          onTap: () => setState(() {
                            _sql =
                                'SELECT * FROM students\nWHERE marks > 80\nORDER BY marks DESC;';
                          }),
                          small: true,
                        ),
                      ]),
                    ),
                  ]),
                ),
                if (_showSql && _sql.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _SqlBlock(sql: _sql),
                ],
                const SizedBox(height: 20),
                const _SectionLabel('Try asking'),
                const SizedBox(height: 8),
                ..._suggestions.map((s) => _SuggestionRow(
                    text: s,
                    onTap: () => setState(() => _ctrl.text = s))),
                const SizedBox(height: 20),
                const _SectionLabel('Results'),
                const SizedBox(height: 8),
                const _EmptyCard(
                    icon: Icons.search_off_rounded,
                    title: 'No results yet',
                    sub: 'Run a query to see data here'),
              ]),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// SCREEN: SETTINGS
// ─────────────────────────────────────────────
class SettingsScreen extends StatefulWidget {
  final DbState db;
  const SettingsScreen({super.key, required this.db});

  @override
  State<SettingsScreen> createState() => _SettingsState();
}

class _SettingsState extends State<SettingsScreen> {
  bool _validate = true;
  bool _confidence = true;
  bool _autoSchema = true;
  double _threshold = 0.7;

  @override
  Widget build(BuildContext ctx) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _PageHeader(
            title: 'Settings',
            subtitle: 'APIs & preferences',
            badge: null),
        const SizedBox(height: 20),
        const _SectionLabel('API Keys'),
        const SizedBox(height: 8),
        _KeyTile(
            icon: Icons.auto_awesome_rounded,
            iconBg: T.accentLight,
            iconColor: T.accent,
            title: 'Claude API Key',
            sub: 'Schema generation & NL→SQL'),
        _KeyTile(
            icon: Icons.image_search_rounded,
            iconBg: T.warningLight,
            iconColor: T.warning,
            title: 'Google Vision API Key',
            sub: 'Image OCR extraction'),
        _KeyTile(
            icon: Icons.mic_rounded,
            iconBg: const Color(0xFFF5F3FF),
            iconColor: const Color(0xFF7C3AED),
            title: 'Whisper API Key',
            sub: 'Voice transcription'),
        const SizedBox(height: 20),
        const _SectionLabel('Extraction'),
        const SizedBox(height: 8),
        _ToggleRow(
            icon: Icons.schema_outlined,
            iconBg: T.successLight,
            iconColor: T.success,
            title: 'Auto Schema Generation',
            sub: 'Create tables from extracted data',
            value: _autoSchema,
            onChanged: (v) => setState(() => _autoSchema = v)),
        _ToggleRow(
            icon: Icons.verified_outlined,
            iconBg: T.accentLight,
            iconColor: T.accent,
            title: 'Intelligent Validation',
            sub: 'Flag anomalies and invalid values',
            value: _validate,
            onChanged: (v) => setState(() => _validate = v)),
        _ToggleRow(
            icon: Icons.percent_rounded,
            iconBg: T.warningLight,
            iconColor: T.warning,
            title: 'Confidence Scores',
            sub: 'Show reliability of each field',
            value: _confidence,
            onChanged: (v) => setState(() => _confidence = v)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: T.white,
              borderRadius: BorderRadius.circular(T.r2),
              border: Border.all(color: T.border)),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Text('Confidence Threshold',
                      style: TextStyle(
                          color: T.t1,
                          fontSize: T.fontMd,
                          fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: T.accentLight,
                        borderRadius: BorderRadius.circular(T.r4)),
                    child: Text('${(_threshold * 100).round()}%',
                        style: const TextStyle(
                            color: T.accent,
                            fontSize: T.fontSm,
                            fontWeight: FontWeight.w700)),
                  ),
                ]),
                const SizedBox(height: 2),
                const Text(
                    'Verify fields below this confidence level',
                    style: TextStyle(color: T.t3, fontSize: T.fontSm)),
                SliderTheme(
                  data: SliderTheme.of(ctx).copyWith(
                    activeTrackColor: T.accent,
                    inactiveTrackColor: T.border,
                    thumbColor: T.accent,
                    overlayColor: T.accentLight,
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 7),
                  ),
                  child: Slider(
                    value: _threshold,
                    min: 0.5,
                    max: 1.0,
                    divisions: 10,
                    onChanged: (v) => setState(() => _threshold = v),
                  ),
                ),
              ]),
        ),
        const SizedBox(height: 20),
        const _SectionLabel('About'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: T.white,
              borderRadius: BorderRadius.circular(T.r2),
              border: Border.all(color: T.border)),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: T.accentLight,
                  borderRadius: BorderRadius.circular(T.r1)),
              child: const Icon(Icons.hub_rounded,
                  color: T.accent, size: 16),
            ),
            const SizedBox(width: 12),
            const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DataBridge v1.0.0',
                      style: TextStyle(
                          color: T.t1,
                          fontSize: T.fontMd,
                          fontWeight: FontWeight.w600)),
                  Text('Multimodal Database Management',
                      style: TextStyle(color: T.t3, fontSize: T.fontSm)),
                ]),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
// REUSABLE WIDGETS
// ─────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? badge;
  const _PageHeader(
      {required this.title,
      required this.subtitle,
      required this.badge});

  @override
  Widget build(BuildContext ctx) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: T.t1,
                        fontSize: T.font2xl,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        color: T.t2, fontSize: T.fontBase)),
              ]),
          if (badge != null) ...[
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                  color: T.successLight,
                  borderRadius: BorderRadius.circular(T.r4),
                  border: Border.all(
                      color: T.success.withValues(alpha: 0.25))),
              child: Text(badge!,
                  style: const TextStyle(
                      color: T.success,
                      fontSize: T.fontSm,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext ctx) => Text(text.toUpperCase(),
      style: const TextStyle(
          color: T.t3,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4));
}

class _InputTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  const _InputTile(
      {required this.icon,
      required this.label,
      required this.sub,
      required this.color});

  @override
  Widget build(BuildContext ctx) => Material(
        color: T.white,
        borderRadius: BorderRadius.circular(T.r2),
        child: InkWell(
          borderRadius: BorderRadius.circular(T.r2),
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(T.r2),
                border: Border.all(color: T.border)),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(T.r1)),
                    child: Icon(icon, color: color, size: 17),
                  ),
                  const Spacer(),
                  Text(label,
                      style: const TextStyle(
                          color: T.t1,
                          fontSize: T.fontBase,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 1),
                  Text(sub,
                      style: const TextStyle(
                          color: T.t3, fontSize: T.fontSm)),
                ]),
          ),
        ),
      );
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatBox(
      {required this.label,
      required this.value,
      required this.icon});

  @override
  Widget build(BuildContext ctx) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: T.white,
            borderRadius: BorderRadius.circular(T.r2),
            border: Border.all(color: T.border)),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: T.t4, size: 15),
              const SizedBox(height: 8),
              Text(value,
                  style: const TextStyle(
                      color: T.t1,
                      fontSize: T.fontXl,
                      fontWeight: FontWeight.w800)),
              Text(label,
                  style: const TextStyle(
                      color: T.t3, fontSize: T.fontSm)),
            ]),
      );
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  const _EmptyCard(
      {required this.icon, required this.title, required this.sub});

  @override
  Widget build(BuildContext ctx) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
            color: T.white,
            borderRadius: BorderRadius.circular(T.r2),
            border: Border.all(color: T.border)),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: T.bg,
                shape: BoxShape.circle,
                border: Border.all(color: T.border)),
            child: Icon(icon, color: T.t4, size: 22),
          ),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(
                  color: T.t1,
                  fontSize: T.fontMd,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(sub,
              style:
                  const TextStyle(color: T.t3, fontSize: T.fontBase)),
        ]),
      );
}

class _NoDbState extends StatelessWidget {
  const _NoDbState();

  @override
  Widget build(BuildContext ctx) => Center(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                      color: T.accentLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: T.accentMid)),
                  child: const Icon(Icons.storage_outlined,
                      color: T.accent, size: 30),
                ),
                const SizedBox(height: 16),
                const Text('No Database Connected',
                    style: TextStyle(
                        color: T.t1,
                        fontSize: T.fontXl,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text(
                  'Tap "Connect DB" at the top\nto link your MySQL database.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: T.t2,
                      fontSize: T.fontBase,
                      height: 1.6),
                ),
              ]),
        ),
      );
}

class _SqlBlock extends StatelessWidget {
  final String sql;
  const _SqlBlock({required this.sql});

  @override
  Widget build(BuildContext ctx) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(T.r2)),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('GENERATED SQL',
                  style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.3)),
              const SizedBox(height: 6),
              Text(sql,
                  style: const TextStyle(
                      color: Color(0xFF7DD3FC),
                      fontSize: T.fontBase,
                      fontFamily: 'monospace',
                      height: 1.6)),
            ]),
      );
}

class _SuggestionRow extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _SuggestionRow({required this.text, required this.onTap});

  @override
  Widget build(BuildContext ctx) => Material(
        color: T.white,
        borderRadius: BorderRadius.circular(T.r2),
        child: InkWell(
          borderRadius: BorderRadius.circular(T.r2),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(T.r2),
                border: Border.all(color: T.border)),
            child: Row(children: [
              const Icon(Icons.north_west_rounded, color: T.t4, size: 13),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(text,
                      style: const TextStyle(
                          color: T.t2, fontSize: T.fontBase))),
            ]),
          ),
        ),
      );
}

class _KeyTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String sub;
  const _KeyTile(
      {required this.icon,
      required this.iconBg,
      required this.iconColor,
      required this.title,
      required this.sub});

  @override
  Widget build(BuildContext ctx) => Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: T.white,
            borderRadius: BorderRadius.circular(T.r2),
            border: Border.all(color: T.border)),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(T.r1)),
            child: Icon(icon, color: iconColor, size: 15),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        color: T.t1,
                        fontSize: T.fontBase,
                        fontWeight: FontWeight.w600)),
                Text(sub,
                    style: const TextStyle(
                        color: T.t3, fontSize: T.fontSm)),
              ])),
          _SmallBtn(
              icon: Icons.edit_rounded, label: 'Set', onTap: () {}),
        ]),
      );
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow(
      {required this.icon,
      required this.iconBg,
      required this.iconColor,
      required this.title,
      required this.sub,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext ctx) => Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: T.white,
            borderRadius: BorderRadius.circular(T.r2),
            border: Border.all(color: T.border)),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(T.r1)),
            child: Icon(icon, color: iconColor, size: 15),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        color: T.t1,
                        fontSize: T.fontBase,
                        fontWeight: FontWeight.w600)),
                Text(sub,
                    style: const TextStyle(
                        color: T.t3, fontSize: T.fontSm)),
              ])),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: T.accent,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: T.border,
            ),
          ),
        ]),
      );
}

// ─────────────────────────────────────────────
// PRIMITIVE BUTTONS
// ─────────────────────────────────────────────

class _Btn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool outline;
  final bool danger;
  final bool small;
  const _Btn({
    required this.label,
    required this.onTap,
    this.outline = false,
    this.danger = false,
    this.small = false,
  });

  @override
  Widget build(BuildContext ctx) {
    final bg = outline
        ? Colors.transparent
        : danger
            ? T.danger
            : T.accent;
    final fg = outline
        ? danger
            ? T.danger
            : T.accent
        : Colors.white;
    final side = outline
        ? BorderSide(
            color: danger
                ? T.danger.withValues(alpha: 0.4)
                : T.accent.withValues(alpha: 0.4))
        : BorderSide.none;

    return Material(
      color: onTap == null ? T.bg : bg,
      borderRadius: BorderRadius.circular(T.r1),
      child: InkWell(
        borderRadius: BorderRadius.circular(T.r1),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: small ? 14 : 18,
              vertical: small ? 8 : 11),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(T.r1),
              border: Border.fromBorderSide(side)),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    color: onTap == null ? T.t3 : fg,
                    fontSize: small ? T.fontSm : T.fontBase,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}

class _SmallBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SmallBtn(
      {required this.icon,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext ctx) => Material(
        color: T.bg,
        borderRadius: BorderRadius.circular(T.r1),
        child: InkWell(
          borderRadius: BorderRadius.circular(T.r1),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(T.r1),
                border: Border.all(color: T.border)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, color: T.t2, size: 12),
              const SizedBox(width: 4),
              Text(label,
                  style: const TextStyle(
                      color: T.t2,
                      fontSize: T.fontSm,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      );
}