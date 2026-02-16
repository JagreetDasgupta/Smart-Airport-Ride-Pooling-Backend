import { Request, Response } from 'express'
import { PricingService } from '../modules/pricing/PricingService'

export class PricingController {
  private engine: PricingService

  constructor() {
    this.engine = new PricingService()
  }

  calculate = (req: Request, res: Response) => {
    const { distance, duration, passengers, demand } = req.body
    const route = { totalDistance: distance ?? 10, estimatedDuration: duration ?? 20 } as any
    const group = { totalPassengers: passengers ?? 1 } as any
    const price = this.engine.calculatePrice(route, group, demand ?? 1.0)
    res.json(price)
  }
}
