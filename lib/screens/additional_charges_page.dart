import 'package:flutter/material.dart';

class AdditionalChargesPage extends StatelessWidget {
  const AdditionalChargesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Additional Charges'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add New Charge',
                style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(labelText: 'Charge Name'),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              child: Text('Add Charge'),
            ),
          ],
        ),
      ),
    );
  }
}
