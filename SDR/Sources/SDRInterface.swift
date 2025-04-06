import Foundation
import SoapySDR
// import rtl_sdr

public class SDRInterface {
    private var device: OpaquePointer?
    private var stream: OpaquePointer?
    private var isRunning: Bool = false
    private var currentSampleRate: Double = 2400000.0
    
    public enum SDRError: Error {
        case deviceCreationFailed
        case streamSetupFailed
        case streamActivationFailed
        case streamDeactivationFailed
        case streamCloseFailed
        case readFailed
        case frequencySetFailed
        case sampleRateSetFailed
        case gainSetFailed
        case enumerationFailed
    }
    
    public struct DeviceInfo: Hashable, Equatable {
        public let driver: String
        public let label: String
        public let serial: String
        
        public static func == (lhs: DeviceInfo, rhs: DeviceInfo) -> Bool {
            return lhs.serial == rhs.serial
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(serial)
        }
    }
    
    // Helper function to convert Swift string to C string
    private static func withCString<T>(_ string: String, _ body: (UnsafePointer<CChar>) throws -> T) rethrows -> T {
        return try string.withCString(body)
    }
    
    // Helper function to get value from kwargs
    private static func getKwargsValue(_ kwargs: UnsafePointer<SoapySDRKwargs>, _ key: String) -> String {
        return withCString(key) { cKey in
            if let value = SoapySDRKwargs_get(kwargs, cKey) {
                return String(cString: value)
            }
            return ""
        }
    }
    
    public static func enumerateDevices() throws -> [DeviceInfo] {
        var devices: [DeviceInfo] = []
        
        do {
            // Create empty kwargs for enumeration
            var kwargs = SoapySDRKwargs()
            kwargs.keys = nil
            kwargs.vals = nil
            
            // Get the number of devices
            var length: size_t = 0
            let results = SoapySDRDevice_enumerate(&kwargs, &length)
            if results == nil {
                throw SDRError.enumerationFailed
            }
            
            // Convert results to Swift array
            for i in 0..<length {
                if var result = results?[i] {
                    // Get values from kwargs using helper function
                    let driver = getKwargsValue(&result, "driver")
                    let label = getKwargsValue(&result, "label")
                    let serial = getKwargsValue(&result, "serial")
                    
                    devices.append(DeviceInfo(driver: driver, label: label, serial: serial))
                    
                }
            }
            
            // Ensure results is properly managed
            if let results = results {
                SoapySDRKwargsList_clear(results, length)
            }
        } catch {
            print("Error during device enumeration: \(error)")
            throw SDRError.enumerationFailed
        }
        
        return devices
    }
    
    public init() {
        // No initialization needed
    }
    
    deinit {
        stop()
    }
    
    public func openDevice(args: String) throws {
        // Convert args to kwargs
        var kwargs = SoapySDRKwargs()
        args.withCString { cArgs in
            kwargs = SoapySDRKwargs_fromString(cArgs)
        }
        
        // Create device with kwargs
        guard let device = SoapySDRDevice_make(&kwargs) else {
            SoapySDRKwargs_clear(&kwargs)
            throw SDRError.deviceCreationFailed
        }
        
        // Clean up kwargs
        SoapySDRKwargs_clear(&kwargs)
        
        self.device = device
    }
    
    public func closeDevice() {
        if let device = device {
            _ = SoapySDRDevice_unmake(device)
            self.device = nil
        }
    }
    
    public func setupStream(direction: Int32, format: String, channels: [Int], args: String?) throws {
        guard let device = device else {
            throw SDRError.streamSetupFailed
        }
        
        // Convert format to C string
        let formatPtr = format.withCString { cFormat in
            return cFormat
        }
        
        // Convert channels to C array
        let channelsPtr = channels.map { Int($0) }
        
        // Convert args to kwargs if provided
        var kwargs: SoapySDRKwargs?
        if let args = args {
            kwargs = args.withCString { cArgs in
                return SoapySDRKwargs_fromString(cArgs)
            }
        }
        
        // Setup stream
        var mutableKwargs = kwargs!
        guard let stream = SoapySDRDevice_setupStream(device, direction, formatPtr, channelsPtr, channelsPtr.count, &mutableKwargs) else {
            if var kwargs = kwargs {
                SoapySDRKwargs_clear(&kwargs)
            }
            throw SDRError.streamSetupFailed
        }
        
        // Clean up kwargs if used
        if var kwargs = kwargs {
            SoapySDRKwargs_clear(&kwargs)
        }
        
        self.stream = stream
    }
    
    public func activateStream() throws {
        guard let stream = stream else {
            throw SDRError.streamActivationFailed
        }
        
        let result = SoapySDRDevice_activateStream(device, stream, 0, 0, 0)
        if result != 0 {
            throw SDRError.streamActivationFailed
        }
    }
    
    public func deactivateStream() throws {
        guard let stream = stream else {
            throw SDRError.streamDeactivationFailed
        }
        
        let result = SoapySDRDevice_deactivateStream(device, stream, 0, 0)
        if result != 0 {
            throw SDRError.streamDeactivationFailed
        }
    }
    
