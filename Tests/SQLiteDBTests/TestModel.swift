import Foundation
import StateModel
import SQLiteDB

enum ModelId: Int {
    case testModel = 1
    case otherModel = 2
    case repeatedModel = 3
}

@Model(id: ModelId.testModel.rawValue)
final class TestModel {

    @Property(id: 1)
    var a: Int

    @Property(id: 2)
    var b: Int = -1

    @Reference(id: 3)
    var ref: NestedModel?

    @ReferenceList(id: 4)
    var list: [NestedModel]
}

@Model(id: ModelId.otherModel.rawValue)
final class NestedModel {

    @Property(id: 1)
    var some: Int
}

@Model(id: ModelId.repeatedModel.rawValue)
final class RepeatedModel {

    @Property(id: 1)
    var some: Int
}
