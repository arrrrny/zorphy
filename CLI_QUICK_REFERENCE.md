# CLI Nested Objects Quick Reference

## Command Syntax Cheat Sheet

```bash
# BASIC SYNTAX
zorphy create -n EntityName --field fieldName:Type

# NESTED ZORPHY OBJECTS
zorphy create -n EntityName \
  --field single:\$Address \
  --field nullable:\$Address? \
  --field list:List<\$Item> \
  --field map:Map<String,\$Product> \
  --field poly:\$\$PaymentMethod \
  --field polyList:List<\$\$PaymentMethod> \
  --field polyMap:Map<String,\$\$PaymentMethod>
```

## Common Patterns

### 1. User with Address
```bash
zorphy create -n User --field id:String --field name:String --field address:\$Address
zorphy create -n Address --field street:String --field city:String
```

### 2. Order with Items
```bash
zorphy create -n Order --field orderId:String --field items:List<\$OrderItem>
zorphy create -n OrderItem --field itemId:String --field name:String
```

### 3. Catalog with Products Map
```bash
zorphy create -n Catalog --field catalogId:String --field products:Map<String,\$Product>
zorphy create -n Product --field productId:String --field name:String
```

### 4. Payment with Polymorphism
```bash
zorphy create -n PaymentMethod --sealed
zorphy create -n CreditCard --field number:String
zorphy create -n PayPal --field email:String
zorphy create -n Transaction --field transactionId:String --field method:\$\$PaymentMethod
```

### 5. Company with Deep Nesting
```bash
zorphy create -n Company \
  --field companyId:String \
  --field address:\$CompanyAddress \
  --field departments:List<\$Department>

zorphy create -n CompanyAddress \
  --field street:String \
  --field location:\$GeoLocation?

zorphy create -n GeoLocation \
  --field latitude:double \
  --field longitude:double

zorphy create -n Department \
  --field manager:\$Employee \
  --field members:List<\$Employee>

zorphy create -n Employee \
  --field contactInfo:\$ContactInfo

zorphy create -n ContactInfo \
  --field email:String?
```

## Type Syntax Guide

| Pattern | Syntax | Example |
|---------|--------|---------|
| Basic | `Type` | `String` |
| Nullable basic | `Type?` | `String?` |
| Nested Zorphy | `$TypeName` | `$Address` |
| Nullable nested | `$TypeName?` | `$Address?` |
| List nested | `List<$TypeName>` | `List<$Item>` |
| List nullable items | `List<$TypeName?>` | `List<$Item?>` |
| Map nested value | `Map<K, $V>` | `Map<String, $User>` |
| Polymorphic | `$$TypeName` | `$$PaymentMethod` |
| Nullable polymorphic | `$$TypeName?` | `$$PaymentMethod?` |
| List polymorphic | `List<$$TypeName>` | `List<$$PaymentMethod>` |
| Map polymorphic value | `Map<K, $$V>` | `Map<String, $$PaymentMethod>` |

## Testing Checklist

```bash
# Run tests
./test_cli_nested_objects.sh

# Or manually test
zorphy create -n TestUser --field address:\$Address
zorphy create -n TestAddress --field street:String
zorphy build

# Verify
cat lib/entities/testuser.dart | grep "get address"
# Should see: $Address get address;
```

## Common Issues

### Issue: Type not found
```bash
# ❌ Wrong (referenced before created)
zorphy create -n User --field address:\$Address
zorphy create -n Address --field street:String

# ✅ Correct (create dependencies first)
zorphy create -n Address --field street:String
zorphy create -n User --field address:\$Address
```

### Issue: Build errors
```bash
# Clean and rebuild
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

### Issue: Wrong prefix
```bash
# ❌ Wrong
--field payment:$PaymentMethod  # Missing $ for sealed

# ✅ Correct
--field payment:$$PaymentMethod  # $$ for sealed/polymorphic
```

## Quick Verification

```bash
# List all entities
zorphy list -o lib/entities

# Check specific entity
cat lib/entities/entityname.dart | grep "get "

# Build all
zorphy build

# Run tests
./test_cli_nested_objects.sh
```

## Real-World Example

```bash
# E-commerce system
# 1. Create base entities
zorphy create -n User --field userId:String --field email:String
zorphy create -n Address --field street:String --field city:String
zorphy create -n Product --field productId:String --field name:String

# 2. Create composite entities
zorphy create -n Order \
  --field orderId:String \
  --field user:\$User \
  --field shippingAddress:\$Address \
  --field items:List<\$OrderItem> \
  --field total:double

zorphy create -n OrderItem \
  --field productId:String \
  --field product:\$Product \
  --field quantity:int \
  --field unitPrice:double

# 3. Build and test
zorphy build
zorphy list
```

## Tips

1. **Create dependencies first** - Create nested/child entities before parents
2. **Use proper prefixes** - `$` for concrete, `$$` for sealed/polymorphic
3. **Test incrementally** - Build after each group of entities
4. **Check generated files** - Verify syntax in `.zorphy.dart` files
5. **Use list command** - `zorphy list` to see all entities

## Support

- Full guide: `CLI_TESTING_GUIDE.md`
- Nested objects: `NESTED_OBJECTS_GUIDE.md`
- MCP usage: `CLI_MCP_NESTED_GUIDE.md`
- Main docs: `README.md`

🚀 **You're ready to use nested Zorphy objects via CLI!**
