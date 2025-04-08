import Foundation
import SwiftUI

@MainActor
class SDRViewModel: ObservableObject {
    private var sdrController: SDRController?
    
    @Published var isRunning = false
    @Published var frequency: Double = 432975000.0 // 432.975 MHz
    @Published var mode: DemodulationMode = .fm
    @Published var errorMessage: String?
    @Published var availableDevices: [SDRInterface.DeviceInfo] = []
    @Published var selectedDevice: SDRInterface.DeviceInfo?
    
    // SDR parameters
    @Published var baseFrequency: Double = 100000000.0 // 100 MHz
    @Published var bandwidth: Double = 2400000.0 // 2.4 MHz
    @Published var gain: Double = 0.0 // 0 dB
    
    // Signal and audio levels
    @Published var signalStrength: Float = 0.0
    @Published var audioLevel: Float = 0.0
    @Published var spectrumData: [Float] = []
    @Published var waterfallData: [[Float]] = []
    private let maxWaterfallLines = 100
    
    @Published var timer: Timer?
    
    init() {
        setupSDR()
        startTimer()
    }
    
    func scanDevices() {
        do {
            availableDevices = try SDRController.enumerateDevices()
            print("Available devices: \(availableDevices)")
            if let firstDevice = availableDevices.first {
                selectedDevice = firstDevice
            }
        } catch {
            errorMessage = "Failed to enumerate devices: \(error.localizedDescription)"
        }
    }
    
    private func setupSDR() {
        sdrController = SDRController()
    }
    
    private func updateWaterfall(spectrum: [Float]) {
        waterfallData.insert(spectrum, at: 0)
        if waterfallData.count > maxWaterfallLines {
            waterfallData.removeLast()
        }
    }
    
    func startStop() {
        guard let controller = sdrController else { return }
        
        if isRunning {
            controller.stop()
            isRunning = false
            errorMessage = nil
        } else {
            do {
                try controller.start(device: selectedDevice!, frequency: frequency, sampleRate: 2.4e6)
                isRunning = true
                errorMessage = nil
            } catch {
                isRunning = false
                errorMessage = "Failed to start SDR: \(error.localizedDescription)"
            }
        }
    }
    
    func setFrequency(_ newFrequency: Double) {
        frequency = newFrequency
        guard let controller = sdrController else { return }
        
        do {
            try controller.setFrequency(newFrequency)
            errorMessage = nil
        } catch {
            errorMessage = "Failed to set frequency: \(error.localizedDescription)"
        }
    }
    
    func setBaseFrequency(_ newFrequency: Double) {
        baseFrequency = newFrequency
        guard let controller = sdrController else { return }
        
        do {
            try controller.setBaseFrequency(newFrequency)
            errorMessage = nil
        } catch {
            errorMessage = "Failed to set base frequency: \(error.localizedDescription)"
        }
    }
    
    func setBandwidth(_ newBandwidth: Double) {
        bandwidth = newBandwidth
        guard let controller = sdrController else { return }
        
        do {
            try controller.setBandwidth(newBandwidth)
            errorMessage = nil
        } catch {
            errorMessage = "Failed to set bandwidth: \(error.localizedDescription)"
        }
    }
    
    func setGain(_ newGain: Double) {
        gain = newGain
        guard let controller = sdrController else { return }
        
        do {
            try controller.setGain(newGain)
            errorMessage = nil
        } catch {
            errorMessage = "Failed to set gain: \(error.localizedDescription)"
        }
    }
    
    func setMode(_ newMode: DemodulationMode) {
        mode = newMode
        sdrController?.setMode(newMode)
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let controller = self.sdrController else { return }
                self.signalStrength = controller.signalStrength
            }
        }
    }
    
    deinit {
        Task { @MainActor in
            sdrController?.stop()
            timer?.invalidate()
        }
    }
} 
