import AVFoundation

final class BeepAudio {
    var enabled = true
    private var player: AVAudioPlayer?
    private var sounds: [GameEvent: Data] = [:]

    init() {
        sounds[.catchEgg] = makeWAV(frequencies: [1047], duration: 0.075)
        sounds[.miss] = makeWAV(frequencies: [330, 260], duration: 0.22)
        sounds[.gameOver] = makeWAV(frequencies: [520, 390, 260], duration: 0.42)
        sounds[.milestone] = makeWAV(frequencies: [784, 988, 1175], duration: 0.30)
    }

    func playAlarm() {
        guard enabled else { return }
        player = try? AVAudioPlayer(data: makeWAV(frequencies: [880], duration: 0.16))
        player?.volume = 0.45
        player?.play()
    }

    func play(_ events: [GameEvent]) {
        guard enabled, let event = events.last, let data = sounds[event] else { return }
        player = try? AVAudioPlayer(data: data)
        player?.volume = 0.42
        player?.play()
    }

    private func makeWAV(frequencies: [Double], duration: Double) -> Data {
        let rate = 22050
        let count = Int(Double(rate) * duration)
        var pcm = Data(capacity: count * 2)
        for i in 0..<count {
            let fraction = Double(i) / Double(count)
            let frequency = frequencies[min(frequencies.count - 1, Int(fraction * Double(frequencies.count)))]
            let envelope = min(1.0, Double(i) / 80) * min(1.0, Double(count-i) / 900)
            let phase = Double(i) * frequency / Double(rate)
            let wave = sin(2 * .pi * phase) + 0.14 * sin(4 * .pi * phase)
            var sample = Int16(max(-32767, min(32767, wave * envelope * 8500))).littleEndian
            withUnsafeBytes(of: &sample) { pcm.append(contentsOf: $0) }
        }
        var data = Data()
        func put(_ text: String) { data.append(contentsOf: text.utf8) }
        func put32(_ x: UInt32) { var v = x.littleEndian; withUnsafeBytes(of: &v) { data.append(contentsOf: $0) } }
        func put16(_ x: UInt16) { var v = x.littleEndian; withUnsafeBytes(of: &v) { data.append(contentsOf: $0) } }
        put("RIFF"); put32(UInt32(36 + pcm.count)); put("WAVEfmt "); put32(16)
        put16(1); put16(1); put32(UInt32(rate)); put32(UInt32(rate * 2)); put16(2); put16(16)
        put("data"); put32(UInt32(pcm.count)); data.append(pcm)
        return data
    }
}
