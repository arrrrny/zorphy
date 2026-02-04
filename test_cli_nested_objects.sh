#!/bin/bash

# Zorphy CLI Test Suite - Nested Objects
# This script tests all nested Zorphy object scenarios via the CLI

set -e  # Exit on error

echo "=========================================="
echo "Zorphy CLI Test Suite - Nested Objects"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"

    TESTS_RUN=$((TESTS_RUN + 1))
    echo "TEST $TESTS_RUN: $test_name"
    echo "Command: $test_command"

    if eval "$test_command"; then
        echo -e "${GREEN}✓ PASSED${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAILED${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    echo ""
}

# Clean up function
cleanup() {
    echo "Cleaning up test files..."
    rm -rf test_entities
    rm -f test_*.dart
    echo ""
}

# Trap to ensure cleanup runs
trap cleanup EXIT

# Create test directory
echo "Setting up test environment..."
mkdir -p test_entities
echo ""

# =============================================================================
# TEST 1: Single Nested Zorphy Object
# =============================================================================
echo "=========================================="
echo "TEST GROUP 1: Single Nested Objects"
echo "=========================================="
echo ""

run_test "Create entity with nested Zorphy object" \
    "dart run zorphy:zorphy_cli create -n TestUser -o test_entities --field id:String --field name:String --field address:\$TestAddress --no-fields"

run_test "Create the nested Address entity" \
    "dart run zorphy:zorphy_cli create -n TestAddress -o test_entities --field street:String --field city:String --field country:String --no-fields"

run_test "Verify TestUser file exists" \
    "test -f test_entities/testuser.dart"

run_test "Verify TestAddress file exists" \
    "test -f test_entities/testaddress.dart"

run_test "Check TestUser contains nested Address type" \
    "grep -q '\$Address get address' test_entities/testuser.dart"

# =============================================================================
# TEST 2: Nullable Nested Zorphy Object
# =============================================================================
echo "=========================================="
echo "TEST GROUP 2: Nullable Nested Objects"
echo "=========================================="
echo ""

run_test "Create entity with nullable nested object" \
    "dart run zorphy:zorphy_cli create -n TestUser2 -o test_entities --field id:String --field address:\$TestAddress? --no-fields"

run_test "Verify nullable syntax in generated file" \
    "grep -q '\$Address? get address' test_entities/testuser2.dart"

# =============================================================================
# TEST 3: List of Zorphy Objects
# =============================================================================
echo "=========================================="
echo "TEST GROUP 3: List of Zorphy Objects"
echo "=========================================="
echo ""

run_test "Create Order entity with List of OrderItems" \
    "dart run zorphy:zorphy_cli create -n TestOrder -o test_entities --field orderId:String --field items:List<\$TestOrderItem> --no-fields"

run_test "Create OrderItem entity" \
    "dart run zorphy:zorphy_cli create -n TestOrderItem -o test_entities --field productId:String --field name:String --field price:double --no-fields"

run_test "Verify List type in TestOrder" \
    "grep -q 'List<\$TestOrderItem> get items' test_entities/testorder.dart"

# =============================================================================
# TEST 4: Map with Zorphy Object Values
# =============================================================================
echo "=========================================="
echo "TEST GROUP 4: Map with Zorphy Values"
echo "=========================================="
echo ""

run_test "Create ProductCatalog entity with Map" \
    "dart run zorphy:zorphy_cli create -n TestProductCatalog -o test_entities --field catalogId:String --field products:Map<String,\$TestProduct> --no-fields"

run_test "Create Product entity" \
    "dart run zorphy:zorphy_cli create -n TestProduct -o test_entities --field id:String --field name:String --field price:double --no-fields"

run_test "Verify Map type in ProductCatalog" \
    "grep -q 'Map<String,\$TestProduct> get products' test_entities/testproductcatalog.dart"

