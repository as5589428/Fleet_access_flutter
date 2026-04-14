import 'package:flutter/material.dart';

class AreaScreen extends StatelessWidget {
  const AreaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Area Management')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              child: ListTile(
                title: const Text('Area 1'),
                subtitle: const Text('Details about Area 1'),
                trailing: Icon(Icons.map_rounded),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Area 2'),
                subtitle: const Text('Details about Area 2'),
                trailing: Icon(Icons.map_rounded),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Area 3'),
                subtitle: const Text('Details about Area 3'),
                trailing: Icon(Icons.map_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
