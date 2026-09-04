import '../models/geo_zone.dart';

const defaultGeoZones = <GeoZone>[
  GeoZone(id: 'haram', name: 'Masjid al-Haram', latitude: 21.4225, longitude: 39.8262, enterRadiusMeters: 1200, exitRadiusMeters: 1500, message: 'You are approaching the Haram. Follow your current ritual guidance.'),
  GeoZone(id: 'mina', name: 'Mina', latitude: 21.4133, longitude: 39.8938, enterRadiusMeters: 1200, exitRadiusMeters: 1500, message: 'You are in Mina. Check today’s Hajj steps and Ramy guidance.'),
  GeoZone(id: 'arafat', name: 'Arafat', latitude: 21.3549, longitude: 39.9841, enterRadiusMeters: 1500, exitRadiusMeters: 1800, message: 'You are in Arafat. Review the Arafah standing guidance.'),
  GeoZone(id: 'muzdalifah', name: 'Muzdalifah', latitude: 21.3891, longitude: 39.9412, enterRadiusMeters: 1200, exitRadiusMeters: 1500, message: 'You are in Muzdalifah. Review the applicable Hajj steps.'),
];
