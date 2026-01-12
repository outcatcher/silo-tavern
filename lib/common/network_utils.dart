import 'dart:io';

class NetworkUtils {
  /// List of private network CIDR blocks as defined in various RFCs
  static final List<CIDRBlock> _privateNetworks = [
    // RFC 1918 - Private IPv4 Networks
    CIDRBlock('10.0.0.0', 8), // 10.0.0.0/8
    CIDRBlock('172.16.0.0', 12), // 172.16.0.0/12
    CIDRBlock('192.168.0.0', 16), // 192.168.0.0/16
    // RFC 5735 - Special Use IPv4 Addresses
    CIDRBlock('127.0.0.0', 8), // 127.0.0.0/8 - Loopback
    CIDRBlock('169.254.0.0', 16), // 169.254.0.0/16 - Link Local
    // RFC 6598 - Shared Address Space
    CIDRBlock('100.64.0.0', 10), // 100.64.0.0/10
    // RFC 3927 - Dynamic Configuration of IPv4 Link-Local Addresses
    CIDRBlock('169.254.0.0', 16), // 169.254.0.0/16
    // RFC 5737 - IPv4 Address Blocks Reserved for Documentation
    CIDRBlock('192.0.2.0', 24), // 192.0.2.0/24
    CIDRBlock('198.51.100.0', 24), // 198.51.100.0/24
    CIDRBlock('203.0.113.0', 24), // 203.0.113.0/24
    // RFC 7526 - 192.88.99.0/24 - Formerly used for 6to4 relay anycast
    CIDRBlock('192.88.99.0', 24), // 192.88.99.0/24
    // RFC 7335 - IPv4 Service Continuity Prefix
    CIDRBlock('192.0.0.0', 24), // 192.0.0.0/24
    // RFC 2544 - Benchmarking Methodology for Network Interconnect Devices
    CIDRBlock('198.18.0.0', 15), // 198.18.0.0/15
    // IPv6 equivalents
    CIDRBlock('::1', 128), // ::1/128 - IPv6 Loopback
    CIDRBlock('fc00::', 7), // fc00::/7 - Unique Local Unicast
    CIDRBlock('fe80::', 10), // fe80::/10 - Link-Local Unicast
  ];

  /// Checks if the given address is a local network address
  static bool isLocalAddress(String address) {
    try {
      // Parse the host from the URL
      final uri = Uri.parse(address);
      final host = uri.host;

      // localhost is always considered local
      if (host.toLowerCase() == 'localhost') {
        return true;
      }

      // If host is already an IP address, parse it directly
      if (_isIpAddress(host)) {
        final internetAddress = InternetAddress(host);
        return _isLocalIpAddress(internetAddress);
      }

      // For any other domain name, assume it's external
      return false;
    } catch (e) {
      // If we can't parse the URI, assume it's not local
      return false;
    }
  }

  /// Helper method to check if a string is an IP address
  static bool _isIpAddress(String host) {
    try {
      InternetAddress(host);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Helper method to check if an InternetAddress is local
  static bool _isLocalIpAddress(InternetAddress address) {
    // Check against all private network CIDR blocks
    for (final cidr in _privateNetworks) {
      if (cidr.contains(address)) {
        return true;
      }
    }

    // Not a local address
    return false;
  }
}

/// Represents a CIDR block for network address matching
class CIDRBlock {
  final InternetAddress network;
  final int prefixLength;
  final List<int> mask;
  final List<int> maskedNetwork;

  CIDRBlock(String networkAddress, this.prefixLength)
    : network = InternetAddress(networkAddress),
      mask = _createMask(networkAddress, prefixLength),
      maskedNetwork = _applyMask(
        InternetAddress(networkAddress),
        _createMask(networkAddress, prefixLength),
      );

  /// Creates a subnet mask based on prefix length
  static List<int> _createMask(String networkAddress, int prefixLength) {
    final isIPv6 = networkAddress.contains(':');
    final mask = <int>[];

    if (isIPv6) {
      // IPv6: 128 bits = 16 bytes
      for (int i = 0; i < 16; i++) {
        if (prefixLength >= 8) {
          mask.add(0xFF);
          prefixLength -= 8;
        } else if (prefixLength > 0) {
          mask.add(0xFF << (8 - prefixLength) & 0xFF);
          prefixLength = 0;
        } else {
          mask.add(0x00);
        }
      }
    } else {
      // IPv4: 32 bits = 4 bytes
      for (int i = 0; i < 4; i++) {
        if (prefixLength >= 8) {
          mask.add(0xFF);
          prefixLength -= 8;
        } else if (prefixLength > 0) {
          mask.add(0xFF << (8 - prefixLength) & 0xFF);
          prefixLength = 0;
        } else {
          mask.add(0x00);
        }
      }
    }

    return mask;
  }

  /// Applies mask to an address
  static List<int> _applyMask(InternetAddress address, List<int> mask) {
    final bytes = address.rawAddress;
    final masked = <int>[];
    for (int i = 0; i < bytes.length && i < mask.length; i++) {
      masked.add(bytes[i] & mask[i]);
    }
    return masked;
  }

  /// Checks if an address belongs to this CIDR block
  bool contains(InternetAddress address) {
    // Must be same type (IPv4 or IPv6)
    if (address.type != network.type) {
      return false;
    }

    final maskedAddress = _applyMask(address, mask);

    // Compare masked address with network address
    for (int i = 0; i < maskedAddress.length && i < maskedNetwork.length; i++) {
      if (maskedAddress[i] != maskedNetwork[i]) {
        return false;
      }
    }

    return true;
  }
}
