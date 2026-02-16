#!/bin/bash

# Airport Cab Pooling System - API Test Script
# Usage: ./test_api.sh

BASE_URL="http://localhost:3000"
API_PREFIX="/api/v1"

echo "🚗 Airport Cab Pooling System - API Testing"
echo "=========================================="

# Function to generate UUID
generate_uuid() {
    if command -v uuidgen &> /dev/null; then
        uuidgen
    else
        echo "$(date +%s)-$(($RANDOM % 10000))"
    fi
}

# Test 1: Health Check
echo "1. Testing Health Check..."
curl -s -X GET "$BASE_URL/health" | jq '.' || echo "Health check failed"
echo ""

# Test 2: Create Ride Request - Passenger 1 (Downtown)
echo "2. Creating Ride Request - Passenger 1 (Downtown)..."
PASSENGER_1_ID=$(generate_uuid)
REQUEST_1=$(curl -s -X POST "$BASE_URL$API_PREFIX/ride-requests" \
  -H "Content-Type: application/json" \
  -d "{
    \"passengerId\": \"$PASSENGER_1_ID\",
    \"pickupLocation\": {\"lat\": 40.7589, \"lng\": -73.9851},
    \"departureTime\": \"2024-01-15T15:00:00Z\",
    \"seatRequirement\": 1,
    \"luggageAmount\": 1,
    \"maxDetourTolerance\": 20
  }")
echo "Passenger 1 Request: $REQUEST_1"
REQUEST_1_ID=$(echo $REQUEST_1 | jq -r '.id' 2>/dev/null || echo "")
echo "Request ID: $REQUEST_1_ID"
echo ""

# Test 3: Create Ride Request - Passenger 2 (Midtown)
echo "3. Creating Ride Request - Passenger 2 (Midtown)..."
PASSENGER_2_ID=$(generate_uuid)
REQUEST_2=$(curl -s -X POST "$BASE_URL$API_PREFIX/ride-requests" \
  -H "Content-Type: application/json" \
  -d "{
    \"passengerId\": \"$PASSENGER_2_ID\",
    \"pickupLocation\": {\"lat\": 40.7614, \"lng\": -73.9776},
    \"departureTime\": \"2024-01-15T15:05:00Z\",
    \"seatRequirement\": 2,
    \"luggageAmount\": 1,
    \"maxDetourTolerance\": 15
  }")
echo "Passenger 2 Request: $REQUEST_2"
REQUEST_2_ID=$(echo $REQUEST_2 | jq -r '.id' 2>/dev/null || echo "")
echo "Request ID: $REQUEST_2_ID"
echo ""

# Test 4: Create Ride Request - Passenger 3 (Chelsea)
echo "4. Creating Ride Request - Passenger 3 (Chelsea)..."
PASSENGER_3_ID=$(generate_uuid)
REQUEST_3=$(curl -s -X POST "$BASE_URL$API_PREFIX/ride-requests" \
  -H "Content-Type: application/json" \
  -d "{
    \"passengerId\": \"$PASSENGER_3_ID\",
    \"pickupLocation\": {\"lat\": 40.7505, \"lng\": -73.9934},
    \"departureTime\": \"2024-01-15T14:55:00Z\",
    \"seatRequirement\": 1,
    \"luggageAmount\": 2,
    \"maxDetourTolerance\": 25
  }")
echo "Passenger 3 Request: $REQUEST_3"
REQUEST_3_ID=$(echo $REQUEST_3 | jq -r '.id' 2>/dev/null || echo "")
echo "Request ID: $REQUEST_3_ID"
echo ""

# Test 5: Trigger Group Matching for Passenger 1
if [ ! -z "$REQUEST_1_ID" ]; then
    echo "5. Triggering Group Matching for Passenger 1..."
    MATCH_RESULT=$(curl -s -X POST "$BASE_URL$API_PREFIX/ride-requests/$REQUEST_1_ID/group")
    echo "Matching Result: $MATCH_RESULT"
    GROUP_ID=$(echo $MATCH_RESULT | jq -r '.id' 2>/dev/null || echo "")
    echo "Group ID: $GROUP_ID"
    echo ""
fi

# Test 6: Calculate Solo Price
echo "6. Calculating Solo Ride Price..."
SOLO_PRICE=$(curl -s -X POST "$BASE_URL$API_PREFIX/pricing/calculate" \
  -H "Content-Type: application/json" \
  -d "{
    \"distance\": 15,
    \"duration\": 25,
    \"passengers\": 1,
    \"demand\": 1.0
  }")
echo "Solo Price: $SOLO_PRICE"
echo ""

# Test 7: Calculate Pooled Price (2 passengers)
echo "7. Calculating Pooled Ride Price (2 passengers)..."
POOLED_PRICE_2=$(curl -s -X POST "$BASE_URL$API_PREFIX/pricing/calculate" \
  -H "Content-Type: application/json" \
  -d "{
    \"distance\": 15,
    \"duration\": 25,
    \"passengers\": 2,
    \"demand\": 1.0
  }")
echo "Pooled Price (2): $POOLED_PRICE_2"
echo ""

# Test 8: Calculate Pooled Price (3 passengers)
echo "8. Calculating Pooled Ride Price (3 passengers)..."
POOLED_PRICE_3=$(curl -s -X POST "$BASE_URL$API_PREFIX/pricing/calculate" \
  -H "Content-Type: application/json" \
  -d "{
    \"distance\": 15,
    \"duration\": 25,
    \"passengers\": 3,
    \"demand\": 1.0
  }")
echo "Pooled Price (3): $POOLED_PRICE_3"
echo ""

# Test 9: Calculate High Demand Price
echo "9. Calculating High Demand Price (1.5x surge)..."
HIGH_DEMAND_PRICE=$(curl -s -X POST "$BASE_URL$API_PREFIX/pricing/calculate" \
  -H "Content-Type: application/json" \
  -d "{
    \"distance\": 15,
    \"duration\": 25,
    \"passengers\": 2,
    \"demand\": 1.5
  }")
echo "High Demand Price: $HIGH_DEMAND_PRICE"
echo ""

# Test 10: Cancel Ride Request (if we have a valid request)
if [ ! -z "$REQUEST_2_ID" ]; then
    echo "10. Canceling Passenger 2's Request..."
    CANCEL_RESULT=$(curl -s -X POST "$BASE_URL$API_PREFIX/ride-requests/$REQUEST_2_ID/cancel")
    echo "Cancel Result: $CANCEL_RESULT"
    echo ""
fi

echo "✅ API Testing Complete!"
echo ""
echo "Summary:"
echo "- Passenger 1 ID: $PASSENGER_1_ID (Request: $REQUEST_1_ID)"
echo "- Passenger 2 ID: $PASSENGER_2_ID (Request: $REQUEST_2_ID)"
echo "- Passenger 3 ID: $PASSENGER_3_ID (Request: $REQUEST_3_ID)"
echo "- Group ID: $GROUP_ID"
echo ""
echo "Next Steps:"
echo "1. Check PostgreSQL database for persisted data"
echo "2. Monitor Redis for caching and locking activity"
echo "3. Test concurrent requests for race condition validation"
echo "4. Verify detour calculations in route optimization"