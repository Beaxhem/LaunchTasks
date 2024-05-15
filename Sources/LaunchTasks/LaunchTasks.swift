import Foundation

public protocol LaunchTask: AnyObject {
    var next: LaunchTask? { get set }

    func handle()
    func finish()
}

extension LaunchTask {

    @discardableResult
    public func then(_ task: LaunchTask) -> LaunchTask {
        self.next = task
        return task
    }

    public func finish() {
        self.next?.handle()
    }

}

public class AsyncLaunchTask: @unchecked Sendable, LaunchTask {

    public typealias DismissAction = @Sendable () -> Void

    public var next: LaunchTask?

    let task: (@escaping DismissAction) -> Void

    public init(task: @escaping (@escaping DismissAction) -> Void) {
        self.task = task
    }

    public func handle() {
        task { [self] in
            self.finish()
        }
    }

}

public class UserDefaultsObservingLaunchTask<T>: AsyncLaunchTask {

    let userDefaults: UserDefaults
    let key: String
    let filter: (T?) -> Bool
    let update: () -> T?

    public init(
        userDefaults: UserDefaults = .standard,
        key: String,
        filter: @escaping (T?) -> Bool,
        task: @escaping (@escaping DismissAction) -> Void,
        update: @escaping @autoclosure () -> T?
    ) {
        self.userDefaults = userDefaults
        self.key = key
        self.filter = filter
        self.update = update
        super.init(task: task)
    }

    public override func handle() {
        let value = userDefaults.value(forKey: key) as? T
        guard filter(value) else {
            return finish()
        }
        super.handle()

        let newSetting = update()
        userDefaults.setValue(newSetting, forKey: key)
    }

}
