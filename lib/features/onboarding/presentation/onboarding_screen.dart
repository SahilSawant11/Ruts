import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/auth/app_user.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/format/money.dart';
import '../../../core/local/backup_service.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/buttons/named_buttons.dart';
import '../../masters/data/master_import_service.dart';
import '../../masters/data/masters_providers.dart';
import '../../sales/data/models/material_dto.dart';
import '../../settings/data/settings_providers.dart';
import '../../auth/presentation/widgets/auth_panel.dart';
import '../data/onboarding_providers.dart';
import '../data/opening_stock_service.dart';

/// First-run setup: pick the day the old system closed, make sure the
/// products exist, enter closing stock (sheet or by hand), confirm.
/// Owners and managers only; a cashier is asked to fetch one.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null || user.role == UserRole.cashier) {
      return AuthPanel(
        icon: AppIcons.store,
        title: 'Store setup isn\'t finished',
        subtitle: 'The owner or a manager needs to enter the store\'s opening stock before billing can start. '
            'Ask them to sign in on this computer.',
        children: [
          SecondaryButton(
            label: 'Sign out',
            icon: AppIcons.logout,
            expand: true,
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      );
    }
    return const _Wizard();
  }
}

enum _Step { date, products, stock, review }

class _Wizard extends ConsumerStatefulWidget {
  const _Wizard();

  @override
  ConsumerState<_Wizard> createState() => _WizardState();
}

class _WizardState extends ConsumerState<_Wizard> {
  _Step _step = _Step.date;
  late DateTime _asOf = DateUtils.dateOnly(DateTime.now()).subtract(const Duration(days: 1));

