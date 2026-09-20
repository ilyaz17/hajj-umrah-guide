'use client'

import { useEffect, useState } from 'react'

export function useGeoLocation(options = {}) {
  const { enableHighAccuracy = true, timeout = 10000, maximumAge = 15000, watch = true } = options
  const [location, setLocation] = useState(null)
  const [error, setError] = useState(null)
  const [loading, setLoading] = useState(true)
  const [permission, setPermission] = useState('prompt')

  useEffect(() => {
    if (!navigator.geolocation) { setError(new Error('Geolocation is not supported by this browser.')); setLoading(false); return undefined }
    let watchId
    const onSuccess = ({ coords, timestamp }) => { setLocation({ latitude: coords.latitude, longitude: coords.longitude, accuracy: coords.accuracy, timestamp }); setLoading(false); setError(null) }
    const onError = (reason) => { setLoading(false); setError(new Error(reason.code === 1 ? 'Location permission was denied.' : reason.message || 'Unable to get your location.')) }
    if (navigator.permissions) navigator.permissions.query({ name: 'geolocation' }).then((result) => setPermission(result.state)).catch(() => {})
    const config = { enableHighAccuracy, timeout, maximumAge }
    if (watch) watchId = navigator.geolocation.watchPosition(onSuccess, onError, config)
    else navigator.geolocation.getCurrentPosition(onSuccess, onError, config)
    return () => { if (watchId !== undefined) navigator.geolocation.clearWatch(watchId) }
  }, [enableHighAccuracy, timeout, maximumAge, watch])

  return { location, error, loading, permission }
}

export function distanceInMeters(a, b) {
  if (!a || !b) return Infinity
  const earthRadius = 6371000
  const toRadians = (value) => value * Math.PI / 180
  const dLat = toRadians(b.latitude - a.latitude)
  const dLon = toRadians(b.longitude - a.longitude)
  const lat1 = toRadians(a.latitude); const lat2 = toRadians(b.latitude)
  const h = Math.sin(dLat / 2) ** 2 + Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLon / 2) ** 2
  return 2 * earthRadius * Math.asin(Math.sqrt(h))
}

export function isWithinRadius(location, target, radiusMeters) { return distanceInMeters(location, target) <= radiusMeters }
