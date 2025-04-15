import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AddProductScreen extends StatefulWidget {
  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DateTime? _selectedDate;

  Future<void> _pickDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _saveProduct() async {
    try {
      final User? user = _auth.currentUser;

      if (user == null) {
        _showSnackbar("❌ Usuário não autenticado.");
        return;
      }

      String userId = user.uid;

      if (_nameController.text.trim().isEmpty ||
          _priceController.text.trim().isEmpty ||
          _quantityController.text.trim().isEmpty) {
        _showSnackbar("⚠️ Preencha os campos obrigatórios: Nome, Quantidade e Preço.");
        return;
      }

      int? quantity = int.tryParse(_quantityController.text);
      if (quantity == null || quantity < 1) {
        _showSnackbar("⚠️ A quantidade deve ser um número válido e maior que 0.");
        return;
      }

      double? price = double.tryParse(_priceController.text);
      if (price == null || price <= 0) {
        _showSnackbar("⚠️ O preço deve ser um número válido e maior que 0.");
        return;
      }

      // Criar referência ao Firestore para produtos sem código de barras
      CollectionReference productsCollection = _firestore
          .collection('Users')
          .doc(userId)
          .collection('ProductWithoutBarcode');

      // Criar um novo documento automaticamente (Firestore gera um ID único)
      DocumentReference productRef = productsCollection.doc();

      // Criar um mapa com os dados do produto
      Map<String, dynamic> productData = {
        'name': _nameController.text.trim(),
        'quantity': quantity,
        'expirationDate': _selectedDate != null ? Timestamp.fromDate(_selectedDate!) : null,
        'price': price,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await productRef.set(productData);

      _showSnackbar("✅ Produto salvo com sucesso!");
      _clearFields();
    } catch (e, stacktrace) {
      print("❌ Erro ao salvar produto: $e");
      print("📌 Stacktrace: $stacktrace");
      _showSnackbar("❌ Erro ao salvar produto.");
    }
  }

  void _clearFields() {
    _nameController.clear();
    _quantityController.clear();
    _priceController.clear();
    setState(() {
      _selectedDate = null;
    });
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Adicionar Produto"),
        backgroundColor: Color(0xFF07063a),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: "Nome *"),
            ),
            TextField(
              controller: _quantityController,
              decoration: InputDecoration(labelText: "Quantidade *"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _priceController,
              decoration: InputDecoration(labelText: "Preço *"),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            ListTile(
              title: Text(
                _selectedDate == null
                    ? "Selecionar Data de Validade"
                    : "Data de Validade: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}",
              ),
              trailing: Icon(Icons.calendar_today),
              onTap: () => _pickDate(context),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveProduct,
              child: Text("Salvar Produto"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF07063a),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
