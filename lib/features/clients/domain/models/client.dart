class Client {
  final String id;
  final String name;
  final String email;
  final String phone; // Keep phone as String
  final String status; // "New", "Won", "Lost", etc.

  Client({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.status,
  });

  // Convert client data to and from Firestore format
  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'] ?? 'Unknown',
      name: map['name'] ?? 'Unknown',
      email: map['email'] ?? 'unknown@example.com',
      phone: _parsePhone(map['phone']), // Ensure phone is parsed as String
      status: map['status'] ?? 'Unknown',
    );
  }

  // Helper function to safely parse the phone field into an integer
  static String _parsePhone(dynamic phone) {
    if (phone == null) {
      return '0'; // Return '0' if phone is null
    }

    if (phone is String) {
      return phone; // If phone is already a String, return it as-is
    }

    // If phone is an int, convert it to a String
    return phone.toString();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'status': status,
    };
  }
}
