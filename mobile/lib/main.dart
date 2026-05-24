import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mesclainvest/app/app.dart';
import 'package:mesclainvest/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Carrega as variáveis de ambiente ANTES de iniciar os serviços
  await dotenv.load(fileName: ".env");
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MesclaInvestApp());
}
