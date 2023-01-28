import 'package:flutter/widgets.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/http_exception.dart';

class Auth with ChangeNotifier {
  String? _token = null;
  String? _userId = null;
  DateTime? _expiryDate = null;
  Timer? _authTimer = null;

  bool get isAuth {
    return token != null;
  }

  String get userId {
    return _userId ?? '';
  }

  String? get token {
    if (_expiryDate != null &&
        _expiryDate!.isAfter(DateTime.now()) &&
        _token != null) {
      return _token;
    }
    return null;
  }

  Future<http.Response> _authenticate(
      String email, String password, String urlSegment) async {
    final url = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:$urlSegment?key=AIzaSyCZqv16HE0IxJJNy8ibqnHQveR628MLNys');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(
          {
            'email': email,
            'password': password,
            'returnSecureToken': true,
          },
        ),
      );

      print(response.body);
      final responseData = json.decode(response.body);
      if (responseData['error'] != null) {
        throw HttpException(responseData['error']['message']);
      }
      _token = responseData['idToken'];
      _userId = responseData['localId'];
      _expiryDate = DateTime.now().add(
        Duration(
          seconds: int.parse(
            responseData['expiresIn'],
          ),
        ),
      );
      _autoLogout();
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      final userData = json.encode({
        'token': _token,
        'userId': _userId,
        'expiryDate': _expiryDate!.toIso8601String(),
      });
      prefs.setString('userData', userData);

      return response;
    } catch (error) {
      print(error);
      throw error;
    }
  }

  Future<http.Response> signUp(String email, String password) async {
    // 'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=AIzaSyCZqv16HE0IxJJNy8ibqnHQveR628MLNys');

    return _authenticate(email, password, 'signUp');
  }

  Future<http.Response> login(String email, String password) async {
    // 'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=AIzaSyCZqv16HE0IxJJNy8ibqnHQveR628MLNys');

    return _authenticate(email, password, 'signInWithPassword');
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) {
      return false;
    }
    if (prefs.getString('userData') == null) {
      return false;
    }
    final extractedUserData =
        json.decode(prefs.getString('userData')!) as Map<String, dynamic>;

    final expiryDate =
        DateTime.parse(extractedUserData['expiryDate'] as String);

    if (expiryDate.isBefore(DateTime.now())) {
      return false;
    }

    //  _token = extractedUserData['expiryDate'] as String;
    _token = extractedUserData['token'] as String;
    _userId = extractedUserData['userId'] as String;
    _expiryDate = expiryDate;
    notifyListeners();
    _autoLogout();
    return true;
  }

  Future<void> logout() async {
    if (_authTimer != null) {
      _authTimer!.cancel();
      _authTimer = null;
    }
    _token = null;
    _userId = null;
    _expiryDate = null;

    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('userData');
    //prefs.clear();
  }

  void _autoLogout() {
    if (_authTimer != null) {
      _authTimer!.cancel();
    }
    final timeToExpory = _expiryDate!.difference(DateTime.now()).inSeconds;
    _authTimer = Timer(Duration(seconds: timeToExpory), logout);
    //_authTimer = Timer(Duration(seconds: 60), logout);
  }
}
