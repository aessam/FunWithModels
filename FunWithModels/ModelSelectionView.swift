import SwiftUI
import FoundationModels

struct ModelInfo: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let model: SystemLanguageModel
}

struct ModelSelectionView: View {
    let onModelSelected: (SystemLanguageModel) -> Void
    @State private var availableModels: [ModelInfo] = []
    @State private var isCheckingAvailability = true

    var body: some View {
        NavigationView {
            VStack {
                if isCheckingAvailability {
                    ProgressView("Checking available models...")
                        .padding()
                } else if availableModels.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)

                        Text("No Models Available")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Foundation Models are not available on this device. Please ensure you're running iOS 26+ with Apple Intelligence enabled.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                    .padding()
                } else {
                    List(availableModels) { modelInfo in
                        Button(action: {
                            onModelSelected(modelInfo.model)
                        }) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(modelInfo.name)
                                    .font(.headline)

                                Text(modelInfo.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Select a Model")
            .onAppear {
                checkAvailableModels()
            }
        }
    }

    private func checkAvailableModels() {
        Task {
            var models: [ModelInfo] = []

            // Check default model
            let defaultModel = SystemLanguageModel.default
            switch defaultModel.availability {
            case .available:
                models.append(ModelInfo(
                    name: "Default Model",
                    description: "General-purpose model optimized for creative generation and Q&A",
                    model: defaultModel
                ))
            case .unavailable(let reason):
                print("Default model unavailable: \(reason)")
            }

            // Check content tagging model (specialized for extraction/tagging)
            let contentTaggingModel = SystemLanguageModel(useCase: .contentTagging)
            switch contentTaggingModel.availability {
            case .available:
                models.append(ModelInfo(
                    name: "Content Tagging Model",
                    description: "Fine-tuned for tagging, extraction, and classification tasks",
                    model: contentTaggingModel
                ))
            case .unavailable(let reason):
                print("Content tagging model unavailable: \(reason)")
            }

            await MainActor.run {
                availableModels = models
                isCheckingAvailability = false
            }
        }
    }
}

#Preview {
    ModelSelectionView { _ in }
}
