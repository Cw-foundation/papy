import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Product/POSScreen.dart';
import 'cashier_auth/RegisterCashierScreen.dart';
import '../components/initialCashDialog.dart';
import 'profile/invoice.dart';

class HomeScreen extends StatefulWidget {
  final String userId;

  const HomeScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double totalVendas = 0.00;
  bool isHidden = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkInitialCash());
  }

  Future<void> _checkInitialCash() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String cashKey = "initial_cash_value_${widget.userId}";

    if (!prefs.containsKey(cashKey)) {
      _showInitialCashDialog();
    } else {
      _loadInitialCash();
    }
  }

  Future<void> _loadInitialCash() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String cashKey = "initial_cash_value_${widget.userId}";
    double initialCash = prefs.getDouble(cashKey) ?? 0.0;

    setState(() {
      totalVendas = initialCash;
    });
  }

  Future<void> _showInitialCashDialog() async {
    TextEditingController controller = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Dinheiro no Caixa"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Com quanto dinheiro estás a começar a venda?"),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Digite o valor inicial",
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  double initialCash = double.tryParse(controller.text) ?? 0.0;
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  String cashKey = "initial_cash_value_${widget.userId}";
                  await prefs.setDouble(cashKey, initialCash);

                  setState(() {
                    totalVendas = initialCash;
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text("Confirmar"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tela Inicial"),
        centerTitle: true,
        backgroundColor: const Color(0xFF07063a),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSalesCard(),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton("Criar Cashier", Icons.person_add_alt, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddCashierScreen()),
                  );
                }),
                _buildActionButton("Faturas", Icons.receipt_rounded, () {
            Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => InvoiceScreen()),
                  );
                }),

                _buildActionButton("POS", Icons.shopping_bag_rounded, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const POSScreen()),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesCard() {
    return Card(
      color: const Color(0xFF07063a),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "VALOR FACTURADO",
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isHidden ? "*********" : "Kz ${totalVendas.toStringAsFixed(2)}",
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    isHidden ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      isHidden = !isHidden;
                    });
                  },
                ),
                ElevatedButton(
                  onPressed: _loadInitialCash,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                  child: const Text(
                    "ATUALIZAR",
                    style: TextStyle(color: Color(0xFF07063a)),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                  child: const Text(
                    "FAZER FECHO",
                    style: TextStyle(color: Color(0xFF07063a)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF07063a),
            child: Icon(icon, size: 30, color: Colors.white),
          ),
          const SizedBox(height: 5),
          Text(title, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
