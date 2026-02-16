import { Prisma, RideRequest, PassengerGroup, RequestStatus } from '@prisma/client'
import prisma from '../../config/prisma'
import { RouteOptimizer } from '../routing/RouteOptimizer'
import { GeoPoint } from '../../shared/types'
import { ConcurrencyManager } from '../../shared/ConcurrencyManager'

export class MatchingEngine {
  private routeOptimizer: RouteOptimizer
  private concurrencyManager: ConcurrencyManager

  constructor() {
    this.routeOptimizer = new RouteOptimizer()
    this.concurrencyManager = new ConcurrencyManager()
  }

  async findCompatiblePassengers(request: RideRequest): Promise<PassengerGroup | null> {
    const lockKey = 'matching:global'
    return await this.concurrencyManager.withLock(lockKey, 5000, async () => {
      const candidates = await this.findCandidates(request)
      let groupMembers = [request]
      let remainingCapacity = 4 - request.seatRequirement
      let remainingLuggage = 4 - request.luggageAmount
      for (const candidate of candidates) {
        if (remainingCapacity >= candidate.seatRequirement && remainingLuggage >= candidate.luggageAmount) {
          const newGroup = [...groupMembers, candidate]
          if (this.checkDetourConstraint(newGroup)) {
            groupMembers.push(candidate)
            remainingCapacity -= candidate.seatRequirement
            remainingLuggage -= candidate.luggageAmount
          }
        }
        if (remainingCapacity <= 0) break
      }
      if (groupMembers.length > 1) {
        const airportLocation: GeoPoint = { lat: 0, lng: 0 }
        const optimizedRoute = this.routeOptimizer.optimizeRoute(groupMembers, airportLocation)
        return await prisma.passengerGroup.create({
          data: {
            totalPassengers: groupMembers.reduce((sum, m) => sum + m.seatRequirement, 0),
            totalSeats: 4,
            totalLuggage: groupMembers.reduce((sum, m) => sum + m.luggageAmount, 0),
            status: 'FORMING',
            rideRequests: {
              connect: groupMembers.map((m) => ({ id: m.id }))
            },
            route: {
              create: {
                waypointOrder: optimizedRoute.waypointOrder as unknown as Prisma.InputJsonValue,
                totalDistance: optimizedRoute.totalDistance,
                estimatedDuration: optimizedRoute.estimatedDuration,
                detourAnalysis: optimizedRoute.detourAnalysis as unknown as Prisma.InputJsonValue
              }
            }
          },
          include: {
            rideRequests: true,
            route: true
          }
        })
      }
      return null
    })
  }

  private async findCandidates(request: RideRequest): Promise<RideRequest[]> {
    const allPending = await prisma.rideRequest.findMany({
      where: {
        status: RequestStatus.PENDING,
        id: { not: request.id },
        departureTime: {
          gte: new Date(request.departureTime.getTime() - 30 * 60000),
          lte: new Date(request.departureTime.getTime() + 30 * 60000)
        }
      }
    })
    const MAX_DISTANCE_KM = 5
    return allPending.filter((candidate: RideRequest) => {
      const dist = this.calculateDistance(
        request.pickupLocation as unknown as GeoPoint,
        candidate.pickupLocation as unknown as GeoPoint
      )
      return dist <= MAX_DISTANCE_KM
    })
  }

  private checkDetourConstraint(group: RideRequest[]): boolean {
    const airportLocation: GeoPoint = { lat: 0, lng: 0 }
    const route = this.routeOptimizer.optimizeRoute(group, airportLocation)
    for (const req of group) {
      const detour = route.detourAnalysis[req.id] || 0
      if (detour > req.maxDetourTolerance) {
        return false
      }
    }
    return true
  }

  private calculateDistance(p1: GeoPoint, p2: GeoPoint): number {
    const R = 6371
    const dLat = this.deg2rad(p2.lat - p1.lat)
    const dLon = this.deg2rad(p2.lng - p1.lng)
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(this.deg2rad(p1.lat)) * Math.cos(this.deg2rad(p2.lat)) * Math.sin(dLon / 2) * Math.sin(dLon / 2)
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
    return R * c
  }

  private deg2rad(deg: number): number {
    return deg * (Math.PI / 180)
  }
}
