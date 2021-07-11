//
//  AutoAdvancingProgressView.swift
//  RSSBud
//
//  Created by Cay Zhang on 2021/7/11.
//

import SwiftUI
import Combine

struct AutoAdvancingProgressView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        ProgressView(value: viewModel.fakeProgress)
            .modifier(_AppearanceActionModifier(
                appear: {
                    viewModel.isShown = true
                    viewModel.animateProgress(recordedRealProgress: viewModel.realProgress)
                }, disappear: {
                    viewModel.isShown = false
                }
            ))
    }
    
    class ViewModel: ObservableObject {
        @Published var fakeProgress: Double = 0
        var realProgress: Double = 0
        var isShown: Bool = false
        
        var progress: Double {
            get { realProgress }
            set {
                realProgress = newValue
                fakeProgress = newValue
                DispatchQueue.main.async {
                    self.animateProgress(recordedRealProgress: newValue)
                }
            }
        }
        
        func animateProgress(recordedRealProgress: Double) {
            if isShown && realProgress == recordedRealProgress && realProgress < 0.9 {
                withAnimation(.easeOut(duration: 10)) {
                    fakeProgress = 0.9
                }
            }
        }
    }
}

// does not work
struct AutoAdvancingProgressView_Previews: PreviewProvider {
    
    @State static var progress: Double = 0
    static let viewModel = AutoAdvancingProgressView.ViewModel()
    
    static var previews: some View {
        VStack {
            AutoAdvancingProgressView(viewModel: viewModel)
            Stepper("Progress: \(progress)") {
                withAnimation {
                    progress += 0.2
                    viewModel.progress += 0.2
                }
            } onDecrement: {
                withAnimation {
                    progress -= 0.2
                    viewModel.progress -= 0.2
                }
            }

        }
    }
}
