# 🤖 FunWithModels

A SwiftUI chat application exploring Apple's new Foundation Models framework for on-device AI, demonstrating the future of privacy-focused artificial intelligence on iOS.

![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![iOS](https://img.shields.io/badge/iOS-26.0%2B-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## 🌟 Overview

FunWithModels is a demonstration app showcasing Apple's Foundation Models framework, introduced as part of Apple Intelligence. This app provides a clean, modern chat interface powered by on-device large language models (LLMs), ensuring user privacy while delivering intelligent conversational experiences.

## ✨ Features

- **💬 Real-time Chat Interface**: Clean, intuitive messaging UI with distinct user/AI message bubbles
- **🔒 Privacy-First**: All AI processing happens on-device using Apple's Foundation Models
- **⚡ Streaming Responses**: Support for streaming AI responses in real-time (iOS 26.1+)
- **🎨 Modern SwiftUI Design**: Built entirely with SwiftUI for a native iOS experience
- **⌨️ Smart Keyboard Handling**: Interactive keyboard dismissal while scrolling
- **🔄 Async/Await**: Modern Swift concurrency for smooth performance
- **📱 Adaptive UI**: Responsive design that works across all iOS devices

## 📋 Requirements

- **iOS 26.0+** (Currently in beta)
- **Xcode 16.0+** with iOS 26 SDK
- **Device Requirements**:
  - Apple Silicon device (iPhone 15 Pro or later recommended)
  - Apple Intelligence enabled in Settings
  - Foundation Models framework support

## 🚀 Getting Started

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/aessam/FunWithModels.git
   cd FunWithModels
   ```

2. **Open in Xcode**
   ```bash
   open FunWithModels.xcodeproj
   ```

3. **Configure Signing**
   - Select the project in Xcode
   - Go to "Signing & Capabilities"
   - Select your development team
   - Update the bundle identifier if needed

4. **Build and Run**
   - Select your target device (physical device recommended)
   - Press `Cmd + R` to build and run

## 🏗️ Architecture

### Project Structure

```
FunWithModels/
├── FunWithModelsApp.swift      # App entry point
├── ContentView.swift            # Main chat UI view
├── ChatViewModel.swift          # Foundation Models integration & business logic
├── Message.swift                # Message data model
└── Assets.xcassets/            # App assets and icons
```

### Key Components

#### **ChatViewModel**
- Manages Foundation Models session and configuration
- Handles message sending and AI response generation
- Implements both streaming and non-streaming response modes
- Manages model availability checking

#### **ContentView**
- Provides the main chat interface
- Implements message bubbles with user/AI distinction
- Handles keyboard management and scroll behavior
- Shows loading states during AI processing

#### **Message Model**
- Simple, identifiable data structure for chat messages
- Tracks message content, sender (user/AI), and timestamps

## 🔧 Configuration

The AI assistant's behavior can be customized by modifying the instructions in `ChatViewModel.swift`:

```swift
session = LanguageModelSession(
    model: model,
    instructions: {
        """
        You are a helpful, friendly AI assistant. 
        Provide clear, concise, and accurate responses.
        Be conversational but professional.
        If you're not sure about something, say so.
        """
    }
)
```

## 📱 Usage

1. **Launch the app** on a compatible device
2. **Type a message** in the text field at the bottom
3. **Send** by tapping the send button or pressing return
4. **View AI responses** appearing in real-time
5. **Scroll to dismiss keyboard** with interactive gesture

## 🔮 API Usage Examples

### Basic Response Generation
```swift
let response = try await session.respond(to: userMessage)
```

### Streaming Responses
```swift
let stream = session.streamResponse(to: userMessage)
for try await chunk in stream {
    responseText += chunk
}
```

## ⚠️ Important Notes

- **Beta Software**: iOS 26 and Foundation Models are currently in beta. APIs may change.
- **Device Limitations**: Requires Apple Intelligence-capable hardware
- **Privacy**: All processing is on-device; no data is sent to external servers
- **Model Availability**: The app checks for model availability at launch

## 🤝 Contributing

Contributions are welcome! As the Foundation Models framework is still in beta, we encourage:

- Bug reports and fixes
- API updates as the framework evolves
- UI/UX improvements
- Documentation enhancements

## 📚 Resources

- [Apple Foundation Models Documentation](https://developer.apple.com/documentation/foundationmodels)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Original Article: Exploring Foundation Models](https://www.createwithswift.com/exploring-the-foundation-models-framework/)
- [Apple Intelligence Overview](https://www.apple.com/apple-intelligence/)

## 📄 License

This project is available under the MIT License. See the LICENSE file for more details.

## 🙏 Acknowledgments

- Thanks to Apple for the Foundation Models framework
- Inspired by the article on createwithswift.com
- Built with SwiftUI and modern Swift concurrency

---

**Note**: This is an experimental project exploring beta APIs. Production use is not recommended until the framework reaches stable release.

Made with ❤️ using SwiftUI and Apple Intelligence