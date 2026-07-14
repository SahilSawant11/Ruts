/// A single packing/rate row for a material (e.g. "500ml CAN").
/// Dummy data only for the UI-first phase.
class MaterialPacking {
  const MaterialPacking({
    required this.index,
    required this.packing,
    required this.itemCode,
    required this.purRate,
    required this.saleRate,
    required this.wholesale,
    required this.qty,
    required this.barcode,
  });

  final int index;
  final String packing;
  final String itemCode;
  final double purRate;
  final double saleRate;
  final double wholesale;
  final int qty;
  final String barcode;

  static List<MaterialPacking> dummy() => const [
        MaterialPacking(
          index: 1,
          packing: '500ml CAN',
          itemCode: 'LP500CAN',
          purRate: 110,
          saleRate: 135,
          wholesale: 128,
          qty: 48,
          barcode: '8901234567890',
        ),
        MaterialPacking(
          index: 2,
          packing: '650ml BTL',
          itemCode: 'LP650BTL',
          purRate: 165,
          saleRate: 195,
          wholesale: 185,
          qty: 24,
          barcode: '8901234567891',
        ),
      ];
}
