/// A single row in the Item Details table.
/// UI-first phase: instances are hard-coded dummy data; once the
/// repository layer lands this will be populated from Drift.
class SaleLineItem {
  const SaleLineItem({
    required this.index,
    required this.barcode,
    required this.type,
    required this.material,
    required this.batch,
    required this.pack,
    required this.qty,
    required this.rate,
    required this.discount,
    required this.tax,
    required this.amount,
  });

  final int index;
  final String barcode;
  final String type;
  final String material;
  final String batch;
  final String pack;
  final int qty;
  final double rate;
  final double discount;
  final double tax;
  final double amount;

  static List<SaleLineItem> dummy() => const [
        SaleLineItem(
          index: 1,
          barcode: '890123',
          type: 'Lic',
          material: 'London Pilsener',
          batch: 'LP-',
          pack: '500ml',
          qty: 24,
          rate: 150,
          discount: 0,
          tax: 162,
          amount: 3402,
        ),
      ];
}
