import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/timer.dart';
import '../models/config.dart';
import '../models/network_status.dart';
import '../utils/constants.dart';
import 'package:flutter/material.dart';

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

  Future<bool> setTimer(String coffeeType, String time) async {
    try {
      final url = '${await getBaseUrl()}/timer/${coffeeType}';
      final response = await _makeRequest(() => http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'time': time}),
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

  Future<NetworkStatus?> fetchNetworkStatus() async {
    try {
      final url = '${await getBaseUrl()}/network/status';
      final response = await _makeRequest(() => http.get(Uri.parse(url)));
      if (response.statusCode == 200) {
        return NetworkStatus.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load network status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching network status: $e');
      return null;
    }
  }

  Future<bool> putNetworkCredentials(String ssid, String password) async {
    try {
      final url = '${await getBaseUrl()}/network/credentials';
      final response = await _makeRequest(() => http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'ssid': ssid, 'password': password}),
      ));
      return response.statusCode == 200;
    } catch (e) {
      print('Error setting network credentials: $e');
      return false;
    }
  }

  Future<bool> forgetNetworkCredentials() async {
    try {
      final url = '${await getBaseUrl()}/network/forget_credentials';
      final response = await _makeRequest(() => http.post(Uri.parse(url)));
      return response.statusCode == 200;
    } catch (e) {
      print('Error forgetting network credentials: $e');
      return false;
    }
  }
}