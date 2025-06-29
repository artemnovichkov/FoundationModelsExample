//
//  Created by Artem Novichkov on 29.06.2025.
//

import FoundationModels
import HealthKit

final class BloodPressureTool: Tool {
    enum Error: Swift.Error, LocalizedError {
        case missingBloodPressureData

        var errorDescription: String? {
            switch self {
            case .missingBloodPressureData:
                return "Missing blood pressure data"
            }
        }
    }

    let name = "blood_pressure"
    let description = "Get the latest blood pressure (systolic and diastolic) from Apple Health."

    @Generable
    struct Arguments {}

    private lazy var healthStore = HKHealthStore()

    private let systolicType = HKQuantityType(.bloodPressureSystolic)
    private let diastolicType = HKQuantityType(.bloodPressureDiastolic)
    private let bloodPressureType = HKCorrelationType(.bloodPressure)

    func call(arguments: Arguments) async throws -> ToolOutput {
        let (systolic, diastolic) = try await fetchLatestBloodPressure()
        let content = GeneratedContent(properties: ["systolic": Int(systolic), "diastolic": Int(diastolic)])
        return ToolOutput(content)
    }

    // MARK: - Private
    
    private func fetchLatestBloodPressure() async throws -> (systolic: Double, diastolic: Double) {
        try await healthStore.requestAuthorization(toShare: [], read: [systolicType, diastolicType])
        let descriptor = HKSampleQueryDescriptor(predicates: [.sample(type: bloodPressureType)], sortDescriptors: [])
        let samples = try await descriptor.result(for: healthStore)
        guard let sample = samples.first as? HKCorrelation else {
            throw Error.missingBloodPressureData
        }
        guard let systolic = sample.objects(for: systolicType).first as? HKQuantitySample,
              let diastolic = sample.objects(for: diastolicType).first as? HKQuantitySample else {
            throw Error.missingBloodPressureData
        }

        let systolicValue = systolic.quantity.doubleValue(for: .millimeterOfMercury())
        let diastolicValue = diastolic.quantity.doubleValue(for: .millimeterOfMercury())
        return (systolicValue, diastolicValue)
    }
}