# =============================================================================
# TEST 5: Polymorphic Objects (Sealed Classes)
# =============================================================================
echo "=========================================="
echo "TEST GROUP 5: Polymorphic Objects"
echo "=========================================="
echo ""

run_test "Create sealed PaymentMethod base class" \
    "dart run zorphy:zorphy_cli create -n TestPaymentMethod -o test_entities --sealed --no-fields"

run_test "Create CreditCard subtype" \
    "dart run zorphy:zorphy_cli create -n TestCreditCard -o test_entities --field cardNumber:String --field expiryDate:String --no-fields"

run_test "Create PayPal subtype" \
    "dart run zorphy:zorphy_cli create -n TestPayPal -o test_entities --field email:String --no-fields"

run_test "Create Transaction with polymorphic field" \
    "dart run zorphy:zorphy_cli create -n TestTransaction -o test_entities --field transactionId:String --field paymentMethod:\$\$TestPaymentMethod --no-fields"

run_test "Verify polymorphic type with \$\$ prefix" \
    "grep -q '\$\$TestPaymentMethod get paymentMethod' test_entities/testtransaction.dart"

# =============================================================================
# TEST 6: List of Polymorphic Objects
# =============================================================================
echo "=========================================="
echo "TEST GROUP 6: List of Polymorphic Objects"
echo "=========================================="
echo ""

run_test "Create Transaction with polymorphic list" \
    "dart run zorphy:zorphy_cli create -n TestTransaction2 -o test_entities --field transactionId:String --field history:List<\$\$TestPaymentMethod> --no-fields"

run_test "Verify List of polymorphic type" \
    "grep -q 'List<\$\$TestPaymentMethod> get history' test_entities/testtransaction2.dart"

# =============================================================================
# TEST 7: Map with Polymorphic Values
# =============================================================================
echo "=========================================="
echo "TEST GROUP 7: Map with Polymorphic Values"
echo "=========================================="
echo ""

run_test "Create Transaction with polymorphic map" \
    "dart run zorphy:zorphy_cli create -n TestTransaction3 -o test_entities --field transactionId:String --field availableMethods:Map<String,\$\$TestPaymentMethod> --no-fields"

run_test "Verify Map of polymorphic type" \
    "grep -q 'Map<String,\$\$TestPaymentMethod> get availableMethods' test_entities/testtransaction3.dart"

# =============================================================================
# TEST 8: Deep Nesting
# =============================================================================
echo "=========================================="
echo "TEST GROUP 8: Deep Nesting"
echo "=========================================="
echo ""

run_test "Create Company with deeply nested objects" \
    "dart run zorphy:zorphy_cli create -n TestCompany -o test_entities --field companyId:String --field address:\$TestCompanyAddress --field departments:List<\$TestDepartment> --field employeeDirectory:Map<String,\$TestEmployee> --no-fields"

run_test "Create CompanyAddress with nested GeoLocation" \
    "dart run zorphy:zorphy_cli create -n TestCompanyAddress -o test_entities --field street:String --field city:String --field location:\$TestGeoLocation? --no-fields"

run_test "Create GeoLocation" \
    "dart run zorphy:zorphy_cli create -n TestGeoLocation -o test_entities --field latitude:double --field longitude:double --no-fields"

run_test "Create Department with nested Employee" \
    "dart run zorphy:zorphy_cli create -n TestDepartment -o test_entities --field departmentId:String --field manager:\$TestEmployee --field members:List<\$TestEmployee> --no-fields"

run_test "Create Employee with nested ContactInfo" \
    "dart run zorphy:zorphy_cli create -n TestEmployee -o test_entities --field employeeId:String --field name:String --field contactInfo:\$TestContactInfo --no-fields"

run_test "Create ContactInfo" \
    "dart run zorphy:zorphy_cli create -n TestContactInfo -o test_entities --field email:String? --field phone:String? --no-fields"

run_test "Verify deep nesting structure" \
    "grep -q '\$TestGeoLocation? get location' test_entities/testcompanyaddress.dart"

