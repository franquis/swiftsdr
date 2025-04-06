import XCTest
@testable import SDR

final class SDRControllerTests: XCTestCase {
    var sdrController: SDRController!
    
    override func setUp() {
        super.setUp()
        sdrController = SDRController(sampleRate: 2400000.0,
                                    audioSampleRate: 48000.0,
                                    frequency: 100000000.0,
                                    mode: .fm)
    }
    
    override func tearDown() {
        sdrController.stop()
        sdrController = nil
        super.tearDown()
    }
    
    func testSDRControllerInitialization() {
        XCTAssertNotNil(sdrController)
    }
    
    func testSDRControllerStartStop() {
        XCTAssertNoThrow(try sdrController.start())
        
        // Wait a short time to ensure processing starts
        let expectation = XCTestExpectation(description: "Wait for processing")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        sdrController.stop()
    }
    
    func testFrequencyChange() {
        XCTAssertNoThrow(try sdrController.start())
        
        // Change frequency
        XCTAssertNoThrow(try sdrController.setFrequency(101000000.0))
        
        // Wait a short time
        let expectation = XCTestExpectation(description: "Wait for frequency change")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        sdrController.stop()
    }
    
    func testModeChange() {
        XCTAssertNoThrow(try sdrController.start())
        
        // Change mode to AM
        sdrController.setMode(.am)
        
        // Wait a short time
        let expectation = XCTestExpectation(description: "Wait for mode change")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        sdrController.stop()
    }
} 