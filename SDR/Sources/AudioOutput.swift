import Foundation
import AVFoundation

public class AudioOutput {
    private var audioEngine: AVAudioEngine
    private var playerNode: AVAudioPlayerNode
    private var format: AVAudioFormat
    
    public init(sampleRate: Double = 48000.0) {
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        
        // Set up audio format (mono float)
        format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        
        // Configure audio engine
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: format)
        
        do {
            try audioEngine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    public func play(samples: [Float]) {
        guard !samples.isEmpty else { return }
        
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count))!
        buffer.frameLength = buffer.frameCapacity
        
        // Copy samples to buffer
        let ptr = buffer.floatChannelData?[0]
        samples.withUnsafeBufferPointer { samplesPtr in
            ptr?.update(from: samplesPtr.baseAddress!, count: samples.count)
        }
        
        // Schedule buffer for playback
        playerNode.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
        
        // Start playback if not already playing
        if !playerNode.isPlaying {
            playerNode.play()
        }
    }
    
    public func stop() {
        playerNode.stop()
        audioEngine.stop()
    }
    
    deinit {
        stop()
    }
} 