import 'agent.dart';

class LoginResponse {
  const LoginResponse({
    required this.authCode,
    required this.expiresAt,
    required this.agent,
  });

  final String authCode;
  final DateTime expiresAt;
  final Agent agent;

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        authCode: json['auth_code'] as String,
        expiresAt: DateTime.parse(json['expires_at'] as String),
        agent: Agent.fromJson(json['agent'] as Map<String, dynamic>),
      );
}
