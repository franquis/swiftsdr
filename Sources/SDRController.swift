import Foundation
import Accelerate

public class SDRController {
    private let sdrInterface: SDRInterface
    private let dspModule: DSPModule
    private let audioOutput: AudioOutput
    
    private var isRunning: Bool = false
    private let processingQueue = DispatchQueue(label: "com.sdr.processing", qos: .userInteractive)
    private let bufferSize: Int = 1024
    
    // Signal strength and audio level
    private var signalStrength: Float = 0.0
    private var audioLevel: Float = 0.0
    private var spectrumData: [Float] = []
    private let spectrumSize = 512 // FFT size
    
    // SDR parameters
    private var baseFrequency: Double = 100000000.0 // 100 MHz
    private var bandwidth: Double = 2400000.0 // 2.4 MHz
    private var gain: Double = 0.0 // 0 dB
    
    // Callbacks for UI updates
    public var onSignalStrengthUpdate: ((Float) -> Void)?
    public var onAudioLevelUpdate: ((Float) -> Void)?
    public var onSpectrumUpdate: (([Float]) -> Void)?
    
    public init(sampleRate: Double = 2400000.0,
                audioSampleRate: Double = 48000.0,
                frequency: Double = 100000000.0,
                mode: DemodulationMode = .fm) {
        
        // Initialize components
        sdrInterface = SDRInterface()
        dspModule = DSPModule(sampleRate: sampleRate, mode: mode)
        audioOutput = AudioOutput(sampleRate: audioSampleRate, bufferSize: bufferSize)
        
        // Setup FFT
        setupFFT()
        
        // Configure SDR
        do {
            try sdrInterface.start(frequency: frequency, sampleRate: sampleRate)
        } catch {
            print("Failed to initialize SDR: \(error)")
        }
    }
    
    private func setupFFT() {
        spectrumData = [Float](repeating: 0, count: spectrumSize)
    }
    
    private func calculateSignalStrength(samples: [Float]) -> Float {
        var sum: Float = 0
        var count: vDSP_Length = 0
        vDSP_sve(samples, 1, &sum, vDSP_Length(samples.count))
        return sum / Float(samples.count)
    }
    
    private func calculateAudioLevel(samples: [Float]) -> Float {
        var max: Float = 0
        vDSP_maxv(samples, 1, &max, vDSP_Length(samples.count))
        return max
    }
    
    private func calculateSpectrum(samples: [Float]) {
        // Prepare FFT
        let log2n = vDSP_Length(log2(Double(spectrumSize)))
        let fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2))
        
        // Create complex buffer
        var complexBuffer = [DSPComplex](repeating: DSPComplex(real: 0, imag: 0), count: spectrumSize)
        
        // Convert real samples to complex
        for i in 0..<min(samples.count, spectrumSize) {
            complexBuffer[i].real = samples[i]
        }
        
        // Perform FFT
        var splitComplex = DSPSplitComplex(realp: &complexBuffer.map { $0.real },
                                         imagp: &complexBuffer.map { $0.imag })
        vDSP_fft_zrip(fftSetup!, &splitComplex, 1, log2n, FFTDirection(kFFTDirection_Forward))
        
        // Calculate magnitude
        var magnitudes = [Float](repeating: 0, count: spectrumSize/2)
        vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(spectrumSize/2))
        
        // Convert to dB
        var zero: Float = 0
        vDSP_vdbcon(magnitudes, 1, &zero, &magnitudes, 1, vDSP_Length(spectrumSize/2), 1)
        
        // Update spectrum data
        DispatchQueue.main.async {
            self.spectrumData = magnitudes
            self.onSpectrumUpdate?(magnitudes)
        }
        
        // Cleanup
        vDSP_destroy_fftsetup(fftSetup)
    }
    
    public func start() throws {
        guard !isRunning else { return }
        
        try audioOutput.start()
        isRunning = true
        processingQueue.async { [weak self] in
            self?.processLoop()
        }
    }
    
    public func stop() {
        guard isRunning else { return }
        
        isRunning = false
        audioOutput.stop()
        sdrInterface.stop()
    }
    
    private func processLoop() {
        while isRunning {
            do {
                // Read samples from SDR
                let samples = try sdrInterface.readSamples(bufferSize: bufferSize)
                
                // Calculate signal strength
                signalStrength = calculateSignalStrength(samples: samples)
                DispatchQueue.main.async {
                    self.onSignalStrengthUpdate?(self.signalStrength)
                }
                
                // Calculate spectrum
                calculateSpectrum(samples: samples)
                
                // Demodulate samples
                let demodulated = dspModule.demodulate(samples: samples)
                
                // Calculate audio level
                audioLevel = calculateAudioLevel(samples: demodulated)
                DispatchQueue.main.async {
                    self.onAudioLevelUpdate?(self.audioLevel)
                }
                
                // Play audio
                audioOutput.playSamples(demodulated)
                
            } catch {
                print("Error in processing loop: \(error)")
                continue
            }
        }
    }
    
    public func setFrequency(_ frequency: Double) throws {
        try sdrInterface.start(frequency: frequency, sampleRate: sdrInterface.sampleRate)
    }
    
    public func setMode(_ mode: DemodulationMode) {
        dspModule.setMode(mode)
    }
    
    public func setBaseFrequency(_ frequency: Double) throws {
        baseFrequency = frequency
        try sdrInterface.setFrequency(frequency)
    }
    
    public func setBandwidth(_ newBandwidth: Double) throws {
        bandwidth = newBandwidth
        try sdrInterface.setSampleRate(newBandwidth)
    }
    
    public func setGain(_ newGain: Double) throws {
        gain = newGain
        try sdrInterface.setGain(newGain)
    }
    
    public func getBaseFrequency() -> Double {
        return baseFrequency
    }
    
    public func getBandwidth() -> Double {
        return bandwidth
    }
    
    public func getGain() -> Double {
        return gain
    }
    
    deinit {
        stop()
    }
} 