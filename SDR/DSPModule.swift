import Foundation
import Accelerate

public enum DemodulationMode {
    case fm
    case am
}

public class DSPModule {
    private let sampleRate: Double
    private let mode: DemodulationMode
    
    // For FM demodulation
    private var previousIQ: SIMD2<Float>?
    
    // For AM demodulation
    private var amFilter: [Float]?
    private let amFilterLength = 65 // FIR filter length for AM demodulation
    
    public init(sampleRate: Double, mode: DemodulationMode) {
        self.sampleRate = sampleRate
        self.mode = mode
        
        if mode == .am {
            setupAMFilter()
        }
    }
    
    private func setupAMFilter() {
        // Create a low-pass filter for AM demodulation
        // Cutoff frequency of 5kHz (typical for AM audio)
        let cutoffFreq = 5000.0 / sampleRate
        amFilter = createLowPassFIRFilter(length: amFilterLength, cutoff: cutoffFreq)
    }
    
    private func createLowPassFIRFilter(length: Int, cutoff: Double) -> [Float] {
        var filter = [Float](repeating: 0, count: length)
        let center = length / 2
        
        for i in 0..<length {
            let x = Double(i - center)
            if x == 0 {
                filter[i] = Float(2 * cutoff)
            } else {
                filter[i] = Float(sin(2 * .pi * cutoff * x) / (.pi * x))
            }
        }
        
        // Apply Hamming window
        var window = [Float](repeating: 0, count: length)
        vDSP_hamm_window(&window, vDSP_Length(length), 0)
        vDSP_vmul(filter, 1, window, 1, &filter, 1, vDSP_Length(length))
        
        return filter
    }
    
    public func demodulate(samples: [Float]) -> [Float] {
        switch mode {
        case .fm:
            return demodulateFM(samples: samples)
        case .am:
            return demodulateAM(samples: samples)
        }
    }
    
    private func demodulateFM(samples: [Float]) -> [Float] {
        var output = [Float](repeating: 0, count: samples.count / 2)
        var currentIQ: SIMD2<Float>
        
        for i in stride(from: 0, to: samples.count, by: 2) {
            currentIQ = SIMD2<Float>(samples[i], samples[i + 1])
            
            if let prevIQ = previousIQ {
                // FM demodulation using arctangent method
                let real = prevIQ.x * currentIQ.x + prevIQ.y * currentIQ.y
                let imag = prevIQ.y * currentIQ.x - prevIQ.x * currentIQ.y
                output[i/2] = atan2(imag, real)
            }
            
            previousIQ = currentIQ
        }
        
        // Normalize output to [-1, 1]
        var min: Float = 0
        var max: Float = 0
        vDSP_minv(output, 1, &min, vDSP_Length(output.count))
        vDSP_maxv(output, 1, &max, vDSP_Length(output.count))
        
        let scale = 1.0 / max(abs(min), abs(max))
        vDSP_vsmul(output, 1, &scale, &output, 1, vDSP_Length(output.count))
        
        return output
    }
    
    private func demodulateAM(samples: [Float]) -> [Float] {
        var output = [Float](repeating: 0, count: samples.count / 2)
        
        // Calculate magnitude (envelope) of I/Q samples
        for i in stride(from: 0, to: samples.count, by: 2) {
            let iSample = samples[i]
            let qSample = samples[i + 1]
            output[i/2] = sqrt(iSample * iSample + qSample * qSample)
        }
        
        // Apply low-pass filter to remove carrier
        if let filter = amFilter {
            var filtered = [Float](repeating: 0, count: output.count)
            vDSP_conv(output, 1, filter, 1, &filtered, 1, vDSP_Length(output.count), vDSP_Length(filter.count))
            output = filtered
        }
        
        // Normalize output to [-1, 1]
        var min: Float = 0
        var max: Float = 0
        vDSP_minv(output, 1, &min, vDSP_Length(output.count))
        vDSP_maxv(output, 1, &max, vDSP_Length(output.count))
        
        let scale = 1.0 / max(abs(min), abs(max))
        vDSP_vsmul(output, 1, &scale, &output, 1, vDSP_Length(output.count))
        
        return output
    }
} 