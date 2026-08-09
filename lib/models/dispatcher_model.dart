class DispatcherModel {
  final String uid;
  final String dispatcherId;
  final String name;
  final String phone;

  DispatcherModel({
    required this.uid,
    required this.dispatcherId,
    required this.name,
    required this.phone,
  });

  factory DispatcherModel.fromMap(Map<String, dynamic> data, String id) {
    return DispatcherModel(
      uid: id,
      dispatcherId: data['dispatcherId'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dispatcherId': dispatcherId,
      'name': name,
      'phone': phone,
    };
  }
}