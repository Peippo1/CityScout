import SwiftUI

#if DEBUG
func debugLog(
    _ message: String,
    file: StaticString = #fileID,
    line: UInt = #line
) {
    print("[TripLingo DEBUG] \(file):\(line) - \(message)")
}

private struct DebugSafetyTimeoutModifier: ViewModifier {
    let label: String
    @Binding var completed: Bool
    let thresholdSeconds: TimeInterval

    func body(content: Content) -> some View {
        content.task(id: completed) {
            guard completed == false else { return }

            try? await Task.sleep(
                nanoseconds: UInt64(thresholdSeconds * 1_000_000_000)
            )

            if completed == false {
                debugLog("Safety timeout warning: \(label) exceeded \(thresholdSeconds)s")
            }
        }
    }
}

extension View {
    func debugSafetyTimeout(
        _ label: String,
        completed: Binding<Bool>,
        thresholdSeconds: TimeInterval = 2.0
    ) -> some View {
        modifier(
            DebugSafetyTimeoutModifier(
                label: label,
                completed: completed,
                thresholdSeconds: thresholdSeconds
            )
        )
    }
}
#else
func debugLog(
    _ message: String,
    file: StaticString = #fileID,
    line: UInt = #line
) {
    _ = message
    _ = file
    _ = line
}

extension View {
    func debugSafetyTimeout(
        _ label: String,
        completed: Binding<Bool>,
        thresholdSeconds: TimeInterval = 2.0
    ) -> some View {
        _ = label
        _ = thresholdSeconds
        _ = completed.wrappedValue
        return self
    }
}
#endif
