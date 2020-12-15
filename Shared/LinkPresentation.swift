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
        provider.startFetchingMetadata(for: previewURL) { (result, _) in
            DispatchQueue.main.async {
                view.metadata = result ?? defaultMetadata()
            }
        }
    }
    
    func defaultMetadata() -> LPLinkMetadata {
        let metadata = LPLinkMetadata()
        metadata.originalURL = previewURL
        metadata.url = previewURL
        return metadata
    }
}
