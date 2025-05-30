import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
  rescheduled,
}

enum TierType { basic, standard, premium }

enum SlotStatus { available, booked }

class TimeSlot {
  final String id;
  final DateTime date;
  final String time;
  final SlotStatus status;

  TimeSlot({
    required this.id,
    required this.date,
    required this.time,
    required this.status,
  });

  // Create a copy with modified fields
  TimeSlot copyWith({
    String? id,
    DateTime? date,
    String? time,
    SlotStatus? status,
  }) {
    return TimeSlot(
      id: id ?? this.id,
      date: date ?? this.date,
      time: time ?? this.time,
      status: status ?? this.status,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'time': time,
      'status': status.toString().split('.').last,
    };
  }

  // Create from JSON
  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    // Handle date in different formats
    DateTime parseDate(dynamic dateValue) {
      if (dateValue is Timestamp) {
        return dateValue.toDate();
      } else if (dateValue is String) {
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          debugPrint('Error parsing date string in TimeSlot: $e');
          return DateTime.now();
        }
      } else if (dateValue is DateTime) {
        return dateValue;
      } else {
        debugPrint('Unknown date format in TimeSlot: $dateValue');
        return DateTime.now();
      }
    }

    return TimeSlot(
      id: json['id'],
      date: parseDate(json['date']),
      time: json['time'],
      status: SlotStatus.values.firstWhere(
        (e) => e.toString() == 'SlotStatus.${json['status']}',
        orElse: () => SlotStatus.available,
      ),
    );
  }
}

class BookingModel {
  final String id;
  final String userId;
  final String serviceId;
  final String serviceName;
  final String serviceImage;
  final TierType tierSelected;
  final double area;
  final double totalPrice;
  final SavedAddress address;
  final TimeSlot timeSlot;
  final BookingStatus status;
  final DateTime createdAt;
  final String? materialDesignId;
  final String? materialDesignName;
  final double? materialPrice;
  final String? reviewId;
  final double? visitCharge;
  final bool serviceChargePaid;

  BookingModel({
    required this.id,
    required this.userId,
    required this.serviceId,
    required this.serviceName,
    required this.serviceImage,
    required this.tierSelected,
    required this.area,
    required this.totalPrice,
    required this.address,
    required this.timeSlot,
    required this.status,
    required this.createdAt,
    this.materialDesignId,
    this.materialDesignName,
    this.materialPrice,
    this.reviewId,
    this.visitCharge,
    this.serviceChargePaid = false,
  });

