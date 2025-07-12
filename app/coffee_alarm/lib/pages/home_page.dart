import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/timer.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _apiService = ApiService();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedCoffeeType = 'coffee';
  TimerAlarm? _activeAlarm;
  
  bool _isSettingAlarm = false;
  bool _isDeletingAlarm = false;

  late Future<TimerAlarm?> _futureActiveAlarm;

  @override
  void initState() {
    super.initState();
    _futureActiveAlarm = _apiService.fetchTimer();
  }

  Future<void> _refreshActiveAlarm() async {
    setState(() {
      _futureActiveAlarm = _apiService.fetchTimer();
    });
  }

  Future<void> _pickTime() async {
    final TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (newTime != null) {
      setState(() {
        _selectedTime = newTime;
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _setAlarm() async {
    setState(() { _isSettingAlarm = true; });
    final success = await _apiService.setTimer(
      _selectedCoffeeType,
      _formatTime(_selectedTime),
    );
    if (success) {
      await _refreshActiveAlarm();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alarm set successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to set alarm')),
      );
    }
    setState(() { _isSettingAlarm = false; });
  }

  Future<void> _deleteAlarm() async {
    setState(() { _isDeletingAlarm = true; });
    final success = await _apiService.deleteTimer();
    if (success) {
      await _refreshActiveAlarm();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alarm deleted successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete alarm')),
      );
    }
    setState(() { _isDeletingAlarm = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coffee Alarm'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [ 
            ValueListenableBuilder<bool>( // error-dialog
              valueListenable: ApiService.isApiReachable,
              builder: (context, isReachable, child) {
                if (!isReachable) {
                  return Container(
                    padding: const EdgeInsets.all(8.0),
                    color: Colors.red.shade700,
                    child: const Text(
                      'API Not Reachable',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return const SizedBox.shrink(); // Hide if reachable
              },
            ),
            const SizedBox(height: 10),
            ListTile( // time-picker
              title: const Text('Alarm time'),
              subtitle: Text(
                _formatTime(_selectedTime),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              trailing: const Icon(Icons.access_time),
              onTap: _pickTime,
            ),
            const SizedBox(height: 20),
            Row( // radio-buttons
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCoffeeTypeButton(
                  'coffee',
                  Icons.coffee,
                  'Coffee',
                ),
                _buildCoffeeTypeButton(
                  'espresso',
                  Icons.local_cafe,
                  'Espresso',
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSettingAlarm || ApiService.isApiReachable.value == false ? null : _setAlarm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: _isSettingAlarm
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    )
                  : const Text('Set', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 30),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Active Alarm:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder<TimerAlarm?>(
                      future: _futureActiveAlarm,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Text('Error loading alarm: ${snapshot.error}', style: const TextStyle(color: Colors.red));
                        } else if (snapshot.hasData && snapshot.data != null) {
                          _activeAlarm = snapshot.data; // Store data once loaded
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Type: ${_activeAlarm!.coffeeType.toUpperCase()}', style: const TextStyle(fontSize: 16)),
                              Text('Time: ${_activeAlarm!.time}', style: const TextStyle(fontSize: 16)),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: _isDeletingAlarm ? null : _deleteAlarm, // Disable if loading
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: _isDeletingAlarm
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                                      )
                                    : const Text('Delete Alarm'),
                              ),
                            ],
                          );
                        } else {
                          return const Text('No active alarm set.', style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic));
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoffeeTypeButton(String type, IconData icon, String label) {
    final bool isSelected = _selectedCoffeeType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCoffeeType = type;
        });
      },
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.teal.shade700 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? Colors.teal.shade900 : Colors.grey.shade400,
                width: 2,
              ),
            ),
            padding: const EdgeInsets.all(15),
            child: Icon(
              icon,
              size: 40,
              color: isSelected ? Colors.white : Colors.teal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.teal : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}