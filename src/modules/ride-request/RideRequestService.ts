import prisma from '../../config/prisma'
import { MatchingEngine } from '../matching/MatchingEngine'
import { Prisma, RideRequest, RequestStatus } from '@prisma/client'
import { GeoPoint } from '../../shared/types'

export class RideRequestService {
  private matchingEngine: MatchingEngine

  constructor() {
    this.matchingEngine = new MatchingEngine()
  }

  async createRequest(data: {
    passengerId: string
    pickupLocation: GeoPoint
    departureTime: string
    seatRequirement: number
    luggageAmount: number
    maxDetourTolerance: number
  }): Promise<RideRequest> {
    let passenger = await prisma.passenger.findUnique({
      where: { id: data.passengerId }
    })
    if (!passenger) {
      passenger = await prisma.passenger.create({
        data: {
          id: data.passengerId,
          name: 'Test Passenger',
          contactInfo: 'test@example.com'
        }
      })
    }

    const createdRequest = await prisma.rideRequest.create({
      data: {
        passengerId: data.passengerId,
        pickupLocation: data.pickupLocation as unknown as Prisma.InputJsonValue,
        departureTime: new Date(data.departureTime),
        seatRequirement: data.seatRequirement,
        luggageAmount: data.luggageAmount,
        maxDetourTolerance: data.maxDetourTolerance,
        status: RequestStatus.PENDING
      }
    })
    return createdRequest
  }

  async findGroup(requestId: string) {
    const request = await prisma.rideRequest.findUnique({
      where: { id: requestId },
      include: { passenger: true }
    })

    if (!request) {
      throw new Error('Request not found')
    }

    if (request.status !== RequestStatus.PENDING) {
      throw new Error('Request is not pending')
    }

    const group = await this.matchingEngine.findCompatiblePassengers(request)

    if (!group) return null

    const groupWithRequests = await prisma.passengerGroup.findUnique({
      where: { id: group.id },
      include: { rideRequests: true }
    })

    if (!groupWithRequests) return null

    const requestIds: string[] = groupWithRequests.rideRequests.map(
      (r: RideRequest) => r.id
    )

    await prisma.rideRequest.updateMany({
      where: { id: { in: requestIds } },
      data: { status: RequestStatus.MATCHED }
    })

    const updatedGroup = await prisma.passengerGroup.findUnique({
      where: { id: group.id },
      include: { rideRequests: true, route: true }
    })

    return updatedGroup
  }

  async cancelRequest(requestId: string): Promise<RideRequest> {
    const request = await prisma.rideRequest.findUnique({
      where: { id: requestId }
    })

    if (!request) throw new Error('Request not found')

    const updated = await prisma.rideRequest.update({
      where: { id: requestId },
      data: { status: RequestStatus.CANCELLED }
    })

    return updated
  }
}
