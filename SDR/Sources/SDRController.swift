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
    
    public func start() {
        do {
            try sdrInterface.start(frequency: 100.0e6, sampleRate: 2.4e6)
            
            // Start processing loop
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                while true {
                    guard let self = self else { break }
                    
                    do {
                        let samples = try self.sdrInterface.read()
                        
                        // Calculate signal metrics
                        self.signalStrength = self.calculateSignalStrength(samples: samples)
                        
                        // Process samples
                        let demodulated = self.dspModule.demodulate(samples: samples, mode: .am)
                        
                        // Calculate audio level
                        self.audioLevel = self.calculateAudioLevel(samples: demodulated)
                        
                        // Calculate spectrum
                        self.calculateSpectrum(samples: samples)
                        
                        // Output audio
                        self.audioOutput.play(samples: demodulated)
                    } catch {
                        print("Error processing samples: \(error)")
                        break
                    }
                }
            }
        } catch {
            print("Error starting SDR: \(error)")
        }
    }
    
    public func stop() {
        sdrInterface.stop()
        audioOutput.stop()
    }
    
    public func setFrequency(_ frequency: Double) {
        try? sdrInterface.setFrequency(frequency)
    }
    
    public func setBaseFrequency(_ frequency: Double) {
        //
    }
    
    public func setSampleRate(_ sampleRate: Double) {
        try? sdrInterface.setSampleRate(sampleRate)
    }
    
    public func setGain(_ gain: Double) {
        try? sdrInterface.setGain(gain)
    }
    
    public func onSignalStrengthUpdate(_ strengh: Float) {
        // 
    }
    
    public func setBandwidth(_ bandwith: Double) {
        //
    }
    
    func setMode(_ mode: DemodulationMode) {
        // Mode is handled in demodulate function
    }
    
    public func onAudioLevelUpdate(_ level: Float) {
        // 
    }
}
