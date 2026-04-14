// lib/core/constants/app_constants.dart
class AppConstants {
  static const String appName = 'Hitech';
  static const String baseUrl = 'https://keerainnovations.com/erpbackend/api';
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String roleKey = 'user_role';
  static const String permissionsKey = 'auth_permissions';
  
  // Routes
  static const String splashRoute = '/';
  static const String loginRoute = '/login';
  static const String dashboardRoute = '/dashboard';
  static const String bookingsRoute = '/bookings';
  static const String tripsRoute = '/trips';
  static const String vehiclesRoute = '/vehicles';
  static const String masterRoute = '/master';
  static const String maintenanceRoute = '/maintenance';
  static const String fuelRoute = '/fuel';
  static const String alertsRoute = '/alerts';
  static const String reportsRoute = '/reports';
  static const String profileRoute = '/profile';
  static const String serviceHistoryRoute = '/service-history';
  
  // User Roles
  static const String adminRole = 'ADMIN';
  static const String teamLeadRole = 'TEAM_LEAD';
  static const String travellerRole = 'TRAVELLER';
  static const String driverRole = 'DRIVER';
  
  // Booking Status
  static const String bookingOpen = 'OPEN';
  static const String bookingBooked = 'BOOKED';
  static const String bookingInProgress = 'IN_PROGRESS';
  static const String bookingCompleted = 'COMPLETED';
  static const String bookingCancelled = 'CANCELLED';
  
  // Vehicle Status
  static const String vehicleActive = 'ACTIVE';
  static const String vehicleInactive = 'INACTIVE';
  static const String vehicleMaintenance = 'MAINTENANCE';
  static const String vehicleResale = 'RESALE';
  static const String vehicleTheft = 'THEFT';
  static const String vehicleScrap = 'SCRAP';
  
  // Trip Status
  static const String tripPending = 'PENDING';
  static const String tripInProgress = 'IN_PROGRESS';
  static const String tripCompleted = 'COMPLETED';
  static const String tripCancelled = 'CANCELLED';
  
  // Alert Priorities
  static const String alertNormal = 'NORMAL';
  static const String alertPriority = 'PRIORITY';
  static const String alertRisk = 'RISK';
  
  // Fuel Types
  static const String fuelPetrol = 'PETROL';
  static const String fuelDiesel = 'DIESEL';
  static const String fuelCng = 'CNG';
  
  // Service History Status
  static const String servicePending = 'PENDING';
  static const String serviceInProgress = 'IN_PROGRESS';
  static const String serviceCompleted = 'COMPLETED';
  static const String serviceCancelled = 'CANCELLED';
}
