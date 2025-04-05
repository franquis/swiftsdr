import SwiftUI

struct SDRView: View {
    @StateObject private var viewModel = SDRViewModel()
    
    private let frequencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("SDR Receiver")
                .font(.largeTitle)
                .padding()
            
            // Main Content
            HStack(spacing: 20) {
                // Controls
                VStack(spacing: 20) {
                    // Frequency Control
                    VStack {
                        Text("Frequency (MHz)")
                            .font(.headline)
                        
                        HStack {
                            Button("-1 MHz") {
                                viewModel.setFrequency(viewModel.frequency - 1_000_000)
                            }
                            .buttonStyle(.bordered)
                            
                            TextField("Frequency", value: $viewModel.frequency, formatter: frequencyFormatter)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 150)
                                .multilineTextAlignment(.center)
                            
                            Button("+1 MHz") {
                                viewModel.setFrequency(viewModel.frequency + 1_000_000)
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        // Fine tuning
                        HStack {
                            Button("-100 kHz") {
                                viewModel.setFrequency(viewModel.frequency - 100_000)
                            }
                            .buttonStyle(.bordered)
                            
                            Button("+100 kHz") {
                                viewModel.setFrequency(viewModel.frequency + 100_000)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding()
                    .background(Color(.windowBackgroundColor))
                    .cornerRadius(10)
                    
                    // Mode Selection
                    Picker("Mode", selection: $viewModel.mode) {
                        Text("FM").tag(DemodulationMode.fm)
                        Text("AM").tag(DemodulationMode.am)
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    // Level Meters
                    HStack(spacing: 20) {
                        LevelMeter(value: viewModel.signalStrength, title: "Signal", height: 100)
                        LevelMeter(value: viewModel.audioLevel, title: "Audio", height: 100)
                    }
                    .padding()
                    
                    // Start/Stop Button
                    Button(action: {
                        viewModel.startStop()
                    }) {
                        Text(viewModel.isRunning ? "Stop" : "Start")
                            .frame(width: 100)
                            .padding()
                            .background(viewModel.isRunning ? Color.red : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .frame(width: 300)
                
                // Spectrum and Waterfall
                VStack(spacing: 10) {
                    SpectrumView(data: viewModel.spectrumData, height: 150)
                        .background(Color.black)
                    
                    WaterfallView(data: viewModel.waterfallData, height: 200)
                        .background(Color.black)
                }
            }
            
            // Error Message
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .padding()
        .frame(minWidth: 800, minHeight: 600)
    }
}

#Preview {
    SDRView()
} 