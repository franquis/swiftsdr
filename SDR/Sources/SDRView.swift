import SwiftUI

@available(macOS 12.0, *)
public struct SDRView: View {
    @StateObject private var viewModel = SDRViewModel()
    private let frequencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    private let bandwidthFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    private let gainFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        return formatter
    }()
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("SDR Receiver")
                .font(.largeTitle)
                .padding()
            
            // Main Content
            HStack(spacing: 20) {
                // Controls
                VStack(spacing: 20) {
                    // Device Selection
                    VStack {
                        Text("Device")
                            .font(.headline)
                        
                        Picker("Select Device", selection: $viewModel.selectedDevice) {
                            ForEach(viewModel.availableDevices, id: \.serial) { device in
                                Text("\(device.label) (\(device.driver))")
                                    .tag(Optional(device))
                            }
                        }
                        .onChange(of: viewModel.selectedDevice) { newDevice in
                            if let device = newDevice {
                                viewModel.selectedDevice = device
                            }
                        }
                    }
                    .padding()
                    .background(Color(.windowBackgroundColor))
                    .cornerRadius(10)
                    
                    // Base Frequency Control
                    VStack {
                        Text("Base Frequency (MHz)")
                            .font(.headline)
                        
                        HStack {
                            Button("-1 MHz") {
                                viewModel.setBaseFrequency(viewModel.baseFrequency - 1_000_000)
                            }
                            .buttonStyle(.bordered)
                            
                            TextField("Frequency", value: $viewModel.baseFrequency, formatter: frequencyFormatter)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 150)
                                .multilineTextAlignment(.center)
                            
                            Button("+1 MHz") {
                                viewModel.setBaseFrequency(viewModel.baseFrequency + 1_000_000)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding()
                    .background(Color(.windowBackgroundColor))
                    .cornerRadius(10)
                    
                    // Bandwidth Control
                    VStack {
                        Text("Bandwidth (MHz)")
                            .font(.headline)
                        
                        HStack {
                            Button("-0.1") {
                                viewModel.setBandwidth(viewModel.bandwidth - 100_000)
                            }
                            .buttonStyle(.bordered)
                            
                            TextField("Bandwidth", value: $viewModel.bandwidth, formatter: bandwidthFormatter)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 150)
                                .multilineTextAlignment(.center)
                            
                            Button("+0.1") {
                                viewModel.setBandwidth(viewModel.bandwidth + 100_000)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding()
                    .background(Color(.windowBackgroundColor))
                    .cornerRadius(10)
                    
                    // Gain Control
                    VStack {
                        Text("Gain (dB)")
                            .font(.headline)
                        
                        HStack {
                            Button("-1") {
                                viewModel.setGain(viewModel.gain - 1.0)
                            }
                            .buttonStyle(.bordered)
                            
                            TextField("Gain", value: $viewModel.gain, formatter: gainFormatter)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 150)
                                .multilineTextAlignment(.center)
                            
                            Button("+1") {
                                viewModel.setGain(viewModel.gain + 1.0)
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
                    
                    // Scan Devices Button
                    Button(action: {
                        viewModel.scanDevices()
                    }) {
                        Text("Scan Devices")
                            .frame(width: 150)
                            .padding()
                            .background(Color.blue)
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
    }
}

#if DEBUG
@available(macOS 12.0, *)
struct SDRView_Previews: PreviewProvider {
    static var previews: some View {
        SDRView()
    }
}
#endif 