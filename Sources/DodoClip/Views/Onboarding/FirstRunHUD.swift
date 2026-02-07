import AppKit
import SwiftUI

/// First-run HUD that shows the keyboard shortcut and celebrates when pressed
final class FirstRunHUD: NSWindow {
    private static let hasShownKey = "hasShownFirstRunHUD"

    static var hasShownFirstRun: Bool {
        get { UserDefaults.standard.bool(forKey: hasShownKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasShownKey) }
    }

    private var viewModel = FirstRunViewModel()

    override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        configureWindow()
    }

    private func configureWindow() {
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = false
    }

    func show(on screen: NSScreen, onDismiss: @escaping () -> Void) {
        viewModel.onDismiss = { [weak self] in
            self?.dismiss()
            onDismiss()
        }

        let content = FirstRunHUDView(viewModel: viewModel)
        let hostingController = NSHostingController(rootView: content)
        contentView = hostingController.view

        // Full screen
        setFrame(screen.frame, display: true)

        alphaValue = 0
        orderFrontRegardless()
        makeKey()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.animator().alphaValue = 1
        }
    }

    func triggerSuccess() {
        viewModel.showConfetti = true
        // Auto-dismiss after confetti
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.viewModel.onDismiss?()
        }
    }

    func dismiss() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            self.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            self?.orderOut(nil)
            FirstRunHUD.hasShownFirstRun = true
        }
    }

    override var canBecomeKey: Bool { true }
}

// MARK: - View Model

@MainActor
final class FirstRunViewModel: ObservableObject {
    @Published var showConfetti = false
    var onDismiss: (() -> Void)?
}

// MARK: - View

struct FirstRunHUDView: View {
    @ObservedObject var viewModel: FirstRunViewModel

    var body: some View {
        ZStack {
            // Dark semi-transparent background
            Color.black.opacity(0.75)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                // App icon
                Image(systemName: "clipboard")
                    .font(.system(size: 64))
                    .foregroundColor(.white.opacity(0.9))

                // Welcome text
                Text(L10n.Onboarding.welcome)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(.white)

                // Instruction
                Text(L10n.Onboarding.pressShortcut)
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.7))

                // Keyboard shortcut display
                HStack(spacing: 16) {
                    KeyCapView(symbol: "⇧")
                    PlusSign()
                    KeyCapView(symbol: "⌘")
                    PlusSign()
                    KeyCapView(symbol: "V")
                }

                // Skip option
                Button(action: { viewModel.onDismiss?() }) {
                    Text(L10n.Onboarding.skip)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
                .padding(.top, 24)
            }

            // Confetti overlay
            if viewModel.showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
            }
        }
    }
}

struct KeyCapView: View {
    let symbol: String

    var body: some View {
        Text(symbol)
            .font(.system(size: 28, weight: .medium, design: .rounded))
            .foregroundColor(.white)
            .frame(width: 60, height: 60)
            .background(
                ZStack {
                    // Key base (darker bottom)
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(white: 0.25),
                                    Color(white: 0.15)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    // Key top surface
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(white: 0.35),
                                    Color(white: 0.25)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .padding(3)

                    // Highlight edge
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                }
            )
            .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 4)
    }
}

struct PlusSign: View {
    var body: some View {
        Text("+")
            .font(.system(size: 24, weight: .medium))
            .foregroundColor(.white.opacity(0.5))
    }
}

// MARK: - Confetti

struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confettiPieces) { piece in
                    ConfettiPieceView(piece: piece)
                }
            }
            .onAppear {
                createConfetti(in: geometry.size)
            }
        }
    }

    private func createConfetti(in size: CGSize) {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
        let centerX = size.width / 2
        let centerY = size.height / 2

        for i in 0..<120 {
            let angle = Double.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 200...600)

            let piece = ConfettiPiece(
                id: i,
                color: colors.randomElement()!,
                x: centerX,
                y: centerY,
                targetX: centerX + cos(angle) * distance,
                targetY: centerY + sin(angle) * distance * 1.5,
                rotation: Double.random(in: 0...360),
                scale: CGFloat.random(in: 0.6...1.2),
                delay: Double.random(in: 0...0.15)
            )
            confettiPieces.append(piece)
        }
    }
}

struct ConfettiPiece: Identifiable {
    let id: Int
    let color: Color
    let x: CGFloat
    let y: CGFloat
    let targetX: CGFloat
    let targetY: CGFloat
    let rotation: Double
    let scale: CGFloat
    let delay: Double
}

struct ConfettiPieceView: View {
    let piece: ConfettiPiece
    @State private var animate = false

    var body: some View {
        Circle()
            .fill(piece.color)
            .frame(width: 8 * piece.scale, height: 8 * piece.scale)
            .rotationEffect(.degrees(animate ? piece.rotation + 360 : piece.rotation))
            .position(
                x: animate ? piece.targetX : piece.x,
                y: animate ? piece.targetY : piece.y
            )
            .opacity(animate ? 0 : 1)
            .onAppear {
                withAnimation(
                    Animation
                        .easeOut(duration: 1.0)
                        .delay(piece.delay)
                ) {
                    animate = true
                }
            }
    }
}

// MARK: - Controller

@MainActor
final class FirstRunController {
    static let shared = FirstRunController()

    private var hudWindow: FirstRunHUD?

    private init() {}

    func showIfNeeded(onComplete: @escaping () -> Void) {
        guard !FirstRunHUD.hasShownFirstRun else {
            return
        }

        guard let screen = NSScreen.main ?? NSScreen.screens.first else {
            return
        }

        hudWindow = FirstRunHUD(
            contentRect: .zero,
            styleMask: [],
            backing: .buffered,
            defer: false
        )

        hudWindow?.show(on: screen, onDismiss: { [weak self] in
            self?.hudWindow = nil
            onComplete()
        })
    }

    func hotkeyPressed() {
        hudWindow?.triggerSuccess()
    }

    var isShowingHUD: Bool {
        hudWindow != nil
    }
}
