import 'package:flutter/material.dart';
import 'customer_orders_sheet.dart';

/// Full-screen Customer Orders & Pickups tab inside the Customer navigation shell.
class CustomerOrdersScreen extends StatelessWidget {
  const CustomerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: CustomerOrdersSheet(isModal: false),
    );
  }
}
