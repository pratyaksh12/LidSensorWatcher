import SwiftUI

struct MainView: View {
    @StateObject private var sensor = LidSensorManager()
    
    var body: some View {
        VStack(spacing: 0) { // Set spacing to 0 for total control
            // 1. Header
            VStack(spacing: 5) {
                Text("Lid Orientation")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.secondary)
                
                Text("\(String(format: "%.1f", sensor.angle))°")
                    .font(.system(size: 48, weight: .black, design: .monospaced))
            }
            .padding(.top, 40)
            
            // This pushes everything below it (the laptop) down
            Spacer()
            
            // 2. The custom visualizer component
            // We reduced the vertical padding to keep it closer to the footer
            LidVisualiser(angle: sensor.angle)
                .padding(.bottom, 40)
            
            // 3. Status Footer
            HStack {
                Circle()
                    .fill(sensor.angle > 0 ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                Text(sensor.angle > 0 ? "Hardware Stream Active" : "Waiting for sensor movement...")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 20)
        }
        .frame(width: 350, height: 450)
        .background(VisualEffectView().ignoresSafeArea())
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { event in
                let key = event.charactersIgnoringModifiers ?? ""
                let isDown = event.type == .keyDown
                
                if "asdfghjkl".contains(key) && !event.isARepeat {
                    print("Key: \(key) Down: \(isDown)")
                    sensor.sendKey(key: key, isDown: isDown)
                    return nil // Consume event (don't beep)
                }
                return event
            }
        }
    }
}

struct LidVisualiser: View {
    let angle: Double
    
    var body: some View {
        // We use bottomLeading to ensure the hinge stays at the bottom left of the frame
        ZStack(alignment: .bottomLeading) {
            
            // 1. THE BASE
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.gray.opacity(0.5))
                .frame(width: 180, height: 4)
            
            // 2. THE LID
            RoundedRectangle(cornerRadius: 2)
                .fill(LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .frame(width: 175, height: 4)
                .rotationEffect(.degrees(-angle), anchor: .leading)
                .animation(.interpolatingSpring(stiffness: 80, damping: 15), value: angle)
        }
        // Fixed height prevents the component from jumping around
        .frame(width: 200, height: 100, alignment: .bottomLeading)
        .offset(x: 20)
    }
}

// MARK: - HELPER: macOS Blur Effect
// This allows us to use the standard macOS 'Glass' background in SwiftUI
struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        // 'behindWindow' makes the wallpaper blur through
        view.blendingMode = .behindWindow
        view.state = .active
        view.material = .underWindowBackground
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        // No updates needed for a static background
    }
}
