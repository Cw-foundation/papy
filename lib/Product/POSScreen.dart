import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class POSScreen extends StatefulWidget {
  const POSScreen({super.key});

  @override
  _POSScreenState createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? get user => _auth.currentUser;
  String cartId = "cliente_123";

  String selectedPaymentMethod = "Dinheiro"; // Método de pagamento padrão
  double receivedAmount = 0.0; // Valor recebido do cliente
  double changeAmount = 0.0; // Troco calculado

  Future<void> _startBarcodeScanner() async {
    String barcode = await FlutterBarcodeScanner.scanBarcode(
      "#ff6666",
      "Cancelar",
      true,
      ScanMode.BARCODE,
    );
    if (barcode != "-1") {
      _addProductToCart(barcode, isBarcode: true);
    }
  }

  Future<void> _addProductToCart(String productId, {bool isBarcode = true}) async {
    if (user == null) return;
    try {
      DocumentSnapshot productSnapshot = await _firestore
          .collection('Users')
          .doc(user!.uid)
          .collection(isBarcode ? 'Products' : 'ProductWithoutBarcode')
          .doc(productId)
          .get();

      if (!productSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Produto não encontrado!")),
        );
        return;
      }

      Map<String, dynamic> productData = productSnapshot.data() as Map<String, dynamic>;
      DocumentReference cartRef = _firestore
          .collection('Users')
          .doc(user!.uid)
          .collection('carts')
          .doc(cartId);

      DocumentSnapshot cartSnapshot = await cartRef.get();
      List<dynamic> products = [];
      double total = 0.0;

      if (cartSnapshot.exists) {
        Map<String, dynamic> cartData = cartSnapshot.data() as Map<String, dynamic>;
        products = cartData['products'];
        total = cartData['total'];
      }

      bool productExists = false;
      for (var p in products) {
        if (p['id'] == productId) {
          p['quantity'] += 1;
          productExists = true;
          break;
        }
      }

      if (!productExists) {
        products.add({
          'id': productId,
          'name': productData['name'],
          'price': productData['price'],
          'quantity': 1,
        });
      }

      total += productData['price'];
      await cartRef.set({'products': products, 'total': total});
      setState(() {});
    } catch (e) {
      print("Erro ao adicionar produto ao carrinho: $e");
    }
  }

  Future<void> _finalizeSale() async {
    try {
      DocumentReference cartRef = _firestore
          .collection('Users')
          .doc(user!.uid)
          .collection('carts')
          .doc(cartId);

      DocumentSnapshot cartSnapshot = await cartRef.get();
      if (cartSnapshot.exists) {
        Map<String, dynamic> cartData = cartSnapshot.data() as Map<String, dynamic>;
        double total = cartData['total'];
        List<dynamic> products = cartData['products'];

        // Mostra o resumo do carrinho em uma caixa de diálogo
        await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Resumo do Carrinho"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...products.map((product) {
                    return Text(
                      "${product['name']} - ${product['quantity']} x Kz ${product['price'].toStringAsFixed(2)}",
                    );
                  }).toList(),
                  const SizedBox(height: 10),
                  Text(
                    "Total: Kz ${total.toStringAsFixed(2)}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Cancelar"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop("OK");
                  },
                  child: const Text("OK"),
                ),
              ],
            );
          },
        ).then((result) async {
          if (result == "OK" && total >= 1500) {
            // Gera uma fatura se o total for maior ou igual a 1500 Kz
            await _generateInvoice(cartData);
          }
        });
      }
    } catch (e) {
      print("Erro ao finalizar a venda: $e");
    }
  }
  Future<void> _generateInvoice(Map<String, dynamic> cartData) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("Erro: Usuário não autenticado!");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro: Usuário não autenticado!")),
        );
        return;
      }

      print("Tentando criar fatura para o UID do usuário: ${user.uid}");

      await _firestore.collection('Users').doc(user.uid).collection('Invoices').add({
        'products': cartData['products'],
        'total': cartData['total'],
        'timestamp': FieldValue.serverTimestamp(),
      });

      print("Fatura criada com sucesso!");

      // Limpa o carrinho após gerar a fatura
      DocumentReference cartRef = _firestore
          .collection('Users')
          .doc(user.uid)
          .collection('carts')
          .doc(cartId);

      await cartRef.set({'products': [], 'total': 0.0});
      print("Carrinho limpo com sucesso!");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fatura gerada com sucesso!")),
      );
      setState(() {});
    } catch (e) {
      print("Erro ao gerar a fatura: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao gerar a fatura: $e")),
      );
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ponto de Venda")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFF07063a),
                borderRadius: BorderRadius.circular(12),
              ),
              child: StreamBuilder<DocumentSnapshot>(
                stream: _firestore
                    .collection('Users')
                    .doc(user?.uid)
                    .collection('carts')
                    .doc(cartId)
                    .snapshots(),
                builder: (context, snapshot) {
                  double total = 0.0;
                  if (snapshot.hasData && snapshot.data!.exists) {
                    Map<String, dynamic> cartData = snapshot.data!.data() as Map<String, dynamic>;
                    total = cartData['total'];
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total: Kz ${total.toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Carrinho:",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      const SizedBox(height: 10),
                      DropdownButton<String>(
                        value: selectedPaymentMethod,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedPaymentMethod = newValue!;
                          });
                        },
                        items: <String>["Dinheiro", "Cartão", "Transferência"]
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: _firestore
                  .collection('Users')
                  .doc(user?.uid)
                  .collection('carts')
                  .doc(cartId)
                  .snapshots(),
              builder: (context, snapshot) {
                List<dynamic> products = [];
                if (snapshot.hasData && snapshot.data!.exists) {
                  Map<String, dynamic> cartData = snapshot.data!.data() as Map<String, dynamic>;
                  products = cartData['products'];
                }

                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ListTile(
                      title: Text(product['name']),
                      subtitle: Text("Quantidade: ${product['quantity']}"),
                      trailing: Text("Preço: Kz ${product['price'].toStringAsFixed(2)}"),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                FloatingActionButton(
                  heroTag: "barcodeScanner", // Tag única para este botão
                  onPressed: _startBarcodeScanner,
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.qr_code_scanner),
                  tooltip: "Escanear Código de Barras",
                ),
                FloatingActionButton(
                  heroTag: "manualAddition", // Tag única para este botão
                  onPressed: () async {
                    QuerySnapshot querySnapshot = await _firestore
                        .collection('Users')
                        .doc(user?.uid)
                        .collection('ProductWithoutBarcode')
                        .get();

                    if (querySnapshot.docs.isNotEmpty) {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text("Adicionar Produtos Sem Código"),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: querySnapshot.docs.map((doc) {
                                final productData =
                                doc.data() as Map<String, dynamic>;
                                return ListTile(
                                  title: Text(productData['name']),
                                  subtitle: Text("Preço: Kz ${productData['price']}"),
                                  trailing: ElevatedButton(
                                    onPressed: () {
                                      _addProductToCart(doc.id, isBarcode: false);
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text("Adicionar"),
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Nenhum produto encontrado!")),
                      );
                    }
                  },
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.add),
                  tooltip: "Adicionar Produtos Manualmente",
                ),
                FloatingActionButton(
                  heroTag: "finalizeSale", // Tag única para este botão
                  onPressed: _finalizeSale,
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.check),
                  tooltip: "Finalizar Venda",
                ),


              ],
            ),
          ),
        ],
      ),
    );
  }
}
