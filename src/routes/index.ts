import { Router } from 'express'
import { RideRequestController } from '../modules/ride-request/RideRequestController'
import { PricingController } from '../controllers/PricingController'

const router = Router()
const rideController = new RideRequestController()
const pricingController = new PricingController()

router.post('/ride-requests', rideController.create)
router.post('/ride-requests/:id/group', rideController.findGroup)
router.post('/ride-requests/:id/cancel', rideController.cancel)

router.post('/pricing/calculate', pricingController.calculate)

export default router
