// usage: bhvol <0.0-1.0>   sets BlackHole 2ch input volume, so apps like Meet see "mic volume low"
//        bhvol inuse       exits 0 if any app is reading BlackHole 2ch (i.e. a call is using it)
//        bhvol speakers    exits 0 if the default output is speakers (built-in, or a DisplayPort/HDMI monitor), not headphones
import CoreAudio
import Foundation
let arg = CommandLine.arguments.count == 2 ? CommandLine.arguments[1] : ""
var v = Float32(arg) ?? -1
guard arg == "inuse" || arg == "speakers" || (0...1).contains(v) else { print("usage: bhvol <0.0-1.0> | inuse | speakers"); exit(2) }
if arg == "speakers" {
  var oa = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultOutputDevice, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
  var out = AudioDeviceID(0); var osz = UInt32(4); AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &oa, 0, nil, &osz, &out)
  var ta = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyTransportType, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
  var t: UInt32 = 0; var tsz = UInt32(4); AudioObjectGetPropertyData(out, &ta, 0, nil, &tsz, &t)
  var na = AudioObjectPropertyAddress(mSelector: kAudioObjectPropertyName, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
  var n: Unmanaged<CFString>?; var nsz = UInt32(MemoryLayout<CFString?>.size); AudioObjectGetPropertyData(out, &na, 0, nil, &nsz, &n)
  let name = (n?.takeRetainedValue() as String?) ?? ""
  // ponytail: built-in jack shows up as "External Headphones" with built-in transport; USB/Bluetooth count as headphones
  let speakers = (t == kAudioDeviceTransportTypeBuiltIn && !name.contains("Headphones")) || t == kAudioDeviceTransportTypeDisplayPort || t == kAudioDeviceTransportTypeHDMI
  exit(speakers ? 0 : 1)
}
var a = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDevices, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
var sz: UInt32 = 0; AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &a, 0, nil, &sz)
var ids = [AudioDeviceID](repeating: 0, count: Int(sz) / 4); AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &a, 0, nil, &sz, &ids)
for d in ids {
  var na = AudioObjectPropertyAddress(mSelector: kAudioObjectPropertyName, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
  var n: Unmanaged<CFString>?; var nsz = UInt32(MemoryLayout<CFString?>.size); AudioObjectGetPropertyData(d, &na, 0, nil, &nsz, &n)
  guard (n?.takeRetainedValue() as String?) == "BlackHole 2ch" else { continue }
  if arg == "inuse" {
    var ra = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
    var running: UInt32 = 0; var rsz = UInt32(4); AudioObjectGetPropertyData(d, &ra, 0, nil, &rsz, &running)
    exit(running != 0 ? 0 : 1)
  }
  var va = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyVolumeScalar, mScope: kAudioDevicePropertyScopeInput, mElement: kAudioObjectPropertyElementMain)
  exit(AudioObjectSetPropertyData(d, &va, 0, nil, 4, &v) == noErr ? 0 : 1)
}
print("BlackHole 2ch not found"); exit(1)