  // Create a copy with modified fields
  BookingModel copyWith({
    String? id,
    String? userId,
    String? serviceId,
    String? serviceName,
    String? serviceImage,
    TierType? tierSelected,
    double? area,
    double? totalPrice,
    SavedAddress? address,
    TimeSlot? timeSlot,
    BookingStatus? status,
    DateTime? createdAt,
    String? materialDesignId,
    String? materialDesignName,
    double? materialPrice,
    String? reviewId,
    double? visitCharge,
    bool? serviceChargePaid,
  }) {
    return BookingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      serviceImage: serviceImage ?? this.serviceImage,
      tierSelected: tierSelected ?? this.tierSelected,
      area: area ?? this.area,
      totalPrice: totalPrice ?? this.totalPrice,
      address: address ?? this.address,
      timeSlot: timeSlot ?? this.timeSlot,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      materialDesignId: materialDesignId ?? this.materialDesignId,
      materialDesignName: materialDesignName ?? this.materialDesignName,
      materialPrice: materialPrice ?? this.materialPrice,
      reviewId: reviewId ?? this.reviewId,
      visitCharge: visitCharge ?? this.visitCharge,
      serviceChargePaid: serviceChargePaid ?? this.serviceChargePaid,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'serviceImage': serviceImage,
      'tierSelected': tierSelected.toString().split('.').last,
      'area': area,
      'totalPrice': totalPrice,
      'address': address.toJson(),
      'timeSlot': timeSlot.toJson(),
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'materialDesignId': materialDesignId,
      'materialDesignName': materialDesignName,
      'materialPrice': materialPrice,
      'reviewId': reviewId,
      'visitCharge': visitCharge,
      'serviceChargePaid': serviceChargePaid,
    };
  }

  // Create from JSON
  factory BookingModel.fromJson(Map<String, dynamic> json) {
    // Handle date in different formats
    DateTime parseDate(dynamic dateValue) {
      if (dateValue is Timestamp) {
        return dateValue.toDate();
      } else if (dateValue is String) {
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          debugPrint('Error parsing date string in BookingModel: $e');
          return DateTime.now();
        }
      } else if (dateValue is DateTime) {
        return dateValue;
      } else {
        debugPrint('Unknown date format in BookingModel: $dateValue');
        return DateTime.now();
      }
    }

    return BookingModel(
      id: json['id'],
      userId: json['userId'],
      serviceId: json['serviceId'],
      serviceName: json['serviceName'],
      serviceImage: json['serviceImage'],
      tierSelected: TierType.values.firstWhere(
        (e) => e.toString() == 'TierType.${json['tierSelected']}',
        orElse: () => TierType.basic,
      ),
      area: json['area'].toDouble(),
      totalPrice: json['totalPrice'].toDouble(),
      address: SavedAddress.fromJson(json['address']),
      timeSlot: TimeSlot.fromJson(json['timeSlot']),
      status: BookingStatus.values.firstWhere(
        (e) => e.toString() == 'BookingStatus.${json['status']}',
        orElse: () => BookingStatus.pending,
      ),
      createdAt: parseDate(json['createdAt']),
      materialDesignId: json['materialDesignId'],
      materialDesignName: json['materialDesignName'],
      materialPrice:
          json['materialPrice'] != null
              ? json['materialPrice'].toDouble()
              : null,
      reviewId: json['reviewId'],
      visitCharge:
          json['visitCharge'] != null ? json['visitCharge'].toDouble() : null,
      serviceChargePaid: json['serviceChargePaid'] ?? false,
    );
  }

  // Added serialization methods
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'serviceImage': serviceImage,
      'tierSelected': tierSelected.toString(),
      'area': area,
      'totalPrice': totalPrice,
      'status': status.toString(),
      'address': {
        'id': address.id,
        'label': address.label,
        'address': address.address,
        'latitude': address.latitude,
        'longitude': address.longitude,
      },
      'timeSlot': {
        'id': timeSlot.id,
        'date': timeSlot.date.millisecondsSinceEpoch,
        'time': timeSlot.time,
        'status': timeSlot.status.toString(),
      },
      'createdAt': createdAt.millisecondsSinceEpoch,
      'materialDesignId': materialDesignId,
      'materialDesignName': materialDesignName,
      'materialPrice': materialPrice,
      'reviewId': reviewId,
      'visitCharge': visitCharge,
      'serviceChargePaid': serviceChargePaid,
    };
  }

  static BookingModel fromMap(Map<String, dynamic> map) {
    TierType getTierType(String value) {
      switch (value) {
        case 'TierType.basic':
          return TierType.basic;
        case 'TierType.standard':
          return TierType.standard;
        case 'TierType.premium':
          return TierType.premium;
        default:
          return TierType.basic;
      }
    }

    BookingStatus getBookingStatus(String value) {
      switch (value) {
        case 'BookingStatus.pending':
          return BookingStatus.pending;
        case 'BookingStatus.confirmed':
          return BookingStatus.confirmed;
        case 'BookingStatus.inProgress':
          return BookingStatus.inProgress;
        case 'BookingStatus.completed':
          return BookingStatus.completed;
        case 'BookingStatus.cancelled':
          return BookingStatus.cancelled;
        case 'BookingStatus.rescheduled':
          return BookingStatus.rescheduled;
        default:
          return BookingStatus.pending;
      }
    }

    SlotStatus getSlotStatus(String value) {
      switch (value) {
        case 'SlotStatus.available':
          return SlotStatus.available;
        case 'SlotStatus.booked':
          return SlotStatus.booked;
        default:
          return SlotStatus.available;
      }
    }

    // Handle date in different formats
    DateTime parseDate(dynamic dateValue) {
      if (dateValue is Timestamp) {
        return dateValue.toDate();
      } else if (dateValue is String) {
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          debugPrint('Error parsing date string in fromMap: $e');
          return DateTime.now();
        }
      } else if (dateValue is int) {
        // Handle milliseconds since epoch
        return DateTime.fromMillisecondsSinceEpoch(dateValue);
      } else if (dateValue is DateTime) {
        return dateValue;
      } else {
        debugPrint('Unknown date format in fromMap: $dateValue');
        return DateTime.now();
      }
    }

    final addressMap = map['address'] as Map<String, dynamic>;
    final timeSlotMap = map['timeSlot'] as Map<String, dynamic>;

    return BookingModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      serviceId: map['serviceId'] as String,
      serviceName: map['serviceName'] as String,
      serviceImage: map['serviceImage'] as String,
      tierSelected: getTierType(map['tierSelected'] as String),
      area: (map['area'] as num).toDouble(),
      totalPrice: (map['totalPrice'] as num).toDouble(),
      status: getBookingStatus(map['status'] as String),
      address: SavedAddress(
        id: addressMap['id'] as String,
        label: addressMap['label'] as String,
        address: addressMap['address'] as String,
        latitude: (addressMap['latitude'] as num).toDouble(),
        longitude: (addressMap['longitude'] as num).toDouble(),
      ),
      timeSlot: TimeSlot(
        id: timeSlotMap['id'] as String,
        date:
            timeSlotMap['date'] is int
                ? DateTime.fromMillisecondsSinceEpoch(
                  timeSlotMap['date'] as int,
                )
                : parseDate(timeSlotMap['date']),
        time: timeSlotMap['time'] as String,
        status: getSlotStatus(timeSlotMap['status'] as String),
      ),
      createdAt:
          map['createdAt'] is int
              ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
              : parseDate(map['createdAt']),
      materialDesignId: map['materialDesignId'] as String?,
      materialDesignName: map['materialDesignName'] as String?,
      materialPrice:
          map['materialPrice'] != null
              ? (map['materialPrice'] as num).toDouble()
              : null,
      reviewId: map['reviewId'] as String?,
      visitCharge:
          map['visitCharge'] != null
              ? (map['visitCharge'] as num).toDouble()
              : null,
      serviceChargePaid: map['serviceChargePaid'] as bool? ?? false,
    );
  }
}

class SavedAddress {
  final String id;
  final String label;
  final String address;
  final double latitude;
  final double longitude;

  SavedAddress({
    required this.id,
    required this.label,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  // Create a copy with modified fields
  SavedAddress copyWith({
    String? id,
    String? label,
    String? address,
    double? latitude,
    double? longitude,
  }) {
    return SavedAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  // Create from JSON
  factory SavedAddress.fromJson(Map<String, dynamic> json) {
    return SavedAddress(
      id: json['id'],
      label: json['label'],
      address: json['address'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
    );
  }
}

class ReviewModel {
  final String id;
  final String bookingId;
  final String userId;
  final String serviceId;
  final double rating;
  final String comment;
  final String userName;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.serviceId,
    required this.rating,
    required this.comment,
    required this.userName,
    required this.createdAt,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'userId': userId,
      'serviceId': serviceId,
      'rating': rating,
      'comment': comment,
      'userName': userName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from JSON
  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'],
      bookingId: json['bookingId'],
      userId: json['userId'],
      serviceId: json['serviceId'],
      rating: json['rating'].toDouble(),
      comment: json['comment'],
      userName: json['userName'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
