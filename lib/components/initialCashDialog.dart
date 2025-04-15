import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
class InitialCashDialog {
  static Future<void> show(BuildContext context) async {
    print("🔹 Verificando se o pop-up deve ser exibido...");

    SharedPreferences prefs = await SharedPreferences.getInstance();
    FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    User? user = auth.currentUser;

    if (user == null) {
      print("❌ Nenhum usuário logado. Pop-up não será exibido.");
      return;
    }

    String today = DateTime.now().toString().split(' ')[0];
    String? lastRecordedDate = prefs.getString('last_cash_record_date');

    if (lastRecordedDate == today) {
      print("✅ Caixa já registrado hoje. Pop-up não será exibido.");
      return;
    }

    TextEditingController cashController = TextEditingController();
    print("⚡ Exibindo pop-up para registrar caixa inicial.");

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Registrar Caixa Inicial"),
          content: TextField(
            controller: cashController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Valor Inicial (Kz)"),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (cashController.text.isEmpty) return;

                double initialCash = double.tryParse(cashController.text) ?? 0.0;
                if (initialCash <= 0) return;

                try {
                  print("💾 Salvando no Firestore...");
                  await firestore
                      .collection('Users')
                      .doc(user.uid)
                      .collection('cash_register')
                      .doc(today)
                      .set({
                    'date': today,
                    'initial_cash': initialCash,
                    'timestamp': FieldValue.serverTimestamp(),
                  });

                  print("🔒 Atualizando SharedPreferences...");
                  await prefs.setString('last_cash_record_date', today);
                  await prefs.setDouble('initial_cash_value', initialCash);

                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  print("❌ Erro ao salvar no Firestore: $e");
                }
              },
              child: const Text("Salvar"),
            ),
          ],
        );
      },
    );
  }
}
