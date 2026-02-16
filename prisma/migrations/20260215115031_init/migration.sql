-- CreateEnum
CREATE TYPE "RequestStatus" AS ENUM ('PENDING', 'MATCHED', 'CANCELLED', 'COMPLETED');

-- CreateEnum
CREATE TYPE "GroupStatus" AS ENUM ('FORMING', 'LOCKED', 'IN_PROGRESS', 'COMPLETED');

-- CreateEnum
CREATE TYPE "CabType" AS ENUM ('SEDAN', 'SUV', 'VAN');

-- CreateEnum
CREATE TYPE "CabStatus" AS ENUM ('AVAILABLE', 'BUSY', 'OFF_DUTY');

-- CreateTable
CREATE TABLE "passengers" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "contact_info" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "passengers_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ride_requests" (
    "id" TEXT NOT NULL,
    "passenger_id" TEXT NOT NULL,
    "pickup_location" JSONB NOT NULL,
    "departure_time" TIMESTAMP(3) NOT NULL,
    "seat_requirement" INTEGER NOT NULL,
    "luggage_amount" INTEGER NOT NULL,
    "max_detour_tolerance" INTEGER NOT NULL,
    "status" "RequestStatus" NOT NULL DEFAULT 'PENDING',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "group_id" TEXT,

    CONSTRAINT "ride_requests_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "passenger_groups" (
    "id" TEXT NOT NULL,
    "total_passengers" INTEGER NOT NULL,
    "total_seats" INTEGER NOT NULL,
    "total_luggage" INTEGER NOT NULL,
    "status" "GroupStatus" NOT NULL DEFAULT 'FORMING',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "route_id" TEXT,

    CONSTRAINT "passenger_groups_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "cabs" (
    "id" TEXT NOT NULL,
    "cab_type" "CabType" NOT NULL,
    "max_capacity" INTEGER NOT NULL,
    "max_luggage" INTEGER NOT NULL,
    "status" "CabStatus" NOT NULL DEFAULT 'AVAILABLE',
    "current_location" JSONB NOT NULL,

    CONSTRAINT "cabs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "cab_assignments" (
    "id" TEXT NOT NULL,
    "cab_id" TEXT NOT NULL,
    "group_id" TEXT NOT NULL,
    "assigned_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "completed_at" TIMESTAMP(3),

    CONSTRAINT "cab_assignments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "routes" (
    "id" TEXT NOT NULL,
    "waypoint_order" JSONB NOT NULL,
    "total_distance" DOUBLE PRECISION NOT NULL,
    "estimated_duration" INTEGER NOT NULL,
    "detour_analysis" JSONB NOT NULL,

    CONSTRAINT "routes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "cancellations" (
    "id" TEXT NOT NULL,
    "request_id" TEXT NOT NULL,
    "cancelled_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "reason" TEXT,
    "impact_analysis" JSONB,

    CONSTRAINT "cancellations_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "ride_requests_status_departure_time_idx" ON "ride_requests"("status", "departure_time");

-- CreateIndex
CREATE INDEX "ride_requests_group_id_idx" ON "ride_requests"("group_id");

-- CreateIndex
CREATE UNIQUE INDEX "passenger_groups_route_id_key" ON "passenger_groups"("route_id");

-- CreateIndex
CREATE INDEX "passenger_groups_status_idx" ON "passenger_groups"("status");

-- CreateIndex
CREATE INDEX "cabs_status_idx" ON "cabs"("status");

-- CreateIndex
CREATE UNIQUE INDEX "cab_assignments_group_id_key" ON "cab_assignments"("group_id");

-- CreateIndex
CREATE INDEX "cab_assignments_cab_id_idx" ON "cab_assignments"("cab_id");

-- AddForeignKey
ALTER TABLE "ride_requests" ADD CONSTRAINT "ride_requests_group_id_fkey" FOREIGN KEY ("group_id") REFERENCES "passenger_groups"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ride_requests" ADD CONSTRAINT "ride_requests_passenger_id_fkey" FOREIGN KEY ("passenger_id") REFERENCES "passengers"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "passenger_groups" ADD CONSTRAINT "passenger_groups_route_id_fkey" FOREIGN KEY ("route_id") REFERENCES "routes"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "cab_assignments" ADD CONSTRAINT "cab_assignments_cab_id_fkey" FOREIGN KEY ("cab_id") REFERENCES "cabs"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "cab_assignments" ADD CONSTRAINT "cab_assignments_group_id_fkey" FOREIGN KEY ("group_id") REFERENCES "passenger_groups"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "cancellations" ADD CONSTRAINT "cancellations_request_id_fkey" FOREIGN KEY ("request_id") REFERENCES "ride_requests"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
