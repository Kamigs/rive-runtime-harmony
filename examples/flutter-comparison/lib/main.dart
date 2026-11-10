import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart' as rive;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await rive.RiveNative.init();
  runApp(const MaterialApp(home: Comparison()));
}

class Comparison extends StatefulWidget {
  const Comparison({super.key});
  @override
  State<Comparison> createState() => _ComparisonState();
}

class _ComparisonState extends State<Comparison> {
  rive.File? file;
  rive.RiveWidgetController? controller;
  rive.ViewModelInstance? viewModel;
  String status = 'Loading';
  final fixture = Uri.base.queryParameters['fixture'] ?? 'vehicles.riv';
  final factoryName = Uri.base.queryParameters['factory'] ?? 'rive';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final factory = factoryName == 'flutter' ? rive.Factory.flutter : rive.Factory.rive;
      file = await rive.File.asset('assets/$fixture', riveFactory: factory,
        assetLoader: (asset, bytes) {
          if (asset is rive.FontAsset && (bytes == null || bytes.isEmpty)) {
            rootBundle.load(asset.name == 'JetBrains Mono' ? 'assets/JetBrainsMono.ttf' : 'assets/Inter-Regular.ttf').then((data) async {
              final font = await factory.decodeFont(data.buffer.asUint8List());
              if (font != null && mounted) { asset.font(font); font.dispose(); }
            });
            return true;
          }
          return false;
        });
      controller = rive.RiveWidgetController(file!,
          artboardSelector: fixture == 'vehicles.riv'
              ? rive.ArtboardSelector.byName('Truck') : const rive.ArtboardDefault(),
          stateMachineSelector: fixture == 'vehicles.riv'
              ? rive.StateMachineSelector.byName('bumpy') : const rive.StateMachineDefault());
      if (fixture == 'rewards.riv' || fixture == 'layout_test.riv') { viewModel = controller!.dataBind(rive.DataBind.auto()); }
      controller!.stateMachine.addEventListener((event) {
        debugPrint('RiveComparison EVENT $event');
      });
      debugPrint('RiveComparison LOADED $fixture factory=$factoryName');
      setState(() => status = 'Loaded $fixture');
    } catch (error) {
      setState(() => status = 'ERROR $error');
      debugPrint(status);
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    file?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xfff3f4f6),
    body: Center(child: SizedBox(width: 700, child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Flutter rive 0.14.11 + rive_native 0.1.11', style: TextStyle(fontSize: 24)),
        Text('Factory.$factoryName · $status'),
        SizedBox(height: 420, child: controller == null ? const SizedBox() :
          rive.RiveWidget(controller: controller!, fit: fixture == 'layout_test.riv' ? rive.Fit.layout : rive.Fit.contain,
            layoutScaleFactor: fixture == 'layout_test.riv' ? 0.5 : 1)),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          ElevatedButton(onPressed: () {controller?.active = false; setState(() => status = 'Paused');}, child: const Text('Pause')),
          ElevatedButton(onPressed: () {controller?.active = true; setState(() => status = 'Playing');}, child: const Text('Resume')),
          ElevatedButton(onPressed: () {controller?.stateMachine.trigger('bump')?.fire(); setState(() => status = 'bump fired');}, child: const Text('bump')),
          if (fixture == 'skills.riv' || fixture == 'runtime-contract.riv') ElevatedButton(onPressed: () { controller?.stateMachine.number('Level')?.value = 2; setState(() => status = 'Level = 2'); }, child: const Text('Level 2')),
          if (fixture == 'runtime-contract.riv') ElevatedButton(onPressed: () { final input = controller?.stateMachine.boolean('enabled'); if (input != null) { input.value = !input.value; setState(() => status = 'enabled = ${input.value}'); } }, child: const Text('Enabled')),
          if (fixture == 'electrified_button_nested_text.riv' || fixture == 'runtime-contract.riv') ElevatedButton(onPressed: () { controller?.artboard.setText('button_text', 'MG CLUB CLI'); setState(() => status = 'Text = MG CLUB CLI'); }, child: const Text('Edit text')),
          if (fixture == 'rewards.riv') ElevatedButton(onPressed: () { viewModel?.number('Energy_Bar/Energy_Bar')?.value = 90; viewModel?.string('Button/State_1')?.value = 'MG CLUB'; setState(() => status = 'Energy = 90, MG CLUB'); }, child: const Text('Bind data')),
        ]),
      ],
    ))),
  );
}
