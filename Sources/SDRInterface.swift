import Foundation
import SoapySDR
import rtl_sdr

public class SDRInterface {
    private var device: SoapySDRDevice?
    private var isRunning = false
    private var processingQueue = DispatchQueue(label: "com.sdr.interface", qos: .userInitiated)
    private var stream: SoapySDRStream?
    private var currentSampleRate: Double = 2400000.0
    
    public init() throws {
        // Initialize SoapySDR device
    public init() {
        // Initialize SoapySDR
        SoapySDR.initialize()
    }
    
    deinit {
        stop()
        SoapySDR.deinitialize()
    }
    
    public func start(frequency: Double, sampleRate: Double) throws {
        // Find RTL-SDR device
        let args = SoapySDR.DeviceArgs()
        args.driver = "rtlsdr"
        
        device = try SoapySDR.Device(args)
        
        // Configure device
        try device?.setSampleRate(SoapySDR.SOAPY_SDR_RX, 0, sampleRate)
        try device?.setFrequency(SoapySDR.SOAPY_SDR_RX, 0, frequency)
        
        // Setup stream
        let format = SoapySDR.StreamFormat.CF32
        stream = try device?.setupStream(SoapySDR.SOAPY_SDR_RX, format, [0])
        
        // Start streaming
        try stream?.activate()
        isRunning = true
        currentSampleRate = sampleRate
    }
    
    public func stop() {
        if isRunning {
            try? stream?.deactivate()
            try? stream?.close()
            device = nil
            isRunning = false
        }
    }
    
    public func readSamples(bufferSize: Int) throws -> [Float] {
        guard isRunning else {
            throw NSError(domain: "SDRInterface", code: 1, userInfo: [NSLocalizedDescriptionKey: "SDR is not running"])
        }
        
        var buffer = [Float](repeating: 0, count: bufferSize * 2) // I and Q samples
        var flags: Int32 = 0
        let timestamp = try stream?.read(&buffer, bufferSize, &flags, 1000000)
        
        return buffer
    }
    
    public func setFrequency(_ frequency: Double) throws {
        guard let device = device else {
            throw NSError(domain: "SDRInterface", code: 2, userInfo: [NSLocalizedDescriptionKey: "Device not initialized"])
        }
        try device.setFrequency(SoapySDR.SOAPY_SDR_RX, 0, frequency)
    }
    
    public func setSampleRate(_ sampleRate: Double) throws {
        guard let device = device else {
            throw NSError(domain: "SDRInterface", code: 2, userInfo: [NSLocalizedDescriptionKey: "Device not initialized"])
        }
        try device.setSampleRate(SoapySDR.SOAPY_SDR_RX, 0, sampleRate)
        currentSampleRate = sampleRate
    }
    
    public func setGain(_ gain: Double) throws {
        guard let device = device else {
            throw NSError(domain: "SDRInterface", code: 2, userInfo: [NSLocalizedDescriptionKey: "Device not initialized"])
        }
        try device.setGain(SoapySDR.SOAPY_SDR_RX, 0, gain)
    }
    
    public var sampleRate: Double {
        return currentSampleRate
    }
} 