import Foundation

class PersistenceManager {
    private let fileName = "medications.json"
    private let containerIdentifier = "iCloud.com.damianrickard.MedicationTracker"

    /// Posted when remote iCloud data changes
    static let remoteDataDidChange = Notification.Name("PersistenceManagerRemoteDataDidChange")

    private var metadataQuery: NSMetadataQuery?

    // MARK: - File URLs

    /// Local fallback URL (original behavior)
    private var localFileURL: URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        let appDir = appSupport.appendingPathComponent("MedicationTracker", isDirectory: true)
        if !FileManager.default.fileExists(atPath: appDir.path) {
            try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        }
        return appDir.appendingPathComponent(fileName)
    }

    /// iCloud URL (nil if iCloud unavailable)
    private var iCloudFileURL: URL? {
        guard let containerURL = FileManager.default.url(
            forUbiquityContainerIdentifier: containerIdentifier
        ) else { return nil }

        let documentsDir = containerURL.appendingPathComponent("Documents", isDirectory: true)
        if !FileManager.default.fileExists(atPath: documentsDir.path) {
            try? FileManager.default.createDirectory(at: documentsDir, withIntermediateDirectories: true)
        }
        return documentsDir.appendingPathComponent(fileName)
    }

    /// Effective URL: iCloud if available, otherwise local
    private var fileURL: URL {
        iCloudFileURL ?? localFileURL
    }

    var isICloudAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    // MARK: - Initialization

    init() {
        migrateLocalToICloudIfNeeded()
        startMonitoringRemoteChanges()
    }

    deinit {
        metadataQuery?.stop()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public API

    func load() -> [Medication] {
        resolveConflicts()

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        do {
            if iCloudFileURL != nil {
                return try loadCoordinated()
            } else {
                let data = try Data(contentsOf: fileURL)
                return try decodeMedications(from: data)
            }
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

            if iCloudFileURL != nil {
                try saveCoordinated(data)
            } else {
                try data.write(to: fileURL, options: .atomic)
            }
        } catch {
            print("Failed to save medications: \(error)")
        }
    }

    // MARK: - File Coordination (required for iCloud documents)

    private func loadCoordinated() throws -> [Medication] {
        var coordinatorError: NSError?
        var result: [Medication] = []
        var loadError: Error?

        let coordinator = NSFileCoordinator(filePresenter: nil)
        coordinator.coordinate(
            readingItemAt: fileURL,
            options: [],
            error: &coordinatorError
        ) { url in
            do {
                let data = try Data(contentsOf: url)
                result = try self.decodeMedications(from: data)
            } catch {
                loadError = error
            }
        }

        if let error = coordinatorError ?? loadError {
            throw error
        }
        return result
    }

    private func saveCoordinated(_ data: Data) throws {
        var coordinatorError: NSError?
        var writeError: Error?

        let coordinator = NSFileCoordinator(filePresenter: nil)
        coordinator.coordinate(
            writingItemAt: fileURL,
            options: .forReplacing,
            error: &coordinatorError
        ) { url in
            do {
                try data.write(to: url, options: .atomic)
            } catch {
                writeError = error
            }
        }

        if let error = coordinatorError ?? writeError {
            throw error
        }
    }

    private func decodeMedications(from data: Data) throws -> [Medication] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Medication].self, from: data)
    }

    // MARK: - Remote Change Monitoring

    private func startMonitoringRemoteChanges() {
        guard iCloudFileURL != nil else { return }

        let query = NSMetadataQuery()
        query.predicate = NSPredicate(
            format: "%K == %@",
            NSMetadataItemFSNameKey,
            fileName
        )
        query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(metadataQueryDidUpdate),
            name: .NSMetadataQueryDidUpdate,
            object: query
        )

        query.start()
        metadataQuery = query
    }

    @objc private func metadataQueryDidUpdate(_ notification: Notification) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Self.remoteDataDidChange, object: nil)
        }
    }

    // MARK: - Conflict Resolution

    private func resolveConflicts() {
        guard let url = iCloudFileURL else { return }

        do {
            guard let conflictVersions = NSFileVersion.unresolvedConflictVersionsOfItem(at: url),
                  !conflictVersions.isEmpty else { return }

            // Load the current version
            let currentMeds = (try? loadFromURL(url)) ?? []
            var mergedDict: [UUID: Medication] = [:]

            for med in currentMeds {
                mergedDict[med.id] = med
            }

            // Merge each conflict version
            for version in conflictVersions {
                if let versionMeds = try? loadFromURL(version.url) {
                    for med in versionMeds {
                        if let existing = mergedDict[med.id] {
                            mergedDict[med.id] = mergeMedication(existing: existing, incoming: med)
                        } else {
                            mergedDict[med.id] = med
                        }
                    }
                }
                version.isResolved = true
            }

            // Remove resolved conflict versions
            try NSFileVersion.removeOtherVersionsOfItem(at: url)

            // Save merged result
            let merged = Array(mergedDict.values)
            save(merged)
        } catch {
            print("Conflict resolution error: \(error)")
        }
    }

    private func mergeMedication(existing: Medication, incoming: Medication) -> Medication {
        // Union dose histories by DoseRecord.id
        var allDoses: [UUID: DoseRecord] = [:]
        for dose in existing.doseHistory {
            allDoses[dose.id] = dose
        }
        for dose in incoming.doseHistory {
            allDoses[dose.id] = dose
        }

        let mergedHistory = Array(allDoses.values).sorted { $0.date < $1.date }

        // Take metadata from whichever version has the most recent dose
        let existingLatest = existing.doseHistory.map(\.date).max() ?? .distantPast
        let incomingLatest = incoming.doseHistory.map(\.date).max() ?? .distantPast

        let baseMed = incomingLatest > existingLatest ? incoming : existing
        return Medication(
            id: baseMed.id,
            name: baseMed.name,
            frequencyHours: baseMed.frequencyHours,
            doseHistory: mergedHistory,
            notes: baseMed.notes
        )
    }

    private func loadFromURL(_ url: URL) throws -> [Medication] {
        let data = try Data(contentsOf: url)
        return try decodeMedications(from: data)
    }

    // MARK: - Local-to-iCloud Migration

    private func migrateLocalToICloudIfNeeded() {
        guard let iCloudURL = iCloudFileURL else { return }

        let localExists = FileManager.default.fileExists(atPath: localFileURL.path)
        let iCloudExists = FileManager.default.fileExists(atPath: iCloudURL.path)

        if localExists && !iCloudExists {
            // First launch with iCloud: move local data to iCloud
            do {
                try FileManager.default.setUbiquitous(
                    true,
                    itemAt: localFileURL,
                    destinationURL: iCloudURL
                )
                print("Migrated local data to iCloud")
            } catch {
                print("Migration to iCloud failed: \(error)")
                // Fall back: copy instead of move
                try? FileManager.default.copyItem(at: localFileURL, to: iCloudURL)
            }
        } else if localExists && iCloudExists {
            // Both exist: merge them, then remove local
            do {
                let localMeds = try loadFromURL(localFileURL)
                let iCloudMeds = try loadFromURL(iCloudURL)

                var mergedDict: [UUID: Medication] = [:]
                for med in iCloudMeds { mergedDict[med.id] = med }
                for med in localMeds {
                    if let existing = mergedDict[med.id] {
                        mergedDict[med.id] = mergeMedication(existing: existing, incoming: med)
                    } else {
                        mergedDict[med.id] = med
                    }
                }

                // Save merged to iCloud
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let data = try encoder.encode(Array(mergedDict.values))
                try data.write(to: iCloudURL, options: .atomic)

                // Remove local file after successful merge
                try? FileManager.default.removeItem(at: localFileURL)
                print("Merged local and iCloud data")
            } catch {
                print("Merge migration failed: \(error)")
            }
        }
    }
}