  List<MaterialDto> _materials = const [];
  final Map<String, int> _qty = {};
  List<ClosingStockRow> _newProducts = const [];
  List<String> _problems = const [];
  String? _sheetName;
  String? _productImportMessage;
  String _search = '';
  int _gridVersion = 0; // bump to rebuild qty fields after an import
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final materials = await ref.read(mastersRepositoryProvider).getMaterials();
    final stock = await ref.read(openingStockServiceProvider).currentStock();
    if (!mounted) return;
    setState(() {
      _materials = [...materials.where((m) => m.isActive)]
        ..sort((a, b) => '${a.category}${a.name}${a.packing}'.compareTo('${b.category}${b.name}${b.packing}'));
      for (final m in _materials) {
        _qty.putIfAbsent(m.id, () => stock[m.id] ?? 0);
      }
      _gridVersion++;
    });
  }

  int get _bottles => _qty.values.fold(0, (a, b) => a + b) + _newProducts.fold(0, (a, p) => a + p.qty);
  int get _stockedProducts => _qty.values.where((q) => q > 0).length + _newProducts.where((p) => p.qty > 0).length;

  // ── actions ──────────────────────────────────────────────────────────

  Future<void> _importProducts() async {
    setState(() => _error = null);
    try {
      final summary = await ref.read(masterImportServiceProvider).pickAndImport(MasterImportTarget.materials);
      if (summary == null) return;
      setState(() => _productImportMessage = summary.message);
      await _reload();
    } catch (e) {
      setState(() => _error = '$e');
    }
  }

  Future<void> _importStock() async {
    setState(() => _error = null);
    const types = XTypeGroup(label: 'Excel or CSV', extensions: ['xlsx', 'xls', 'csv']);
    final file = await openFile(acceptedTypeGroups: const [types], confirmButtonText: 'Import');
    if (file == null) return;
    setState(() => _busy = true);
    try {
      final service = ref.read(openingStockServiceProvider);
      final problems = <String>[];
      final rows = await service.readSheet(file, problems: problems);
      final match = OpeningStockService.match(rows, _materials);
      setState(() {
        // A sheet is the full closing position: products it doesn't list are 0.
        for (final m in _materials) {
          _qty[m.id] = match.qtyByMaterial[m.id] ?? 0;
        }
        _newProducts = match.newProducts;
        _problems = [...problems, ...match.problems];
        _sheetName = file.name;
        _gridVersion++;
      });
    } on FormatException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Could not read ${file.name}: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finish() async {
    final user = ref.read(currentUserProvider);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(openingStockServiceProvider).apply(
            asOf: _asOf,
            qtyByMaterial: _qty,
            newProducts: _newProducts,
            enteredBy: user?.username ?? 'unknown',
          );
      ref.invalidate(materialsListProvider);
      ref.invalidate(needsOnboardingProvider);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not save opening stock: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Moving to a new or reinstalled computer: load a Caskly backup instead
  /// of entering opening stock. The backup carries its own setup, users
  /// and bills, so the wizard is skipped after the restart.
  Future<void> _restoreBackup() async {
    final picked = await openFile(acceptedTypeGroups: const [
      XTypeGroup(label: 'Caskly backup', extensions: ['sqlite', 'db']),
    ]);
    if (picked == null || !mounted) return;
    final file = File(picked.path);
    final invalid = BackupService.validateBackup(file);
    if (invalid != null) {
      setState(() => _error = invalid);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore this backup?'),
        content: Text(
          'Caskly will load all products, stock, bills and users from\n${file.uri.pathSegments.last}.\n\n'
          'After the restart, sign in with a username and password from that backup.',
        ),
        actions: [
          SecondaryButton(label: 'Cancel', onPressed: () => Navigator.of(ctx).pop(false)),
          PrimaryButton(label: 'Restore', onPressed: () => Navigator.of(ctx).pop(true)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(backupServiceProvider).stageRestore(file);
      AppLogger.info('Onboarding', 'Restore staged from ${file.path}');
    } catch (e, st) {
      AppLogger.error('Onboarding', e, st);
      if (mounted) setState(() => _error = 'Could not restore: $e');
      return;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Restart to finish restore'),
        content: const Text('Caskly will now close. Open it again to load your data.'),
        actions: [PrimaryButton(label: 'Close Caskly', onPressed: () => exit(0))],
      ),
    );
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _asOf,
      firstDate: today.subtract(const Duration(days: 366)),
      lastDate: today,
    );
    if (picked != null) setState(() => _asOf = picked);
  }

  bool get _canContinue => switch (_step) {
        _Step.date => true,
        _Step.products => true,
        _Step.stock => _materials.isNotEmpty || _newProducts.isNotEmpty,
        _Step.review => !_busy,
      };

  void _next() {
    if (_step == _Step.review) {
      _finish();
    } else {
      setState(() {
        _error = null;
        _step = _Step.values[_step.index + 1];
      });
    }
  }

  void _back() => setState(() {
        _error = null;
        _step = _Step.values[_step.index - 1];
      });

  // ── layout ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      body: Row(
        children: [
          _Rail(step: _step),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(48, 44, 48, 0),
                    child: switch (_step) {
                      _Step.date => _dateStep(context),
                      _Step.products => _productsStep(context),
                      _Step.stock => _stockStep(context),
                      _Step.review => _reviewStep(context),
                    },
                  ),
                ),
                _footer(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(48, 16, 48, 20),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.borderFor(context)))),
      child: Row(
        children: [
          if (_error != null)
            Expanded(child: Text(_error!, style: AppTypography.caption.copyWith(color: AppColors.danger)))
          else
            const Spacer(),
          if (_step != _Step.date) ...[
            SecondaryButton(label: 'Back', icon: AppIcons.chevronLeft, onPressed: _busy ? null : _back),
            const SizedBox(width: 12),
          ],
          PrimaryButton(
            label: switch (_step) {
              _Step.review => _busy ? 'Saving…' : 'Start using Caskly',
              _ => 'Continue',
            },
            icon: _step == _Step.review ? AppIcons.check : AppIcons.arrowForward,
            onPressed: _canContinue && !_busy ? _next : null,
          ),
        ],
      ),
    );
  }

  Widget _heading(BuildContext context, String title, String subtitle) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.h1.copyWith(fontSize: 30, height: 1.1)),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Text(subtitle,
                style: AppTypography.body.copyWith(height: 1.55, color: AppColors.textSecondaryFor(context))),
          ),
          const SizedBox(height: 28),
        ],
      );

  Widget _dateStep(BuildContext context) {
    final next = _asOf.add(const Duration(days: 1));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(
            context,
            'When did your old system close?',
            'Pick the last day you billed on your old software. You\'ll enter the stock you had at the end of that day, '
                'and Caskly carries on from there.'),
        _Panel(
          child: Row(
            children: [
              const AppIcon(AppIcons.calendar, size: 22),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CLOSING STOCK AS OF',
                      style: AppTypography.label.copyWith(color: AppColors.textMutedFor(context))),
                  const SizedBox(height: 4),
                  Text(_fmtDate(_asOf), style: AppTypography.h2),
                ],
              ),
              const SizedBox(width: 32),
              SecondaryButton(label: 'Change date', onPressed: _pickDate),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Billing in Caskly starts ${_fmtDate(next)}.',
            style: AppTypography.body.copyWith(color: AppColors.textSecondaryFor(context))),
        const Spacer(),
        _restoreOffer(context),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _restoreOffer(BuildContext context) {
    final isOwner = ref.watch(currentUserProvider)?.role == UserRole.owner;
    final muted = AppTypography.body.copyWith(color: AppColors.textSecondaryFor(context));
    return Container(
      padding: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.borderFor(context)))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Already using Caskly on another computer?', style: AppTypography.sectionTitleFor(context)),
                const SizedBox(height: 4),
                Text(
                  isOwner
                      ? 'Restore a Caskly backup instead. Your products, stock, bills and users come with it.'
                      : 'The owner can restore a Caskly backup here instead of entering stock.',
                  style: muted,
                ),
              ],
            ),
          ),
          if (isOwner) ...[
            const SizedBox(width: 24),
            SecondaryButton(
              label: 'Restore from backup…',
              icon: AppIcons.upload,
              onPressed: _busy ? null : _restoreBackup,
            ),
          ],
        ],
      ),
    );
  }

  Widget _productsStep(BuildContext context) {
    final count = _materials.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(
          context,
          count == 0 ? 'Add your products' : 'Your products',
          count == 0
              ? 'Import your brand list from Excel (SCM code, name, category, size, MRP). If your closing stock sheet '
                  'already has those columns, you can skip this — products are added from it in the next step.'
              : 'These are the products Caskly knows about. Import more if anything is missing; '
                  'your closing stock sheet can also add products it finds.',
        ),
        _Panel(
          child: Row(
            children: [
              Text(Money.group(count, decimals: 0), style: AppTypography.h1.copyWith(fontSize: 34)),
              const SizedBox(width: 12),
              Text(count == 1 ? 'product' : 'products', style: AppTypography.bodyMuted),
              const Spacer(),
              SecondaryButton(label: 'Import products', icon: AppIcons.uploadFile, onPressed: _importProducts),
            ],
          ),
        ),
        if (_productImportMessage != null) ...[
          const SizedBox(height: 12),
          Text(_productImportMessage!,
              style: AppTypography.caption.copyWith(color: AppColors.textSecondaryFor(context))),
        ],
      ],
    );
  }

  Widget _stockStep(BuildContext context) {
    final q = _search.trim().toLowerCase();
    final rows = q.isEmpty
        ? _materials
        : _materials
            .where((m) =>
                m.name.toLowerCase().contains(q) || m.id.toLowerCase().contains(q) || m.barcode.toLowerCase() == q)
            .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(
            context,
            'Enter closing stock',
            'Import the closing stock report from your old software, or type the bottles on hand for each product. '
                'Products you leave at 0 start with no stock.'),
        Row(
          children: [
            PrimaryButton(
              label: _busy ? 'Reading…' : 'Import closing stock',
              icon: AppIcons.uploadFile,
              onPressed: _busy ? null : _importStock,
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 280,
              height: 44,
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                style: AppTypography.body,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  hintText: 'Search product or code',
                  prefixIconConstraints: BoxConstraints(minWidth: 40, minHeight: 40),
                  prefixIcon: AppIcon(AppIcons.search, size: 18),
                ),
              ),
            ),
            const Spacer(),
            _Totals(products: _stockedProducts, bottles: _bottles),
          ],
        ),
        if (_sheetName != null || _newProducts.isNotEmpty || _problems.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SheetReport(sheet: _sheetName, newProducts: _newProducts, problems: _problems),
        ],
        const SizedBox(height: 12),
        Expanded(
          child: _Panel(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                const _GridHeader(),
                Expanded(
                  child: rows.isEmpty
                      ? Center(
                          child: Text(
                              _materials.isEmpty
                                  ? 'No products yet. Import your closing stock sheet to add them.'
                                  : 'No product matches "$_search".',
                              style: AppTypography.bodyMuted))
                      : ListView.builder(
                          itemCount: rows.length,
                          itemExtent: 48,
                          itemBuilder: (context, i) {
                            final m = rows[i];
                            return _StockRow(
                              key: ValueKey('${m.id}#$_gridVersion'),
                              material: m,
                              qty: _qty[m.id] ?? 0,
                              onChanged: (v) => setState(() => _qty[m.id] = v),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _reviewStep(BuildContext context) {
    final byCategory = <String, int>{};
    for (final m in _materials) {
      final q = _qty[m.id] ?? 0;
      if (q > 0) byCategory[m.category] = (byCategory[m.category] ?? 0) + q;
    }
    for (final p in _newProducts) {
      if (p.qty > 0) byCategory[p.category] = (byCategory[p.category] ?? 0) + p.qty;
    }
    final cats = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(context, 'Check and confirm',
              'This becomes your opening stock. After this, stock changes only through bills, purchases and returns.'),
          _Panel(
            child: Column(
              children: [
                _ReviewLine('Closing stock as of', _fmtDate(_asOf), text: true),
                _ReviewLine('Billing starts', _fmtDate(_asOf.add(const Duration(days: 1))), text: true),
                _ReviewLine('Products with stock', Money.group(_stockedProducts, decimals: 0)),
                if (_newProducts.isNotEmpty)
                  _ReviewLine('New products to add', Money.group(_newProducts.length, decimals: 0)),
                _ReviewLine('Total bottles', Money.group(_bottles, decimals: 0), strong: true),
              ],
            ),
          ),
          if (cats.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('BY CATEGORY', style: AppTypography.label.copyWith(color: AppColors.textMutedFor(context))),
            const SizedBox(height: 8),
            _Panel(
              child: Column(children: [for (final c in cats) _ReviewLine(c.key, Money.group(c.value, decimals: 0))]),
            ),
          ],
          if (_bottles == 0) ...[
            const SizedBox(height: 16),
            Text('You haven\'t entered any stock. You can still continue and add stock through purchases.',
                style: AppTypography.body.copyWith(color: AppColors.warning)),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

String _fmtDate(DateTime d) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
}

// ── pieces ─────────────────────────────────────────────────────────────

class _Rail extends StatelessWidget {
  const _Rail({required this.step});
  final _Step step;

  static const _labels = {
    _Step.date: 'Closing date',
    _Step.products: 'Products',
    _Step.stock: 'Closing stock',
    _Step.review: 'Confirm',
  };

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF141218), cream = Color(0xFFF3EFE6);
    return Container(
      width: 280,
      color: ink,
      padding: const EdgeInsets.fromLTRB(32, 40, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset('assets/branding/caskly_mark_light.svg', width: 44, height: 44),
          const SizedBox(height: 28),
          Text('Set up your store', style: AppTypography.h2.copyWith(color: cream)),
          const SizedBox(height: 8),
          Text('One-time. Takes a few minutes.',
              style: AppTypography.caption.copyWith(color: cream.withValues(alpha: 0.55))),
          const SizedBox(height: 36),
          for (final s in _Step.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: s.index < step.index ? cream : Colors.transparent,
                      border:
                          Border.all(color: s.index <= step.index ? cream : cream.withValues(alpha: 0.25), width: 1.5),
                    ),
                    child: s.index < step.index
                        ? const AppIcon(AppIcons.check, size: 14, color: ink)
                        : Text('${s.index + 1}',
                            style: AppTypography.caption.copyWith(
                                color: s == step ? cream : cream.withValues(alpha: 0.4), fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    _labels[s]!,
                    style: AppTypography.body.copyWith(
                      color: s == step ? cream : cream.withValues(alpha: s.index < step.index ? 0.75 : 0.4),
                      fontWeight: s == step ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding = const EdgeInsets.all(20)});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderFor(context)),
        ),
        child: child,
      );
}

class _Totals extends StatelessWidget {
  const _Totals({required this.products, required this.bottles});
  final int products;
  final int bottles;

  @override
  Widget build(BuildContext context) {
    final muted = AppTypography.caption.copyWith(color: AppColors.textMutedFor(context));
    return Row(
      children: [
        Text(Money.group(products, decimals: 0), style: AppTypography.mono.copyWith(fontWeight: FontWeight.w700)),
        Text('  products  ·  ', style: muted),
        Text(Money.group(bottles, decimals: 0), style: AppTypography.mono.copyWith(fontWeight: FontWeight.w700)),
        Text('  bottles', style: muted),
      ],
    );
  }
}

class _SheetReport extends StatelessWidget {
  const _SheetReport({required this.sheet, required this.newProducts, required this.problems});
  final String? sheet;
  final List<ClosingStockRow> newProducts;
  final List<String> problems;

  @override
  Widget build(BuildContext context) {
    final muted = AppTypography.caption.copyWith(color: AppColors.textSecondaryFor(context));
    return _Panel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sheet != null)
            Text('Imported $sheet', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
          if (newProducts.isNotEmpty)
            Text(
                '${newProducts.length} product${newProducts.length == 1 ? '' : 's'} from the sheet will be added '
                '(${newProducts.take(3).map((p) => p.name).join(', ')}${newProducts.length > 3 ? ', …' : ''}).',
                style: muted),
          if (problems.isNotEmpty)
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                dense: true,
                title: Text('${problems.length} row${problems.length == 1 ? '' : 's'} skipped — see why',
                    style: AppTypography.caption.copyWith(color: AppColors.warning, fontWeight: FontWeight.w700)),
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 140),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final p in problems)
                          Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(p, style: muted))
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _GridHeader extends StatelessWidget {
  const _GridHeader();

  @override
  Widget build(BuildContext context) {
    final s = AppTypography.label.copyWith(color: AppColors.textMutedFor(context));
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceAltFor(context),
        border: Border(bottom: BorderSide(color: AppColors.borderFor(context))),
      ),
      child: Row(
        children: [
          SizedBox(width: 130, child: Text('SCM CODE', style: s)),
          Expanded(child: Text('PRODUCT', style: s)),
          SizedBox(width: 110, child: Text('SIZE', style: s)),
          SizedBox(width: 140, child: Text('CATEGORY', style: s)),
          SizedBox(width: 120, child: Text('CLOSING QTY', style: s, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class _StockRow extends StatefulWidget {
  const _StockRow({super.key, required this.material, required this.qty, required this.onChanged});
  final MaterialDto material;
  final int qty;
  final ValueChanged<int> onChanged;

  @override
  State<_StockRow> createState() => _StockRowState();
}

class _StockRowState extends State<_StockRow> {
  late final _controller = TextEditingController(text: widget.qty == 0 ? '' : '${widget.qty}');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.material;
    final muted = AppTypography.caption.copyWith(color: AppColors.textSecondaryFor(context));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderFor(context)))),
      child: Row(
        children: [
          SizedBox(
              width: 130,
              child: Text(m.id, style: AppTypography.mono.copyWith(fontSize: 12), overflow: TextOverflow.ellipsis)),
          Expanded(child: Text(m.name, style: AppTypography.body, overflow: TextOverflow.ellipsis)),
          SizedBox(width: 110, child: Text(m.packing, style: muted, overflow: TextOverflow.ellipsis)),
          SizedBox(width: 140, child: Text(m.category, style: muted, overflow: TextOverflow.ellipsis)),
          SizedBox(
            width: 120,
            height: 34,
            child: TextField(
              controller: _controller,
              textAlign: TextAlign.right,
              style: AppTypography.mono.copyWith(fontWeight: FontWeight.w600),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                isDense: true,
                hintText: '0',
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              onChanged: (v) => widget.onChanged(int.tryParse(v) ?? 0),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewLine extends StatelessWidget {
  const _ReviewLine(this.label, this.value, {this.strong = false, this.text = false});
  final String label;
  final String value;
  final bool strong;

  /// Words (dates) rather than a number: body font instead of mono.
  final bool text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Text(label, style: AppTypography.body.copyWith(color: AppColors.textSecondaryFor(context))),
            const Spacer(),
            Text(value,
                style: (strong
                        ? AppTypography.h2
                        : text
                            ? AppTypography.body
                            : AppTypography.mono)
                    .copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      );
}
