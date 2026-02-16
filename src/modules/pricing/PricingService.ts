import { Route, PassengerGroup } from '@prisma/client'
import { PriceBreakdown } from '../../shared/types'

export class PricingService {
  private BASE_FARE = 5
  private PER_KM_RATE = 1.5
  private PER_MIN_RATE = 0.5

  calculatePrice(route: Route, group: PassengerGroup, demandFactor: number = 1): PriceBreakdown {
    const distancePrice = route.totalDistance * this.PER_KM_RATE
    const timePrice = route.estimatedDuration * this.PER_MIN_RATE
    const basePrice = this.BASE_FARE + distancePrice + timePrice
    const soloFare = basePrice * demandFactor
    const passengerCount = group.totalPassengers
    const discount = this.getPoolingDiscount(passengerCount)
    const perPassengerFare = soloFare * (1 - discount)
    const totalFare = perPassengerFare * passengerCount
    return {
      total: totalFare,
      perPassenger: {},
      currency: 'USD'
    }
  }

  private getPoolingDiscount(count: number): number {
    if (count < 2) return 0
    if (count === 2) return 0.2
    if (count === 3) return 0.3
    return 0.4
  }
}
