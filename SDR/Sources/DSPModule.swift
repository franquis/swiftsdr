import Foundation
import Accelerate

enum DemodulationMode {
    case am
    case lsb
    case usb
    case fm
}

class DSPModule {
    private var fftSetup: FFTSetup?
    private let log2n: vDSP_Length
    private let n: Int
    private let halfN: Int
    
    init(fftSize: Int) {
        log2n = vDSP_Length(log2(Double(fftSize)))
        n = fftSize
        halfN = n / 2
        fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2))
    }
    
    deinit {
        if let setup = fftSetup {
            vDSP_destroy_fftsetup(setup)
        }
    }
    
    private func processFM(samples: [Float]) -> [Float] {
        // TODO
        return samples
    }
    
    private func processAM(samples: [Float]) -> [Float] {
        var output = [Float](repeating: 0, count: n)
        
        // Create separate buffers for FFT
        var fftReal = [Float](repeating: 0, count: n/2)
        var fftImag = [Float](repeating: 0, count: n/2)
        
        // Copy input samples to FFT buffer
        samples.withUnsafeBufferPointer { samplesPtr in
            fftReal.withUnsafeMutableBufferPointer { realpPtr in
                vDSP_mmov(samplesPtr.baseAddress!, realpPtr.baseAddress!, vDSP_Length(samples.count), 1, 1, vDSP_Length(n/2))
            }
        }
        
        // Perform FFT
        fftReal.withUnsafeMutableBufferPointer { realpPtr in
            fftImag.withUnsafeMutableBufferPointer { imagpPtr in
                var splitComplex = DSPSplitComplex(realp: realpPtr.baseAddress!, imagp: imagpPtr.baseAddress!)
                vDSP_fft_zrip(fftSetup!, &splitComplex, 1, log2n, FFTDirection(kFFTDirection_Forward))
                
                // Calculate magnitude
                vDSP_zvmags(&splitComplex, 1, &output, 1, vDSP_Length(n))
                
                // Scale the output
                var scale = Float(1.0) / Float(n)
                vDSP_vsmul(output, 1, &scale, &output, 1, vDSP_Length(output.count))
                
                // Normalize
                var min: Float = 0
                var max: Float = 0
                vDSP_minv(output, 1, &min, vDSP_Length(output.count))
                vDSP_maxv(output, 1, &max, vDSP_Length(output.count))
                
                scale = 1.0 / Swift.max(abs(min), abs(max))
                vDSP_vsmul(output, 1, &scale, &output, 1, vDSP_Length(output.count))
            }
        }
        
        return output
    }
    
    private func processSSB(samples: [Float], isLowerSideband: Bool) -> [Float] {
        var output = [Float](repeating: 0, count: n)
        
        // Create separate buffers for FFT
        var fftReal = [Float](repeating: 0, count: n/2)
        var fftImag = [Float](repeating: 0, count: n/2)
        
        // Copy input samples to FFT buffer
        samples.withUnsafeBufferPointer { samplesPtr in
            fftReal.withUnsafeMutableBufferPointer { realpPtr in
                vDSP_mmov(samplesPtr.baseAddress!, realpPtr.baseAddress!, vDSP_Length(samples.count), 1, 1, vDSP_Length(n/2))
            }
        }
        
        // Perform FFT
        fftReal.withUnsafeMutableBufferPointer { realpPtr in
            fftImag.withUnsafeMutableBufferPointer { imagpPtr in
                var splitComplex = DSPSplitComplex(realp: realpPtr.baseAddress!, imagp: imagpPtr.baseAddress!)
                vDSP_fft_zrip(fftSetup!, &splitComplex, 1, log2n, FFTDirection(kFFTDirection_Forward))
                
                // Create separate buffers for filtered data
                var filteredReal = [Float](repeating: 0, count: n/2)
                var filteredImag = [Float](repeating: 0, count: n/2)
                
                // Copy FFT data to filtered buffers
                vDSP_mmov(realpPtr.baseAddress!, &filteredReal, vDSP_Length(n/2), 1, 1, vDSP_Length(n/2))
                vDSP_mmov(imagpPtr.baseAddress!, &filteredImag, vDSP_Length(n/2), 1, 1, vDSP_Length(n/2))
                
                // Apply Hilbert transform and SSB filtering
                if isLowerSideband {
                    // For LSB, keep negative frequencies
                    for i in 0..<halfN {
                        filteredReal[i] = 0
                        filteredImag[i] = 0
                    }
                } else {
                    // For USB, keep positive frequencies
                    for i in halfN..<n {
                        filteredReal[i] = 0
                        filteredImag[i] = 0
                    }
                }
                
                // Create new split complex with filtered data
                filteredReal.withUnsafeMutableBufferPointer { filteredRealpPtr in
                    filteredImag.withUnsafeMutableBufferPointer { filteredImagpPtr in
                        var filteredSplitComplex = DSPSplitComplex(realp: filteredRealpPtr.baseAddress!, imagp: filteredImagpPtr.baseAddress!)
                        
                        // Perform inverse FFT
                        vDSP_fft_zrip(fftSetup!, &filteredSplitComplex, 1, log2n, FFTDirection(kFFTDirection_Inverse))
                        
                        // Take real part as output
                        vDSP_zvmags(&filteredSplitComplex, 1, &output, 1, vDSP_Length(n))
                        
                        // Scale the output
                        var scale = Float(1.0) / Float(n)
                        vDSP_vsmul(output, 1, &scale, &output, 1, vDSP_Length(output.count))
                        
                        // Normalize
                        var min: Float = 0
                        var max: Float = 0
                        vDSP_minv(output, 1, &min, vDSP_Length(output.count))
                        vDSP_maxv(output, 1, &max, vDSP_Length(output.count))
                        
                        scale = 1.0 / Swift.max(abs(min), abs(max))
                        vDSP_vsmul(output, 1, &scale, &output, 1, vDSP_Length(output.count))
                    }
                }
            }
        }
        
        return output
    }
    
    func demodulate(samples: [Float], mode: DemodulationMode) -> [Float] {
        switch mode {
            case .am:
                return processAM(samples: samples)
            case .lsb:
                return processSSB(samples: samples, isLowerSideband: true)
            case .usb:
                return processSSB(samples: samples, isLowerSideband: false)
            case .fm:
                return processFM(samples: samples)
        }
    }
} 
