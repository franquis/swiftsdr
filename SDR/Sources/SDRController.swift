import Foundation
import Accelerate

public class SDRController {
    private let sdrInterface: SDRInterface
    private let dspModule: DSPModule
    private let audioOutput: AudioOutput
    
    private var fftSetup: FFTSetup?
    private let log2n: UInt
    private let n: Int
    private let halfN: Int
    
    @Published public var signalStrength: Float = 0
    @Published public var audioLevel: Float = 0
    @Published public var spectrumData: [Float] = []
    
    public init() {
        sdrInterface = SDRInterface()
        dspModule = DSPModule(fftSize: 1024)
        audioOutput = AudioOutput()
        
        // Initialize FFT
        log2n = UInt(log2(Double(1024)))
        n = 1024
        halfN = n / 2
        fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2))
        
        setupFFT()
    }
    
    deinit {
        if let fftSetup = fftSetup {
            vDSP_destroy_fftsetup(fftSetup)
        }
    }
    
    private func setupFFT() {
        spectrumData = [Float](repeating: 0, count: n)
    }
    
    private func calculateSignalStrength(samples: [Float]) -> Float {
        var sum: Float = 0
        vDSP_sve(samples, 1, &sum, vDSP_Length(samples.count))
        return sum / Float(samples.count)
    }
    
    private func calculateAudioLevel(samples: [Float]) -> Float {
        var rms: Float = 0
        vDSP_rmsqv(samples, 1, &rms, vDSP_Length(samples.count))
        return rms
    }
    
    private func calculateSpectrum(samples: [Float]) {
        var realp = [Float](repeating: 0, count: n)
        var imagp = [Float](repeating: 0, count: n)
        
        // Copy input samples to real part
        realp = Array(samples.prefix(n))
        
        // Create split complex buffer
        realp.withUnsafeMutableBufferPointer { realpPtr in
            imagp.withUnsafeMutableBufferPointer { imagpPtr in
                var splitComplex = DSPSplitComplex(realp: realpPtr.baseAddress!, imagp: imagpPtr.baseAddress!)
                
                // Perform FFT
                vDSP_fft_zrip(fftSetup!, &splitComplex, 1, log2n, FFTDirection(kFFTDirection_Forward))
                
                // Calculate magnitude spectrum
                vDSP_zvmags(&splitComplex, 1, &spectrumData, 1, vDSP_Length(n))
                
                // Convert to dB scale
                var scale = Float(1.0)
                vDSP_vdbcon(spectrumData, 1, &scale, &spectrumData, 1, vDSP_Length(n), 1)
            }
        }
    }
    
    public func start(device: SDRInterface.DeviceInfo, frequency: Double, sampleRate: Double) throws {
        print("Starting SDRController with device: \(device.label)")
        let enable_demod = false

        try sdrInterface.start(deviceInfo: device, frequency: frequency, sampleRate: sampleRate)

        // Start processing loop
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            while true {
                guard let self = self else { break }
                
                do {
                    let samples = try self.sdrInterface.read(numElements: 1024)

                    // Calculate signal metrics
                    self.signalStrength = self.calculateSignalStrength(samples: samples)
                    
                    // print("Signal strength: \(self.signalStrength)")
                    if enable_demod {
                        // Process samples
                        let demodulated = self.dspModule.demodulate(samples: samples, mode: .am)
                        
                        // Calculate audio level
                        self.audioLevel = self.calculateAudioLevel(samples: demodulated)

                        // Output audio
                    
                        self.audioOutput.play(samples: demodulated)
                    }
                    
                    // Calculate spectrum
                    if samples.count >= self.n {
                        self.calculateSpectrum(samples: samples)
                    } else {
                        print("Insufficient samples for spectrum calculation, received \(samples.count) samples")
                    }
                    
                    
                } catch {
                    print("Error processing samples: \(error)")
                    break
                }
            }
        }
    }
    
    public func stop() {
        sdrInterface.stop()
        audioOutput.stop()
    }
    
    public func setFrequency(_ frequency: Double) throws {
        try sdrInterface.setFrequency(frequency, direction: 0, channel: 0)
    }
    
    public func setBaseFrequency(_ frequency: Double) throws {
        // Implementation needed
        throw SDRError.deviceError("Base frequency setting not implemented")
    }
    
    public func setSampleRate(_ sampleRate: Double) throws {
        try sdrInterface.setSampleRate(sampleRate, direction: 0, channel: 0)
    }
    
    public func setGain(_ gain: Double) throws {
        try sdrInterface.setGain(gain, direction: 0, channel: 0)
    }
    
    public func onSignalStrengthUpdate(_ strengh: Float) {
        // 
    }
    
    public func setBandwidth(_ bandwidth: Double) throws {
        // Implementation needed
        throw SDRError.deviceError("Bandwidth setting not implemented")
    }
    
    func setMode(_ mode: DemodulationMode) {
        // Mode is handled in demodulate function
    }
    
    public func onAudioLevelUpdate(_ level: Float) {
        // 
    }
    
    public static func enumerateDevices() throws -> [SDRInterface.DeviceInfo] {
        return try SDRInterface.enumerateDevices()
    }
}
