import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/config.dart';
import '../utils/constants.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _apiIpController = TextEditingController();
  final TextEditingController _coffeeDurationController = TextEditingController();
  final TextEditingController _espressoDurationController = TextEditingController();
  final TextEditingController _wifiSsidController = TextEditingController();
  final TextEditingController _wifiPasswordController = TextEditingController();

  late Future<void> _prefsLoadFuture; // This new future for SharedPreferences only
  late Future<AppConfig?> _futureConfig;

  @override
  void initState() {
    super.initState();
    _prefsLoadFuture = _loadApiIpFromPrefs(); 
    _futureConfig = _apiService.fetchConfig();
  }

  Future<void> _loadApiIpFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _apiIpController.text = prefs.getString(Constants.apiIpKey) ?? Constants.defaultHotspotIp;
  }

  bool _isSavingApiIp = false;
  bool _isUpdatingDurations = false;
  bool _isSettingWifi = false;
  bool _isForgettingWifi = false;

  Future<void> _saveApiIp() async {
    setState(() { _isSavingApiIp = true; });
    await ApiService.setBaseIp(_apiIpController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API IP saved and updated.')),
    );
    setState(() { _isSavingApiIp = false; });
  }

  Future<void> _updateConfig() async {
    setState(() { _isUpdatingDurations = true; });
    final newConfig = AppConfig(
      coffeeDurationSeconds: int.tryParse(_coffeeDurationController.text) ?? 0,
      espressoDurationSeconds: int.tryParse(_espressoDurationController.text) ?? 0,
    );
    final success = await _apiService.updateConfig(newConfig);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('durations updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('failed to update durations')),
      );
    }
    setState(() { _isUpdatingDurations = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: FutureBuilder<void>( // This FutureBuilder only waits for _prefsLoadFuture
        future: _prefsLoadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('error loading API IP: ${snapshot.error}'));
          } else {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // API Reachability Indicator
                  ValueListenableBuilder<bool>(
                    valueListenable: ApiService.isApiReachable,
                    builder: (context, isReachable, child) {
                      if (!isReachable) {
                        return Container(
                          padding: const EdgeInsets.all(8.0),
                          color: Colors.red.shade700,
                          child: const Text(
                            'API not reachable',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 10),

                  // API IP Configuration (always visible after prefs load)
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 20),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('API IP address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _apiIpController,
                            decoration: const InputDecoration(
                              labelText: 'API IP',
                              hintText: Constants.defaultHotspotIp,
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _isSavingApiIp ? null : _saveApiIp,
                            child: _isSavingApiIp
                                ? const SizedBox(
                                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('save IP'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Config Durations (now uses _futureConfig directly)
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 20),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('GPIO config', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          FutureBuilder<AppConfig?>(
                            future: _futureConfig, // Now correctly points to the already started future
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              } else if (snapshot.hasError) {
                                return Text('error loading config: ${snapshot.error}', style: const TextStyle(color: Colors.red));
                              } else {
                                // Only populate controllers if data loaded and they are empty or different
                                if (snapshot.hasData && snapshot.data != null) {
                                  // Only update if current value isn't matching to avoid cursor jump
                                  if (_coffeeDurationController.text != snapshot.data!.coffeeDurationSeconds.toString()) {
                                    _coffeeDurationController.text = snapshot.data!.coffeeDurationSeconds.toString();
                                  }
                                  if (_espressoDurationController.text != snapshot.data!.espressoDurationSeconds.toString()) {
                                    _espressoDurationController.text = snapshot.data!.espressoDurationSeconds.toString();
                                  }
                                }
                                return Column(
                                  children: [
                                    TextField(
                                      controller: _coffeeDurationController,
                                      decoration: const InputDecoration(
                                        labelText: 'coffee Duration (seconds)',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: _espressoDurationController,
                                      decoration: const InputDecoration(
                                        labelText: 'espresso Duration (seconds)',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                    const SizedBox(height: 10),
                                    ElevatedButton(
                                      onPressed: _isUpdatingDurations ? null : _updateConfig,
                                      child: _isUpdatingDurations
                                          ? const SizedBox(
                                              width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                          : const Text('update config'),
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}