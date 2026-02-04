#!/bin/bash
set -e

echo "🧪 Testing Zorphy CLI..."

# Test 1: Basic entity creation
echo "1️⃣ Testing basic entity creation..."
dart run zorphy_cli create -n User --field name:String --field age:int --field email:String?

# Test 2: Enum creation
echo "2️⃣ Testing enum creation..."
dart run zorphy_cli enum -n UserStatus --value active,inactive,pending,suspended

# Test 3: Entity with enum reference
echo "3️⃣ Testing entity with enum reference..."
dart run zorphy_cli create -n Account --field username:String --field status:UserStatus --field createdAt:DateTime

# Test 4: Entity with nested entity reference
echo "4️⃣ Testing entity with nested entity reference..."
dart run zorphy_cli create -n Address --field street:String --field city:String --field postalCode:String
dart run zorphy_cli create -n UserWithAddress --field name:String --field address:\$Address --field phone:String?

# Test 5: Sealed class with subtypes
echo "5️⃣ Testing sealed class with subtypes..."
dart run zorphy_cli create -n PaymentMethod --sealed --field displayName:String
dart run zorphy_cli create -n CreditCard --field cardNumber:String --field expiryDate:String --extends \$PaymentMethod
dart run zorphy_cli create -n PayPal --field email:String --extends \$PaymentMethod

# Test 6: List and complex types
echo "6️⃣ Testing complex types..."
dart run zorphy_cli create -n Company --field name:String --field employees:List<\$User> --field locations:List<String>

# Test 7: Build and verify
echo "7️⃣ Building generated code..."
dart run build_runner build --delete-conflicting-outputs

echo "✅ All tests completed!"