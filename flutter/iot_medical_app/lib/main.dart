import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:pull_to_refresh/pull_to_refresh.dart';

const String apiUrl = "http://192.168.81.187:8000/sensors";


const primaryColor = Color(0xFF3F51B5);
const pollingInterval = 5; // Refresh every 5 seconds

void main() {
  runApp(const SensorDashboardApp());
}

class SensorDashboardApp extends StatelessWidget {
  const SensorDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Real-Time Health Monitor',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const SensorDashboardScreen(),
    );
  }
}

class SensorData {
  final int id;
  final int heartRate;
  final double temperature;
  final double humidity;
  final int spo2;
  final int bpSys;
  final int bpDia;
  final String timestamp;

  SensorData({
    required this.id,
    required this.heartRate,
    required this.temperature,
    required this.humidity,
    required this.spo2,
    required this.bpSys,
    required this.bpDia,
    required this.timestamp,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      id: json['id'],
      heartRate: json['heart_rate'],
      temperature: json['temperature'].toDouble(),
      humidity: json['humidity'].toDouble(),
      spo2: json['spo2'],
      bpSys: json['bp_sys'],
      bpDia: json['bp_dia'],
      timestamp: json['timestamp'],
    );
  }
}

class SensorDashboardScreen extends StatefulWidget {
  const SensorDashboardScreen({super.key});

  @override
  _SensorDashboardScreenState createState() => _SensorDashboardScreenState();
}

class _SensorDashboardScreenState extends State<SensorDashboardScreen> {
  final RefreshController _refreshController = RefreshController();
  late Timer _pollingTimer;
  List<SensorData> _sensorData = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _startPolling();
    _fetchData();
  }

  @override
  void dispose() {
    _pollingTimer.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(
      const Duration(seconds: pollingInterval),
          (timer) => _fetchData(),
    );
  }

  Future<void> _fetchData() async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl?cache=${DateTime.now().millisecondsSinceEpoch}'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _sensorData = data.map((json) => SensorData.fromJson(json)).toList();
          _isLoading = false;
          _errorMessage = '';
        });
      } else {
        _showError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Connection Error: ${e.toString()}');
    } finally {
      _refreshController.refreshCompleted();
    }
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500
          )),
        ],
      ),
    );
  }

  Widget _buildSensorCard(SensorData data) {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reading #${data.id}',
                  style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.bold
                  ),
                ),
                Text(data.timestamp,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
            const Divider(),
            _buildDataRow('Heart Rate', '${data.heartRate} BPM'),
            _buildDataRow('Temperature', '${data.temperature.toStringAsFixed(1)}°C'),
            _buildDataRow('SpO2', '${data.spo2}%'),
            _buildDataRow('Humidity', '${data.humidity.toStringAsFixed(1)}%'),
            _buildDataRow('Blood Pressure', '${data.bpSys}/${data.bpDia} mmHg'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Latest Health Readings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
            tooltip: 'Manual Refresh',
          ),
        ],
      ),
      body: SmartRefresher(
        controller: _refreshController,
        enablePullDown: true,
        onRefresh: _fetchData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _sensorData.isEmpty
            ? const Center(child: Text('No data available'))
            : ListView.builder(
          itemCount: _sensorData.length,
          itemBuilder: (context, index) {
            return _buildSensorCard(_sensorData[index]);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchData,
        backgroundColor: primaryColor,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}