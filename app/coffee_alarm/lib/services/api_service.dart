import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/timer.dart';
import '../models/config.dart';
import '../utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ApiService {
  static String? _baseUrl;
  static final ValueNotifier<bool> isApiReachable = ValueNotifier<bool>(true);

  static Future<String> getBaseUrl() async {
    if (_baseUrl == null) {
      final prefs = await SharedPreferences.getInstance();
      String? storedIp = prefs.getString(Constants.apiIpKey);
      String ipToUse = storedIp ?? Constants.defaultHotspotIp;
      _baseUrl = 'http://$ipToUse:8000';
    }
    return _baseUrl!;
  }

  static Future<void> setBaseIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(Constants.apiIpKey, ip);
    _baseUrl = 'http://$ip:8000';
  }

  Future<http.Response> _makeRequest(Future<http.Response> Function() requestFunction) async {
    try {
      final response = await requestFunction();
      if (!isApiReachable.value) {
        isApiReachable.value = true;
      }
      return response;
    } catch (e) {
      if (isApiReachable.value) {
        isApiReachable.value = false;
      }
      
      rethrow;
    }
  }


  Future<TimerAlarm?> fetchTimer() async {
    try {
      final url = '${await getBaseUrl()}/timer';
      final response = await _makeRequest(() => http.get(Uri.parse(url)));

      if (response.statusCode == 200) {
        if (response.body.isEmpty) return null; // No active alarm
        return TimerAlarm.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        return null; // No alarm set
      } else {
        throw Exception('Failed to load timer: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error fetching timer: $e');
      return null;
    }
  }

  Future<bool> setTimer(String coffeeType, TimeOfDay time) async {
    try {
      final baseUrl = await getBaseUrl();
      final url = Uri.parse('$baseUrl/timer/$coffeeType').replace(
        queryParameters: { 'time': _formatTime(time) }
      );

      final response = await _makeRequest(() => http.put(
        url,
        headers: {'Content-Type': 'application/json'},
      ));
      return response.statusCode == 200;
    } catch (e) {
      print('Error setting timer: $e');
      return false;
    }
  }

  Future<bool> deleteTimer() async {
    try {
      final url = '${await getBaseUrl()}/timer';
      final response = await _makeRequest(() => http.delete(Uri.parse(url)));
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting timer: $e');
      return false;
    }
  }

  // --- Config API ---
  Future<AppConfig?> fetchConfig() async {
    try {
      final url = '${await getBaseUrl()}/config';
      final response = await _makeRequest(() => http.get(Uri.parse(url)));
      if (response.statusCode == 200) {
        return AppConfig.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load config: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching config: $e');
      return null;
    }
  }

  Future<bool> updateConfig(AppConfig config) async {
    try {
      final url = '${await getBaseUrl()}/config';
      final response = await _makeRequest(() => http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(config.toJson()),
      ));
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating config: $e');
      return false;
    }
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    DateTime scheduledDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDateTime.isBefore(now)) {
      scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
    }
    
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(scheduledDateTime);
  }
}