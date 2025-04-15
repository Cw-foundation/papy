import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  _ScannerScreenState createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get user => _auth.currentUser;

  /// Salva o produto no Firestore após confirmação do usuário
  Future<void> _saveProduct(String barcode, String name, String expirationDate, double price) async {
    if (user == null) {
      print("❌ Usuário não autenticado. Não é possível salvar.");
      return;
    }

    try {
      await _firestore
          .collection('Users')
          .doc(user!.uid)
          .collection('ProductsBarcode')
          .doc(barcode)
          .set({
        'barcode': barcode,
        'name': name,
        'expirationDate': Timestamp.fromDate(DateTime.parse(expirationDate)),
        'price': price,
      });
      print("✅ Produto salvo no Firestore!");
      _showSuccessMessage();
    } catch (e) {
      print("❌ Erro ao salvar produto: $e");
    }
  }

  /// Inicia o scanner de código de barras
  Future<void> _startBarcodeScanner() async {
    String barcode = await FlutterBarcodeScanner.scanBarcode(
      "#ff6666", "Cancelar", true, ScanMode.BARCODE,
    );

    if (barcode != "-1") {
      _showProductForm(barcode);
    }
  }

  /// Exibe o formulário para confirmar os dados do produto antes de salvar
  void _showProductForm(String barcode) {
    TextEditingController nameController = TextEditingController();
    TextEditingController expirationController = TextEditingController();
    TextEditingController priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Confirmar Produto"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: "Nome")),
                TextField(controller: expirationController, decoration: const InputDecoration(labelText: "Data de Validade (AAAA-MM-DD)")),
                TextField(controller: priceController, decoration: const InputDecoration(labelText: "Preço"), keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancelar")),
            ElevatedButton(
              onPressed: () {
                double price = double.tryParse(priceController.text) ?? 0.0;
                _saveProduct(barcode, nameController.text, expirationController.text, price);
                Navigator.pop(dialogContext);
              },
              child: const Text("Salvar"),
            ),
          ],
        );
      },
    );
  }

  /// Exibe mensagem de sucesso ao salvar
  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("✅ Produto salvo com sucesso!"),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Scanner de Código de Barras")),
        body: const Center(child: Text("Por favor, faça login para registrar produtos.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _startBarcodeScanner,
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(40),
                backgroundColor: Colors.white,
              ),
              child: const Icon(Icons.qr_code_scanner, size: 40, color: Color(0xFF07063a)),
            ),
            const SizedBox(height: 10),
            const Text("Escanear Código", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
