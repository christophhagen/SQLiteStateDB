# SQLite State Database

This repository provides an implementation for a [StateModel](https://github.com/christophhagen/StateModel) database based on SQLite, with integer [key paths](https://github.com/christophhagen/StateModel#database-definition).
It can be used as a simple storage solution for mobile devices.

Integrate this package like you would any other:

```
...
    dependencies: [
        .package(url: "https://github.com/christophhagen/SQLiteStateDB", from: "1.0.0")
    ],
...
    .target(
        name: "MyTarget",
        dependencies: [
            .product(name: "SQLiteDB", package: "SQLiteStateDB")
        ]
    ),
...
```

## Usage

Consult the [StateModel Documentation](https://github.com/christophhagen/StateModel#database-definition) on how to define a model database.

### Path components

The current implementation of `SQLiteDatabase` only supports integer path components:
```swift
SQLiteDatabase.KeyPath: Path<Int, Int, Int>
```

> Future versions may support any path type component that can be natively represented in a SQLite column.

### Encoder and Decoder

The SQLite database stores natively supported types in separate tables, e.g. all integer values are stored in a table with an `INTEGER` column.
For types that can't be natively represented, each value is encoded to binary data before insertion.
For these operations you need to supply an encoder and decoder, as evident by the class singature:
```swift
SQLiteDatabase<Encoder: GenericEncoder, Decoder: GenericDecoder>
```

`GenericEncoder` and `GenericDecoder` are types that provide the required operations.
There are a few types that can readily be used.

#### `JSONEncoder` and `JSONDecoder`

Since the `Foundation` module already provides [JSONEncoder](https://developer.apple.com/documentation/foundation/jsonencoder) and [JSONDecoder](https://developer.apple.com/documentation/foundation/jsondecoder), you can simply use those:

```swift
SQLiteDatabase<JSONEncoder, JSONDecoder>
```

While encoding values as JSON is great for debugging, it is not recommended for production use, due to the inefficient encoding as a string.
Additionally, there is a bug with nested optionals that may produce unexpected behaviour:

```swift
let value: Int?? = .some(.none)
let encoded = try JSONEncoder().encode(value)
let decoded = try JSONDecoder().decode(Int??.self, from: encoded)
print(value == decoded) // Prints "false"
print(decoded) // Prints "nil"
```

Any `nil` value will be decoded as a top-level `nil`, even if nested in another optional.
You need to consider this behaviour if you want to use `JSONEncoder`.
Since `SQLiteDatabase` encodes optionals using SQLite `NULL` values, double optionals will still work correctly when used in properties:

```swift
@Property(id: 1)
var value: Int?? // Safe
```

More deeply nested optionals will not be decoded correctly (not sure where those would be needed).
Note that this behaviour also applies to `Codable` types:

```swift
struct MyType: Codable {
    var value: Int?? // Not consistent with `JSONEncoder`
}
```

#### PropertyListEncoder

The Foundation module also supplies `PropertyListEncoder` for codable types, but it's very restricted in the types it can encode, so its use is not recommended.

#### BinaryCodable

There is an efficient encoder available for `Codable` types with [BinaryCodable](https://github.com/christophhagen/BinaryCodable/tree/master), which does not suffer from any known inconsistencies.
To use it, install the package and conform the classes to the required protocols:

```swift
import SQLiteDB
import BinaryCodable

extension BinaryEncoder: GenericEncoder { }
extension BinaryDecoder: GenericDecoder { }
```

### Database specification

You can define a typealias to substitute your chosen encoding types:
```swift
typealias MyDatabase = SQLiteDatabase<MyEncoder, MyDecoder>
```

Now you can continue to define your model types:

```swift
typealias MyModel = Model<Int, Int, Int>
```

With these definitions you are ready to [define your models](https://github.com/christophhagen/StateModel#model-definition):

```swift
final class User: MyModel {

    static let modelId = 1

    @Property(id: 42)
    var name: String
}
```

### Caching

There is an additional class `CachedSQLiteDatabase`, which can cache property values so that the database doesn't need to be queried as often.
It hase a generic cache type, which must conform to `SQLiteCache`.

You can either implement your own cache, or use one of:
- `AnyCache`: Very simple in memory cache with a maximum capacity and LRU eviction when full
- `BasicCache`: Simple caches for different SQLite types with individual sizes and LRU eviction
