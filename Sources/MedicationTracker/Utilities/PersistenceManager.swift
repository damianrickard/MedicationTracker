import Foundation

struct PersistenceManager {
    private let fileName = "medications.json"

    private var fileURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = appSupport.appendingPathComponent("MedicationTracker", isDirectory: true)

        if !FileManager.default.fileExists(atPath: appDirectory.path) {
            try? FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        }

        return appDirectory.appendingPathComponent(fileName)
    }

    func load() -> [Medication] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([Medication].self, from: data)
        } catch {
            print("Failed to load medications: \(error)")
            return []
        }
    }

    func save(_ medications: [Medication]) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(medications)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save medications: \(error)")
        }
    }
}
