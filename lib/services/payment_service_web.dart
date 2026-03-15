import 'dart:async';
import 'dart:js' as js;
import 'dart:js_util' as js_util;

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

  void init() {
    // Web initialization is not required beyond ensuring Razorpay script loads in openCheckout.
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
    final globalObject = js_util.globalThis;
    final documentObject = js_util.getProperty(globalObject, 'document');
    if (documentObject == null) {
      onError('web_error', 'Web document unavailable');
      return;
    }

    var razorpayConstructor = js_util.getProperty(globalObject, 'Razorpay');
    if (razorpayConstructor == null) {
      final completer = Completer<void>();
      final scriptElement =
          js_util.callMethod(documentObject, 'createElement', ['script']);
      js_util.setProperty(
          scriptElement, 'src', 'https://checkout.razorpay.com/v1/checkout.js');
      js_util.setProperty(scriptElement, 'async', true);
      js_util.callMethod(scriptElement, 'addEventListener', [
        'load',
        js.allowInterop((_) => completer.complete()),
      ]);
      js_util.callMethod(scriptElement, 'addEventListener', [
        'error',
        js.allowInterop((_) => completer
            .completeError('Failed to load Razorpay checkout script.')),
      ]);
      final body = js_util.getProperty(documentObject, 'body');
      if (body == null) {
        onError('web_error', 'Web body object unavailable');
        return;
      }
      js_util.callMethod(body, 'appendChild', [scriptElement]);

      try {
        await completer.future;
      } catch (e) {
        onError('web_error', e.toString());
        return;
      }

      razorpayConstructor = js_util.getProperty(globalObject, 'Razorpay');
    }

    if (razorpayConstructor == null) {
      onError('web_error', 'Razorpay checkout is not available');
      return;
    }

    final handler = js.allowInterop((dynamic response) {
      final paymentId =
          js_util.getProperty(response, 'razorpay_payment_id') as String?;
      final orderId =
          js_util.getProperty(response, 'razorpay_order_id') as String?;
      final signature =
          js_util.getProperty(response, 'razorpay_signature') as String?;
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

  void dispose() {
    // No native razorpay instance to clear on web.
  }
}
