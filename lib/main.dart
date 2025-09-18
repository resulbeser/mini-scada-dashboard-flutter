import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;

/// -------------------- STATE: APP (örnek sayaç + sahte değerler) --------------------
class AppState extends ChangeNotifier {
  int _counter = 0;
  int get counter => _counter;

  void runStep() {
    _counter++;
    notifyListeners();
  }

  void reset() {
    _counter = 0;
    notifyListeners();
  }

  // Sahte “ölçüm” değerleri (counter’dan türetiyoruz)
  double get mainsL1 => (200 + (_counter % 60)).toDouble(); // 200..259V
  double get mainsL2 => (210 + (_counter % 50)).toDouble(); // 210..259V
  double get mainsL3 => (200 + (_counter % 40)).toDouble(); // 200..239V

  double get gensetL1 => (200 + (_counter % 55)).toDouble();
  double get gensetL2 => (210 + (_counter % 45)).toDouble();
  double get gensetL3 => (200 + (_counter % 35)).toDouble();

  double get fuelOffice => ((_counter % 100) / 100); // 0..1
  double get fuelFactory => (((_counter + 35) % 100) / 100); // 0..1
}

/// -------------------- STATE: WEBSOCKET --------------------
class WebSocketState extends ChangeNotifier {
  WebSocketChannel? _channel;
  bool _connected = false;
  String _lastMessage = '';

  bool get connected => _connected;
  String get lastMessage => _lastMessage;

  Future<void> connect() async {
    // Web platformu için daha güvenilir alternatifler
    final testUrls = [
      'wss://ws.postman-echo.com/raw',
      'wss://socketsbay.com/wss/v2/1/demo/',
      'wss://echo-websocket.herokuapp.com/',
    ];

    for (String url in testUrls) {
      try {
        print('Trying to connect to: $url');
        _channel = WebSocketChannel.connect(Uri.parse(url));
        _connected = true;
        notifyListeners();

        _channel!.stream.listen(
          (event) {
            _lastMessage = event?.toString() ?? '';
            notifyListeners();
          },
          onDone: () {
            _connected = false;
            notifyListeners();
          },
          onError: (e) {
            _connected = false;
            _lastMessage = 'WebSocket error: $e';
            notifyListeners();
          },
        );

        print('Successfully connected to: $url');
        return; // Başarılı bağlantı, döngüden çık
      } catch (e) {
        print('Failed to connect to $url: $e');
        continue;
      }
    }

    // Hiçbiri çalışmazsa
    _connected = false;
    _lastMessage = 'All WebSocket connections failed';
    notifyListeners();
  }

  void send(String data) {
    final ch = _channel;
    if (ch != null) ch.sink.add(data);
  }

  Future<void> disconnect() async {
    final ch = _channel;
    _connected = false;
    notifyListeners();
    await ch?.sink.close(ws_status.goingAway);
    _channel = null;
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

/// -------------------- APP --------------------
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => WebSocketState()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mini SCADA Dashboard',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        useMaterial3: true,
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Uygulama açılınca WebSocket’e bağlan
    Future.microtask(() => context.read<WebSocketState>().connect());
  }

