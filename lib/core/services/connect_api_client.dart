import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:http/http.dart' as http;

import '../connect_config.dart';

class ConnectApiClient {
  ConnectApiClient(this._client);

  final Client _client;

  Future<String> createJwt() async {
    final account = Account(_client);
    final jwt = await account.createJWT();
    return jwt.jwt;
  }

  Future<void> callPermissionsApi({
    required String method,
    String? rowId,
    String? databaseId,
    String? tableId,
    required Map<String, dynamic> payload,
  }) async {
    final jwt = await createJwt();
    final uri = Uri.parse('${ConnectConfig.accountsDomain}/api/permissions');
    final request = http.Request(method, uri)
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwt',
      })
      ..body = jsonEncode({
        ...?(rowId != null ? {'rowId': rowId} : null),
        ...?(databaseId != null ? {'databaseId': databaseId} : null),
        ...?(tableId != null ? {'tableId': tableId} : null),
        ...payload,
      });
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode >= 400) {
      final errorBody = response.body.isNotEmpty ? response.body : '{}';
      dynamic errorData;
      try {
        errorData = jsonDecode(errorBody);
      } catch (_) {
        errorData = null;
      }
      if (errorData is Map && errorData['error'] is String) {
        throw Exception(errorData['error']);
      }
      throw Exception('Permission update failed');
    }
  }

  Future<void> grantPermissions({
    required String rowId,
    required String permission,
    required List<String> targetUserIds,
    required String databaseId,
    required String tableId,
    String action = 'grant',
  }) {
    return callPermissionsApi(
      method: 'POST',
      rowId: rowId,
      databaseId: databaseId,
      tableId: tableId,
      payload: {
        'action': action,
        'permission': permission,
        'targetUserIds': targetUserIds,
      },
    );
  }

  Future<void> revokePermissions({
    required String rowId,
    required List<String> targetUserIds,
    required String databaseId,
    required String tableId,
  }) {
    return callPermissionsApi(
      method: 'DELETE',
      rowId: rowId,
      databaseId: databaseId,
      tableId: tableId,
      payload: {
        'targetUserIds': targetUserIds,
      },
    );
  }

  Future<void> reclaimGhostNotes({
    required String userId,
    required List<String> noteIds,
    String? wrappedKey,
    Map<String, dynamic> metadata = const {},
  }) {
    return callPermissionsApi(
      method: 'POST',
      payload: {
        'action': 'pin_ghost_note',
        'userId': userId,
        'noteIds': noteIds,
        ...?(wrappedKey != null ? {'wrappedKey': wrappedKey} : null),
        ...?(metadata.isNotEmpty ? {'metadata': metadata} : null),
      },
    );
  }
}
