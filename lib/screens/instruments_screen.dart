import 'package:flutter/material.dart';
import 'package:tuna/icons/myna_solid.dart';
import 'package:tuna/services/instrument_catalog.dart';
import 'package:tuna/widgets/instrument_mark.dart';
import 'package:tuna/widgets/top_bar.dart';
import 'package:tuna/widgets/tuna_scope.dart';

class InstrumentRouteArgs {
  final bool editing;

  const InstrumentRouteArgs({this.editing = false});
}

class InstrumentsScreen extends StatefulWidget {
  const InstrumentsScreen({super.key});

  @override
  State<InstrumentsScreen> createState() => _InstrumentsScreenState();
}

class _InstrumentsScreenState extends State<InstrumentsScreen> {
  bool? _editing;

  bool get editing => _editing ?? false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    _editing ??= args is InstrumentRouteArgs && args.editing;
  }

  @override
  Widget build(BuildContext context) {
    final app = TunaScope.of(context);
    final selectedId = app.selectedInstrumentId;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              title: 'Instruments',
              buttonLeft: IconButton(
                icon: const Icon(MynaSolid.xHexagon),
                tooltip: 'Close',
                onPressed: () => Navigator.maybePop(context),
              ),
              buttonRight: IconButton(
                icon: Icon(editing ? MynaSolid.check : MynaSolid.list),
                tooltip: editing ? 'Done arranging' : 'Arrange',
                onPressed: () => setState(() => _editing = !editing),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Text(
                editing
                    ? 'Hide a tuning or drag it to change the order.'
                    : 'Choose a tuning, or stay chromatic.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (!editing)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: _TuningTile(
                  title: 'Chromatic',
                  subtitle: 'Nearest equal-tempered note',
                  selected: selectedId == null,
                  icon: const Icon(MynaSolid.music, size: 28),
                  onTap: () {
                    app.selectInstrument(null);
                    Navigator.maybePop(context);
                  },
                ),
              ),
            Expanded(
              child: editing
                  ? _ArrangeList(entries: app.orderedInstruments)
                  : _TuningGrid(entries: app.visibleInstruments, selectedId: selectedId),
            ),
          ],
        ),
      ),
    );
  }
}

class _TuningGrid extends StatelessWidget {
  final List<CatalogEntry> entries;
  final String? selectedId;

  const _TuningGrid({required this.entries, required this.selectedId});

  @override
  Widget build(BuildContext context) {
    final app = TunaScope.of(context);
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.35,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _TuningTile(
          title: entry.instrument.name,
          subtitle: entry.familyName,
          selected: entry.id == selectedId,
          icon: InstrumentMark(familyId: entry.familyId),
          onTap: () {
            app.selectInstrument(entry.id);
            Navigator.maybePop(context);
          },
        );
      },
    );
  }
}

class _ArrangeList extends StatelessWidget {
  final List<CatalogEntry> entries;

  const _ArrangeList({required this.entries});

  @override
  Widget build(BuildContext context) {
    final app = TunaScope.of(context);
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: entries.length,
      onReorderItem: app.reorderInstruments,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final visible = app.grid.visibilityMap[entry.id] ?? true;
        return Padding(
          key: ValueKey(entry.id),
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: visible ? Colors.black : Colors.black26),
            ),
            child: ListTile(
              leading: Opacity(
                opacity: visible ? 1 : 0.35,
                child: InstrumentMark(familyId: entry.familyId),
              ),
              title: Text(entry.instrument.name),
              subtitle: Text(entry.familyName),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: visible ? 'Hide' : 'Show',
                    icon: Icon(visible ? MynaSolid.eye : MynaSolid.eyeOff),
                    onPressed: () => app.toggleInstrumentVisibility(entry.id),
                  ),
                  ReorderableDragStartListener(
                    index: index,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(MynaSolid.moveVertical),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TuningTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final Widget icon;
  final VoidCallback onTap;

  const _TuningTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.black : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.black),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              IconTheme(
                data: IconThemeData(
                  color: selected ? Colors.white : Colors.black,
                ),
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    selected ? Colors.white : Colors.black,
                    BlendMode.srcIn,
                  ),
                  child: icon,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? Colors.white70 : Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
