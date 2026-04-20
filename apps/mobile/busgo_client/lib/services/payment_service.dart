import '../models/payment_model.dart';
import 'api_client.dart';

class PaymentService {
  final ApiClient _api;

  PaymentService(this._api);

  /// Submit a payment. Returns the created [PaymentModel] (success or failed).
  Future<PaymentModel> createPayment({
    required String paymentMethod,
    required String cardHolderName,
    required String cardNumber,
    required String expiryDate,
    required String cvv,
    required double amountLkr,
  }) async {
    final data = await _api.post('/payments', data: {
      'payment_method':   paymentMethod,
      'card_holder_name': cardHolderName,
      'card_number':      cardNumber,
      'expiry_date':      expiryDate,
      'cvv':              cvv,
      'amount_lkr':       amountLkr,
    });
    return PaymentModel.fromJson(data as Map<String, dynamic>);
  }

  /// Fetch the current user's payment history.
  Future<List<PaymentModel>> listMyPayments() async {
    final data = await _api.get('/payments');
    return (data as List)
        .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
