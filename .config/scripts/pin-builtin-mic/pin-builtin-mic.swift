import CoreAudio
import Foundation

var defaultInputAddr = AudioObjectPropertyAddress(
    mSelector: kAudioHardwarePropertyDefaultInputDevice,
    mScope: kAudioObjectPropertyScopeGlobal,
    mElement: kAudioObjectPropertyElementMain)

func defaultInputDevice() -> AudioDeviceID {
    var id = AudioDeviceID(0)
    var size = UInt32(MemoryLayout<AudioDeviceID>.size)
    AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &defaultInputAddr, 0, nil, &size, &id)
    return id
}

func transportType(of device: AudioDeviceID) -> UInt32 {
    var addr = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyTransportType,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain)
    var transport: UInt32 = 0
    var size = UInt32(MemoryLayout<UInt32>.size)
    AudioObjectGetPropertyData(device, &addr, 0, nil, &size, &transport)
    return transport
}

func hasInputStreams(_ device: AudioDeviceID) -> Bool {
    var addr = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyStreams,
        mScope: kAudioObjectPropertyScopeInput,
        mElement: kAudioObjectPropertyElementMain)
    var size: UInt32 = 0
    AudioObjectGetPropertyDataSize(device, &addr, 0, nil, &size)
    return size > 0
}

func name(of device: AudioDeviceID) -> String {
    var addr = AudioObjectPropertyAddress(
        mSelector: kAudioObjectPropertyName,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain)
    var cfName: Unmanaged<CFString>?
    var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
    AudioObjectGetPropertyData(device, &addr, 0, nil, &size, &cfName)
    return cfName?.takeRetainedValue() as String? ?? "device \(device)"
}

func builtInInputDevice() -> AudioDeviceID? {
    var addr = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDevices,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain)
    var size: UInt32 = 0
    AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &size)
    var devices = [AudioDeviceID](repeating: 0, count: Int(size) / MemoryLayout<AudioDeviceID>.size)
    AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &size, &devices)
    return devices.first { transportType(of: $0) == kAudioDeviceTransportTypeBuiltIn && hasInputStreams($0) }
}

func enforceBuiltInMic() {
    let current = defaultInputDevice()
    let transport = transportType(of: current)
    guard transport == kAudioDeviceTransportTypeBluetooth || transport == kAudioDeviceTransportTypeBluetoothLE else { return }
    guard var builtIn = builtInInputDevice() else { return }
    let size = UInt32(MemoryLayout<AudioDeviceID>.size)
    let status = AudioObjectSetPropertyData(AudioObjectID(kAudioObjectSystemObject), &defaultInputAddr, 0, nil, size, &builtIn)
    if status == noErr {
        print("input switched to \(name(of: current)); reverted to \(name(of: builtIn))")
    } else {
        print("failed to revert input from \(name(of: current)): OSStatus \(status)")
    }
}

setvbuf(stdout, nil, _IOLBF, 0)
AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &defaultInputAddr, DispatchQueue.main) { _, _ in
    enforceBuiltInMic()
}
enforceBuiltInMic()
RunLoop.main.run()
