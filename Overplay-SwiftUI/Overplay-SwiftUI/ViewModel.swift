//
//  ViewModel.swift
//  Overplay-SwiftUI
//
//  Created by Alvaro Peche on 19/04/24.
//

import Foundation
import SwiftUI
import CoreMotion
import MediaPlayer

extension ContentView {
    enum Status: String { case started }
    enum Orientation { case portrait, landscape }
    class ViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
        @Published var status = Status.started.rawValue.uppercased()
        @Published var player = CustomAVPlayer()
        var orientation: Orientation
        private var observer: NSObjectProtocol?
        var locationManager: CLLocationManager
        let manager = CMMotionManager()
        
        private var lastRotation: Double = 0
        private let VIDEO_URL = "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4"
        private let VIDEO_TIME_VARIATION: Double = 5
        private let VARIATION: Double = 0.5
        private func VARIATION_THRESHOLD(action: VariationAction) -> ClosedRange<Double> {
            switch action {
            case .decrease:
                //if the phone has changed to landscape and the last rotation was to the right, the rotation angle will stop being negative on the decrease threshold, therefore it needs a new interval
                if orientation == .landscape, lastRotation > 0 {
                    return (Double.pi + VARIATION)...(Double.pi + Double.pi/2)
                } else { return (-Double.pi + VARIATION)...(0) }
            case .increase:
                //if the phone has changed to landscape and the last rotation was to the left, the rotation angle will stop being postive on the increase threshold, therefore it needs a new interval
                if orientation == .landscape, lastRotation < 0 {
                    return (-Double.pi - Double.pi/2)...(-Double.pi - VARIATION)
                } else { return (0)...(Double.pi - VARIATION) }
                
            }
        }
        
        override init() {
            locationManager = CLLocationManager()
            orientation = UIDevice.current.orientation.isLandscape ? .landscape: .portrait
            super.init()
            locationManager.requestAlwaysAuthorization()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.distanceFilter = 10
            locationManager.startUpdatingLocation()
            
            if manager.isDeviceMotionAvailable {
                manager.deviceMotionUpdateInterval = 0.25
                manager.startDeviceMotionUpdates(to: .main) { [weak self] (data, error) in
                    guard let self = self, let data = data else { return }
                    
                    //MARK: X AXIS CONTROL ON VOLUME
                    ///by checking the variation on the Z axis, you can see hows it's rotated along the X axis
                    if -VARIATION > data.gravity.z {
                        MPVolumeView.changeVolume(.decrease)
                    } else if VARIATION < data.gravity.z {
                        MPVolumeView.changeVolume(.increase)
                    }
                    //MARK: Z AXIS CONTROL ON PLAYBACK
                    ///getting the rotation on the Z axis depends on the variation of the X axis and depending on the orientation, we tweak it to match the new orientation
                    var rotationOnZ = atan2(data.gravity.x, data.gravity.y)
                    switch orientation {
                    case .portrait: rotationOnZ += 0
                    case .landscape: rotationOnZ += lastRotation > 0 ? Double.pi/2 : -Double.pi/2
                    }
                    lastRotation = rotationOnZ
                    print(rotationOnZ)
                    if VARIATION_THRESHOLD(action: .decrease).contains(rotationOnZ) {
                        playback(isForward: false)
                        status = "-\(Int(VIDEO_TIME_VARIATION)) SECONDS"
                    } else if VARIATION_THRESHOLD(action: .increase).contains(rotationOnZ) {
                        playback(isForward: true)
                        status = "+\(Int(VIDEO_TIME_VARIATION)) SECONDS"
                    }
                }
            }
            
            observer = NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: nil) { [unowned self] note in
                guard let device = note.object as? UIDevice else { return }
                orientation = device.orientation.isLandscape ? .landscape : .portrait
            }
            
        }
        
        deinit { if let observer = observer { NotificationCenter.default.removeObserver(observer) } }
        
        //MARK: LAUNCH AND PLAY VIDEO
        func play() {
            guard let url = URL(string: VIDEO_URL) else { return }
            player = CustomAVPlayer(url: url)
            player.play()
        }
        
        //MARK: RESTART ON DISTANCE CHANGE
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            player.seek(to: CMTime.zero)
            status = "RESTARTED"
        }
        
        private func playback(isForward: Bool) {
            guard let duration = player.currentItem?.duration else { return }
            
            let currentElapsedTime = player.currentTime().seconds
            var destinationTime = isForward ? (currentElapsedTime + VIDEO_TIME_VARIATION) : (currentElapsedTime - VIDEO_TIME_VARIATION)
            
            if destinationTime < 0 { destinationTime = 0 }
            if destinationTime < duration.seconds {
                let newTime = CMTime(value: Int64(destinationTime * 1000 as Float64), timescale: 1000)
                player.seek(to: newTime)
            }
        }
    }
}
