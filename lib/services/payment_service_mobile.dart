import 'package:razorpay_flutter/razorpay_flutter.dart';

typedef PaymentSuccessCallback = void Function(Map<String, dynamic> data);
typedef PaymentErrorCallback = void Function(String code, String message);
typedef PaymentExternalWalletCallback = void Function(String wallet);

class PaymentService {
  PaymentService({
    required this.onSuccess,
    required this.onError,
    required this.onExternalWallet,
  });

  final PaymentSuccessCallback onSuccess;
  final PaymentErrorCallback onError;
  final PaymentExternalWalletCallback onExternalWallet;

  Razorpay? _razorpay;

  void init() {
    _razorpay = Razorpay();
    _razorpay?.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay?.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay?.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  Future<void> openCheckout({
    required String key,
    required int amountInPaise,
    required String currency,
    required String name,
    required String description,
    required String email,
    required String contact,
  }) async {
    if (_razorpay == null) {
      onError('init_error', 'Payment service not initialized');
      return;
    }

    final options = {
      'key': key,
      'amount': amountInPaise,
      'currency': currency,
      'name': name,
      'description': description,
      'prefill': {
        'email': email,
        'contact': contact,
      },
      'theme': {
        'color': '#5A2E4A',
      },
    };

    try {
      _razorpay?.open(options);
    } catch (e) {
      onError('open_error', e.toString());
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    onSuccess({
      'razorpay_payment_id': response.paymentId ?? '',
      'razorpay_order_id': response.orderId ?? '',
      'razorpay_signature': response.signature ?? '',
    });
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    onError('${response.code}', response.message ?? 'Payment failed.');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    onExternalWallet(response.walletName ?? 'external_wallet');
  }

  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
  }
}
