import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuna/models/app_settings.dart';
import 'package:tuna/models/instrument_grid_config.dart';
import 'package:tuna/models/tempo.dart';
import 'package:tuna/services/instrument_catalog.dart';
import 'package:tuna/services/metronome_engine.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class AppController extends ChangeNotifier {
  AppController() {
    engine.bind(
      bpm: () => tempo.bpm,
      beatsPerBar: () => beatsPerBar,
      tickSound: () => settings.tickSound,
    );
  }

  final MetronomeEngine engine = MetronomeEngine();

  InstrumentCatalog catalog = InstrumentCatalog.empty;
  AppSettings settings = AppSettings.defaultSettings();
  InstrumentGridConfig grid = InstrumentGridConfig(
    orderedIds: const [],
    visibilityMap: const {},
  );
  Tempo tempo = Tempo(id: 'current', name: tempoMarking(120), bpm: 120);
  int beatsPerBar = 4;
  String? selectedInstrumentId;
  bool isReady = false;
  Object? loadError;

  SharedPreferences? _prefs;

  CatalogEntry? get selectedInstrument {
    final id = selectedInstrumentId;
    if (id == null) {
      return null;
    }
    return catalog.byId(id);
  }

  List<CatalogEntry> get orderedInstruments => [
    for (final id in grid.orderedIds) ?catalog.byId(id),
  ];

  List<CatalogEntry> get visibleInstruments => [
    for (final entry in orderedInstruments)
      if (grid.visibilityMap[entry.id] ?? true) entry,
  ];

  Future<void> load() async {
    try {
      final source = await rootBundle.loadString('assets/instruments.json');
      catalog = InstrumentCatalog.parse(source);
      _prefs = await SharedPreferences.getInstance();
      _readPrefs();
      grid = grid.reconcile(catalog.entries.map((entry) => entry.id));
      _ensureSelectionVisible();
      await _applyWakelock();
    } catch (error) {
      loadError = error;
    }
    isReady = true;
    notifyListeners();
  }

  void setSettings(AppSettings next) {
    settings = next;
    notifyListeners();
    unawaited(_persistSettings());
    unawaited(_applyWakelock());
  }

  void setTolerance(double cents) {
    setSettings(settings.copyWith(tuningTolerance: cents));
  }

  void setInTuneColor(int hex) {
    setSettings(settings.copyWith(colorOnCorrectHex: hex));
  }

  void setKeepAwake(bool enabled) {
    setSettings(settings.copyWith(keepDeviceAwake: enabled));
  }

  void setSaveEnergy(bool enabled) {
    setSettings(settings.copyWith(saveEnergy: enabled));
  }

  void setTickSound(TickSoundType sound) {
    setSettings(settings.copyWith(tickSound: sound));
  }

  void setFlashOnBeat(bool enabled) {
    setSettings(settings.copyWith(flashOnBeat: enabled));
  }

  void setBpm(double bpm) {
    final clamped = bpm.clamp(40, 240).toDouble();
    tempo = Tempo(id: 'current', name: tempoMarking(clamped), bpm: clamped);
    engine.retune();
    notifyListeners();
    unawaited(_persistTempo());
  }

  void bumpBpm(int delta) {
    setBpm(tempo.bpm.roundToDouble() + delta);
  }

  void setBeatsPerBar(int beats) {
    beatsPerBar = beats.clamp(2, 6);
    engine.retune();
    notifyListeners();
    unawaited(_prefs?.setInt(_beatsKey, beatsPerBar));
  }

  void selectInstrument(String? id) {
    selectedInstrumentId = id;
    notifyListeners();
    unawaited(_writeSelected());
  }

  void toggleInstrumentVisibility(String id) {
    final visible = grid.visibilityMap[id] ?? true;
    grid = grid.copyWith(
      visibilityMap: {...grid.visibilityMap, id: !visible},
    );
    _ensureSelectionVisible();
    notifyListeners();
    unawaited(_persistGrid());
  }

  void reorderInstruments(int oldIndex, int newIndex) {
    final ids = [...grid.orderedIds];
    if (oldIndex < 0 ||
        oldIndex >= ids.length ||
        newIndex < 0 ||
        newIndex >= ids.length ||
        oldIndex == newIndex) {
      return;
    }
    final moved = ids.removeAt(oldIndex);
    ids.insert(newIndex, moved);
    grid = grid.copyWith(orderedIds: ids);
    notifyListeners();
    unawaited(_persistGrid());
  }

  @override
  void dispose() {
    engine.dispose();
    super.dispose();
  }

  void _readPrefs() {
    final prefs = _prefs;
    if (prefs == null) {
      return;
    }
    final settingsRaw = prefs.getString(_settingsKey);
    if (settingsRaw != null) {
      settings = AppSettings.fromJson(
        Map<String, dynamic>.from(jsonDecode(settingsRaw) as Map),
      );
    }
    final gridRaw = prefs.getString(_gridKey);
    if (gridRaw != null) {
      grid = InstrumentGridConfig.fromJson(
        Map<String, dynamic>.from(jsonDecode(gridRaw) as Map),
      );
    }
    final tempoRaw = prefs.getString(_tempoKey);
    if (tempoRaw != null) {
      tempo = Tempo.fromJson(
        Map<String, dynamic>.from(jsonDecode(tempoRaw) as Map),
      );
    }
    beatsPerBar = (prefs.getInt(_beatsKey) ?? beatsPerBar).clamp(2, 6);
    if (prefs.containsKey(_selectedKey)) {
      selectedInstrumentId = prefs.getString(_selectedKey);
    }
  }

  void _ensureSelectionVisible() {
    final id = selectedInstrumentId;
    if (id == null) {
      return;
    }
    final known = catalog.byId(id) != null;
    final visible = grid.visibilityMap[id] ?? false;
    if (!known || !visible) {
      selectedInstrumentId = null;
    }
  }

  Future<void> _persistSettings() async {
    await _prefs?.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  Future<void> _persistGrid() async {
    await _prefs?.setString(_gridKey, jsonEncode(grid.toJson()));
  }

  Future<void> _persistTempo() async {
    await _prefs?.setString(_tempoKey, jsonEncode(tempo.toJson()));
  }

  Future<void> _writeSelected() async {
    final prefs = _prefs;
    if (prefs == null) {
      return;
    }
    final id = selectedInstrumentId;
    if (id == null) {
      await prefs.remove(_selectedKey);
    } else {
      await prefs.setString(_selectedKey, id);
    }
  }

  Future<void> _applyWakelock() async {
    try {
      if (settings.keepDeviceAwake) {
        await WakelockPlus.enable();
      } else {
        await WakelockPlus.disable();
      }
    } catch (_) {
      // The browser Wake Lock API can reject before a user gesture.
    }
  }
}

const _settingsKey = 'settings';
const _gridKey = 'instrumentGrid';
const _tempoKey = 'tempo';
const _beatsKey = 'beatsPerBar';
const _selectedKey = 'selectedInstrumentId';
