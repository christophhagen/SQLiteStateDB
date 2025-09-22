
extension Optional {

    func asResult<T>() -> T {
        self as! T
    }
}
