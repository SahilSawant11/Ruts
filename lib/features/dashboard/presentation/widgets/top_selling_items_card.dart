import 'package:flutter/material.dart';
import '../../../../shared/widgets/data/info_list_tile.dart';
import '../../../../shared/widgets/layout/app_card.dart';

class TopSellingItemsCard extends StatelessWidget {
  const TopSellingItemsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SectionHeader(title: 'Top Selling Items', subtitle: 'By quantity today'),
          InfoListTile(
            icon: Icons.inventory_2_outlined,
            title: 'Royal Stag Classic Whisky',
            subtitle: '750ml · Batch RS-0199',
            trailing: '612',
          ),
          InfoListTile(
            icon: Icons.inventory_2_outlined,
            title: 'London Pilsener Premium Beer',
            subtitle: '500ml CAN · Batch LP-2290',
            trailing: '1,240',
          ),
          InfoListTile(
            icon: Icons.inventory_2_outlined,
            title: 'Budweiser Premium Beer',
            subtitle: '330ml BTL · Batch BW-3301',
            trailing: '2,010',
          ),
          InfoListTile(
            icon: Icons.inventory_2_outlined,
            title: "McDowell's No.1 Rum",
            subtitle: '750ml · Batch MD-7741',
            trailing: '388',
          ),
        ],
      ),
    );
  }
}
