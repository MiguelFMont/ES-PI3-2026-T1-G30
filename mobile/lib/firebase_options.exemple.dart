// firebase_options.example.dart
//
// IMPORTANTE: Este é um arquivo de exemplo com os campos em branco.
// NÃO commite o arquivo firebase_options.dart real — ele está no .gitignore.
//
// Para gerar o seu firebase_options.dart:
//   1. Instale o FlutterFire CLI: dart pub global activate flutterfire_cli
//   2. Rode: flutterfire configure
//   3. Selecione o projeto MesclaInvest e a plataforma Android

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'SEU_API_KEY_AQUI',
    appId: 'SEU_APP_ID_AQUI',
    messagingSenderId: 'SEU_MESSAGING_SENDER_ID_AQUI',
    projectId: 'SEU_PROJECT_ID_AQUI',
    storageBucket: 'SEU_PROJECT_ID_AQUI.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'SEU_API_KEY_IOS_AQUI',
    appId: 'SEU_APP_ID_IOS_AQUI',
    messagingSenderId: 'SEU_MESSAGING_SENDER_ID_AQUI',
    projectId: 'SEU_PROJECT_ID_AQUI',
    storageBucket: 'SEU_PROJECT_ID_AQUI.firebasestorage.app',
    iosBundleId: 'com.example.mobile',
  );
}