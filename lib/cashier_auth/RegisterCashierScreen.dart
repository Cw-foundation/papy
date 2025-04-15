import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AddCashierScreen extends StatefulWidget {
  @override
  _AddCashierScreenState createState() => _AddCashierScreenState();
}

class _AddCashierScreenState extends State<AddCashierScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  /// Gera um hash seguro da senha
  String _generatePasswordHash(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Registra o Cashier
  Future<void> _registerCashier() async {
    String name = _nameController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();
    User? adminUser = _auth.currentUser;

    if (adminUser == null) {
      print("Usuário não autenticado.");
      return;
    }

    if (name.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      print("Preencha todos os campos.");
      return;
    }

    if (password.length < 6) {
      print("A senha deve ter pelo menos 6 caracteres.");
      return;
    }

    if (password != confirmPassword) {
      print("As senhas não coincidem.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      String cashierId = _firestore.collection('Users').doc(adminUser.uid).collection('Cashiers').doc().id;
      String passwordHash = _generatePasswordHash(password);

      /// Salvando o Cashier corretamente
      await _firestore.collection('Users').doc(adminUser.uid).collection('Cashiers').doc(cashierId).set({
        'cashierId': cashierId,
        'name': name,
        'password': passwordHash,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _nameController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();

      /// **Voltar à tela anterior**
      Navigator.pop(context);
    } catch (e) {
      print("Erro ao criar cashier: $e");
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Cadastrar Cashier"),
        backgroundColor: Color(0xFF07063a),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.badge, size: 150, color: Color(0xFF07063a)),
            SizedBox(height: 20),
            _buildTextField(_nameController, "Nome", false),
            SizedBox(height: 16),
            _buildTextField(_passwordController, "Senha", true),
            SizedBox(height: 16),
            _buildTextField(_confirmPasswordController, "Confirmar Senha", true),
            SizedBox(height: 30),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _registerCashier,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF07063a),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: EdgeInsets.symmetric(horizontal: 100, vertical: 15),
              ),
              child: Text("Criar Cashier", style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController? controller, String hint, bool isPassword) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blueGrey.shade50, width: 2),
        ),
      ),
    );
  }
}
