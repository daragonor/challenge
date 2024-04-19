//
//  ContentView.swift
//  Overplay-SwiftUI
//
//  Created by Alvaro Peche on 19/04/24.
//

import AVKit
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ViewModel()
    var body: some View {
        ZStack {
            VideoPlayer(player: viewModel.player)
                .navigationBarBackButtonHidden()
                .onAppear {
                    viewModel.play()
                }
                .onDisappear {
                    viewModel.player.pause()
                }
                //MARK: PAUSE ON SHAKE
                .onShakeGesture {
                    viewModel.status = viewModel.player.playOrPause()
                }
                .padding(.bottom, 24)
            VStack {
                Spacer().frame(maxWidth: .infinity)
                Text(viewModel.status)
            }
        }
    }
}

#Preview {
    ContentView()
}
