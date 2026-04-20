class FuelEntry {
  final String? id;
  final String vehicleId;
  final String vehicleNumber;
  final String fuelType;
  final double km;
  final double price;
  final String unit;
  final DateTime? createdAt;
  final String? remarks;
  final String? billUrl;
  final String? addedBy;

  FuelEntry({
    this.id,
    required this.vehicleId,
    required this.vehicleNumber,
    required this.fuelType,
    required this.km,
    required this.price,
    this.unit = 'litre',
    this.createdAt,
    this.remarks,
    this.billUrl,
    this.addedBy,
  });

  factory FuelEntry.fromJson(Map<String, dynamic> json) {
    // Handle fuel_type which comes as List<String> from API
    String fuelTypeString = '';

    if (json['fuel_type'] != null) {
      if (json['fuel_type'] is List) {
        final fuelList = (json['fuel_type'] as List).cast<dynamic>();
        if (fuelList.isNotEmpty) {
          fuelTypeString = fuelList.first.toString();
        }
      } else {
        fuelTypeString = json['fuel_type'].toString();
      }
    } else if (json['fuelType'] != null) {
      fuelTypeString = json['fuelType'].toString();
    }

    double parsePrice() {
      try {
        if (json['price'] == null) return 0.0;
        if (json['price'] is int) return (json['price'] as int).toDouble();
        if (json['price'] is double) return json['price'];
        final parsed = double.tryParse(json['price'].toString());
        return parsed ?? 0.0;
      } catch (e) {
        return 0.0;
      }
    }

    double parseKm() {
      try {
        if (json['km'] == null) return 0.0;
        if (json['km'] is int) return (json['km'] as int).toDouble();
        if (json['km'] is double) return json['km'];
        final parsed = double.tryParse(json['km'].toString());
        return parsed ?? 0.0;
      } catch (e) {
        return 0.0;
      }
    }

    DateTime? parseDate() {
      try {
        if (json['created_at'] != null) {
          return DateTime.parse(json['created_at'].toString());
        }
        if (json['createdAt'] != null) {
          return DateTime.parse(json['createdAt'].toString());
        }
        return null;
      } catch (e) {
        return null;
      }
    }

    return FuelEntry(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      vehicleId:
          json['vehicle_id']?.toString() ?? json['vehicleId']?.toString() ?? '',
      vehicleNumber: json['vehicle_number']?.toString() ??
          json['vehicleNumber']?.toString() ??
          '',
      fuelType: fuelTypeString.isNotEmpty ? fuelTypeString : 'Diesel',
      km: parseKm(),
      price: parsePrice(),
      unit: json['unit']?.toString() ?? 'litre',
      createdAt: parseDate(),
      remarks: json['remarks']?.toString(),
      billUrl: json['bill_url']?.toString() ?? json['billUrl']?.toString(),
      addedBy: json['added_by']?.toString() ?? json['addedBy']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicle_id': vehicleId,
      'vehicle_number': vehicleNumber,
      'fuel_type': fuelType,
      'km': km,
      'price': price,
      'unit': unit,
      'remarks': remarks,
      if (billUrl != null) 'bill_url': billUrl,
    };
  }

  // Convert to form-data format (all values as strings)
  Map<String, String> toFormData() {
    final formData = {
      'vehicle_id': vehicleId,
      'vehicle_number': vehicleNumber,
      'fuel_type': fuelType,
      'km': km.toString(),
      'price': price.toString(),
      'unit': unit,
    };

    if (remarks?.isNotEmpty == true) {
      formData['remarks'] = remarks!;
    }

    if (addedBy?.isNotEmpty == true) {
      formData['added_by'] = addedBy!;
    }

    return formData;
  }
}

class Vehicle {
  final String vehicleId;
  final String vehicleNumber;
  final String vehicleType;
  final String bookingColorCode;
  final List<String> fuelType;
  final String? unit;

  Vehicle({
    required this.vehicleId,
    required this.vehicleNumber,
    required this.vehicleType,
    required this.bookingColorCode,
    required this.fuelType,
    this.unit,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      vehicleId: json['vehicle_id']?.toString() ?? 
                 json['_id']?.toString() ?? 
                 json['id']?.toString() ?? '',
      vehicleNumber: json['vehicle_number']?.toString() ?? '',
      vehicleType: json['vehicle_type']?.toString() ?? '',
      bookingColorCode: json['booking_color_code']?.toString() ?? '',
      fuelType: (json['fuel_type'] is List)
          ? (json['fuel_type'] as List).map((e) => e.toString()).toList()
          : (json['fuel_type'] != null ? [json['fuel_type'].toString()] : []),
      unit: json['unit']?.toString() ?? json['fuel_unit']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicle_id': vehicleId,
      'vehicle_number': vehicleNumber,
      'vehicle_type': vehicleType,
      'booking_color_code': bookingColorCode,
      'fuel_type': fuelType,
      if (unit != null) 'unit': unit,
    };
  }
}
