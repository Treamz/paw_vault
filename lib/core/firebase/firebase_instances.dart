import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseInstances {
  FirebaseInstances({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    FirebaseAI? ai,
    FirebaseAnalytics? analytics,
  })  : auth = auth ?? FirebaseAuth.instance,
        firestore = firestore ?? FirebaseFirestore.instance,
        storage = storage ?? FirebaseStorage.instance,
        ai = ai ?? FirebaseAI.vertexAI(),
        analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;
  final FirebaseAI ai;
  final FirebaseAnalytics analytics;
}
