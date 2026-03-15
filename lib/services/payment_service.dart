import 'dart:async';
import 'dart:js' as js;
import 'dart:js_util' as js_util;
import 'package:flutter/foundation.dart';
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
    if (kIsWeb) return;
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
    if (kIsWeb) {
      await _openWebCheckout(
        key: key,
        amountInPaise: amountInPaise,
        currency: currency,
        name: name,
        description: description,
        email: email,
        contact: contact,
      );
      return;
    }

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

  Future<void> _openWebCheckout({
    required String key,
    required int amountInPaise,
    required String currency,
    required String name,
    required String description,
    required String email,
    required String contact,
  }) async {
    final globalObject = js_util.globalThis;
    final documentObject = js_util.getProperty(globalObject, 'document');
    if (documentObject == null) {
      onError('web_error', 'Web document unavailable');
      return;
    }

    var razorpayConstructor = js_util.getProperty(globalObject, 'Razorpay');
    if (razorpayConstructor == null) {
      final completer = Completer<void>();
      final scriptElement = js_util.callMethod(documentObject, 'createElement', ['script']);
      js_util.setProperty(scriptElement, 'src', 'https://checkout.razorpay.com/v1/checkout.js');
      js_util.setProperty(scriptElement, 'async', true);
      js_util.callMethod(scriptElement, 'addEventListener', [
        'load',
        js.allowInterop((_) => completer.complete()),
      ]);
      js_util.callMethod(scriptElement, 'addEventListener', [
        'error',
        js.allowInterop((_) => completer.completeError('Failed to load Razorpay checkout script.')),
      ]);
      final body = js_util.getProperty(documentObject, 'body');
      if (body == null) {
        onError('web_error', 'Web body object unavailable');
        return;
      }
      js_util.callMethod(body, 'appendChild', [scriptElement]);
      await completer.future;

      razorpayConstructor = js_util.getProperty(globalObject, 'Razorpay');
    }

    if (razorpayConstructor == null) {
      onError('web_error', 'Razorpay checkout is not available');
      return;
    }

    final handler = js.allowInterop((dynamic response) {
      final paymentId = js_util.getProperty(response, 'razorpay_payment_id') as String?;
      final orderId = js_util.getProperty(response, 'razorpay_order_id') as String?;
      final signature = js_util.getProperty(response, 'razorpay_signature') as String?;
      onSuccess({
        'razorpay_payment_id': paymentId ?? '',
        'razorpay_order_id': orderId ?? '',
        'razorpay_signature': signature ?? '',
      });
    });

    final options = js_util.jsify({
      'key': key,
      'amount': amountInPaise,
      'currency': currency,
      'name': name,
      'description': description,
      'prefill': {
        'email': email,
        'contact': contact,
      },
      'handler': handler,
      'modal': {
        'ondismiss': js.allowInterop(() {
          onError('payment_cancelled', 'Payment cancelled by user.');
        }),
      },
    });

    try {
      final razorpay = js_util.callConstructor(razorpayConstructor, [options]);
      js_util.callMethod(razorpay, 'open', []);
    } catch (e) {
      onError('web_error', e.toString());
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
    if (!kIsWeb) {
      _razorpay?.clear();
      _razorpay = null;
    }
  }
}
