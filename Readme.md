# SQLite State Database

This repository provides an implementation for a [StateModel](https://github.com/christophhagen/StateModel) database based on SQLite, with [key paths](https://github.com/christophhagen/StateModel#database-definition) that can be represented as SQLite values.
It can be used as a simple storage solution for mobile devices.

Integrate this package like you would any other:

```
...
    dependencies: [
        .package(url: "https://github.com/christophhagen/SQLiteStateDB", from: "6.0.0")
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
The library provides different implementations depending on the feature set required.
`SQLiteDatabase` offers basic value storage and conforms to `Database`, while `SQLiteTimestampedDatabase` also stores the last modified timestamp for each property, but no historic values.
For features like `HistoryView`, use a `SQLiteHistoryDatabase` instead.

### Encoder and Decoder

The SQLite database stores natively supported types in separate tables, e.g. all integer values are stored in a table with an `INTEGER` column.
For types that can't be natively represented, each value is encoded to binary data before insertion.
For these operations you need to supply an encoder and decoder, which are provided to the initializer:
```swift
SQLiteDatabase(file: URL, encoder: any GenericEncoder, decoder: any GenericDecoder)
```

The `GenericEncoder` and `GenericDecoder` protocols are defined by the `StateModel` library, and a few basic encoders can be used directly. 

#### `JSONEncoder` and `JSONDecoder`

Since the `Foundation` module already provides [JSONEncoder](https://developer.apple.com/documentation/foundation/jsonencoder) and [JSONDecoder](https://developer.apple.com/documentation/foundation/jsondecoder), you can simply use those:

```swift
let database = MyDatabase(encoder: JSONEncoder(), decoder: JSONDecoder())
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

### Caching

To improve query times for repeated access to the same properties, it is recommended to perform caching.
`StateModel` already provides a `CachedDatabase` wrapper, that can be used with `SQLiteDatabase`.
You can use the provided caches, or implement your own `DatabaseCache`.
