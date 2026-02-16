import { Passenger, RideRequest, PassengerGroup, Route, Cab, CabAssignment, Cancellation } from '@prisma/client'

export type GeoPoint = {
  lat: number
  lng: number
}

export interface MatchingConstraints {
  maxPassengers: number
  maxLuggage: number
  timeWindowOverlap: number
  maxDetourTolerance: number
  pickupProximity: number
}

export interface RouteSegment {
  from: GeoPoint
  to: GeoPoint
  distance: number
  duration: number
}

export interface OptimizedRoute {
  waypointOrder: GeoPoint[]
  totalDistance: number
  estimatedDuration: number
  detourAnalysis: Record<string, number>
}

export interface PriceBreakdown {
  total: number
  perPassenger: Record<string, number>
  currency: string
}

export interface GroupCandidate {
  requestId: string
  compatibilityScore: number
}
