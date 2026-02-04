# CLI Testing Guide - Nested Zorphy Objects

This guide provides step-by-step instructions to manually test all nested Zorphy object scenarios via the CLI.

## Prerequisites

```bash
# Activate Zorphy CLI
dart pub global activate zorphy

# Or run from within the project
cd /path/to/zorphy
```

## Test Scenarios

### Test 1: Single Nested Zorphy Object

**Goal:** Create an entity with a nested Zorphy object

```bash
# Step 1: Create User entity with nested Address
dart run zorphy:zorphy_cli create -n User \
  --field id:String \
  --field name:String \
  --field email:String? \
  --field address:\$Address

# Step 2: Create the Address entity
dart run zorphy:zorphy_cli create -n Address \
  --field street:String \
  --field city:String \
  --field state:String \
  --field zipCode:String \
  --field country:String

# Step 3: Verify the generated files
cat lib/entities/user.dart | grep -A 5 "abstract class"
cat lib/entities/address.dart | grep -A 5 "abstract class"

# Expected output should show:
# - User has: $Address get address;
# - Address has: String get street; String get city; etc.
```

### Test 2: Nullable Nested Object

**Goal:** Test nullable nested Zorphy objects

```bash
# Create entity with nullable nested object
dart run zorphy:zorphy_cli create -n UserProfile \
  --field userId:String \
  --field displayName:String \
  --field bio:String? \
  --field avatarUrl:String? \
  --field address:\$Address?

# Verify nullable syntax
cat lib/entities/userprofile.dart | grep "get address"
# Expected: $Address? get address;
```

### Test 3: List of Zorphy Objects

**Goal:** Test List containing Zorphy objects

```bash
# Create Order with List of OrderItems
dart run zorphy:zorphy_cli create -n Order \
  --field orderId:String \
  --field userId:String \
  --field items:List<\$OrderItem> \
  --field total:double \
  --field createdAt:DateTime

# Create OrderItem
dart run zorphy:zorphy_cli create -n OrderItem \
  --field itemId:String \
  --field productId:String \
  --field name:String \
  --field quantity:int \
  --field unitPrice:double

# Verify List type
cat lib/entities/order.dart | grep "get items"
# Expected: List<$OrderItem> get items;
```

### Test 4: Map with Zorphy Object Values

**Goal:** Test Map with Zorphy object values

```bash
# Create ProductCatalog
dart run zorphy:zorphy_cli create -n ProductCatalog \
  --field catalogId:String \
  --field name:String \
  --field products:Map<String,\$Product> \
  --field categoryCount:int

# Create Product
dart run zorphy:zorphy_cli create -n Product \
  --field productId:String \
  --field name:String \
  --field description:String? \
  --field price:double \
  --field inStock:bool

# Verify Map type
cat lib/entities/productcatalog.dart | grep "get products"
# Expected: Map<String, $Product> get products;
```

### Test 5: Polymorphic Objects (Sealed Hierarchy)

**Goal:** Test sealed classes with concrete implementations

```bash
# Step 1: Create sealed base class
dart run zorphy:zorphy_cli create -n PaymentMethod \
  --sealed

# Step 2: Create CreditCard subtype
dart run zorphy:zorphy_cli create -n CreditCard \
  --field cardNumber:String \
  --field expiryDate:String \
  --field cardholderName:String

# Step 3: Create PayPal subtype
dart run zorphy:zorphy_cli create -n PayPal \
  --field email:String \
  --field verified:bool

# Step 4: Create Transaction with polymorphic field
dart run zorphy:zorphy_cli create -n Transaction \
  --field transactionId:String \
  --field amount:double \
  --field paymentMethod:\$\$PaymentMethod

# Verify polymorphic syntax (note the $$ prefix)
cat lib/entities/transaction.dart | grep "get paymentMethod"
# Expected: $$PaymentMethod get paymentMethod;
```

### Test 6: List of Polymorphic Objects

**Goal:** Test List containing polymorphic Zorphy objects

```bash
# Create Transaction with payment history
dart run zorphy:zorphy_cli create -n TransactionWithHistory \
  --field transactionId:String \
  --field paymentMethod:\$\$PaymentMethod \
  --field history:List<\$\$PaymentMethod> \
  --field attemptedCount:int

# Verify List of polymorphic type
cat lib/entities/transactionwithhistory.dart | grep "get history"
# Expected: List<$$PaymentMethod> get history;
```

### Test 7: Map with Polymorphic Values

**Goal:** Test Map with polymorphic Zorphy object values

