class AppConfig {
  // Declare base URL as a static variable
  static String baseUrl = 'http://170.64.223.178:3000/';

  // Method to change the base URL if needed
  static void setBaseUrl(String url) {
    baseUrl = url;
  }
}
