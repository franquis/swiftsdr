import Foundation
import AVFoundation

public class AudioOutput {
    private let engine: AVAudioEngine
    private let player: AVAudioPlayerNode
    private let format: AVAudioFormat
    private let sampleRate: Double
    private let bufferSize: Int
    
    private var isPlaying: Bool = false
    private var bufferQueue: [AVAudioPCMBuffer] = []
    private let queueLock = NSLock()
    
    public init(sampleRate: Double = 48000.0, bufferSize: Int = 1024) {
        self.sampleRate = sampleRate
        self.bufferSize = bufferSize
        
        // Create audio engine and player
        engine = AVAudioEngine()
        player = AVAudioPlayerNode()
        
        // Create audio format (mono, 32-bit float)
        format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        
        // Setup audio engine
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        
        // Set up buffer scheduling
        player.installTap(onBus: 0, bufferSize: AVAudioFrameCount(bufferSize), format: format) { [weak self] buffer, time in
            self?.scheduleNextBuffer()
        }
    }
    
    public func start() throws {
        guard !isPlaying else { return }
        
        try engine.start()
        player.play()
        isPlaying = true
    }
    
    public func stop() {
        guard isPlaying else { return }
        
        player.stop()
        engine.stop()
        isPlaying = false
        
        // Clear buffer queue
        queueLock.lock()
        bufferQueue.removeAll()
        queueLock.unlock()
    }
    
    public func playSamples(_ samples: [Float]) {
        guard isPlaying else { return }
        
        // Create audio buffer
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count))!
        buffer.frameLength = AVAudioFrameCount(samples.count)
        
        // Copy samples to buffer
        let channelData = buffer.floatChannelData![0]
        samples.withUnsafeBufferPointer { ptr in
            channelData.assign(from: ptr.baseAddress!, count: samples.count)
        }
        
        // Add buffer to queue
        queueLock.lock()
        bufferQueue.append(buffer)
        queueLock.unlock()
        
        // Schedule buffer if this is the first one
        if bufferQueue.count == 1 {
            scheduleNextBuffer()
        }
    }
    
    private func scheduleNextBuffer() {
        queueLock.lock()
        defer { queueLock.unlock() }
        
        guard !bufferQueue.isEmpty else { return }
        
        let buffer = bufferQueue.removeFirst()
        player.scheduleBuffer(buffer) { [weak self] in
            self?.scheduleNextBuffer()
        }
    }
    
    deinit {
        stop()
    }
} 