@available(iOS 13.0, *)
public struct MyNedapSDK {
    public private(set) var text = "Hello, World!"
    
    private var bleViewController : BleViewController
    
    public init(bleViewController:BleViewController) {
        self.bleViewController = bleViewController
    }
    
    public func getBleController () -> BleViewController {
        return bleViewController
    }
}
