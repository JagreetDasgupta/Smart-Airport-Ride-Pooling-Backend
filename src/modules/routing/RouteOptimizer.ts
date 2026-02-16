import { RideRequest } from '@prisma/client'
import { GeoPoint, OptimizedRoute } from '../../shared/types'

export class RouteOptimizer {
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

  public optimizeRoute(requests: RideRequest[], airportLocation: GeoPoint): OptimizedRoute {
    const pickups = requests.map((r) => ({
      id: r.id,
      location: r.pickupLocation as unknown as GeoPoint
    }))

    if (pickups.length === 0) {
      return {
        waypointOrder: [],
        totalDistance: 0,
        estimatedDuration: 0,
        detourAnalysis: {}
      }
    }

    let bestOrder = pickups
    let minDistance = Infinity

    if (pickups.length <= 6) {
      const permutations = this.permute(pickups)
      for (const perm of permutations) {
        const dist = this.calculateRouteDistance(perm, airportLocation)
        if (dist < minDistance) {
          minDistance = dist
          bestOrder = perm
        }
      }
    } else {
      bestOrder = pickups.sort(
        (a, b) =>
          this.calculateDistance(b.location, airportLocation) - this.calculateDistance(a.location, airportLocation)
      )
      minDistance = this.calculateRouteDistance(bestOrder, airportLocation)
    }

    const detourAnalysis: Record<string, number> = {}
    for (const request of requests) {
      const directDist = this.calculateDistance(request.pickupLocation as unknown as GeoPoint, airportLocation)
      const pickupIndex = bestOrder.findIndex((p) => p.id === request.id)
      let actualDist = 0
      for (let i = pickupIndex; i < bestOrder.length - 1; i++) {
        actualDist += this.calculateDistance(bestOrder[i].location, bestOrder[i + 1].location)
      }
      actualDist += this.calculateDistance(bestOrder[bestOrder.length - 1].location, airportLocation)
      const detour = directDist > 0 ? ((actualDist - directDist) / directDist) * 100 : 0
      detourAnalysis[request.id] = detour
    }

    return {
      waypointOrder: [...bestOrder.map((p) => p.location), airportLocation],
      totalDistance: minDistance,
      estimatedDuration: minDistance * 2,
      detourAnalysis
    }
  }

  private calculateRouteDistance(points: { id: string; location: GeoPoint }[], end: GeoPoint): number {
    let dist = 0
    for (let i = 0; i < points.length - 1; i++) {
      dist += this.calculateDistance(points[i].location, points[i + 1].location)
    }
    if (points.length > 0) {
      dist += this.calculateDistance(points[points.length - 1].location, end)
    }
    return dist
  }

  private permute<T>(permutation: T[]): T[][] {
    const length = permutation.length
    const result = [permutation.slice()]
    const c = new Array(length).fill(0)
    let i = 1
    let k
    let p
    while (i < length) {
      if (c[i] < i) {
        k = i % 2 && c[i]
        p = permutation[i]
        permutation[i] = permutation[k]
        permutation[k] = p
        ++c[i]
        i = 1
        result.push(permutation.slice())
      } else {
        c[i] = 0
        ++i
      }
    }
    return result
  }
}
