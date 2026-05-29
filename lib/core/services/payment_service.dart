// lib/core/services/payment_service.dart
//
// End-to-end Razorpay flow:
//   1. createOrder() → POST /create_order.php (server creates RZP order using
//      key_id+secret read from app_settings)
//   2. open() → opens Razorpay native checkout
//   3. on success → POST /verify_payment.php → marks user premium
//   4. After success, AuthService cache + UI is updated
//
// The screen using this service should:
//   - call `attach(onSuccess, onError)` in initState
//   - call `dispose()` in dispose
//   - call `startUpgrade(plan: 'lifetime')` on the Pay button.

import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../network/api_client.dart';
import 'auth_service.dart';
import 'app_settings_service.dart';

typedef PaymentSuccessHandler = void Function(Map<String, dynamic> premiumInfo);
typedef PaymentErrorHandler = void Function(String message);

class PaymentService {
  Razorpay? _razorpay;
  PaymentSuccessHandler? _onSuccess;
  PaymentErrorHandler? _onError;
  String _currentPlan = 'lifetime';

  void attach({
    required PaymentSuccessHandler onSuccess,
    required PaymentErrorHandler onError,
  }) {
    _onSuccess = onSuccess;
    _onError = onError;

    _razorpay = Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _handleError)
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
  }

  /// Step 1+2: ask server for an order, then open the checkout.
  ///
  /// Throws nothing — surfaces errors via [onError] callback.
  Future<void> startUpgrade({String plan = 'lifetime'}) async {
    _currentPlan = plan;

    if (_razorpay == null) {
      _onError?.call('Payment not initialised');
      return;
    }

    // Make sure settings (including razorpay_enabled) are fresh
    await AppSettingsService.instance.refresh();
    final enabled = AppSettingsService.instance.getBool('razorpay_enabled');
    if (!enabled) {
      _onError?.call('Online payments are temporarily disabled. Please try again later.');
      return;
    }

    Map<String, dynamic> orderRes;
    try {
      orderRes = await ApiClient.post(
        'create_order.php',
        {'plan': plan},
        auth: true,
      );
    } catch (e) {
      _onError?.call('Could not start payment. Check your internet.');
      return;
    }

    final ok = orderRes['success'] == true || orderRes['status'] == true;
    if (!ok) {
      _onError?.call(
          (orderRes['message'] ?? 'Could not create order').toString());
      return;
    }

    final orderId = orderRes['order_id']?.toString() ?? '';
    final keyId = orderRes['key_id']?.toString() ?? '';
    final amount = (orderRes['amount'] as num?)?.toInt() ?? 0;
    final name = (orderRes['name'] ?? '').toString();
    final phone = (orderRes['phone'] ?? '').toString();

    if (orderId.isEmpty || keyId.isEmpty || amount <= 0) {
      _onError?.call('Invalid order from server');
      return;
    }

    final appName = AppSettingsService.instance.get('app_name', 'Tunnel');
    final appTagline = AppSettingsService.instance.get(
      'app_tagline',
      'Premium Upgrade',
    );

    final options = <String, dynamic>{
      'key': keyId,
      'amount': amount,
      'currency': 'INR',
      'order_id': orderId,
      'name': appName,
      'description': appTagline,
      'theme': {'color': '#00E5FF'},
      'prefill': <String, String>{
        if (phone.isNotEmpty) 'contact': phone,
        if (name.isNotEmpty) 'name': name,
      },
      'retry': {'enabled': true, 'max_count': 1},
    };

    try {
      _razorpay!.open(options);
    } catch (e) {
      _onError?.call('Could not open Razorpay: $e');
    }
  }

  // ── Razorpay callbacks ───────────────────────────
  Future<void> _handleSuccess(PaymentSuccessResponse r) async {
    try {
      final verify = await ApiClient.post(
        'verify_payment.php',
        {
          'razorpay_order_id': r.orderId,
          'razorpay_payment_id': r.paymentId,
          'razorpay_signature': r.signature,
          'plan': _currentPlan,
        },
        auth: true,
      );

      final ok = verify['success'] == true || verify['status'] == true;
      if (ok) {
        // Update local premium flag immediately
        await AuthService.setPremium(true);
        final premiumInfo = (verify['premium'] is Map)
            ? Map<String, dynamic>.from(verify['premium'] as Map)
            : <String, dynamic>{};
        _onSuccess?.call(premiumInfo);
      } else {
        _onError?.call((verify['message'] ?? 'Verification failed').toString());
      }
    } catch (e) {
      debugPrint('[PaymentService.verify] $e');
      _onError?.call('Network error during verification. If money was deducted, contact support.');
    }
  }

  void _handleError(PaymentFailureResponse r) {
    final msg = r.message ?? 'Payment cancelled';
    if (r.code == Razorpay.PAYMENT_CANCELLED) {
      _onError?.call('Payment cancelled.');
    } else {
      _onError?.call(msg);
    }
  }

  void _handleExternalWallet(ExternalWalletResponse r) {
    debugPrint('[Razorpay external wallet] ${r.walletName}');
  }
}