```bash
# Create Wallet with multiple payment methods
dart run zorphy:zorphy_cli create -n Wallet \
  --field walletId:String \
  --field userId:String \
  --field paymentMethods:Map<String,\$\$PaymentMethod> \
  --field defaultMethod:String

# Verify Map of polymorphic type
cat lib/entities/wallet.dart | grep "get paymentMethods"
# Expected: Map<String, $$PaymentMethod> get paymentMethods;
```

### Test 8: Deep Nesting

**Goal:** Test deeply nested Zorphy objects at multiple levels

```bash
# Create Company
dart run zorphy:zorphy_cli create -n Company \
  --field companyId:String \
  --field name:String \
  --field headquarters:\<$CompanyAddress \
  --field departments:List<\$Department> \
  --field employeeDirectory:Map<String,\$Employee>

# Create CompanyAddress with nested GeoLocation
dart run zorphy:zorphy_cli create -n CompanyAddress \
  --field street:String \
  --field city:String \
  --field state:String \
  --field country:String \
  --field location:\$GeoLocation?

# Create GeoLocation
dart run zorphy:zorphy_cli create -n GeoLocation \
  --field latitude:double \
  --field longitude:double

# Create Department with nested Manager and Employees
dart run zorphy:zorphy_cli create -n Department \
  --field departmentId:String \
  --field name:String \
  --field manager:\$Employee \
  --field members:List<\$Employee>

# Create Employee with nested ContactInfo
dart run zorphy:zorphy_cli create -n Employee \
  --field employeeId:String \
  --field firstName:String \
  --field lastName:String \
  --field email:String \
  --field contactInfo:\$ContactInfo

# Create ContactInfo
dart run zorphy:zorphy_cli create -n ContactInfo \
  --field phone:String? \
  --field mobile:String? \
  --field emergencyContact:String?

# Verify deep nesting
echo "=== Checking Company ==="
cat lib/entities/company.dart | grep "get headquarters"
cat lib/entities/company.dart | grep "get departments"
cat lib/entities/company.dart | grep "get employeeDirectory"

echo "=== Checking CompanyAddress ==="
cat lib/entities/companyaddress.dart | grep "get location"

echo "=== Checking Department ==="
cat lib/entities/department.dart | grep "get manager"
cat lib/entities/department.dart | grep "get members"

echo "=== Checking Employee ==="
cat lib/entities/employee.dart | grep "get contactInfo"
```

### Test 9: Real-World E-commerce Scenario

**Goal:** Test a complete e-commerce system with nested objects

```bash
# 1. User Management
dart run zorphy:zorphy_cli create -n EcomUser \
  --field userId:String \
  --field username:String \
  --field email:String \
  --field profile:\$UserProfile?

dart run zorphy:zorphy_cli create -n UserProfile \
  --field displayName:String \
  --field avatarUrl:String? \
  --field bio:String? \
  --field preferences:Map<String,dynamic>

# 2. Product Management
dart run zorphy:zorphy_cli create -n EcomProduct \
  --field productId:String \
  --field name:String \
  --field description:String? \
  --field price:double \
  --field compareAtPrice:double? \
  --field variants:List<\$ProductVariant> \
  --field images:List<String> \
  --field tags:List<String>

dart run zorphy:zorphy_cli create -n ProductVariant \
  --field variantId:String \
  --field name:String \
  --field price:double \
  --field sku:String \
  --field attributes:Map<String,String>

# 3. Order Management
dart run zorphy:zorphy_cli create -n EcomOrder \
  --field orderId:String \
  --field user:\$EcomUser \
  --field items:List<\$OrderLineItem> \
  --field shippingAddress:\$Address \
  --field billingAddress:\$Address \
  --field subtotal:double \
  --field tax:double \
  --field total:double \
  --field status:\$\$OrderStatus \
  --field createdAt:DateTime \
  --field updatedAt:DateTime?

dart run zorphy:zorphy_cli create -n OrderLineItem \
  --field lineItemId:String \
  --field product:\$EcomProduct \
  --field variant:\$ProductVariant? \
  --field quantity:int \
  --field unitPrice:double

# 4. Create OrderStatus sealed hierarchy
dart run zorphy:zorphy_cli create -n OrderStatus --sealed
dart run zorphy:zorphy_cli create -n StatusPending
dart run zorphy:zorphy_cli create -n StatusProcessing
dart run zorphy:zorphy_cli create -n StatusShipped
dart run zorphy:zorphy_cli create -n StatusDelivered
dart run zorphy:zorphy_cli create -n StatusCancelled

# 5. Payment Management
dart run zorphy:zorphy_cli create -n EcomPayment \
  --field paymentId:String \
  --field order:\$EcomOrder \
  --field amount:double \
  --field currency:String \
  --field method:\$\$PaymentMethod \
  --field status:\$\$PaymentStatus \
  --field createdAt:DateTime

dart run zorphy:zorphy_cli create -n PaymentStatus --sealed
dart run zorphy:zorphy_cli create -n PaymentStatusPending
dart run zorphy:zorphy_cli create -n PaymentStatusCompleted
dart run zorphy:zorphy_cli create -n PaymentStatusFailed

# Verify the complete structure
echo "=== Checking Order ==="
cat lib/entities/ecomorder.dart | grep "get user"
cat lib/entities/ecomorder.dart | grep "get items"
cat lib/entities/ecomorder.dart | grep "get shippingAddress"
cat lib/entities/ecomorder.dart | grep "get status"

echo "=== Checking OrderLineItem ==="
cat lib/entities/orderlineitem.dart | grep "get product"
cat lib/entities/orderlineitem.dart | grep "get variant"

echo "=== Checking Product ==="
cat lib/entities/ecomproduct.dart | grep "get variants"

echo "=== Checking Payment ==="
cat lib/entities/ecompayment.dart | grep "get order"
cat lib/entities/ecompayment.dart | grep "get method"
cat lib/entities/ecompayment.dart | grep "get status"
```

