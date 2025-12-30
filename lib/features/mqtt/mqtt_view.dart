import 'package:flutter/material.dart';
import 'mqtt_service.dart';

class MqttView extends StatefulWidget {
  const MqttView({super.key});

  static const routeName = '/mqtt';

  @override
  State<MqttView> createState() => _MqttViewState();
}

class _MqttViewState extends State<MqttView> {
  final MqttService _mqttService = MqttService();
  // Local state for visual toggle effect
  bool _isSaklar1On = false;
  bool _isSaklar2On = false;

  @override
  void dispose() {
    _mqttService.disconnect();
    super.dispose();
  }

  void _sendMessage(String message) {
    if (_mqttService.isConnected.value) {
      _mqttService.publish(message);
      // Optional: Show snackbar feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Mengirim: $message'),
            duration: const Duration(seconds: 1)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Belum terhubung!'), duration: Duration(seconds: 1)),
      );
    }
  }

  void _toggleConnection() {
    if (_mqttService.isConnected.value) {
      _mqttService.disconnect();
    } else {
      _mqttService.connect();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Theme awareness
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFFEF7FF);
    final cardColor = isDarkMode ? const Color(0xFF2D2D2D) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor,
      // No AppBar as per design implication (clean look), or we keep it minimal if needed.
      // Design shows "Kontrol Lampu" as a header text in body.
      body: SafeArea(
        child: ValueListenableBuilder<bool>(
          valueListenable: _mqttService.isConnected,
          builder: (context, isConnected, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                // Header Image
                Center(
                  child: Image.asset(
                    isConnected
                        ? 'assets/images/connect.png'
                        : 'assets/images/disconnect.png',
                    height: 250, // Adjust height to match design proportion
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 40),

                // Title
                Text(
                  'Smart Control',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 40),

                // Controls Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      // Switch 1 - Yellow/Orange
                      Expanded(
                        child: _buildSwitchCard(
                          label: 'Device 1',
                          icon: Icons.power_settings_new_rounded,
                          isOn: _isSaklar1On,
                          activeColor: Colors.amber,
                          cardColor: cardColor,
                          textColor: textColor,
                          onTap: () {
                            setState(() {
                              _isSaklar1On = !_isSaklar1On;
                            });
                            _sendMessage('A');
                          },
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Switch 2 - Blue
                      Expanded(
                        child: _buildSwitchCard(
                          label: 'Device 2',
                          icon: Icons.wifi,
                          isOn: _isSaklar2On,
                          activeColor: Colors.blueAccent,
                          cardColor: cardColor,
                          textColor: textColor,
                          onTap: () {
                            setState(() {
                              _isSaklar2On = !_isSaklar2On;
                            });
                            _sendMessage('B');
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Connect Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 50.0),
                  child: InkWell(
                    onTap: _toggleConnection,
                    borderRadius: BorderRadius.circular(30),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 200,
                      height: 55,
                      decoration: BoxDecoration(
                        color: isConnected
                            ? const Color(0xFF10B981)
                            : const Color(
                                0xFF374151), // Emerald Green / Cool Grey
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: isConnected
                                ? const Color(0xFF10B981).withOpacity(0.4)
                                : Colors.black.withOpacity(0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.power_settings_new,
                            color: Colors.white.withOpacity(0.9),
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isConnected ? 'DISCONNECT' : 'CONNECT',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSwitchCard({
    required String label,
    required IconData icon,
    required bool isOn,
    required Color activeColor,
    required Color cardColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        height: 170,
        decoration: BoxDecoration(
          color: isOn ? activeColor : cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isOn
                  ? activeColor.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isOn ? 12 : 8,
              offset: Offset(0, isOn ? 6 : 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon Container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isOn
                    ? Colors.white.withOpacity(0.2)
                    : activeColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: isOn ? Colors.white : activeColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                color: isOn ? Colors.white : textColor.withOpacity(0.8),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
