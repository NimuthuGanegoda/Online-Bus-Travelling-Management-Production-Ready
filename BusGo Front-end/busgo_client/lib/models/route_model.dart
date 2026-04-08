import 'package:flutter/material.dart';

class BusRoute {
  final String routeNumber;
  final String from;
  final String to;
  final int stopCount;
  final int durationMinutes;
  final int etaMinutes;
  final Color routeColor;

  const BusRoute({
    required this.routeNumber,
    required this.from,
    required this.to,
    required this.stopCount,
    required this.durationMinutes,
    required this.etaMinutes,
    required this.routeColor,
  });

  String get displayRoute => '$from → $to';
  String get info => '$stopCount stops · ~$durationMinutes min';
}
