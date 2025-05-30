import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import 'dart:io';

void main() async {
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Get reference to the database
  final database = FirebaseDatabase.instance;
  
  // Read initial_data.json
  final file = File('initial_data.json');
  final jsonString = await file.readAsString();
  final data = json.decode(jsonString);
  
  // Update services
  if (data['services'] != null) {
    await database.ref('services').set(data['services']);
    print('Services updated successfully');
  }
  
  // Update service types
  if (data['serviceTypes'] != null) {
    await database.ref('serviceTypes').set(data['serviceTypes']);
    print('Service types updated successfully');
  }
  
  // Update app settings
  if (data['app_settings'] != null) {
    await database.ref('app_settings').set(data['app_settings']);
    print('App settings updated successfully');
  }
  
  print('Database initialization complete');
  exit(0);
} 