@echo off
chcp 65001 >nul

set BASE_URL=http://localhost:3000
set API_PREFIX=/api/v1

echo 🚗 Airport Cab Pooling System - API Testing
echo ==========================================
echo.

REM Valid UUIDs
set PASSENGER_1_ID=550e8400-e29b-41d4-a716-446655440001
set PASSENGER_2_ID=550e8400-e29b-41d4-a716-446655440002
set PASSENGER_3_ID=550e8400-e29b-41d4-a716-446655440003

REM =========================
REM 1. Health Check
REM =========================
echo 1. Health Check
curl -s "%BASE_URL%/health"
echo.
echo.

REM =========================
REM 2. Create Passenger 1
REM =========================
echo 2. Create Ride Request - Passenger 1
curl -s -X POST "%BASE_URL%%API_PREFIX%/ride-requests" ^
-H "Content-Type: application/json" ^
-d "{\"passengerId\":\"%PASSENGER_1_ID%\",\"pickupLocation\":{\"lat\":40.7589,\"lng\":-73.9851},\"departureTime\":\"2026-02-15T15:00:00Z\",\"seatRequirement\":1,\"luggageAmount\":1,\"maxDetourTolerance\":20}"
echo.
echo.

REM =========================
REM 3. Create Passenger 2
REM =========================
echo 3. Create Ride Request - Passenger 2
curl -s -X POST "%BASE_URL%%API_PREFIX%/ride-requests" ^
-H "Content-Type: application/json" ^
-d "{\"passengerId\":\"%PASSENGER_2_ID%\",\"pickupLocation\":{\"lat\":40.7614,\"lng\":-73.9776},\"departureTime\":\"2026-02-15T15:05:00Z\",\"seatRequirement\":2,\"luggageAmount\":1,\"maxDetourTolerance\":15}"
echo.
echo.

REM =========================
REM 4. Create Passenger 3
REM =========================
echo 4. Create Ride Request - Passenger 3
curl -s -X POST "%BASE_URL%%API_PREFIX%/ride-requests" ^
-H "Content-Type: application/json" ^
-d "{\"passengerId\":\"%PASSENGER_3_ID%\",\"pickupLocation\":{\"lat\":40.7505,\"lng\":-73.9934},\"departureTime\":\"2026-02-15T14:55:00Z\",\"seatRequirement\":1,\"luggageAmount\":2,\"maxDetourTolerance\":25}"
echo.
echo.

REM =========================
REM 5. Pricing Solo
REM =========================
echo 5. Pricing Solo
curl -s -X POST "%BASE_URL%%API_PREFIX%/pricing/calculate" ^
-H "Content-Type: application/json" ^
-d "{\"distance\":15,\"duration\":25,\"passengers\":1,\"demand\":1.0}"
echo.
echo.

REM =========================
REM 6. Pricing Pool (2)
REM =========================
echo 6. Pricing Pool (2)
curl -s -X POST "%BASE_URL%%API_PREFIX%/pricing/calculate" ^
-H "Content-Type: application/json" ^
-d "{\"distance\":15,\"duration\":25,\"passengers\":2,\"demand\":1.0}"
echo.
echo.

REM =========================
REM 7. Pricing Pool (3)
REM =========================
echo 7. Pricing Pool (3)
curl -s -X POST "%BASE_URL%%API_PREFIX%/pricing/calculate" ^
-H "Content-Type: application/json" ^
-d "{\"distance\":15,\"duration\":25,\"passengers\":3,\"demand\":1.0}"
echo.
echo.

REM =========================
REM 8. Pricing Surge
REM =========================
echo 8. Pricing Surge (1.5x)
curl -s -X POST "%BASE_URL%%API_PREFIX%/pricing/calculate" ^
-H "Content-Type: application/json" ^
-d "{\"distance\":15,\"duration\":25,\"passengers\":2,\"demand\":1.5}"
echo.
echo.

echo ✅ API Test Finished
pause
