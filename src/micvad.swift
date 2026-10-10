// micvad: reads 16 kHz mono float32 PCM on stdin, exits 0 once Apple's built-in sound classifier hears sustained speech.
// usage: sox ... -t raw -r 16000 -c 1 -e float -b 32 - | micvad [minConfidence=0.6] [windowsInARow=2]
import AVFoundation
import SoundAnalysis

let args = CommandLine.arguments
let minConfidence = args.count > 1 ? Double(args[1])! : 0.6
let needed = args.count > 2 ? Int(args[2])! : 2

final class Observer: NSObject, SNResultsObserving {
  var streak = 0
  func request(_ request: SNRequest, didProduce result: SNResult) {
    guard let r = result as? SNClassificationResult else { return }
    let c = r.classification(forIdentifier: "speech")?.confidence ?? 0
    streak = c >= minConfidence ? streak + 1 : 0
    if ProcessInfo.processInfo.environment["MICVAD_DEBUG"] != nil { FileHandle.standardError.write("speech \(String(format: "%.2f", c))\n".data(using: .utf8)!) }
    if streak >= needed { print("speech"); exit(0) }
  }
}

let format = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1)!
let analyzer = SNAudioStreamAnalyzer(format: format)
let request = try! SNClassifySoundRequest(classifierIdentifier: .version1)
request.windowDuration = CMTime(seconds: 1.0, preferredTimescale: 16000)
request.overlapFactor = 0.5
let observer = Observer()
try! analyzer.add(request, withObserver: observer)

let frames: AVAudioFrameCount = 8000  // 0.5 s per chunk
var position: AVAudioFramePosition = 0
let stdin = FileHandle.standardInput
while true {
  let data = stdin.readData(ofLength: Int(frames) * 4)
  if data.isEmpty { break }
  let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!
  buf.frameLength = AVAudioFrameCount(data.count / 4)
  data.withUnsafeBytes { buf.floatChannelData![0].update(from: $0.bindMemory(to: Float.self).baseAddress!, count: Int(buf.frameLength)) }
  analyzer.analyze(buf, atAudioFramePosition: position)
  position += AVAudioFramePosition(buf.frameLength)
}
analyzer.completeAnalysis()
exit(1)
