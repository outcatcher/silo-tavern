import 'dart:io';

void main() {
  print('Testing InternetAddress networking capabilities');
  
  // Test creating addresses
  final addr1 = InternetAddress('192.168.1.100');
  final addr2 = InternetAddress('10.0.0.1');
  final addr3 = InternetAddress('8.8.8.8');
  
  print('Address 1: ${addr1.address}');
  print('Address 2: ${addr2.address}');
  print('Address 3: ${addr3.address}');
  
  // Test raw address bytes
  print('Addr1 raw: ${addr1.rawAddress}');
  print('Addr2 raw: ${addr2.rawAddress}');
  print('Addr3 raw: ${addr3.rawAddress}');
  
  // Test IPv6
  final addr4 = InternetAddress('::1');
  print('IPv6 loopback raw: ${addr4.rawAddress}');
}