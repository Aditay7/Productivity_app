import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cardio_sync_service.dart';

class StepTrackerService {
  StreamSubscription<StepCount>? _stepCountStream;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusStream;
  SharedPreferences? _prefs;

  // Trackers
  int _todaySteps = 0;
  Map<String, int> _hourlySteps = {};
  String _status = 'stopped';
  bool _isListening = false;
  String? _error;

  // Storage Keys
  static const String _kLastRawStepCount = 'cardio_last_raw_step_count';
  static const String _kTodayAccumulatedSteps =
      'cardio_today_accumulated_steps';
  static const String _kHourlySteps = 'cardio_hourly_steps';
  static const String _kLastSavedDate = 'cardio_last_saved_date';
  static const String _kDailyGoal = 'cardio_daily_goal';

  // Callbacks
  final Function(int) onStepCount;
  final Function(String) onStatusChanged;
  final Function(String) onError;

  StepTrackerService({
    required this.onStepCount,
    required this.onStatusChanged,
    required this.onError,
  });

  Future<void> initPlatformState() async {
    // Web fallback
    if (kIsWeb) {
      _error =
          'Step tracking is not supported on Web (requires physical hardware sensors).';
      onError(_error!);
      return;
    }

    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadSavedSteps();

      final status = await Permission.activityRecognition.request();
      if (status.isPermanentlyDenied || status.isRestricted) {
        _error =
            'Activity Recognition permission was denied permanently. You must grant it from settings.';
        onError(_error!);
        return;
      }

      if (status.isGranted) {
        _initStreams();
      } else {
        _error =
            'Tracking requires Activity Recognition permission. Tap to permit.';
        onError(_error!);
      }
    } catch (e) {
      _error = 'Failed to initialize pedometer: $e';
      onError(_error!);
    }
  }

  void _initStreams() {
    if (_isListening) return;

    try {
      _pedestrianStatusStream = Pedometer.pedestrianStatusStream.listen(
        _onPedestrianStatusChanged,
        onError: _onPedestrianStatusError,
        cancelOnError: true,
      );

      _stepCountStream = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: _onStepCountError,
        cancelOnError: true,
      );

      _isListening = true;

      // Immediately attempt to sync any old backlog queued when offline
      cardioSyncService.pushSyncQueue();
    } catch (e) {
      _error = 'Error starting pedometer stream: $e';
      onError(_error!);
    }
  }

  Future<void> _loadSavedSteps() async {
    final lastSavedDate = _prefs?.getString(_kLastSavedDate);
    final todayStr = _getTodayStr();

    if (lastSavedDate != todayStr) {
      // New day
      _todaySteps = 0;
      _hourlySteps = {};
      await _prefs?.setString(_kLastSavedDate, todayStr);
      await _prefs?.setInt(_kTodayAccumulatedSteps, 0);
      await _prefs?.setString(_kHourlySteps, jsonEncode(_hourlySteps));
    } else {
      // Load today's accumulated steps
      _todaySteps = _prefs?.getInt(_kTodayAccumulatedSteps) ?? 0;
      final hourlyStr = _prefs?.getString(_kHourlySteps);
      if (hourlyStr != null) {
        try {
          final decoded = jsonDecode(hourlyStr) as Map<String, dynamic>;
          _hourlySteps = decoded.map(
            (key, value) => MapEntry(key, value as int),
          );
        } catch (_) {
          _hourlySteps = {};
        }
      }
    }

    onStepCount(_todaySteps);
  }

  String _getTodayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void _onStepCount(StepCount event) async {
    if (_prefs == null) return;

    // Check if day rolled over while app was in background/listening
    final todayStr = _getTodayStr();
    final lastSavedDate = _prefs?.getString(_kLastSavedDate);

    if (lastSavedDate != todayStr) {
      _todaySteps = 0;
      _hourlySteps = {};
      await _prefs?.setString(_kLastSavedDate, todayStr);
      await _prefs?.setInt(_kTodayAccumulatedSteps, 0);
      await _prefs?.setString(_kHourlySteps, jsonEncode(_hourlySteps));
    }

    int currentRaw = event.steps;
    int lastRaw = _prefs?.getInt(_kLastRawStepCount) ?? currentRaw;

    int delta = currentRaw - lastRaw;

    if (delta < 0) {
      // Device was rebooted, step count reset natively to 0
      delta = currentRaw;
    }

    if (delta > 0) {
      _todaySteps += delta;
      await _prefs?.setInt(_kTodayAccumulatedSteps, _todaySteps);

      // Track hourly bucket
      final currentHour = DateTime.now().hour.toString().padLeft(2, '0');
      _hourlySteps[currentHour] = (_hourlySteps[currentHour] ?? 0) + delta;
      await _prefs?.setString(_kHourlySteps, jsonEncode(_hourlySteps));

      // Add to offline sync queue (Estimated ~0.04 cals and ~0.0008 km per step)
      await cardioSyncService.queueDailyLog(
        dateStr: todayStr,
        steps: _todaySteps,
        hourlyDistribution: _hourlySteps,
        caloriesBurned: _todaySteps * 0.04,
        distanceKm: _todaySteps * 0.0008,
      );

      // Attempt background push if we've accumulated > 10 steps since last push attempt
      // (A real production app would use flutter_workmanager for this)
      if (_todaySteps % 20 == 0) {
        cardioSyncService.pushSyncQueue();
      }
    }

    await _prefs?.setInt(_kLastRawStepCount, currentRaw);

    // Emit the true daily step count to the UI
    onStepCount(_todaySteps);
  }

  void _onPedestrianStatusChanged(PedestrianStatus event) {
    _status = event.status;
    onStatusChanged(_status);
  }

  void _onPedestrianStatusError(dynamic error) {
    _status = 'Pedestrian Status not available';
    onStatusChanged(_status);
  }

  void _onStepCountError(dynamic error) {
    _error =
        'Step Count not available. Are you using an emulator or web browser?';
    onError(_error!);
  }

  void stopTracking() {
    _stepCountStream?.cancel();
    _pedestrianStatusStream?.cancel();
    _isListening = false;
  }

  Future<void> saveDailyGoal(int goal) async {
    await _prefs?.setInt(_kDailyGoal, goal);
  }

  int getSavedDailyGoal() {
    return _prefs?.getInt(_kDailyGoal) ?? 8000;
  }

  // Exposed for the sync service
  Map<String, int> get hourlySteps => _hourlySteps;
  int get todaySteps => _todaySteps;
  String get todayDateStr => _getTodayStr();
}
