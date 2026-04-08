import 'package:flutter/material.dart';
import '../core/utils/helpers.dart';

class BusModel {
  final String routeNumber;
  final String routeName;
  final String from;
  final String to;
  final String stopId;
  final String stopName;
  final double distance;
  final int etaMinutes;
  final CrowdLevel crowdLevel;
  final Color routeColor;
  final String driverName;
  final String driverId;
  final double driverRating;
  final int passengerCount;
  final int capacity;

  const BusModel({
    required this.routeNumber,
    required this.routeName,
    required this.from,
    required this.to,
    required this.stopId,
    required this.stopName,
    required this.distance,
    required this.etaMinutes,
    required this.crowdLevel,
    required this.routeColor,
    this.driverName = 'Kamal Perera',
    this.driverId = 'DRV-2841',
    this.driverRating = 4.2,
    this.passengerCount = 12,
    this.capacity = 40,
  });

  String get displayRoute => '$from → $to';
  String get stopInfo => 'Bus Stop $stopId · $distance km';
  String get passengerLoad => '$passengerCount/$capacity';
}
