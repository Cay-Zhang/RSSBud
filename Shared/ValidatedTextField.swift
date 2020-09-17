//
//  ValidatedTextField.swift
//  RSSBud
//
//  Created by Cay Zhang on 2020/9/17.
//

import SwiftUI

struct ValidatedTextField: View {
    
    var titleKey: LocalizedStringKey
    @Binding var text: String
    var validate: (String) -> Bool
    
    @State private var isEditing: Bool = false
    @State private var transientText: String = ""
    
    init(_ titleKey: LocalizedStringKey, text _text: Binding<String>, validation validate: @escaping (String) -> Bool = { _ in true }) {
        self.titleKey = titleKey
        self._text = _text
        self.validate = validate
    }
    
    var transientTextBinding: Binding<String> {
        Binding<String>(get: { transientText }, set: { newValue in
            withAnimation {
                transientText = newValue
                if validate(newValue) {
                    text = newValue
                }
            }
        })
    }
    
    var body: some View {
        HStack {
            TextField(
                titleKey,
                text: isEditing ? transientTextBinding : $text,
                onEditingChanged: { isEditing in
                    withAnimation {
                        self.isEditing = isEditing
                        if isEditing {
                            self.transientText = self.text
                        }
                    }
                }
            )
            
            if !validate(isEditing ? transientText : text) {
                Image(systemName: "exclamationmark.circle.fill")
                    .imageScale(.large)
                    .foregroundColor(.red)
                    .transition(
                        AnyTransition.scale(scale: 0.7)
                            .combined(with: AnyTransition.opacity)
                            .animation(.spring())
                    )
            }
        }
    }
}

struct ValidatedTextField_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            IntegrationSettingsView()
        }
    }
}
