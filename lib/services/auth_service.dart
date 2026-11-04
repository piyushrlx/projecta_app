import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../models/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  AuthService._internal();

  final ApiClient _apiClient = ApiClient();

  static const String _userStorageKey = 'auth_user';
  static const String _tokenStorageKey = 'auth_token';

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  /// Authenticates user against backend login.php endpoint.
  /// Accepts identifier and password, saves token and user profile locally in SharedPreferences.
  Future<UserModel> login(
    String identifier,
    String password, {
    String? deviceName,
  }) async {
    final payload = {
      'username': identifier.trim(),
      'password': password,
      'device_name': deviceName ?? 'Projecta Mobile Flutter App',
    };

    try {
      // First attempt primary login.php endpoint
      final response = await _apiClient.post('/login.php', body: payload);

      final dynamic decoded = _apiClient.decodeJson(response);
      if (decoded is! Map<String, dynamic>) {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Invalid response format from server.',
        );
      }

      final bool isSuccess =
          decoded['success'] == true || decoded['ok'] == true;
      if (!isSuccess) {
        final errorMsg =
            decoded['error'] ?? decoded['message'] ?? 'Authentication failed.';
        throw ApiException(
          statusCode: response.statusCode,
          message: errorMsg.toString(),
        );
      }

      final String? token = decoded['token']?.toString();
      if (token == null || token.isEmpty) {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Server did not return a valid authentication token.',
        );
      }

      // Persist auth token
      await _apiClient.saveToken(token);

      // Parse user profile
      final userMap = decoded['user'] is Map<String, dynamic>
          ? decoded['user'] as Map<String, dynamic>
          : <String, dynamic>{};

      final user = UserModel.fromJson(userMap, token: token);
      _currentUser = user;

      // Save user profile locally
      await _saveUserLocally(user);

      return user;
    } on ApiException catch (e) {
      // If /login.php returned 404, fallback to /auth/login REST route
      if (e.statusCode == 404) {
        final fallbackResponse = await _apiClient.post(
          '/auth/login',
          body: payload,
        );

        final dynamic fallbackDecoded = _apiClient.decodeJson(fallbackResponse);
        if (fallbackDecoded is Map<String, dynamic>) {
          final String? token = fallbackDecoded['token']?.toString();
          if (token != null && token.isNotEmpty) {
            await _apiClient.saveToken(token);
            final userMap =
                fallbackDecoded['user'] as Map<String, dynamic>? ?? {};
            final user = UserModel.fromJson(userMap, token: token);
            _currentUser = user;
            await _saveUserLocally(user);
            return user;
          }
        }
      }
      rethrow;
    }
  }

  /// Registers a new Admin (manager) account via POST /auth/register.
  /// Returns a map with 'message', 'auto_approved', and optionally 'token' / 'user'.
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    String? deviceName,
  }) async {
    final payload = {
      'full_name': fullName.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
      'device_name': deviceName ?? 'projeqta Mobile Flutter App',
    };

    final response = await _apiClient.post('/auth/register', body: payload);
    final dynamic decoded = _apiClient.decodeJson(response);

    if (decoded is! Map<String, dynamic>) {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Invalid response format from server.',
      );
    }

    final bool isSuccess =
        decoded['success'] == true || decoded['ok'] == true;
    if (!isSuccess) {
      final errorMsg =
          decoded['error'] ?? decoded['message'] ?? 'Registration failed.';
      throw ApiException(
        statusCode: response.statusCode,
        message: errorMsg.toString(),
      );
    }

    final String? token = decoded['token']?.toString();
    if (token != null && token.isNotEmpty) {
      await _apiClient.saveToken(token);
      if (decoded['user'] is Map<String, dynamic>) {
        final user = UserModel.fromJson(
          decoded['user'] as Map<String, dynamic>,
          token: token,
        );
        _currentUser = user;
        await _saveUserLocally(user);
      }
    }

    return decoded;
  }

  /// Changes the user's password via POST /auth/change-password.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await _apiClient.post(
      '/auth/change-password',
      body: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      },
    );

    final dynamic decoded = _apiClient.decodeJson(response);
    final bool isSuccess = decoded is Map<String, dynamic> &&
        (decoded['ok'] == true || decoded['success'] == true);

    if (!isSuccess) {
      final errorMsg = decoded is Map<String, dynamic>
          ? (decoded['error'] ?? decoded['message'] ?? 'Failed to update password')
          : 'Failed to update password';
      throw ApiException(
        statusCode: response.statusCode,
        message: errorMsg.toString(),
      );
    }

    // Refresh user cached profile to clear must_change_password flag
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(mustChangePassword: false);
      await _saveUserLocally(_currentUser!);
    }
  }

  /// Persists user model JSON string to SharedPreferences
  Future<void> _saveUserLocally(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(user.toJson());
    await prefs.setString(_userStorageKey, jsonString);
  }

  /// Loads locally cached UserModel from SharedPreferences
  Future<UserModel?> getCurrentUser() async {
    if (_currentUser != null) {
      return _currentUser;
    }

    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_userStorageKey);
    if (jsonString == null || jsonString.isEmpty) {
      return null;
    }

    try {
      final Map<String, dynamic> map = jsonDecode(jsonString);
      final token = await _apiClient.getToken();
      _currentUser = UserModel.fromJson(map, token: token);
      return _currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Fetches authenticated user profile, using cached session or API endpoint
  Future<UserModel> getMe() async {
    final cached = await getCurrentUser();
    if (cached != null) {
      return cached;
    }

    final response = await _apiClient.get('/auth/me');
    final dynamic decoded = _apiClient.decodeJson(response);
    final userMap =
        (decoded is Map<String, dynamic> &&
            decoded['user'] is Map<String, dynamic>)
        ? decoded['user'] as Map<String, dynamic>
        : (decoded is Map<String, dynamic> ? decoded : <String, dynamic>{});

    final token = await _apiClient.getToken();
    final user = UserModel.fromJson(userMap, token: token);
    _currentUser = user;
    await _saveUserLocally(user);
    return user;
  }

  /// Updates FCM registration token on server
  Future<void> updateFcmToken(String fcmToken) async {
    try {
      await _apiClient.post('/auth/fcm-token', body: {'fcm_token': fcmToken});
    } catch (_) {
      // Background push registration failure should not interrupt workflow
    }
  }

  /// Checks if active session exists with valid token and user profile
  Future<bool> isLoggedIn() async {
    final token = await _apiClient.getToken();
    if (token == null || token.isEmpty) {
      return false;
    }

    final user = await getCurrentUser();
    return user != null;
  }

  /// Verifies active session and returns user if session is valid
  Future<UserModel?> checkSession() async {
    final token = await _apiClient.getToken();
    if (token == null || token.isEmpty) {
      await logout();
      return null;
    }

    final cachedUser = await getCurrentUser();
    if (cachedUser == null) {
      await logout();
      return null;
    }

    return cachedUser;
  }

  /// Logs out user, invalidating session locally and notifying backend
  Future<void> logout() async {
    try {
      // Notify backend to revoke token if endpoint is available
      await _apiClient.post('/auth/logout');
    } catch (_) {
      // Ignore network failures on logout so user is always logged out locally
    } finally {
      _currentUser = null;
      await _apiClient.clearToken();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userStorageKey);
      await prefs.remove(_tokenStorageKey);
    }
  }

  /// Sends a request to send a password reset link to the given email address.
  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    final response = await _apiClient.post(
      '/forgot-password.php',
      body: {'email': email.trim()},
    );

    final dynamic decoded = _apiClient.decodeJson(response);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Invalid response format from server.',
      );
    }

    final bool isSuccess =
        decoded['success'] == true || decoded['ok'] == true;
    if (!isSuccess) {
      final errorMsg =
          decoded['error'] ?? decoded['message'] ?? 'Failed to request password reset.';
      throw ApiException(
        statusCode: response.statusCode,
        message: errorMsg.toString(),
      );
    }

    return decoded;
  }
}


