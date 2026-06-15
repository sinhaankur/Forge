import SwiftUI
import SwiftData

/// Focus / Play mode — a calm, full-screen guided session player. Shows one
/// step at a time, big and distraction-free: the movement, how to do it, a timer
/// for timed steps, and a clear "next". Turns a plan into something you press
/// play on and follow. Finishing logs the routine.
struct FocusSessionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let routine: Routine

    @State private var index = 0
    @State private var secondsLeft = 0
    @State private var timerRunning = false
    @State private var finished = false
    @State private var achieved = ""

    private var steps: [RoutineStep] { routine.orderedSteps }
    private var step: RoutineStep? { steps.indices.contains(index) ? steps[index] : nil }
    private var progress: Double { steps.isEmpty ? 0 : Double(index) / Double(steps.count) }

    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            GlowTheme.background.ignoresSafeArea()
            if finished {
                finishView
            } else if let step {
                sessionView(step)
            } else {
                finishView
            }
        }
        .onReceive(tick) { _ in
            guard timerRunning, secondsLeft > 0 else { return }
            secondsLeft -= 1
            if secondsLeft == 0 { timerRunning = false; Haptics.success() }
        }
    }

    // MARK: Session

    private func sessionView(_ step: RoutineStep) -> some View {
        VStack(spacing: 0) {
            // Top bar: progress + close.
            HStack(spacing: 12) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 15, weight: .bold)).foregroundStyle(GlowTheme.inkMuted)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(GlowTheme.faint).frame(height: 6)
                        Capsule().fill(GlowTheme.accentGradient)
                            .frame(width: geo.size.width * progress, height: 6)
                    }
                }.frame(height: 6)
                Text("\(index + 1)/\(steps.count)").font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
            }
            .padding(.horizontal, 20).padding(.top, 12)

            Spacer()

            // Big figure.
            Image(systemName: ExerciseFigure.symbol(for: step.title))
                .font(.system(size: 96, weight: .regular))
                .foregroundStyle(GlowTheme.accentGradient)
                .padding(.bottom, 12)

            // Name + summary.
            Text(ExerciseGuide.cleaned(step.title))
                .font(.system(size: 30, weight: .heavy))
                .multilineTextAlignment(.center)
                .foregroundStyle(GlowTheme.ink)
                .padding(.horizontal, 24)
            if !step.summary.isEmpty {
                Text(step.summary).font(GlowTheme.body(17)).foregroundStyle(GlowTheme.inkMuted)
                    .padding(.top, 4)
            }

            // Timer for timed steps.
            if step.durationSeconds > 0 {
                timerView(step)
            }

            // First form cue (intuitive coaching).
            Text(ExerciseGuide.guide(for: step.title).steps.first ?? "")
                .font(GlowTheme.body(14)).foregroundStyle(GlowTheme.inkMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32).padding(.top, 14)

            Spacer()

            // Controls.
            HStack(spacing: 14) {
                if index > 0 {
                    Button { back() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold)).foregroundStyle(GlowTheme.ink)
                            .frame(width: 56, height: 56).background(GlowTheme.surface).clipShape(Circle())
                    }
                }
                GlowButton(title: index == steps.count - 1 ? "Finish" : "Next", systemImage: index == steps.count - 1 ? "checkmark" : "chevron.right") {
                    next()
                }
            }
            .padding(.horizontal, 20).padding(.bottom, 24)
        }
        .onAppear { prepareTimer(step) }
    }

    private func timerView(_ step: RoutineStep) -> some View {
        VStack(spacing: 8) {
            Text(timeString(secondsLeft))
                .font(.system(size: 56, weight: .heavy, design: .rounded))
                .foregroundStyle(GlowTheme.ink)
                .monospacedDigit()
            Button {
                timerRunning.toggle(); Haptics.tap()
            } label: {
                Label(timerRunning ? "Pause" : "Start", systemImage: timerRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 15, weight: .semibold)).foregroundStyle(GlowTheme.accent)
                    .padding(.horizontal, 20).padding(.vertical, 8)
                    .background(GlowTheme.accent.opacity(0.12)).clipShape(Capsule())
            }
        }
        .padding(.top, 18)
    }

    // MARK: Finish

    private var finishView: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle().fill(GlowTheme.accentGradient).frame(width: 110, height: 110)
                Image(systemName: "checkmark").font(.system(size: 48, weight: .bold)).foregroundStyle(.black)
            }
            Text("Session complete").font(.system(size: 28, weight: .heavy)).foregroundStyle(GlowTheme.ink)
            Text(routine.name).font(GlowTheme.body(16)).foregroundStyle(GlowTheme.inkMuted)

            if routine.hasTarget, let metric = routine.targetMetric {
                HStack {
                    Text("Logged \(metric.title.lowercased())")
                        .font(GlowTheme.body(15)).foregroundStyle(GlowTheme.ink)
                    Spacer()
                    TextField("0", text: $achieved).keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing).frame(width: 70)
                    Text(metric.unit).foregroundStyle(GlowTheme.inkMuted)
                }
                .padding(16).background(GlowTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 28)
            }

            Spacer()
            GlowButton(title: "Done", systemImage: "checkmark") { logAndClose() }
                .padding(.horizontal, 20).padding(.bottom, 24)
        }
        .onAppear { Haptics.celebrate() }
    }

    // MARK: Logic

    private func prepareTimer(_ step: RoutineStep) {
        secondsLeft = step.durationSeconds
        timerRunning = false
    }
    private func next() {
        Haptics.toggle()
        if index >= steps.count - 1 { finished = true; return }
        index += 1
        if let s = step { prepareTimer(s) }
    }
    private func back() {
        Haptics.tap()
        guard index > 0 else { return }
        index -= 1
        if let s = step { prepareTimer(s) }
    }
    private func logAndClose() {
        let value = Double(achieved) ?? 0
        if !RoutineStore.isCompleted(routine, on: .now) {
            RoutineStore.toggleCompletion(routine, on: .now, achievedValue: value, in: context)
            ConnectivityService.shared.push(RoutineStore.snapshot(in: context))
        }
        Haptics.success()
        dismiss()
    }
    private func timeString(_ s: Int) -> String {
        String(format: "%d:%02d", s / 60, s % 60)
    }
}
