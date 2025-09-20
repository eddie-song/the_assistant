import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  String get apiKey => dotenv.env['FIREBASE_API_KEY'] ?? '';
  String get projectId => dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
  String? _currentUserId;
  String? _currentIdToken;

  /// Registers user using Firebase Auth REST
  Future<Map<String, dynamic>> registerWithEmailAndPassword(
    String email,
    String username,
    String password,
  ) async {
    final url = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey',
    );

    final response = await http.post(
      url,
      body: json.encode({
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      final String uid = data['localId'];
      final String idToken = data['idToken'];

      await saveUserToFirestore(
        idToken: idToken,
        uid: uid,
        email: email,
        username: username,
      );

      return data;
    } else {
      throw data['error']['message'] ?? 'Registration failed';
    }
  }

  /// Writes user data to Firestore using REST
  Future<void> saveUserToFirestore({
    required String idToken,
    required String uid,
    required String email,
    required String username,
  }) async {
    final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/users/$uid',
    );

    final body = {
      "fields": {
        "email": {"stringValue": email},
        "username": {"stringValue": username},
        "createdAt": {
          "timestampValue": DateTime.now().toUtc().toIso8601String()
        },
        "events": {"arrayValue": {"values": []}}, // Optional: Initialize with empty event list
      },
    };

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to write user data: ${response.body}');
    }
  }

  /// Signs in user using Firebase Auth REST
  Future<Map<String, dynamic>> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final url = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey',
    );

    final response = await http.post(
      url,
      body: json.encode({
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw data['error']['message'] ?? 'Login failed';
    }
  }

  /// Placeholder sign out
  Future<void> signOut() async {
    return;
  }

  // Login/Register setters
  void setAuthSession(String uid, String idToken) {
    _currentUserId = uid;
    _currentIdToken = idToken;
  }

  String getCurrentUserId() {
    if (_currentUserId == null) throw Exception("User not logged in.");
    return _currentUserId!;
  }

  String getIdToken() {
    if (_currentIdToken == null) throw Exception("No auth token available.");
    return _currentIdToken!;
  }

  Future<void> createEvent({
    required String idToken,
    required String uid,
    required String title,
    required String date,
    required String time,
    String? description,
  }) async {
    final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/users/$uid',
    );

    final timestamp = DateTime.parse("${date}T${time}:00Z").toUtc().toIso8601String();

    final getResponse = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );

    if (getResponse.statusCode != 200) {
      throw Exception("Failed to fetch current events: ${getResponse.body}");
    }

    final currentData = jsonDecode(getResponse.body);
    final currentEvents = currentData['fields']?['events']?['arrayValue']?['values'] ?? [];

    final newEvent = {
      "mapValue": {
        "fields": {
          "title": {"stringValue": title},
          "date": {"stringValue": date},
          "time": {"stringValue": time},
          if (description != null && description.isNotEmpty)
            "description": {"stringValue": description},
        }
      }
    };

    final updatedEvents = [...currentEvents, newEvent];

    final existingFields = currentData['fields'] ?? {};
    existingFields['events'] = {
      "arrayValue": {
        "values": updatedEvents
      }
    };

    final body = {
      "fields": existingFields,
    };

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to add event: ${response.body}");
    }
  }

  Future<List<Map<String, dynamic>>> getAllEvents({
    required String idToken,
    required String uid,
  }) async {
    final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/users/$uid',
    );

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to fetch events: ${response.body}");
    }

    final data = jsonDecode(response.body);
    final events = data['fields']?['events']?['arrayValue']?['values'] ?? [];

    return (events as List)
        .map((event) {
          final fields = event['mapValue']['fields'];
          return {
            "title": fields['title']?['stringValue'],
            "date": fields['date']?['stringValue'],
            "time": fields['time']?['stringValue'],
            "description": fields['description']?['stringValue'],
          };
        })
        .where((e) => e['title'] != null && e['date'] != null)
        .cast<Map<String, dynamic>>()
        .toList();
  }

  Future<List<Map<String, dynamic>>> getSchedule({
    required String idToken,
    required String uid,
    required String date,
  }) async {
    final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/users/$uid',
    );

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to fetch schedule: ${response.body}");
    }

    final data = jsonDecode(response.body);
    final events = data['fields']?['events']?['arrayValue']?['values'] ?? [];

    return (events as List)
        .map((event) {
          final fields = event['mapValue']['fields'];
          return {
            "title": fields['title']?['stringValue'],
            "date": fields['date']?['stringValue'],
            "time": fields['time']?['stringValue'],
            "description": fields['description']?['stringValue'],
          };
        })
        .where((e) => 
          e['title'] != null && 
          e['date'] != null && 
          e['date'] == date
        )
        .cast<Map<String, dynamic>>()
        .toList();
  }

  Future<void> clearSchedule({
    required String idToken,
    required String uid,
    required String date,
  }) async {
    final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/users/$uid',
    );

    final getResponse = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );

    if (getResponse.statusCode != 200) {
      throw Exception("Failed to fetch current user data: ${getResponse.body}");
    }

    final currentData = jsonDecode(getResponse.body);
    final existingFields = currentData['fields'] ?? {};

    final currentEvents = existingFields['events']?['arrayValue']?['values'] ?? [];

    final updatedEvents = (currentEvents as List).where((event) {
      final eventDate = event['mapValue']['fields']['date']?['stringValue'];
      return eventDate != date;
    }).toList();

    existingFields['events'] = updatedEvents.isEmpty
        ? { "arrayValue": {} }
        : {
            "arrayValue": {
              "values": updatedEvents
            }
          };

    final patchResponse = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({ "fields": existingFields }),
    );

    if (patchResponse.statusCode != 200) {
      throw Exception("Failed to clear events: ${patchResponse.body}");
    }
  }

  Future<void> deleteEvent({
    required String idToken,
    required String uid,
    String? title,
    String? date,
    String? time,
  }) async {
    final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/users/$uid',
    );

    // Fetch current user data
    final getResponse = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );

    if (getResponse.statusCode != 200) {
      throw Exception("Failed to fetch current events: ${getResponse.body}");
    }

    final currentData = jsonDecode(getResponse.body);
    final existingFields = currentData['fields'] ?? {};
    final currentEvents = existingFields['events']?['arrayValue']?['values'] ?? [];

    // Filter based on non-null matching fields
    final updatedEvents = (currentEvents as List).where((event) {
      final fields = event['mapValue']['fields'];
      final eventTitle = fields['title']?['stringValue'];
      final eventDate = fields['date']?['stringValue'];
      final eventTime = fields['time']?['stringValue'];

      final matchesTitle = title == null || title.isEmpty || eventTitle != title;
      final matchesDateTime = (date == null || date.isEmpty || eventDate != date) ||
                              (time == null || time.isEmpty || eventTime != time);

      // Only delete if all non-null filters match — so keep if it does *not* match all filters
      return matchesTitle || matchesDateTime;
    }).toList();

    // Reconstruct the full field map, replacing only the updated events
    existingFields['events'] = updatedEvents.isEmpty
        ? { "arrayValue": {} }
        : {
            "arrayValue": {
              "values": updatedEvents
            }
          };

    final patchResponse = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({ "fields": existingFields }),
    );

    if (patchResponse.statusCode != 200) {
      throw Exception("Failed to delete event: ${patchResponse.body}");
    }
  }
}
