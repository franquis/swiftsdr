import XCTest
@testable import SDR

final class DSPModuleTests: XCTestCase {
    func testFMDemodulation() {
        let sampleRate = 2400000.0
        let dsp = DSPModule(sampleRate: sampleRate, mode: .fm)
        
        // Create a simple FM test signal (sine wave)
        let testSamples = createTestSignal(sampleRate: sampleRate, frequency: 1000.0, modulationIndex: 0.5)
        
        // Demodulate the signal
        let demodulated = dsp.demodulate(samples: testSamples)
        
        // Verify the output
        XCTAssertEqual(demodulated.count, testSamples.count / 2)
        XCTAssertGreaterThan(demodulated.max() ?? 0, 0)
        XCTAssertLessThan(demodulated.min() ?? 0, 0)
    }
    
    func testAMDemodulation() {
        let sampleRate = 2400000.0
        let dsp = DSPModule(sampleRate: sampleRate, mode: .am)
        
        // Create a simple AM test signal
        let testSamples = createAMTestSignal(sampleRate: sampleRate, carrierFreq: 1000000.0, modulationFreq: 1000.0, modulationIndex: 0.5)
        
        // Demodulate the signal
        let demodulated = dsp.demodulate(samples: testSamples)
        
        // Verify the output
        XCTAssertEqual(demodulated.count, testSamples.count / 2)
        XCTAssertGreaterThan(demodulated.max() ?? 0, 0)
        XCTAssertGreaterThanOrEqual(demodulated.min() ?? 0, 0)
    }
    
    private func createTestSignal(sampleRate: Double, frequency: Double, modulationIndex: Double) -> [Float] {
        let numSamples = 1024
        var samples = [Float](repeating: 0, count: numSamples * 2)
        
        for i in 0..<numSamples {
            let t = Double(i) / sampleRate
            let phase = 2 * .pi * frequency * t
            let iSample = cos(phase)
            let qSample = sin(phase)
            
            samples[i * 2] = Float(iSample)
            samples[i * 2 + 1] = Float(qSample)
        }
        
        return samples
    }
    
    private func createAMTestSignal(sampleRate: Double, carrierFreq: Double, modulationFreq: Double, modulationIndex: Double) -> [Float] {
        let numSamples = 1024
        var samples = [Float](repeating: 0, count: numSamples * 2)
        
        for i in 0..<numSamples {
            let t = Double(i) / sampleRate
            let carrierPhase = 2 * .pi * carrierFreq * t
            let modulationPhase = 2 * .pi * modulationFreq * t
            
            let amplitude = 1.0 + modulationIndex * cos(modulationPhase)
            let iSample = amplitude * cos(carrierPhase)
            let qSample = amplitude * sin(carrierPhase)
            
            samples[i * 2] = Float(iSample)
            samples[i * 2 + 1] = Float(qSample)
        }
        
        return samples
    }
} 