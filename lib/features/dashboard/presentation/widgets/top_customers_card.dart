import 'package:flutter/material.dart';
import '../../../../shared/widgets/data/info_list_tile.dart';
import '../../../../shared/widgets/layout/app_card.dart';

class TopCustomersCard extends StatelessWidget {
  const TopCustomersCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SectionHeader(title: 'Top Customers', subtitle: 'This month'),
          InfoListTile(avatarText: 'S', title: 'M/s Shinde Traders', subtitle: '23 bills · Credit', trailing: '₹4.2L'),
          InfoListTile(avatarText: 'T', title: 'The Terminus Bar', subtitle: '18 bills · Cash', trailing: '₹3.1L'),
          InfoListTile(avatarText: 'R', title: 'Royal Spirits', subtitle: '15 bills · Credit', trailing: '₹2.6L'),
          InfoListTile(avatarText: 'P', title: 'Planet 9 Lounge', subtitle: '11 bills · Card', trailing: '₹1.9L'),
        ],
      ),
    );
  }
}
