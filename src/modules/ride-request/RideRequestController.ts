import { Request, Response } from 'express'
import { RideRequestService } from './RideRequestService'
import { z, ZodError } from 'zod'

const createRequestSchema = z.object({
  passengerId: z.string().min(1),
  pickupLocation: z.object({
    lat: z.number(),
    lng: z.number()
  }),
  departureTime: z.string().datetime(),
  seatRequirement: z.number().int().min(1).max(4),
  luggageAmount: z.number().int().min(0).max(4),
  maxDetourTolerance: z.number().int().min(0).max(100)
})

export class RideRequestController {
  private service: RideRequestService

  constructor() {
    this.service = new RideRequestService()
  }

  create = async (req: Request, res: Response) => {
    try {
      const data = createRequestSchema.parse(req.body)
      const request = await this.service.createRequest(data)
      return res.status(201).json(request)
    } catch (error) {
      if (error instanceof ZodError) {
        return res.status(400).json({
          message: 'Validation failed',
          errors: error.issues
        })
      }
      return res.status(500).json({ message: 'Internal Server Error' })
    }
  }

  findGroup = async (req: Request, res: Response) => {
    try {
      const id = req.params.id as string
      const group = await this.service.findGroup(id)
      if (group) {
        return res.status(200).json(group)
      } else {
        return res.status(404).json({ message: 'No suitable group found yet' })
      }
    } catch (error: any) {
      return res.status(400).json({ error: error.message })
    }
  }

  cancel = async (req: Request, res: Response) => {
    try {
      const id = req.params.id as string
      const updatedRequest = await this.service.cancelRequest(id)
      return res.status(200).json(updatedRequest)
    } catch (error: any) {
      return res.status(400).json({ error: error.message })
    }
  }
}
