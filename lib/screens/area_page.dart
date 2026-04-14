import 'package:flutter/material.dart';

class AreaPage extends StatelessWidget {
  const AreaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Area'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add New Area',
                style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(labelText: 'Area Name'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              child: Text('Add Area'),
            ),
          ],
        ),
      ),
    );
  }
}
