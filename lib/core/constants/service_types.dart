class ServiceTypes {
  static const String washAndIron = 'Wash & Iron';
  static const String dryClean = 'Dry Clean';
  static const String ironOnly = 'Iron Only';
  static const String washOnly = 'Wash Only';
  
  static const Map<String, double> defaultPrices = {
    washAndIron: 50.0,
    dryClean: 150.0,
    ironOnly: 30.0,
    washOnly: 40.0,
  };
}