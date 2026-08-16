import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../models/models.dart';
import '../services/api.dart';
import '../state/auth.dart';
import '../theme/palette.dart';
import '../utils/format.dart';
import '../widgets/domain.dart';
import '../widgets/ui.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  CameraController? _camera;
  bool busy = false;
  bool starting = false;
  bool torch = false;
  bool permissionDenied = false;
  String? error;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    ref.listenManual<bool>(scanTabActiveProvider, (previous, next) {
      if (next) {
        _startCamera();
      } else {
        _stopCamera();
      }
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _camera?.dispose();
    super.dispose();
  }

  Future<void> _startCamera() async {
    if (_camera != null || starting) return;
    setState(() {
      starting = true;
      permissionDenied = false;
      error = null;
    });
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          starting = false;
          error = 'No camera is available on this device.';
        });
        return;
      }
      final back = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted || !ref.read(scanTabActiveProvider)) {
        await controller.dispose();
        return;
      }
      setState(() {
        _camera = controller;
        starting = false;
      });
    } on CameraException catch (e) {
      setState(() {
        starting = false;
        permissionDenied = e.code.toLowerCase().contains('denied') || e.code.toLowerCase().contains('access');
        error = permissionDenied
            ? 'Camera access is needed to read labels.'
            : (e.description ?? e.code);
      });
    } catch (e) {
      setState(() {
        starting = false;
        error = describeError(e);
      });
    }
  }

  Future<void> _stopCamera() async {
    torch = false;
    final controller = _camera;
    _camera = null;
    if (controller != null) {
      await controller.dispose();
    }
    if (mounted) setState(() {});
  }

  Future<void> submitImage(XFile file) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final bytes = await File(file.path).readAsBytes();
      final mime = file.mimeType ?? (file.path.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg');
      final result = await Api.scan({
        'imageBase64': base64Encode(bytes),
        'mimeType': mime,
      });
      scanHolder.scan = result;
      if (mounted) context.push('/scan/review');
    } catch (e) {
      setState(() => error = describeError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> capture() async {
    final controller = _camera;
    if (busy) return;
    if (controller == null || !controller.value.isInitialized) {
      await _startCamera();
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final shot = await controller.takePicture();
      await submitImage(shot);
    } catch (e) {
      setState(() {
        busy = false;
        error = describeError(e);
      });
    }
  }

  Future<void> pick() async {
    if (busy) return;
    try {
      final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (file != null) await submitImage(file);
    } catch (e) {
      setState(() => error = describeError(e));
    }
  }

  Future<void> toggleTorch() async {
    final controller = _camera;
    if (controller == null) return;
    try {
      final next = !torch;
      await controller.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      setState(() => torch = next);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final controller = _camera;
    final ready = controller != null && controller.value.isInitialized;

    if (permissionDenied && !ready) {
      return Scaffold(
        backgroundColor: Palette.canvas,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 48, 28, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.camera_alt_outlined, size: 36, color: Palette.brand),
                const SizedBox(height: 16),
                Text('Camera access is needed to read labels', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                const Text(
                  'MedGuard reads the medication name and ingredients from the label. The photo is processed to extract text and is not stored.',
                ),
                const Spacer(),
                PrimaryButton(label: 'Allow camera access', onPressed: _startCamera),
                const SizedBox(height: 12),
                SecondaryButton(label: 'Enter label text instead', onPressed: () => context.push('/scan/manual')),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Palette.ink,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.hardEdge,
        children: [
          if (ready)
            _CoveredCameraPreview(controller: controller)
          else
            ColoredBox(color: Palette.ink),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
              child: Column(
                children: [
                  const Text(
                    'Scan medication label',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Place the medication name and ingredients inside the frame.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                  const Expanded(child: Center(child: _ScanFrame())),
                  if (busy)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                          SizedBox(width: 8),
                          Text('Reading the label…', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    )
                  else if (starting)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text('Opening camera…', style: TextStyle(color: Colors.white70)),
                    ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CircleAction(icon: Icons.photo_library_outlined, onPressed: busy ? null : pick),
                      GestureDetector(
                        onTap: busy ? null : capture,
                        child: Container(
                          height: 72,
                          width: 72,
                          decoration: BoxDecoration(
                            color: busy ? Colors.white38 : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: Icon(Icons.camera_alt, size: 28, color: Palette.ink),
                        ),
                      ),
                      _CircleAction(
                        icon: torch ? Icons.flash_on : Icons.flash_off_outlined,
                        onPressed: busy ? null : toggleTorch,
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => context.push('/scan/manual'),
                    child: const Text(
                      'Type the label text instead',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoveredCameraPreview extends StatelessWidget {
  const _CoveredCameraPreview({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    final preview = controller.value.previewSize;
    final width = preview == null ? 9.0 : preview.height;
    final height = preview == null ? 16.0 : preview.width;
    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.center,
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: width,
            height: height,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      style: IconButton.styleFrom(backgroundColor: Colors.white24, foregroundColor: Colors.white, minimumSize: const Size(56, 56)),
      icon: Icon(icon),
    );
  }
}

class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 256, maxWidth: 420),
      child: const AspectRatio(
        aspectRatio: 4 / 3,
        child: Stack(
          children: [
            Align(alignment: Alignment.topLeft, child: _Corner(top: true, left: true)),
            Align(alignment: Alignment.topRight, child: _Corner(top: true, left: false)),
            Align(alignment: Alignment.bottomLeft, child: _Corner(top: false, left: true)),
            Align(alignment: Alignment.bottomRight, child: _Corner(top: false, left: false)),
          ],
        ),
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  const _Corner({required this.top, required this.left});

  final bool top;
  final bool left;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        border: Border(
          top: top ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
          bottom: top ? BorderSide.none : const BorderSide(color: Colors.white, width: 4),
          left: left ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
          right: left ? BorderSide.none : const BorderSide(color: Colors.white, width: 4),
        ),
        borderRadius: BorderRadius.only(
          topLeft: top && left ? const Radius.circular(16) : Radius.zero,
          topRight: top && !left ? const Radius.circular(16) : Radius.zero,
          bottomLeft: !top && left ? const Radius.circular(16) : Radius.zero,
          bottomRight: !top && !left ? const Radius.circular(16) : Radius.zero,
        ),
      ),
    );
  }
}

class ManualScanScreen extends ConsumerStatefulWidget {
  const ManualScanScreen({super.key});

  @override
  ConsumerState<ManualScanScreen> createState() => _ManualScanScreenState();
}

class _ManualScanScreenState extends ConsumerState<ManualScanScreen> {
  final controller = TextEditingController();
  bool busy = false;
  String? error;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (controller.text.trim().isEmpty) {
      setState(() => error = 'Type the text printed on the label first.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await Api.scan({'ocrText': controller.text});
      scanHolder.scan = result;
      if (mounted) context.replace('/scan/review');
    } catch (e) {
      setState(() => error = describeError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final demo = ref.watch(authProvider).user?.isDemoAccount == true;
    return ScreenScaffold(
      children: [
        const Align(alignment: Alignment.centerLeft, child: BackCircle()),
        Text('Type the label text', style: Theme.of(context).textTheme.headlineMedium),
        const Text(
          'Copy the medication name, the active ingredients and the directions exactly as printed. MedGuard matches them against trusted medication data and you confirm the result.',
        ),
        TextField(
          controller: controller,
          maxLines: 8,
          decoration: const InputDecoration(hintText: 'Brand name\nActive ingredient 500 mg\nDirections'),
        ),
        if (error != null) Text(error!, style: TextStyle(color: Palette.critical)),
        if (demo)
          Callout(
            title: 'Demo walkthrough',
            message: 'Use the sample Parol label to see a verified match.',
            child: SecondaryButton(label: 'Use the sample label', onPressed: () => setState(() => controller.text = demoLabel)),
          ),
        PrimaryButton(label: 'Continue', loading: busy, onPressed: submit),
      ],
    );
  }
}

class ScanReviewScreen extends ConsumerStatefulWidget {
  const ScanReviewScreen({super.key});

  @override
  ConsumerState<ScanReviewScreen> createState() => _ScanReviewScreenState();
}

class _ScanReviewScreenState extends ConsumerState<ScanReviewScreen> {
  late ScanDraft draft;
  String? selectedRxCui;
  bool busy = false;
  bool needsAck = false;
  bool ack = false;
  String? error;
  List<IngredientDraft> ingredients = [IngredientDraft()];
  final brand = TextEditingController();
  final generic = TextEditingController();
  final form = TextEditingController();
  final strength = TextEditingController();
  final route = TextEditingController();
  final directions = TextEditingController();
  DateTime? expirationDate;

  ScanResponse? get scan => scanHolder.scan;

  @override
  void initState() {
    super.initState();
    final current = scan;
    selectedRxCui = current?.candidates.firstOrNull?.rxCui;
    _applyDraft(ScanDraft.from(current, current?.candidates.firstOrNull));
  }

  @override
  void dispose() {
    brand.dispose();
    generic.dispose();
    form.dispose();
    strength.dispose();
    route.dispose();
    directions.dispose();
    super.dispose();
  }

  void _applyDraft(ScanDraft next) {
    draft = next;
    ingredients = next.ingredients;
    brand.text = next.brandName;
    generic.text = next.genericName;
    form.text = next.dosageForm;
    strength.text = next.strength;
    route.text = next.route;
    directions.text = next.directions;
    expirationDate = DateTime.tryParse(next.expirationDate);
  }

  Future<void> confirm(bool acknowledged) async {
    final current = scan;
    if (current == null) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final outcome = await Api.confirmScan(current.scanId, {
        'selectedCandidateRxCui': selectedRxCui,
        'brandName': brand.text.trim().isEmpty ? null : brand.text.trim(),
        'genericName': generic.text.trim().isEmpty ? null : generic.text.trim(),
        'ingredients': ingredients.where((i) => i.name.trim().isNotEmpty).map((i) => i.toJson()).toList(),
        'dosageForm': form.text.trim().isEmpty ? null : form.text.trim(),
        'strength': strength.text.trim().isEmpty ? null : strength.text.trim(),
        'route': route.text.trim().isEmpty ? null : route.text.trim(),
        'labelDirections': directions.text.trim().isEmpty ? null : directions.text.trim(),
        'acknowledgedUnverified': acknowledged,
        if (expirationDate != null)
          'expirationDate':
              '${expirationDate!.year.toString().padLeft(4, '0')}-${expirationDate!.month.toString().padLeft(2, '0')}-${expirationDate!.day.toString().padLeft(2, '0')}',
      });
      scanHolder.outcome = outcome;
      ref.read(dataRevisionProvider.notifier).state++;
      if (mounted) context.replace('/scan/result');
    } on ApiException catch (e) {
      if (e.code == 'unverified_requires_acknowledgement') {
        setState(() {
          needsAck = true;
          error = e.message;
        });
      } else {
        setState(() => error = e.message);
      }
    } catch (e) {
      setState(() => error = describeError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = scan;
    if (current == null) {
      return ScreenScaffold(
        children: [
          const Align(alignment: Alignment.centerLeft, child: BackCircle()),
          const Callout(title: 'Nothing to review', message: 'Scan a medication label to see the extracted details.'),
          PrimaryButton(label: 'Open the scanner', onPressed: () => context.go('/scan')),
        ],
      );
    }

    if (current.status == 'extraction_failed') {
      return ScreenScaffold(
        children: [
          const Align(alignment: Alignment.centerLeft, child: BackCircle()),
          Callout(tone: Tone.attention, title: "We couldn't read the label clearly", message: current.message),
          PrimaryButton(label: 'Try again', onPressed: () => context.go('/scan')),
          SecondaryButton(label: 'Enter the details manually', onPressed: () => context.replace('/medication/new')),
        ],
      );
    }

    final low = current.extractionConfidence < 0.7;
    final verified = current.verificationStatus.toLowerCase() == 'verified';

    return ScreenScaffold(
      children: [
        const Align(alignment: Alignment.centerLeft, child: BackCircle()),
        Text('Scan result', style: Theme.of(context).textTheme.headlineMedium),
        Text(current.message),
        if (low)
          Callout(
            tone: Tone.attention,
            title: 'Please review the details',
            message:
                'The label was read with ${formatConfidence(current.extractionConfidence)} confidence. Check every field against the label before confirming.',
          ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Used to verify', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              const Text(
                'MedGuard matches these fields against a trusted medication database. Edit them if the scan misread the label.',
              ),
              const SizedBox(height: 12),
              LabeledField(label: 'Brand name', controller: brand, hint: 'As printed on the box', usedForVerification: true),
              const SizedBox(height: 12),
              LabeledField(label: 'Generic name', controller: generic, usedForVerification: true),
              const SizedBox(height: 12),
              LabeledField(label: 'Strength', controller: strength, hint: '500 mg', usedForVerification: true),
              const SizedBox(height: 12),
              LabeledField(label: 'Dosage form', controller: form, hint: 'Tablet', usedForVerification: true),
              const SizedBox(height: 12),
              IngredientEditor(
                key: ValueKey(selectedRxCui ?? 'extracted'),
                ingredients: ingredients,
                onChanged: (v) => ingredients = v,
              ),
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('On the label only', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              const Text('These stay as you entered them. They are not used to verify the product.'),
              const SizedBox(height: 12),
              LabeledField(label: 'Route', controller: route, hint: 'Oral', usedForVerification: false),
              const SizedBox(height: 12),
              LabeledField(label: 'Label directions', controller: directions, maxLines: 3, usedForVerification: false),
              const SizedBox(height: 12),
              Text('Expiration date', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: expirationDate ?? now,
                    firstDate: DateTime(now.year - 1),
                    lastDate: DateTime(now.year + 15),
                  );
                  if (picked != null) setState(() => expirationDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(suffixIcon: Icon(Icons.calendar_today_outlined)),
                  child: Text(
                    expirationDate == null
                        ? 'Not set'
                        : formatDate(
                            '${expirationDate!.year.toString().padLeft(4, '0')}-${expirationDate!.month.toString().padLeft(2, '0')}-${expirationDate!.day.toString().padLeft(2, '0')}',
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Verification', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (verified) ...[
                const AppBadge(label: 'Verified', tone: Tone.safe, glyph: '✓'),
                if (current.candidates.firstOrNull?.provenance != null)
                  Text(
                    'Source: ${current.candidates.first.provenance.provider}${current.candidates.first.provenance.datasetVersion != null ? ' · dataset ${current.candidates.first.provenance.datasetVersion}' : ''}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
              ] else ...[
                const AppBadge(label: 'Not independently verified', tone: Tone.attention, glyph: '?'),
                const SizedBox(height: 8),
                const Text(
                  'MedGuard could not confirm this product against its medication data source. You can still save it, and it will stay marked as unverified.',
                ),
              ],
            ],
          ),
        ),
        if (current.candidates.isNotEmpty)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Candidate matches', style: Theme.of(context).textTheme.titleMedium),
                const Text('Choose the product that matches the label in your hand.'),
                const SizedBox(height: 8),
                for (final candidate in current.candidates)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => setState(() {
                        selectedRxCui = candidate.rxCui;
                        _applyDraft(ScanDraft.from(current, candidate));
                      }),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: candidate.rxCui == selectedRxCui ? Palette.brandSoft : Palette.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: candidate.rxCui == selectedRxCui ? Palette.brand : Palette.line),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(candidate.brandName, style: const TextStyle(fontWeight: FontWeight.w600))),
                                if (candidate.rxCui == selectedRxCui) Icon(Icons.check_circle, color: Palette.brand),
                              ],
                            ),
                            Text(
                              [candidate.genericName, candidate.strength, candidate.dosageForm, candidate.manufacturer]
                                  .whereType<String>()
                                  .where((v) => v.isNotEmpty)
                                  .join(' · '),
                            ),
                            Text('Match ${formatConfidence(candidate.matchScore)} · ${candidate.provenance.provider}', style: Theme.of(context).textTheme.labelSmall),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        if (needsAck)
          Callout(
            tone: Tone.attention,
            title: 'Save as unverified?',
            message: error ?? '',
            child: CheckboxRow(
              label: 'I understand this medication is not independently verified and I checked the details against the label.',
              checked: ack,
              onChanged: (v) => setState(() => ack = v),
            ),
          )
        else if (error != null)
          Text(error!, style: TextStyle(color: Palette.critical)),
        PrimaryButton(
          label: needsAck ? 'Save as unverified' : 'Confirm Medication',
          loading: busy,
          onPressed: needsAck && !ack ? null : () => confirm(needsAck ? ack : false),
        ),
        GhostButton(label: 'Scan again', onPressed: () => context.go('/scan')),
      ],
    );
  }
}

class ScanDraft {
  ScanDraft({
    required this.brandName,
    required this.genericName,
    required this.dosageForm,
    required this.strength,
    required this.route,
    required this.directions,
    required this.ingredients,
    required this.expirationDate,
  });

  String brandName;
  String genericName;
  String dosageForm;
  String strength;
  String route;
  String directions;
  List<IngredientDraft> ingredients;
  String expirationDate;

  factory ScanDraft.from(ScanResponse? scan, MedicationCandidate? candidate) {
    final extracted = scan?.extractedIngredients
            .map((i) => IngredientDraft(name: i['name'] ?? '', strength: i['strength'] ?? '', unit: i['unit'] ?? ''))
            .toList() ??
        [];
    final fromCandidate = candidate?.ingredients
            .map((i) => IngredientDraft(name: i.name, strength: i.strength ?? '', unit: i.unit ?? ''))
            .toList() ??
        [];
    final ingredients = fromCandidate.isNotEmpty ? fromCandidate : extracted;
    return ScanDraft(
      brandName: candidate?.brandName ?? scan?.field('brandName') ?? '',
      genericName: candidate?.genericName ?? scan?.field('genericName') ?? '',
      dosageForm: candidate?.dosageForm ?? scan?.field('dosageForm') ?? '',
      strength: candidate?.strength ?? '',
      route: scan?.field('route') ?? '',
      directions: scan?.field('directions') ?? '',
      ingredients: ingredients.isEmpty ? [IngredientDraft()] : ingredients,
      expirationDate: scan?.field('expirationDate') ?? '',
    );
  }
}

class ScanResultScreen extends StatelessWidget {
  const ScanResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final outcome = scanHolder.outcome;
    if (outcome == null) {
      return ScreenScaffold(
        children: [
          const Callout(title: 'Nothing to show', message: 'Scan and confirm a medication to see its safety result.'),
          PrimaryButton(label: 'Open the scanner', onPressed: () => context.go('/scan')),
        ],
      );
    }
    final medication = outcome.medication;
    final safety = outcome.safety;
    return ScreenScaffold(
      children: [
        Text('${medication.displayName} was saved', style: Theme.of(context).textTheme.headlineMedium),
        const Text('MedGuard checked it against the medications already in your list.'),
        SafetySummaryCard(analysis: safety),
        ...safety.findings.map((f) => FindingCard(finding: f)),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Saved medication', style: Theme.of(context).textTheme.titleMedium)),
                  AppBadge(
                    label: medication.verificationLabel,
                    tone: verificationTone(medication.verificationStatus),
                    glyph: verificationGlyph(medication.verificationStatus),
                  ),
                ],
              ),
              FieldRow(label: 'Brand', value: medication.brandName),
              FieldRow(label: 'Generic name', value: medication.genericName),
              FieldRow(
                label: 'Active ingredients',
                value: medication.ingredients.map((i) => '${i.normalizedName} ${i.displayStrength}'.trim()).join('\n'),
              ),
              FieldRow(label: 'Label directions', value: medication.labelDirections, divider: false),
            ],
          ),
        ),
        SafetyChecksCard(analysis: safety),
        if (outcome.scheduleSuggestion != null)
          PrimaryButton(label: 'Create reminders from the label', onPressed: () => context.replace('/schedule/${medication.id}')),
        SecondaryButton(label: 'View medication', onPressed: () => context.replace('/medication/${medication.id}')),
        GhostButton(
          label: 'Back to home',
          onPressed: () {
            scanHolder.scan = null;
            scanHolder.outcome = null;
            context.go('/home');
          },
        ),
      ],
    );
  }
}
