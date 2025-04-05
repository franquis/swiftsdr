import Foundation
import SwiftUI

@MainActor
class SDRViewModel: ObservableObject {
    private var sdrController: SDRController?
    
    @Published var isRunning = false
    @Published var frequency: Double = 100000000.0 // 100 MHz
    @Published var mode: DemodulationMode = .fm
    @Published var errorMessage: String?
    
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
    
    init() {
        setupSDR()
    }
    
    private func setupSDR() {
        sdrController = SDRController(
            sampleRate: bandwidth,
            audioSampleRate: 48000.0,
            frequency: baseFrequency,
            mode: mode
        )
        
        // Setup callbacks
        sdrController?.onSignalStrengthUpdate = { [weak self] strength in
            self?.signalStrength = strength
        }
        
        sdrController?.onAudioLevelUpdate = { [weak self] level in
            self?.audioLevel = level
        }
        
        sdrController?.onSpectrumUpdate = { [weak self] spectrum in
            self?.spectrumData = spectrum
            self?.updateWaterfall(spectrum: spectrum)
        }
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
        } else {
            do {
                try controller.start()
                isRunning = true
                errorMessage = nil
            } catch {
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
    
    deinit {
        sdrController?.stop()
    }
} 