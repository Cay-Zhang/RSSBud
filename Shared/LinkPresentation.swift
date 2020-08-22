//
//  LinkPresentation.swift
//  RSSBud
//
//  Created by Cay Zhang on 2020/7/6.
//

import SwiftUI
import LinkPresentation

struct LinkPresentation: UIViewRepresentable {
    
    var previewURL: URL
    
    @State private var redraw: Bool = false
    
    func makeUIView(context: Context) -> LPLinkView {
        let view = LPLinkView(url: previewURL)
        return view
    }
    
    func updateUIView(_ view: LPLinkView, context: Context) {
        let provider = LPMetadataProvider()
        provider.startFetchingMetadata(for: previewURL) { (metadata, error) in
            DispatchQueue.main.async {
                if let md = metadata {
                    view.metadata = md
                } else if error != nil {
                    let md = LPLinkMetadata()
                    md.title = "Error"
                    view.metadata = md
                }
            }
        }
    }
}
