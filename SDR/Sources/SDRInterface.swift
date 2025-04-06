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
    }
    
    public init() {
        // No initialization needed
    }
    
    deinit {
        stop()
    }
    
    public func openDevice(args: String) throws {
        // Convert args to C string
        guard let device = args.withCString({ cArgs in
            SoapySDRDevice_make(nil)  // Using nil for now since we need to create SoapySDRKwargs
        }) else {
            throw SDRError.deviceCreationFailed
        }
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
            throw SDRError.deviceCreationFailed
        }
        
        let channelsCount = channels.count
        let channelsPtr = UnsafeMutablePointer<Int>.allocate(capacity: channelsCount)
        defer { channelsPtr.deallocate() }
        
        for (index, channel) in channels.enumerated() {
            channelsPtr[index] = channel
        }
        
        guard let stream = format.withCString({ cFormat in
            SoapySDRDevice_setupStream(device, direction, cFormat, nil, 0, nil)
        }) else {
            throw SDRError.streamSetupFailed
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
            var ptrs = [ptr]
            return SoapySDRDevice_readStream(device, stream, buffer, numElements, &flags, &timeNs, timeoutUs)
        }
        
        guard result >= 0 else {
            throw SDRError.readFailed
        }
        
        if flags & Int32(SoapySDR.SOAPY_SDR_OVERFLOW) != 0 {
            print("Overflow detected")
        }
        
        // Convert complex samples to real samples (I component only)
        return buffer.map { $0.real }
    }
    
    public var sampleRate: Double {
        return currentSampleRate
    }
    
    public func start(deviceString: String = "rtlsdr", frequency: Double, sampleRate: Double) throws {
        // Find device
        var keys: [UnsafeMutablePointer<CChar>?] = [strdup("driver"), nil]
        var vals: [UnsafeMutablePointer<CChar>?] = [strdup(deviceString), nil]

        var kwargs = SoapySDRKwargs()
        kwargs.keys = &keys
        kwargs.vals = &vals

        let newDevice = SoapySDRDevice_make(&kwargs)

        // Libérer la mémoire (strdup → free)
        free(keys[0])
        free(vals[0])
        device = newDevice
        
        // Configure device
        let result = SoapySDRDevice_setFrequency(device, Int32(SoapySDR.SOAPY_SDR_RX), 0, frequency, nil)
        guard result == 0 else {
            throw SDRError.frequencySetFailed
        }
        
        let sampleResult = SoapySDRDevice_setSampleRate(device, Int32(SoapySDR.SOAPY_SDR_RX), 0, sampleRate)
        guard sampleResult == 0 else {
            throw SDRError.sampleRateSetFailed
        }
        
        let gainResult = SoapySDRDevice_setGain(device, Int32(SoapySDR.SOAPY_SDR_RX), 0, 20.0)
        guard gainResult == 0 else {
            throw SDRError.gainSetFailed
        }
        
        // Setup stream
        var newStream: OpaquePointer?
        let channels: [Int] = [0]
        let streamResult = channels.withUnsafeBufferPointer { channelsPtr in
            SoapySDRDevice_setupStream(device, Int32(SoapySDR.SOAPY_SDR_RX), SOAPY_SDR_CF32, channelsPtr.baseAddress, 1, nil)
        }
        guard streamResult == 0, let stream = newStream else {
            throw SDRError.streamSetupFailed
        }
        self.stream = stream
        
        // Activate stream
        let activateResult = SoapySDRDevice_activateStream(device, stream, 0, 0, 0)
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

