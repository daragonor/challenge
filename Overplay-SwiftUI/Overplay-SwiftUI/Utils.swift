//
//  Utils.swift
//  Overplay-SwiftUI
//
//  Created by Alvaro Peche on 19/04/24.
//

import Foundation
import SwiftUI
import AVKit
import MediaPlayer

struct ShakeGestureViewModifier: ViewModifier {
    let action: () -> Void
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.deviceDidShake)) { _ in
                action()
            }
    }
}

extension View {
    public func onShakeGesture(perform action: @escaping () -> Void) -> some View {
        self.modifier(ShakeGestureViewModifier(action: action))
    }
}

extension UIDevice {
    static let deviceDidShake = Notification.Name("deviceDidShake")
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with: UIEvent?) {
        guard motion == .motionShake else { return }
        
        NotificationCenter.default.post(name: UIDevice.deviceDidShake, object: nil)
    }
}

class CustomAVPlayer: AVPlayer {
    enum VideoState: String { case playing, paused }
    var state = VideoState.paused
    override func pause() {
        state = .paused
        super.pause()
    }
    
    override func play() {
        state = .playing
        super.play()
    }
    
    func playOrPause() -> String {
        switch timeControlStatus {
        case .playing: pause()
        case .paused: play()
        default: break
        }
        return state.rawValue.uppercased()
    }
}
enum VariationAction {
    case increase
    case decrease
    
    var volumeVariation: Float {
        switch self {
        case .increase: 0.05
        case .decrease: -0.05
        }
    }
}
extension MPVolumeView {
    private static func canChange(action: VariationAction, on slider: UISlider) -> Bool {
        switch action {
        case .decrease: slider.value != slider.minimumValue
        case .increase: slider.value != slider.maximumValue
        }
    }
    
    static func changeVolume(_ action: VariationAction) {
        let volumeView = MPVolumeView()
        guard let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider
        else { return }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            guard canChange(action: action, on: slider) else { return }
            slider.value = slider.value + action.volumeVariation
        }
    }
}
