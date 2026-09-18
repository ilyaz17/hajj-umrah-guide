'use client'

import { useState, useEffect, useCallback } from 'react'

/**
 * Custom hook for handling HTML5 Geolocation API
 * Provides real-time location tracking with configurable options
 * 
 * @param {Object} options - Geolocation options
 * @param {boolean} options.enableHighAccuracy - Use GPS if available
 * @param {number} options.timeout - Max time to wait for location (ms)
 * @param {number} options.maximumAge - Accept cached position this old (ms)
 * @param {boolean} options.watch - Continuously watch position changes
 * @returns {Object} Location state and controls
 */
export function useGeoLocation(options = {}) {
  const {
    enableHighAccuracy = true,
    timeout = 10000,
    maximumAge = 0,
    watch = true
  } = options

  const [location, setLocation] = useState(null)
  const [error, setError] = useState(null)
  const [loading, setLoading] = useState(true)
  const [permission, setPermission] = useState('prompt')

  // Check geolocation permission status
  useEffect(() => {
    if (!navigator.permissions) {
      setPermission('prompt')
      return
    }

    navigator.permissions.query({ name: 'geolocation' })
      .then(result => {
        setPermission(result.state)
        result.onchange = () => setPermission(result.state)
      })
      .catch(() => setPermission('prompt'))
  }, [])

  // Get current position
  const getCurrentPosition = useCallback(() => {
    if (!navigator.geolocation) {
      setError(new Error('Geolocation is not supported by your browser'))
      setLoading(false)
      return
    }

    setLoading(true)
    setError(null)

    navigator.geolocation.getCurrentPosition(
      (position) => {
        setLocation({
          latitude: position.coords.latitude,
          longitude: position.coords.longitude,
          accuracy: position.coords.accuracy,
          altitude: position.coords.altitude,
          heading: position.coords.heading,
          speed: position.coords.speed,
          timestamp: position.timestamp
        })
        setLoading(false)
      },
      (err) => {
        let errorMessage = 'Unable to get your location'
        
        switch (err.code) {
          case err.PERMISSION_DENIED:
            errorMessage = 'Location permission denied. Please enable location access in your browser settings.'
            break
          case err.POSITION_UNAVAILABLE:
            errorMessage = 'Location information unavailable'
            break
          case err.TIMEOUT:
            errorMessage = 'Location request timed out'
            break
          default:
            errorMessage = err.message || errorMessage
        }
        
        setError(new Error(errorMessage))
        setLoading(false)
      },
      {
        enableHighAccuracy,
        timeout,
        maximumAge
      }
    )
  }, [enableHighAccuracy, timeout, maximumAge])

  // Watch position changes
  useEffect(() => {
    if (!watch || !navigator.geolocation) return

    let watchId = null

    const startWatching = () => {
      watchId = navigator.geolocation.watchPosition(
        (position) => {
          setLocation({
            latitude: position.coords.latitude,
            longitude: position.coords.longitude,
            accuracy: position.coords.accuracy,
            altitude: position.coords.altitude,
            heading: position.coords.heading,
            speed: position.coords.speed,
            timestamp: position.timestamp
          })
          setLoading(false)
          setError(null)
        },
        (err) => {
          setError(err)
          setLoading(false)
        },
        {
          enableHighAccuracy,
          timeout,
          maximumAge
        }
      )
    }

    // Start watching after initial permission check
    if (permission === 'granted') {
      startWatching()
    } else if (permission === 'prompt') {
      // Wait for user to grant permission
      const timer = setTimeout(() => {
        if (permission !== 'denied') {
          startWatching()
        }
      }, 1000)
      return () => clearTimeout(timer)
    }

    // Cleanup watcher on unmount
    return () => {
      if (watchId !== null) {
        navigator.geolocation.clearWatch(watchId)
      }
    }
  }, [watch, enableHighAccuracy, timeout, maximumAge, permission])

  // Request permission manually
  const requestPermission = useCallback(async () => {
    if (!navigator.permissions) {
      getCurrentPosition()
      return
    }

    try {
      const result = await navigator.permissions.query({ name: 'geolocation' })
      setPermission(result.state)
      
      if (result.state === 'prompt') {
        // Trigger permission prompt by requesting location
        getCurrentPosition()
      }
    } catch (error) {
      console.error('Error requesting location permission:', error)
    }
  }, [getCurrentPosition])

  return {
    location,
    error,
    loading,
    permission,
    getCurrentPosition,
    requestPermission
  }
}

/**
 * Calculate distance between two coordinates using Haversine formula
 * Returns distance in meters
 * 
 * @param {number} lat1 - Latitude of point 1
 * @param {number} lon1 - Longitude of point 1
 * @param {number} lat2 - Latitude of point 2
 * @param {number} lon2 - Longitude of point 2
 * @returns {number} Distance in meters
 */
export function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371e3 // Earth's radius in meters
  const φ1 = lat1 * Math.PI / 180
  const φ2 = lat2 * Math.PI / 180
  const Δφ = (lat2 - lat1) * Math.PI / 180
  const Δλ = (lon2 - lon1) * Math.PI / 180

  const a = Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
          Math.cos(φ1) * Math.cos(φ2) *
          Math.sin(Δλ / 2) * Math.sin(Δλ / 2)
  
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

  return R * c
}

/**
 * Check if a coordinate is within a radius of a target location
 * 
 * @param {Object} current - Current location {latitude, longitude}
 * @param {Object} target - Target location {latitude, longitude}
 * @param {number} radiusMeters - Radius in meters
 * @returns {boolean} True if within radius
 */
export function isWithinRadius(current, target, radiusMeters) {
  if (!current || !target) return false
  
  const distance = calculateDistance(
    current.latitude,
    current.longitude,
    target.latitude,
    target.longitude
  )
  
  return distance <= radiusMeters
}

/**
 * Get bearing between two coordinates in degrees
 * 
 * @param {number} lat1 - Latitude of point 1
 * @param {number} lon1 - Longitude of point 1
 * @param {number} lat2 - Latitude of point 2
 * @param {number} lon2 - Longitude of point 2
 * @returns {number} Bearing in degrees (0-360)
 */
export function getBearing(lat1, lon1, lat2, lon2) {
  const φ1 = lat1 * Math.PI / 180
  const φ2 = lat2 * Math.PI / 180
  const Δλ = (lon2 - lon1) * Math.PI / 180

  const y = Math.sin(Δλ) * Math.cos(φ2)
  const x = Math.cos(φ1) * Math.sin(φ2) -
          Math.sin(φ1) * Math.cos(φ2) * Math.cos(Δλ)
  
  const θ = Math.atan2(y, x)
  const bearing = (θ * 180 / Math.PI + 360) % 360
  
  return bearing
}

/**
 * Get cardinal direction from bearing
 * 
 * @param {number} bearing - Bearing in degrees
 * @returns {string} Cardinal direction (N, NE, E, SE, S, SW, W, NW)
 */
export function getCardinalDirection(bearing) {
  const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW']
  const index = Math.round(bearing / 45) % 8
  return directions[index]
}
