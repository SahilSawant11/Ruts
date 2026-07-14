/// A single row in the Purchase Bill's Item Details table.
/// Dummy data only for the UI-first phase.
class PurchaseLineItem {
  const PurchaseLineItem({
    required this.index,
    required this.material,
    required this.batch,
    required this.packing,
    required this.kg,
    required this.rate,
    required this.discountPercent,
    required this.discount,
    required this.per,
    required this.taxPercent,
    required this.taxAmount,
    required this.amount,
    required this.totalAmount,
    required this.units,
  });

  final int index;
  final String material;
  final String batch;
  final String packing;
  final int kg;
  final double rate;
  final double discountPercent;
  final double discount;
  final String per;
  final double taxPercent;
  final double taxAmount;
  final double amount;
  final double totalAmount;
  final String units;

  static List<PurchaseLineItem> dummy() => const [
        PurchaseLineItem(
          index: 1,
          material: 'London Pilsener Premium Strong Beer',
          batch: 'LP-2290',
          packing: '500ml CAN',
          kg: 48,
          rate: 110,
          discountPercent: 2,
          discount: 106,
          per: 'CAN',
          taxPercent: 5,
          taxAmount: 159,
          amount: 5153,
          totalAmount: 5153,
          units: '48 CAN',
        ),
      ];
}
