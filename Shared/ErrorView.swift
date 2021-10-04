//
//  ErrorView.swift
//  RSSBud
//
//  Created by Cay Zhang on 2021/9/21.
//

import SwiftUI

struct ErrorView: View {
    var error: Error
    var editOriginalURL: () -> Void
    
    @Environment(\.customOpenURLAction) var openURL
    @Environment(\.xCallbackContext) var xCallbackContext: Binding<XCallbackContext>
    
    func cancelXCallbackText() -> LocalizedStringKey {
        if let source = xCallbackContext.wrappedValue.source {
            return LocalizedStringKey("Continue in \(source)")
        } else {
            return LocalizedStringKey("Continue")
        }
    }
    
    func cancelXCallback() {
        let url = xCallbackContext
            .wrappedValue
            .cancel
        url.map(openURL.callAsFunction(_:))
        xCallbackContext.wrappedValue = nil
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark")
                .font(.system(size: 24, weight: .semibold, design: .default))
                .foregroundColor(.red)
                .frame(width: 70, height: 70)
                .background(Color(UIColor.tertiarySystemBackground))
                .clipShape(Circle())
            
            Text("Error Occurred")
                .font(.system(size: 24, weight: .semibold, design: .default))
            
            Text(verbatim: error.localizedDescription)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                if xCallbackContext.wrappedValue.cancel == nil {
                    Button("Edit Original URL", systemImage: "character.cursor.ibeam", action: editOriginalURL)
                } else {
                    Button(cancelXCallbackText(), systemImage: "arrowtriangle.backward.fill", withAnimation: .default, action: cancelXCallback)
                }
            }.buttonStyle(CayButtonStyle(wideContainerWithBackgroundColor: Color(uiColor: .tertiarySystemBackground)))
        }.padding(.horizontal, 8)
        .padding(.top, 20)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct ErrorView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView_Previews.previews
    }
}