  @override
  void dispose() {
    context.read<WebSocketState>().disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ws = context.watch<WebSocketState>();
    final app = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mini SCADA Dashboard'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                Icon(
                  ws.connected ? Icons.cloud_done : Icons.cloud_off,
                  color: ws.connected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 6),
                Text(ws.connected ? 'Connected' : 'Disconnected'),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: LayoutBuilder(
          builder: (context, c) {
            final isWide = c.maxWidth > 900;
            return isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _leftColumn(context)),
                      const SizedBox(width: 14),
                      Expanded(child: _rightColumn(context)),
                    ],
                  )
                : ListView(
                    children: [
                      _leftColumn(context),
                      const SizedBox(height: 14),
                      _rightColumn(context),
                    ],
                  );
          },
        ),
      ),
      bottomNavigationBar: Container(
        color: Theme.of(context).colorScheme.surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            FilledButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('RUN (+1 & send)'),
              onPressed: () {
                context.read<AppState>().runStep();
                context.read<WebSocketState>().send(
                  'RUN ${DateTime.now().toIso8601String()} '
                  'counter=${app.counter}',
                );
              },
            ),
            const SizedBox(width: 10),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.stop),
              label: const Text('STOP (reset & send)'),
              onPressed: () {
                context.read<AppState>().reset();
                context.read<WebSocketState>().send(
                  'STOP ${DateTime.now().toIso8601String()}',
                );
              },
            ),
            const Spacer(),
            Text(
              'Last WS msg: ${ws.lastMessage.isEmpty ? "-" : ws.lastMessage}',
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _leftColumn(BuildContext context) {
    final app = context.watch<AppState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          title: 'Mains Summary',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: GaugeCard(
                      title: 'Mains L1',
                      value: app.mainsL1,
                      min: 180,
                      max: 260,
                      unit: 'V',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GaugeCard(
                      title: 'Mains L2',
                      value: app.mainsL2,
                      min: 180,
                      max: 260,
                      unit: 'V',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GaugeCard(
                      title: 'Mains L3',
                      value: app.mainsL3,
                      min: 180,
                      max: 260,
                      unit: 'V',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TableCard(
                title: 'Mains Values',
                rows: const ['L1', 'L2', 'L3'],
                values: [
                  app.mainsL1,
                  app.mainsL2,
                  app.mainsL3,
                ].map((e) => '${e.toStringAsFixed(0)} V').toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Fuel Level',
          child: Column(
            children: [
              FuelBar(title: 'Office D-500', level: app.fuelOffice),
              const SizedBox(height: 8),
              FuelBar(title: 'Factory D-500', level: app.fuelFactory),
            ],
          ),
        ),
      ],
    );
  }

  Widget _rightColumn(BuildContext context) {
    final app = context.watch<AppState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          title: 'Genset Summary',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: GaugeCard(
                      title: 'Genset L1',
                      value: app.gensetL1,
                      min: 180,
                      max: 260,
                      unit: 'V',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GaugeCard(
                      title: 'Genset L2',
                      value: app.gensetL2,
                      min: 180,
                      max: 260,
                      unit: 'V',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GaugeCard(
                      title: 'Genset L3',
                      value: app.gensetL3,
                      min: 180,
                      max: 260,
                      unit: 'V',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TableCard(
                title: 'Engine Summary',
                rows: const ['RPM', 'Oil Temp', 'Fuel %'],
                values: [
                  1500 + (app.counter % 200),
                  60 + (app.counter % 20),
                  (app.fuelOffice * 100),
                ].map((e) => e.toStringAsFixed(0)).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Controls',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              ControlChip(icon: Icons.bolt, label: 'MAINS'),
              ControlChip(icon: Icons.power, label: 'GENSET'),
              ControlChip(icon: Icons.handyman, label: 'MAN'),
              ControlChip(icon: Icons.auto_mode, label: 'AUTO'),
            ],
          ),
        ),
      ],
    );
  }
}

/// -------------------- UI WIDGETS --------------------
class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const SectionCard({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: ShapeDecoration(shape: border),
              padding: const EdgeInsets.all(12),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class GaugeCard extends StatelessWidget {
  final String title;
  final double value, min, max;
  final String unit;
  const GaugeCard({
    super.key,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = ((value - min) / (max - min)).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 120,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(6),
              child: Column(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: ratio,
                        widthFactor: 0.6,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('${value.toStringAsFixed(0)} $unit'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class TableCard extends StatelessWidget {
  final String title;
  final List<String> rows;
  final List<String> values;
  const TableCard({
    super.key,
    required this.title,
    required this.rows,
    required this.values,
  });

  @override
  Widget build(BuildContext context) {
    assert(rows.length == values.length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),
        DataTable(
          columns: const [
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Value')),
          ],
          rows: List.generate(rows.length, (i) {
            return DataRow(
              cells: [DataCell(Text(rows[i])), DataCell(Text(values[i]))],
            );
          }),
          headingTextStyle: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          dataTextStyle: Theme.of(context).textTheme.bodyMedium,
          columnSpacing: 24,
        ),
      ],
    );
  }
}

class FuelBar extends StatelessWidget {
  final String title;
  final double level; // 0..1
  const FuelBar({super.key, required this.title, required this.level});

  @override
  Widget build(BuildContext context) {
    final pct = (level * 100).clamp(0, 100).toStringAsFixed(0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: level.clamp(0.0, 1.0),
            minHeight: 18,
          ),
        ),
        const SizedBox(height: 4),
        Align(alignment: Alignment.centerRight, child: Text('%$pct')),
      ],
    );
  }
}

class ControlChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const ControlChip({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onSelected: (_) {},
      selected: false,
    );
  }
}
