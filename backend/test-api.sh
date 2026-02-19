#!/bin/bash

# Solo Leveling API Test Script
BASE_URL="http://localhost:3000"

echo "=========================================="
echo "🎮 Solo Leveling API Feature Test"
echo "=========================================="
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

test_endpoint() {
    local name=$1
    local url=$2
    local method=${3:-GET}
    
    echo -n "Testing $name... "
    
    if [ "$method" == "GET" ]; then
        response=$(curl -s -w "\n%{http_code}" "$url")
    fi
    
    http_code=$(echo "$response" | tail -1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" == "200" ] || [ "$http_code" == "201" ]; then
        echo -e "${GREEN}✓ PASS${NC} ($http_code)"
        return 0
    else
        echo -e "${RED}✗ FAIL${NC} ($http_code)"
        return 1
    fi
}

# Test 1: Health Check
echo "1. Health Check"
test_endpoint "Health" "$BASE_URL/health"
echo ""

# Test 2: Player API
echo "2. Player API"
test_endpoint "Get Player" "$BASE_URL/api/player"
echo ""

# Test 3: Quests API
echo "3. Quests API"
test_endpoint "Get All Quests" "$BASE_URL/api/quests"
test_endpoint "Get Today's Quests" "$BASE_URL/api/quests/today"
echo ""

# Test 4: Templates API
echo "4. Quest Templates API"
test_endpoint "Get All Templates" "$BASE_URL/api/templates"
echo ""

# Test 5: Achievements API
echo "5. Achievements API"
test_endpoint "Get All Achievements" "$BASE_URL/api/achievements"
echo ""

echo "=========================================="
echo "Test Complete!"
echo "=========================================="
