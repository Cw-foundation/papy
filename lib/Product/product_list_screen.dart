import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:async/async.dart';

class ProductListScreen extends StatefulWidget {
  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  TextEditingController _searchController = TextEditingController();

  User? get user => _auth.currentUser;

  late Stream<List<QueryDocumentSnapshot<Object?>>> _productsStream;

  @override
  void initState() {
    super.initState();
    _refreshProducts();
  }

  void _refreshProducts() {
    setState(() {
      _productsStream = _fetchProducts();
    });
  }

  Stream<List<QueryDocumentSnapshot<Object?>>> _fetchProducts() {
    if (user == null) return const Stream.empty();

    Stream<QuerySnapshot<Object?>> productsStream = _firestore
        .collection('Users')
        .doc(user!.uid)
        .collection('ProductsBarcode')
        .orderBy('timestamp', descending: true)
        .snapshots();

    Stream<QuerySnapshot<Object?>> productsWithoutBarcodeStream = _firestore
        .collection('Users')
        .doc(user!.uid)
        .collection('ProductWithoutBarcode')
        .orderBy('timestamp', descending: true)
        .snapshots();

    return StreamZip([productsStream, productsWithoutBarcodeStream]).map((snapshots) {
      List<QueryDocumentSnapshot<Object?>> allProducts = [];
      for (var snapshot in snapshots) {
        allProducts.addAll(snapshot.docs.cast<QueryDocumentSnapshot<Object?>>());
      }
      return allProducts;
    });
  }

  void _editProduct(QueryDocumentSnapshot product) {
    TextEditingController nameController = TextEditingController(text: product['name']);
    TextEditingController priceController = TextEditingController(text: product['price'].toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Editar Produto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Nome'),
              ),
              TextField(
                controller: priceController,
                decoration: InputDecoration(labelText: 'Preço'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                String collectionName = product.reference.parent.id; // Obtém o nome da coleção

                await _firestore
                    .collection('Users')
                    .doc(user!.uid)
                    .collection(collectionName) // Atualiza na coleção correta
                    .doc(product.id)
                    .update({
                  'name': nameController.text,
                  'price': double.tryParse(priceController.text) ?? product['price'],
                });

                _refreshProducts();
                Navigator.pop(context);
              },
              child: Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  void _deleteProduct(QueryDocumentSnapshot product) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Excluir Produto'),
          content: Text('Tem certeza que deseja excluir este produto?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                String collectionName = product.reference.parent.id; // Obtém o nome da coleção

                await _firestore
                    .collection('Users')
                    .doc(user!.uid)
                    .collection(collectionName) // Remove na coleção correta
                    .doc(product.id)
                    .delete();

                _refreshProducts();
                Navigator.pop(context);
              },
              child: Text('Excluir', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Stock'),
          backgroundColor: const Color(0xFF07063a),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text("Por favor, faça login para visualizar os produtos."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Produtos Cadastrados'),
        centerTitle: true,
        backgroundColor: const Color(0xFF07063a),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshProducts,
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
                hintText: 'Procurar item',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<QueryDocumentSnapshot<Object?>>>(
              stream: _productsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Nenhum produto cadastrado ainda!'));
                }

                var products = snapshot.data!.where((product) {
                  var productData = product.data() as Map<String, dynamic>;
                  var name = productData['name'].toString().toLowerCase();
                  return name.contains(_searchController.text.toLowerCase());
                }).toList();

                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    var product = products[index];
                    var productData = product.data() as Map<String, dynamic>;

                    return ListTile(
                      title: Text(productData['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      subtitle: Text('Preço: ${productData['price']} kz'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.red), onPressed: () => _editProduct(product)),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteProduct(product)),
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
}
