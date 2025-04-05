import XCTest
@testable import SDR

final class SDRInterfaceTests: XCTestCase {
    var sdrInterface: SDRInterface!
    
    override func setUp() {
        super.setUp()
        sdrInterface = SDRInterface()
    }
    
    override func tearDown() {
        sdrInterface = nil
        super.tearDown()
    }
    
    func testSDRInitialization() {
        // Test frequency: 100 MHz, Sample rate: 2.4 MHz
        XCTAssertNoThrow(try sdrInterface.start(frequency: 100e6, sampleRate: 2.4e6))
        
        // Try to read some samples
        XCTAssertNoThrow(try sdrInterface.readSamples(bufferSize: 1024))
        
        // Clean up
        sdrInterface.stop()
    }
} 