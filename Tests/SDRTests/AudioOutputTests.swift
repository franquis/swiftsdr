import XCTest
import AVFoundation
@testable import SDR

final class AudioOutputTests: XCTestCase {
    var audioOutput: AudioOutput!
    
    override func setUp() {
        super.setUp()
        audioOutput = AudioOutput(sampleRate: 48000.0, bufferSize: 1024)
    }
    
    override func tearDown() {
        audioOutput.stop()
        audioOutput = nil
        super.tearDown()
    }
    
    func testAudioOutputInitialization() {
        XCTAssertNotNil(audioOutput)
    }
    
    func testAudioOutputStartStop() {
        XCTAssertNoThrow(try audioOutput.start())
        audioOutput.stop()
    }
    
    func testAudioOutputPlayback() {
        // Create a simple sine wave
        let sampleRate = 48000.0
        let frequency = 440.0 // A4 note
        let duration = 1.0 // 1 second
        let numSamples = Int(sampleRate * duration)
        
        var samples = [Float](repeating: 0, count: numSamples)
        for i in 0..<numSamples {
            let t = Double(i) / sampleRate
            samples[i] = Float(sin(2 * .pi * frequency * t))
        }
        
        // Start playback
        XCTAssertNoThrow(try audioOutput.start())
        
        // Play the samples
        audioOutput.playSamples(samples)
        
        // Wait for a short time to allow playback
        let expectation = XCTestExpectation(description: "Wait for playback")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Stop playback
        audioOutput.stop()
    }
} 