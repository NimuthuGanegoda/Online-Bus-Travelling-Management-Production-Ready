class StopModel {
  final String stopId;
  final String name;
  final double distance;
  final List<String> routes;

  const StopModel({
    required this.stopId,
    required this.name,
    required this.distance,
    required this.routes,
  });

  String get distanceDisplay => '$distance km';
  String get routesDisplay => 'Routes: ${routes.join(', ')}';
  String get info => '$distanceDisplay · $routesDisplay';
}
