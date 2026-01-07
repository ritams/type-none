import AVFoundation
import Accelerate

/// Manages real-time audio capture from the microphone
class AudioManager: NSObject {
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var audioBuffer: AVAudioPCMBuffer?
    private var recordedData: [Float] = []
    
    private var isRecording = false
    private var audioLevelCallback: ((Float) -> Void)?
    private var completionHandler: ((Data?) -> Void)?
    
    // Whisper requires 16kHz mono audio
    private let targetSampleRate: Double = 16000
    private let targetChannels: AVAudioChannelCount = 1
    
    override init() {
        super.init()
        setupAudioEngine()
    }
    
    /// Setup the audio engine and input node
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        inputNode = audioEngine?.inputNode
    }
    
    /// Request microphone permission
    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    /// Start recording audio from the microphone
    func startRecording(audioLevelCallback: @escaping (Float) -> Void) {
        guard !isRecording else { return }
        
        self.audioLevelCallback = audioLevelCallback
        self.recordedData = []
        
        guard let inputNode = inputNode, let audioEngine = audioEngine else {
            print("Audio engine not initialized")
            return
        }
        
        // Get the native format of the input
        let inputFormat = inputNode.outputFormat(forBus: 0)
        
        // Create target format for Whisper (16kHz mono)
        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: targetSampleRate,
            channels: targetChannels,
            interleaved: false
        ) else {
            print("Failed to create target audio format")
            return
        }
        
        // Create converter if needed
        let converter = AVAudioConverter(from: inputFormat, to: targetFormat)
        
        // Calculate buffer size (100ms chunks)
        let bufferSize = AVAudioFrameCount(inputFormat.sampleRate * 0.1)
        
        // Install tap on input node
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: inputFormat) { [weak self] buffer, time in
            guard let self = self else { return }
            
            // Calculate audio level for visualization
            let level = self.calculateAudioLevel(buffer: buffer)
            DispatchQueue.main.async {
                self.audioLevelCallback?(level)
            }
            
            // Convert to target format if needed
            if let converter = converter {
                let convertedBuffer = AVAudioPCMBuffer(
                    pcmFormat: targetFormat,
                    frameCapacity: AVAudioFrameCount(Double(buffer.frameLength) * targetFormat.sampleRate / inputFormat.sampleRate)
                )!
                
                var error: NSError?
                let status = converter.convert(to: convertedBuffer, error: &error) { inNumberOfPackets, outStatus in
                    outStatus.pointee = .haveData
                    return buffer
                }
                
                if status == .haveData {
                    self.appendBuffer(convertedBuffer)
                }
            } else {
                self.appendBuffer(buffer)
            }
        }
        
        // Start the audio engine
        do {
            audioEngine.prepare()
            try audioEngine.start()
            isRecording = true
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    /// Stop recording and return the audio data
    func stopRecording(completion: @escaping (Data?) -> Void) {
        guard isRecording else {
            completion(nil)
            return
        }
        
        self.completionHandler = completion
        
        // Remove the tap
        inputNode?.removeTap(onBus: 0)
        
        // Stop the engine
        audioEngine?.stop()
        isRecording = false
        
        // Convert recorded samples to Data
        let audioData = convertSamplesToData(recordedData)
        completion(audioData)
    }
    
    /// Append audio buffer to recorded data
    private func appendBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)
        
        for i in 0..<frameLength {
            recordedData.append(channelData[i])
        }
    }
    
    /// Calculate the audio level (RMS) for visualization
    private func calculateAudioLevel(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else { return 0 }
        let frameLength = Int(buffer.frameLength)
        
        var sum: Float = 0
        for i in 0..<frameLength {
            sum += channelData[i] * channelData[i]
        }
        
        let rms = sqrt(sum / Float(frameLength))
        
        // Convert to dB and normalize to 0-1 range
        let db = 20 * log10(max(rms, 0.0001))
        let normalized = (db + 60) / 60 // -60dB to 0dB mapped to 0-1
        
        return max(0, min(1, normalized))
    }
    
    /// Convert float samples to Data for Whisper
    private func convertSamplesToData(_ samples: [Float]) -> Data {
        return samples.withUnsafeBufferPointer { buffer in
            Data(buffer: buffer)
        }
    }
    
    /// Get available audio input devices
    func getAvailableInputDevices() -> [String] {
        var devices: [String] = ["Default"]
        
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.microphone, .external],
            mediaType: .audio,
            position: .unspecified
        )
        
        for device in discoverySession.devices {
            devices.append(device.localizedName)
        }
        
        return devices
    }
    
    /// Cleanup resources
    func cleanup() {
        if isRecording {
            inputNode?.removeTap(onBus: 0)
            audioEngine?.stop()
        }
        audioEngine = nil
        inputNode = nil
    }
}
