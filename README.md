# RecodeVoice
## Usage

### Swift

1. Ensure your view  controller conforms to the `RecordViewProtocol` protocol:
```swift
class  YourViewController: ZLRecordViewProtocol{
    func zlRecordFinishRecordVoice(didFinishRecode voiceData: NSData) {
        voiceData = data
        // YourViewController code here
    }
}
```
