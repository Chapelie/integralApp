/// Sale item model representing individual line items in a sale transaction
///
/// This class manages the details of each product sold in a transaction,
/// including quantity, pricing, discounts, and tax calculations.
library;

class SaleItem {
  final String? id;
  final String? saleId;
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final double taxRate;
  final double? discount;
  final double lineTotal;

  SaleItem({
    this.id,
    this.saleId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    this.taxRate = 0.0,
    this.discount,
    required this.lineTotal,
  });

  /// Calculates the line total for this item
  ///
  /// Formula: (quantity * price) + tax
  double calculateLineTotal() {
    final subtotal = quantity * price;
    final taxAmount = subtotal * (taxRate / 100);
    return subtotal + taxAmount;
  }

  /// Converts SaleItem to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'saleId': saleId,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'price': price,
      'taxRate': taxRate,
      'discount': discount,
      'lineTotal': lineTotal,
    };
  }

  /// Converts SaleItem to API JSON map (snake_case for backend)
  Map<String, dynamic> toApiJson({String? deviceId}) {
    final json = {
      'product_id': productId,
      'quantity': quantity,
      'price': price,
    };
    
    // Add device_id if provided
    if (deviceId != null) {
      json['devices_id'] = deviceId;
    }
    
    return json;
  }

  /// Creates SaleItem from JSON map
  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      id: json['id'] as String?,
      saleId: json['saleId'] as String?,
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
      taxRate: json['taxRate'] != null ? (json['taxRate'] as num).toDouble() : 0.0,
      discount: json['discount'] != null ? (json['discount'] as num).toDouble() : null,
      lineTotal: (json['lineTotal'] as num).toDouble(),
    );
  }

  /// Creates a copy of this SaleItem with updated fields
  SaleItem copyWith({
    String? id,
    String? saleId,
    String? productId,
    String? productName,
    int? quantity,
    double? price,
    double? taxRate,
    double? discount,
    double? lineTotal,
  }) {
    return SaleItem(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      taxRate: taxRate ?? this.taxRate,
      discount: discount ?? this.discount,
      lineTotal: lineTotal ?? this.lineTotal,
    );
  }

  @override
  String toString() {
    return 'SaleItem(id: $id, productId: $productId, productName: $productName, quantity: $quantity, lineTotal: $lineTotal)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SaleItem &&
        other.id == id &&
        other.saleId == saleId &&
        other.productId == productId &&
        other.productName == productName &&
        other.quantity == quantity &&
        other.price == price &&
        other.taxRate == taxRate &&
        other.discount == discount &&
        other.lineTotal == lineTotal;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        saleId.hashCode ^
        productId.hashCode ^
        productName.hashCode ^
        quantity.hashCode ^
        price.hashCode ^
        taxRate.hashCode ^
        discount.hashCode ^
        lineTotal.hashCode;
  }
}
