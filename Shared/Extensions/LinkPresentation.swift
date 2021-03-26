//
//  LinkPresentation.swift
//  RSSBud
//
//  Created by Cay Zhang on 2020/7/6.
//

import SwiftUI
import LinkPresentation

struct LinkPresentation: UIViewRepresentable {
    
    var metadata: LPLinkMetadata
    
    func makeUIView(context: Context) -> LPLinkView {
        let view = LPLinkView(metadata: metadata)
        return view
    }
    
    func updateUIView(_ view: LPLinkView, context: Context) {
        view.metadata = metadata
    }
}
