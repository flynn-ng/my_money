import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n/app_strings.dart';

String friendlyError(Object error) {
  if (error is AuthException) {
    switch (error.message) {
      case 'Invalid login credentials':
        return 'Email hoặc mật khẩu không đúng';
      case 'User already registered':
        return 'Email đã được đăng ký';
      case 'Email not confirmed':
        return 'Vui lòng xác nhận email trước khi đăng nhập';
      default:
        return S.somethingWrong;
    }
  }
  if (error is PostgrestException) {
    if (error.code == '23503') return 'Dữ liệu liên quan không tồn tại';
    if (error.code == '23505') return 'Dữ liệu đã tồn tại';
    return S.somethingWrong;
  }
  final msg = error.toString();
  if (msg.contains('Invite code not found') || msg.contains('not found')) {
    return 'Mã mời không hợp lệ. Kiểm tra lại và thử lại.';
  }
  if (msg.contains('network') || msg.contains('SocketException')) {
    return 'Không có kết nối mạng. Kiểm tra và thử lại.';
  }
  return S.somethingWrong;
}
