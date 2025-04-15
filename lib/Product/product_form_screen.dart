import 'package:flutter/material.dart';

import 'productWithoutcCode.dart';

class ProductFormScreen extends StatelessWidget {
  const ProductFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // Navegar para a tela de cadastro manual
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddProductScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(40),
                backgroundColor: Colors.white,
              ),
              child: const Icon(Icons.edit, size: 40, color: Color(0xFF07063a)),
            ),
            const SizedBox(height: 10),
            const Text("Cadastro Manual", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class ManualRegistrationScreen extends StatelessWidget {
  const ManualRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cadastro Manual"),
        backgroundColor: const Color(0xFF07063a),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text("Tela de Cadastro Manual", style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
