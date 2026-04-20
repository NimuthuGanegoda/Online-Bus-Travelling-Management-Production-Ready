class PaymentModel {
  final String id;
  final String paymentMethod;
  final String cardHolderName;
  final String maskedCard;
  final double amountLkr;
  final String status;
  final DateTime createdAt;

  const PaymentModel({
    required this.id,
    required this.paymentMethod,
    required this.cardHolderName,
    required this.maskedCard,
    required this.amountLkr,
    required this.status,
    required this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id:              json['id'] as String,
      paymentMethod:   json['payment_method'] as String,
      cardHolderName:  json['card_holder_name'] as String,
      maskedCard:      json['masked_card'] as String,
      amountLkr:       (json['amount_lkr'] as num).toDouble(),
      status:          json['status'] as String,
      createdAt:       DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isSuccess => status == 'success';

  String get methodLabel =>
      paymentMethod == 'credit_card' ? 'Credit Card' : 'Debit Card';
}