    public func closeStream() throws {
        guard let stream = stream else {
            throw SDRError.streamCloseFailed
        }
        
        let result = SoapySDRDevice_closeStream(device, stream)
        if result != 0 {
            throw SDRError.streamCloseFailed
        }
        self.stream = nil
    }
    
    public func setFrequency(_ frequency: Double, direction: Int32, channel: Int) throws {
        guard let device = device else {
            throw SDRError.deviceCreationFailed
        }
        
        let result = SoapySDRDevice_setFrequency(device, direction, channel, frequency, nil)
        if result != 0 {
            throw SDRError.frequencySetFailed
        }
    }
    
    public func setSampleRate(_ rate: Double, direction: Int32, channel: Int) throws {
        guard let device = device else {
            throw SDRError.deviceCreationFailed
        }
        
        let result = SoapySDRDevice_setSampleRate(device, direction, channel, rate)
        if result != 0 {
            throw SDRError.sampleRateSetFailed
        }
        currentSampleRate = rate
    }
    
    public func setGain(_ gain: Double, direction: Int32, channel: Int) throws {
        guard let device = device else {
            throw SDRError.deviceCreationFailed
        }
        
        let result = SoapySDRDevice_setGain(device, direction, channel, gain)
        if result != 0 {
            throw SDRError.gainSetFailed
        }
    }
    
    public func readStream(buffers: UnsafeMutablePointer<UnsafeMutableRawPointer?>, numElements: Int, timeoutUs: Int) throws -> (Int32, Int32) {
        guard let stream = stream else {
            throw SDRError.readFailed
        }
        
        var flags: Int32 = 0
        var timeNs: Int64 = 0
        
        let result = SoapySDRDevice_readStream(device, stream, buffers, numElements, &flags, &timeNs, timeoutUs)
        if result < 0 {
            throw SDRError.readFailed
        }
        
        return (result, flags)
    }
    
    public func read(numElements: Int, timeoutUs: Int = 1000000) throws -> [Float] {
        guard let stream = stream else {
            throw SDRError.deviceCreationFailed
        }
        
        let bufferSize = 1024 * 1024
        var buffer = [ComplexFloat](repeating: ComplexFloat(), count: bufferSize)
        var flags: Int32 = 0
        var timeNs: Int64 = 0
        
        let result = buffer.withUnsafeMutableBufferPointer { bufferPtr in
            let ptr = UnsafeMutableRawPointer(bufferPtr.baseAddress)
            var ptrs: [UnsafeMutableRawPointer?] = [ptr]
            return SoapySDRDevice_readStream(device, stream, &ptrs, numElements, &flags, &timeNs, timeoutUs)
        }
        
        guard result >= 0 else {
            throw SDRError.readFailed
        }
        
        if flags & SoapySDR.SOAPY_SDR_END_ABRUPT != 0 {
            print("Overflow detected")
        }
        
        // Convert complex samples to real samples (I component only)
        return buffer[..<Int(result)].map { $0.real }
    }
    
    public var sampleRate: Double {
        return currentSampleRate
    }
    
    public func start(deviceInfo: DeviceInfo, frequency: Double, sampleRate: Double) throws {
        
        try openDevice(args: deviceInfo.driver)
        
        print("Start SDRInterface with device: \(deviceInfo.label)")

        // Configure device
        let result = SoapySDRDevice_setFrequency(self.device, Int32(SoapySDR.SOAPY_SDR_RX), 0, frequency, nil)
        guard result == 0 else {
            throw SDRError.frequencySetFailed
        }
        
        let sampleResult = SoapySDRDevice_setSampleRate(self.device, Int32(SoapySDR.SOAPY_SDR_RX), 0, sampleRate)
        guard sampleResult == 0 else {
            throw SDRError.sampleRateSetFailed
        }
        
        let gainResult = SoapySDRDevice_setGain(self.device, Int32(SoapySDR.SOAPY_SDR_RX), 0, 20.0)
        guard gainResult == 0 else {
            throw SDRError.gainSetFailed
        }
        
        // Setup stream
        let channels: [Int] = [0]
        let streamResult = channels.withUnsafeBufferPointer { channelsPtr in
            SoapySDRDevice_setupStream(self.device, Int32(SoapySDR.SOAPY_SDR_RX), SoapySDR.SOAPY_SDR_CF32, channelsPtr.baseAddress, 1, nil)
        }
        guard let stream = streamResult else {
            throw SDRError.streamSetupFailed
        }
        self.stream = stream
        
        // Activate stream
        let activateResult = SoapySDRDevice_activateStream(self.device, stream, 0, 0, 0)
        guard activateResult == 0 else {
            throw SDRError.streamActivationFailed
        }
        
        isRunning = true
        currentSampleRate = sampleRate
    }
    
    public func stop() {
        if let stream = stream {
            _ = SoapySDRDevice_deactivateStream(device, stream, 0, 0)
            _ = SoapySDRDevice_closeStream(device, stream)
        }
        if let device = device {
            SoapySDRDevice_unmake(device)
        }
        device = nil
        stream = nil
        isRunning = false
    }
}

enum SDRError: Error {
    case deviceNotInitialized
    case deviceError(String)
} 

