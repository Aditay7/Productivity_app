import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StepTrackerService {
  StreamSubscription<StepCount>? _stepCountStream;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusStream;
  SharedPreferences? _prefs;

  // Trackers
  int _todaySteps = 0;
  String _status = 'stopped';
  bool _isListening = false;
  String? _error;

  // Storage Keys
  static const String _kLastRawStepCount = 'cardio_last_raw_step_count';
  static const String _kTodayAccumulatedSteps =
      'cardio_today_accumulated_steps';
  static const String _kLastSavedDate = 'cardio_last_saved_date';

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
      await _prefs?.setString(_kLastSavedDate, todayStr);
      await _prefs?.setInt(_kTodayAccumulatedSteps, 0);
    } else {
      // Load today's accumulated steps
      _todaySteps = _prefs?.getInt(_kTodayAccumulatedSteps) ?? 0;
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
      await _prefs?.setString(_kLastSavedDate, todayStr);
      await _prefs?.setInt(_kTodayAccumulatedSteps, 0);
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
}