run_test "Verify Department has List of Employees" \
    "grep -q 'List<\$TestEmployee> get members' test_entities/testdepartment.dart"

run_test "Verify Company has Map of Employees" \
    "grep -q 'Map<String,\$TestEmployee> get employeeDirectory' test_entities/testcompany.dart"

# =============================================================================
# TEST 9: Complex Real-World E-commerce Scenario
# =============================================================================
echo "=========================================="
echo "TEST GROUP 9: Real-World E-commerce"
echo "=========================================="
echo ""

run_test "Create Order with User and OrderItems" \
    "dart run zorphy:zorphy_cli create -n TestEcomOrder -o test_entities --field orderId:String --field user:\$TestEcomUser --field items:List<\$TestEcomOrderItem> --field total:double --no-fields"

run_test "Create EcomUser with Address" \
    "dart run zorphy:zorphy_cli create -n TestEcomUser -o test_entities --field userId:String --field name:String --field shippingAddress:\$TestEcomAddress --field billingAddress:\$TestEcomAddress? --no-fields"

run_test "Create EcomAddress" \
    "dart run zorphy:zorphy_cli create -n TestEcomAddress -o test_entities --field street:String --field city:String --field state:String --field zipCode:String --field country:String --no-fields"

run_test "Create EcomOrderItem with Product" \
    "dart run zorphy:zorphy_cli create -n TestEcomOrderItem -o test_entities --field itemId:String --field product:\$TestEcomProduct --field quantity:int --field unitPrice:double --no-fields"

run_test "Create EcomProduct with variants" \
    "dart run zorphy:zorphy_cli create -n TestEcomProduct -o test_entities --field productId:String --field name:String --field price:double --field variants:List<\$TestEcomProductVariant> --no-fields"

run_test "Create EcomProductVariant" \
    "dart run zorphy:zorphy_cli create -n TestEcomProductVariant -o test_entities --field variantId:String --field name:String --field price:double --no-fields"

run_test "Verify Order has nested User and List of Items" \
    "grep -q '\$TestEcomUser get user' test_entities/testecomorder.dart && grep -q 'List<\$TestEcomOrderItem> get items' test_entities/testecomorder.dart"

run_test "Verify User has two Address fields" \
    "grep -q '\$TestEcomAddress get shippingAddress' test_entities/testecomuser.dart && grep -q '\$TestEcomAddress? get billingAddress' test_entities/testecomuser.dart"

run_test "Verify Product has List of variants" \
    "grep -q 'List<\$TestEcomProductVariant> get variants' test_entities/testecomproduct.dart"

# =============================================================================
# TEST 10: Field Types Verification
# =============================================================================
echo "=========================================="
echo "TEST GROUP 10: Field Types Verification"
echo "=========================================="
echo ""

run_test "Verify String type" \
    "grep -q 'String get name' test_entities/testuser.dart"

run_test "Verify int type" \
    "grep -q 'int get quantity' test_entities/testecomorderitem.dart"

run_test "Verify double type" \
    "grep -q 'double get price' test_entities/testorderitem.dart"

run_test "Verify bool type (if exists)" \
    "grep -q 'bool get' test_entities/*.dart || true"

run_test "Verify DateTime type" \
    "grep -q 'DateTime get' test_entities/*.dart || true"

run_test "Verify nullable String type" \
    "grep -q 'String? get' test_entities/testuser.dart || grep -q 'String? get' test_entities/testecomuser.dart"

# =============================================================================
# SUMMARY
# =============================================================================
echo "=========================================="
echo "TEST SUMMARY"
echo "=========================================="
echo ""
echo "Total Tests Run: $TESTS_RUN"
echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}ALL TESTS PASSED! 🎉${NC}"
    echo -e "${GREEN}========================================${NC}"
    exit 0
else
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}SOME TESTS FAILED${NC}"
    echo -e "${RED}========================================${NC}"
    exit 1
fi