### Test 10: Build and Verify

**Goal:** Build all entities and verify they compile

```bash
# Step 1: Build all entities
dart run build_runner build --delete-conflicting-outputs

# Step 2: Check for generated files
ls -la lib/entities/*.zorphy.dart

# Step 3: Verify no errors in generated code
grep -r "error" lib/entities/*.zorphy.dart || echo "No errors found"

# Step 4: List all entities created
dart run zorphy:zorphy_cli list -o lib/entities
```

## Automated Test Script

Alternatively, run the automated test script:

```bash
# Make it executable
chmod +x test_cli_nested_objects.sh

# Run all tests
./test_cli_nested_objects.sh
```

## Expected Results

✅ All entities should be created successfully  
✅ All nested types should have correct syntax (`$Type`, `$$Type`)  
✅ Nullable types should have `?` suffix  
✅ Lists should use `List<$Type>` syntax  
✅ Maps should use `Map<Key, $Type>` syntax  
✅ Polymorphic types should use `$$Type` syntax  
✅ Generated files should compile without errors  
✅ `zorphy list` should show all created entities  

## Troubleshooting

### Issue: "Type not found" error

**Solution:** Make sure nested entities are created before the entities that reference them.

**Example:**
```bash
# Create Address FIRST
dart run zorphy:zorphy_cli create -n Address --field street:String

# Then create User that references it
dart run zorphy:zorphy_cli create -n User --field address:\$Address
```

### Issue: Build errors

**Solution:** 
1. Clean first: `dart run build_runner clean`
2. Then build: `dart run build_runner build --delete-conflicting-outputs`

### Issue: Wrong syntax in generated files

**Solution:** Check your CLI command syntax:
- Single nested: `--field name:\$TypeName`
- Nullable: `--field name:\$TypeName?`
- List: `--field name:List<\$TypeName>`
- Map: `--field name:Map<Key,\$TypeName>`
- Polymorphic: `--field name:\$\$TypeName`

## Quick Reference

| Scenario | CLI Syntax | Example |
|----------|-----------|---------|
| Single nested | `--field name:\$Type` | `--field address:\$Address` |
| Nullable | `--field name:\$Type?` | `--field address:\$Address?` |
| List | `--field name:List<\$Type>` | `--field items:List<\$Item>` |
| Map | `--field name:Map<Key,\$Type>` | `--field users:Map<String,\$User>` |
| Polymorphic | `--field name:\$\$Type` | `--field payment:\$\$PaymentMethod` |
| Nullable polymorphic | `--field name:\$\$Type?` | `--field payment:\$\$PaymentMethod?` |
| List of polymorphic | `--field name:List<\$\$Type>` | `--field methods:List<\$\$PaymentMethod>` |
| Map of polymorphic | `--field name:Map<Key,\$\$Type>` | `--field methods:Map<String,\$\$PaymentMethod>` |

## Success Criteria

You've successfully tested nested Zorphy objects if:

- [ ] All entities created without errors
- [ ] Generated files contain correct type syntax
- [ ] `build_runner build` completes successfully
- [ ] No import errors in generated files
- [ ] `zorphy list` shows all entities
- [ ] Can instantiate objects in Dart code
- [ ] JSON serialization includes `_className_` for nested objects

## Next Steps

After successful testing:

1. **Use in your project:** Start creating entities with nested objects
2. **Test JSON serialization:** Verify `_className_` is added for all nested objects
3. **Test polymorphism:** Create sealed hierarchies and test exhaustiveness
4. **Test patching:** Use the patch system to update nested objects

🎉 **Happy testing!**
