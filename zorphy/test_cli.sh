#!/bin/bash
set -e

echo "🧪 Testing Zorphy CLI..."

# Test 1: Basic entity creation
echo "1️⃣ Testing basic entity creation..."
dart run bin/zorphy_cli.dart create -n User --field name:String --field age:int --field email:String?

# Test 2: Enum creation
echo "2️⃣ Testing enum creation..."
dart run bin/zorphy_cli.dart enum -n UserStatus --value active,inactive,pending,suspended

# Test 3: Entity with enum reference
echo "3️⃣ Testing entity with enum reference..."
dart run bin/zorphy_cli.dart create -n Account --field username:String --field status:UserStatus --field createdAt:DateTime

# Test 4: Entity with nested entity reference
echo "4️⃣ Testing entity with nested entity reference..."
dart run bin/zorphy_cli.dart create -n Address --field street:String --field city:String --field postalCode:String
dart run bin/zorphy_cli.dart create -n UserWithAddress --field name:String --field address:Address --field phone:String?

# Test 5: Sealed class with subtypes
echo "5️⃣ Testing sealed class with subtypes..."
dart run bin/zorphy_cli.dart create -n PaymentMethod --sealed --field displayName:String
dart run bin/zorphy_cli.dart create -n CreditCard --field cardNumber:String --field expiryDate:String --extends PaymentMethod
dart run bin/zorphy_cli.dart create -n PayPal --field email:String --extends PaymentMethod

# Test 6: List and complex types
echo "6️⃣ Testing complex types..."
dart run bin/zorphy_cli.dart create -n Company --field name:String --field 'employees:List<User>' --field 'locations:List<String>'

# Test 7: Dry Run
echo "7️⃣ Testing dry run..."
dart run bin/zorphy_cli.dart create -n GhostUser --field name:String --dry-run
if [ -d "lib/src/domain/entities/ghost_user" ]; then
  echo "❌ Error: Dry run should not create directory!"
  exit 1
fi
echo "✅ Dry run successful (no file created)"

# Test 8: Build and verify
echo "8️⃣ Building generated code..."
dart run build_runner build --delete-conflicting-outputs

echo "✅ All tests completed!"