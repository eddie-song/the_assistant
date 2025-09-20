import 'package:flutter/material.dart';
import 'package:the_assistant/services/firebase_service.dart';

class EventsProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  Map<DateTime, List<Map<String, String>>> _eventsByDate = {};
  bool _isLoading = false;

  Map<DateTime, List<Map<String, String>>> get eventsByDate => _eventsByDate;
  bool get isLoading => _isLoading;

  // Singleton pattern
  static final EventsProvider _instance = EventsProvider._internal();
  factory EventsProvider() => _instance;
  EventsProvider._internal();

  Future<void> loadEvents() async {
    try {
      _isLoading = true;
      notifyListeners();

      final uid = await _firebaseService.getCurrentUserId();
      final idToken = await _firebaseService.getIdToken();
      final events = await _firebaseService.getAllEvents(idToken: idToken, uid: uid);

      final Map<DateTime, List<Map<String, String>>> mapped = {};
      for (final event in events) {
        final date = DateTime.parse(event['date']);
        final cleanDate = DateTime.utc(date.year, date.month, date.day);
        mapped.putIfAbsent(cleanDate, () => []).add({
          'title': event['title'] as String,
          'description': event['description'] as String? ?? '',
          'time': event['time'] as String? ?? '',
        });
      }

      _eventsByDate = mapped;
    } catch (e) {
      print("Failed to load events: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createEvent({
    required String title,
    required String date,
    String? time,
    String? description,
  }) async {
    try {
      await _firebaseService.createEvent(
        idToken: _firebaseService.getIdToken(),
        uid: _firebaseService.getCurrentUserId(),
        title: title,
        date: date,
        time: time ?? '',
        // description: description ?? '',
      );
      await loadEvents();
    } catch (e) {
      print("Failed to create event: $e");
      rethrow;
    }
  }

  Future<void> deleteEvent({
    required String title,
    required String date,
    String? time,
  }) async {
    try {
      await _firebaseService.deleteEvent(
        idToken: _firebaseService.getIdToken(),
        uid: _firebaseService.getCurrentUserId(),
        title: title,
        date: date,
        time: time ?? '',
      );
      await loadEvents();
    } catch (e) {
      print("Failed to delete event: $e");
      rethrow;
    }
  }

  Future<void> clearSchedule(String date) async {
    try {
      await _firebaseService.clearSchedule(
        idToken: _firebaseService.getIdToken(),
        uid: _firebaseService.getCurrentUserId(),
        date: date,
      );
      await loadEvents();
    } catch (e) {
      print("Failed to clear schedule: $e");
      rethrow;
    }
  }

  Future<List<Map<String, String>>> getSchedule(String date) async {
    try {
      final schedule = await _firebaseService.getSchedule(
        idToken: _firebaseService.getIdToken(),
        uid: _firebaseService.getCurrentUserId(),
        date: date,
      );
      
      return schedule.map((e) => {
        'title': e['title'] as String,
        'time': e['time'] as String? ?? '',
        'description': e['description'] as String? ?? '',
      }).toList();
    } catch (e) {
      print("Failed to get schedule: $e");
      rethrow;
    }
  }

  List<Map<String, String>> getEventsForDate(DateTime date) {
    final cleanDate = DateTime.utc(date.year, date.month, date.day);
    return _eventsByDate[cleanDate] ?? [];
  }
} 