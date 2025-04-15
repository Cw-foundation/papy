import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductViewScreen extends StatefulWidget {
  @override
  _ProductViewScreenState createState() => _ProductViewScreenState();
}

class _ProductViewScreenState extends State<ProductViewScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();

  User? get user => _auth.currentUser;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Produtos'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text("Por favor, faça login para visualizar os produtos."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Produtos'),
        backgroundColor: const Color(0xFF07063a),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}), // Atualiza a tela manualmente
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Color(0xFF07063a)),
                hintText: 'Procurar produto',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('Users')
                  .doc(user!.uid)
                  .collection('ProductsBarcode')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Nenhum produto cadastrado!'));
                }

                var products = snapshot.data!.docs.where((product) {
                  var productData = product.data() as Map<String, dynamic>;
                  var name = productData['name']?.toString().toLowerCase() ?? '';
                  return name.contains(_searchController.text.toLowerCase());
                }).toList();

                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    var product = products[index];
                    var productData = product.data() as Map<String, dynamic>;

                    return ListTile(
                      title: Text(productData['name'] ?? 'Sem nome'),
                      subtitle: Text('Preço: ${productData['price']} kz'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: const Color(0xFF07063a)),
                            onPressed: () {
                              _editProduct(product.id, productData);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _deleteProduct(product.id);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _editProduct(String productId, Map<String, dynamic> productData) {
    TextEditingController nameController =
    TextEditingController(text: productData['name']);
    TextEditingController priceController =
    TextEditingController(text: productData['price'].toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Produto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nome do Produto'),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Preço (kz)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                _firestore
                    .collection('Users')
                    .doc(user!.uid)
                    .collection('ProductsBarcode')
                    .doc(productId)
                    .update({
                  'name': nameController.text,
                  'price': double.tryParse(priceController.text) ?? 0,
                });
                Navigator.pop(context);
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  void _deleteProduct(String productId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar exclusão'),
          content: const Text('Tem certeza que deseja excluir este produto?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                _firestore
                    .collection('Users')
                    .doc(user!.uid)
                    .collection('ProductsBarcode')
                    .doc(productId)
                    .delete();
                Navigator.pop(context);
              },
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
