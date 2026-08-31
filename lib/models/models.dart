enum LoadState { loading, success, error }

class Client {
  final int id;
  String title, body;
  Client({required this.id, required this.title, required this.body});
  factory Client.fromJson(Map<String, dynamic> j) => Client(id: j['id'], title: j['title'] ?? '', body: j['body'] ?? '');
}

class CartItem {
  final String name;
  final int price;
  int quantity;
  CartItem({required this.name, required this.price, this.quantity = 1});
}

class TeamTask {
  final int id;
  final String title;
  bool completed;
  TeamTask({required this.id, required this.title, required this.completed});
}

class Product {
  final String name;
  final String category;
  final String price;
  const Product(this.name, this.category, this.price);
}

class City {
  final String name;
  final double lat, lon;
  const City(this.name, this.lat, this.lon);
}

const cities = [
  City('Lahore', 31.55, 74.34),
  City('Karachi', 24.86, 67.01),
  City('Islamabad', 33.68, 73.05),
  City('Sahiwal', 30.66, 73.10),
  City('Dubai', 25.20, 55.27),
  City('London', 51.51, -0.13),
];

class WeatherResult {
  final double temp, wind;
  final String condition;
  WeatherResult(this.temp, this.wind, this.condition);
}

String weatherLabel(int code) {
  if (code == 0) return 'Clear sky';
  if (code <= 3) return 'Partly cloudy';
  if (code <= 48) return 'Fog';
  if (code <= 55) return 'Drizzle';
  if (code <= 65) return 'Rain';
  if (code <= 75) return 'Snow';
  if (code <= 82) return 'Rain showers';
  return 'Thunderstorm';
}

// The API's /todos endpoint returns placeholder Latin-style filler text
// for titles — meaningless test data, not a real language. The id and
// completed status are still the real values from the server; only the
// display title is swapped for a realistic business task name.
const realisticTaskTitles = [
  'Confirm supplier invoice — Metro Textiles',
  'Follow up with Al-Noor Traders',
  'Review Q3 inventory report',
  'Prepare client onboarding docs',
  'Approve staff leave requests',
  'Update product pricing sheet',
  'Schedule vendor site visit',
  'Reconcile monthly expenses',
  'Send payment reminder — invoice #2291',
  'Renew business insurance',
];

const shopProducts = [
  ('Fabric Roll', 1200),
  ('Office Chair', 8500),
  ('Printer Ink', 950),
  ('Notebook Pack', 450),
];
