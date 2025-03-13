import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal(); // Singleton instance

  factory ApiService() {
    return _instance; // Always return the same instance
  }

  ApiService._internal(); // Private named constructor

  static ApiService get instance => _instance; // Exposing instance

  final String baseUrl = "http://192.168.171.214:5000/"; // Replace with your actual API base URL
  String? _authToken;

  /// Save token in local storage
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    _authToken = token;
  }

  /// Load token from local storage
  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
  }

  /// Generic GET request function
  Future<dynamic> getRequest(String endpoint) async {
    if (_authToken == null) await _loadToken();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Authorization': 'Bearer $_authToken'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to fetch data: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching $endpoint: $e");
      return null;
    }
  }

  /// Login and store token
  Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      
      print("Login Response Status Code: ${response.statusCode}");
      print("Login Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveToken(data['access_token']);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("Login error: $e");
      return false;
    }
  }

  /// Fetch user groups and mark admin groups
  Future<List<Map<String, dynamic>>> fetchGroups() async {
    List<dynamic>? userGroups = await getRequest('/groups');
    List<dynamic>? adminGroups = await getRequest('/admin_of');

    if (userGroups == null || adminGroups == null) return [];

    // Convert admin group IDs into a set for quick lookup
    Set<int> adminGroupIds = adminGroups.map<int>((group) => group['id']).toSet();

    // Merge lists, marking `esAdmin` accordingly
    List<Map<String, dynamic>> mergedGroups = userGroups.map((group) {
      return {
        "id": group["id"],
        "nombre": group["name"],
        "esAdmin": adminGroupIds.contains(group["id"]),
      };
    }).toList();

    return mergedGroups;
  }

  /// Add a user to a specified group
  Future<bool> addUserToGroup(int groupId, int userId) async {
    try {
      final url = Uri.parse('$baseUrl/group/$groupId');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_authToken',
      };

      final body = jsonEncode({
        'user_id': userId,
      });

      final response = await http.put(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        print("User successfully added to the group.");
        return true; // User added successfully
      } else {
        print("Failed to add user: ${response.statusCode}");
        print("Response body: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error adding user to group: $e");
      return false;
    }
  }
  /// Fetch users of a specified group
  Future<List<Map<String, dynamic>>?> fetchUsersOfGroup(int groupId) async {
    try {
      final url = Uri.parse('$baseUrl/users/$groupId');
      final headers = {
        'Authorization': 'Bearer $_authToken',
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        // Parse the response as a list of user objects
        List<dynamic> users = jsonDecode(response.body);
        return users.map((user) {
          return {
            'id': user['id'],
            'username': user['username'],
          };
        }).toList();
      } else {
        print("Failed to fetch users: ${response.statusCode}");
        print("Response body: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error fetching users for group: $e");
      return null;
    }
  }

  /// Fetch user ID by username
  Future<int?> fetchUserIdByUsername(String username) async {
    try {
      final url = Uri.parse('$baseUrl/by_username/$username');
      final headers = {
        'Authorization': 'Bearer $_authToken',
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        // Parse the response body to get the user ID
        final data = jsonDecode(response.body);
        return data['id'];
      } else {
        print("Failed to fetch user ID: ${response.statusCode}");
        print("Response body: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error fetching user ID by username: $e");
      return null;
    }
  }


}