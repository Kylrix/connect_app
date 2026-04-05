import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:http/http.dart' as http;

import '../connect_config.dart';

class ConnectApiClient {
  ConnectApiClient(this._client);

  final Client _client;

  Future<String?> createJwt() async {
    final account = Account(_client);
    try {
      final jwt = await account.createJWT();
      return jwt.jwt;
    } catch (_) {
      return null;
    }
  }

  Future<void> updatePermissions({
    required String rowId,
    required String permission,
    required List<String> targetUserIds,
    required String databaseId,
    required String tableId,
    String method = 'POST',
  }) async {
    final jwt = await createJwt();
    final uri = Uri.parse('${ConnectConfig.accountsDomain}/api/permissions');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (jwt != null) 'Authorization': 'Bearer $jwt',
      },
      body: jsonEncode({
        'rowId': rowId,
        'permission': permission,
        'targetUserIds': targetUserIds,
        'databaseId': databaseId,
        'tableId': tableId,
        'method': method,
      }),
    );
    if (response.statusCode >= 400) {
      throw Exception('Permission update failed');
    }
  }

  Future<void> reclaimGhostNotes(String userId) async {
    final functions = Functions(_client);
    await functions.createExecution(
      functionId: ConnectConfig.claimGhostNotesFunction,
      body: jsonEncode({'userId': userId}),
    );
  }
}
