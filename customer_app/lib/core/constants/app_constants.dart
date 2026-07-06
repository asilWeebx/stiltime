class AppConstants {
  static const baseUrl = 'http://127.0.0.1:8000/api/v1';
  static const appName = 'StilTime';
  static const appVersion = '1.0.0';
  static const accessTokenKey = 'access_token';
  static const refreshTokenKey = 'refresh_token';
  static const userKey = 'user_data';
  static const languageKey = 'language';
  static const themeKey = 'theme_mode';

  static const categories = [
    {'id': 1, 'name': 'Soch olish', 'icon': '✂️'},
    {'id': 2, 'name': 'Soqol', 'icon': '🪒'},
    {'id': 3, 'name': 'Bo\'yash', 'icon': '🎨'},
    {'id': 4, 'name': 'Yuz parvarishi', 'icon': '💆'},
    {'id': 5, 'name': 'Manikür', 'icon': '💅'},
  ];

  static const reminderOptions = [
    {'minutes': 15, 'label': '15 daqiqa oldin'},
    {'minutes': 30, 'label': '30 daqiqa oldin'},
    {'minutes': 45, 'label': '45 daqiqa oldin'},
    {'minutes': 60, 'label': '1 soat oldin'},
  ];

  static const languages = [
    {'code': 'uz', 'label': "O'zbek", 'flag': '🇺🇿'},
    {'code': 'ru', 'label': 'Русский', 'flag': '🇷🇺'},
    {'code': 'en', 'label': 'English', 'flag': '🇺🇸'},
  ];
}
