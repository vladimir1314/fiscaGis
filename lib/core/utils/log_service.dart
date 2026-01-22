import 'package:flutter/material.dart';

class LogEntry {
  final DateTime timestamp;
  final String message;
  final bool isError;

  LogEntry(this.message, {this.isError = false}) : timestamp = DateTime.now();
}

class LogService {
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;
  LogService._internal();

  final List<LogEntry> logs = [];
  final ValueNotifier<int> logCount = ValueNotifier(0);

  void log(String message) {
    logs.insert(0, LogEntry(message));
    if (logs.length > 100) logs.removeLast();
    logCount.value++;
    // ignore: avoid_print
    print('APP LOG: $message');
  }

  void error(String message) {
    logs.insert(0, LogEntry(message, isError: true));
    if (logs.length > 100) logs.removeLast();
    logCount.value++;
    // ignore: avoid_print
    print('APP ERROR: $message');
  }

  void clear() {
    logs.clear();
    logCount.value = 0;
  }
}

class LogViewerSheet extends StatelessWidget {
  const LogViewerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final logService = LogService();
    
    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Debug Logs", style: Theme.of(context).textTheme.titleLarge),
              IconButton(
                icon: const Icon(Icons.delete_sweep),
                onPressed: () {
                  logService.clear();
                },
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: logService.logCount,
              builder: (context, count, _) {
                return ListView.builder(
                  itemCount: logService.logs.length,
                  itemBuilder: (context, index) {
                    final entry = logService.logs[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        "[${entry.timestamp.hour}:${entry.timestamp.minute}:${entry.timestamp.second}] ${entry.message}",
                        style: TextStyle(
                          color: entry.isError ? Colors.red : Colors.black87,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
