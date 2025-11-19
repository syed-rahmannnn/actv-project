import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🔍 === NETWORK CONNECTIVITY TEST ===\n');

  // Test 1: Check if device can resolve DNS
  print('1️⃣ Testing DNS resolution...');
  try {
    final addresses = await InternetAddress.lookup('google.com');
    print('   ✅ DNS working: ${addresses.first.address}\n');
  } catch (e) {
    print('   ❌ DNS failed: $e\n');
  }

  // Test 2: Check if device has internet
  print('2️⃣ Testing internet connectivity...');
  try {
    final response = await http
        .get(Uri.parse('https://www.google.com'))
        .timeout(const Duration(seconds: 5));
    print('   ✅ Internet working: Status ${response.statusCode}\n');
  } catch (e) {
    print('   ❌ No internet: $e\n');
  }

  // Test 3: Check if backend server is reachable
  print('3️⃣ Testing backend server connectivity...');
  final backendUrl = 'http://10.201.103.174:3000/api/browse-members';

  print('   📡 Attempting to reach: $backendUrl');

  try {
    final response = await http
        .get(
          Uri.parse(backendUrl),
          headers: {'Content-Type': 'application/json'},
        )
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('   ⏱️ Request timed out after 10 seconds');
            throw Exception('Timeout');
          },
        );

    print('   ✅ Backend reachable! Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final memberCount = data['data']?.length ?? 0;
      print('   📊 Found $memberCount members in database\n');

      if (memberCount > 0) {
        print('   Sample member:');
        final firstMember = data['data'][0];
        print('   - Name: ${firstMember['name']}');
        print('   - Organization: ${firstMember['organization']}');
        print('   - Approval: ${firstMember['approvalStatus']}');
        print('   - Payment: ${firstMember['paymentStatus']}\n');
      }
    }
  } on SocketException catch (e) {
    print('   ❌ Socket error: Cannot connect to server');
    print('   💡 This means:');
    print('      - Device is NOT on the same network (needs 10.201.x.x)');
    print('      - Backend server is not running');
    print('      - Firewall is blocking the connection\n');
    print('   Error details: $e\n');
  } on TimeoutException {
    print('   ❌ Timeout: Server not responding');
    print('   💡 Possible causes:');
    print('      - Server is slow or overloaded');
    print('      - Network latency too high');
    print('      - Wrong IP address\n');
  } catch (e) {
    print('   ❌ Error: $e\n');
  }

  // Test 4: Check local network info
  print('4️⃣ Device network information:');
  try {
    final interfaces = await NetworkInterface.list();
    for (var interface in interfaces) {
      print('   Interface: ${interface.name}');
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4) {
          print('      IPv4: ${addr.address}');

          if (addr.address.startsWith('10.201.')) {
            print('      ✅ Device is on correct network (10.201.x.x)');
          } else if (addr.address.startsWith('192.168.')) {
            print('      ⚠️  Device might be on different WiFi network');
          }
        }
      }
    }
  } catch (e) {
    print('   ❌ Could not get network info: $e');
  }

  print('\n' + '=' * 50);
  print('🏁 Test complete!');
  print('=' * 50);
}
