import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:silo_tavern/domain/connection/domain.dart';
import 'package:silo_tavern/domain/servers/domain.dart';

@GenerateNiceMocks([
  MockSpec<GoRouter>(),
  MockSpec<ServerDomain>(),
  MockSpec<ConnectionDomain>(),
])
void main() {}
