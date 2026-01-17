/// Models for the connection domain
library;

import 'package:cookie_jar/cookie_jar.dart';
import 'package:silo_tavern/services/connection/network.dart';

abstract class ConnectionSessionFactory {
  ConnectionSessionInterface create(
    String server, {
    List<Cookie>? cookies = const [],
  });
}
