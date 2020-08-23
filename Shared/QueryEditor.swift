//
//  QueryEditor.swift
//  RSSBud
//
//  Created by Cay Zhang on 2020/8/21.
//

import SwiftUI

struct QueryEditor: View {
    
    @Binding var queryItems: [URLQueryItem]
    
    var body: some View {
        LazyVStack {
            Menu {
                let currentQueryItemNames = queryItems.map(\.name)
                
                Menu {
                    ForEach(QueryEditor.filterInQueryItemNames, id: \.self) { name in
                        Button(action: addQueryItemAction(name: name)) {
                            label(forQueryItemNamed: name)
                        }.environment(\.isEnabled, !currentQueryItemNames.contains(name))
                    }
                } label: { Label("Include", systemImage: "line.horizontal.3.decrease.circle.fill") }
                
                Menu {
                    ForEach(QueryEditor.filterOutQueryItemNames, id: \.self) { name in
                        Button(action: addQueryItemAction(name: name)) {
                            label(forQueryItemNamed: name)
                        }.environment(\.isEnabled, !currentQueryItemNames.contains(name))
                    }
                } label: { Label("Exclude", systemImage: "line.horizontal.3.decrease.circle") }
                
                ForEach(QueryEditor.otherQueryItemNames, id: \.self) { name in
                    Button(action: addQueryItemAction(name: name)) {
                        label(forQueryItemNamed: name)
                    }.environment(\.isEnabled, !currentQueryItemNames.contains(name))
                }
            } label: {
                Label("Add Query Item", systemImage: "plus")
                    .padding(.horizontal)
                    .roundedRectangleBackground()
//                    .font(Font.body.weight(.semibold))
            }.frame(maxWidth: .infinity, alignment: .trailing)
            
            ForEach(queryItems, id: \.name) { item in
                GroupBox(label:
                    HStack {
                        label(forQueryItemNamed: item.name)
                        Spacer()
                        Button(action: removeQueryItemAction(name: item.name)) {
                            Image(systemName: "trash.fill")
                        }
                    }
                ) {
                    TextField("Value", text: queryItemBinding(for: item.name))
                }.contextMenu {
                    Button(action: removeQueryItemAction(name: item.name)) {
                        Label("Delete", systemImage: "trash.fill")
                    }
                }
            }
        }
    }
    
    func addQueryItemAction(name: String) -> () -> Void {
        return {
            withAnimation {
                if !queryItems.contains(where: { $0.name == name }) {
                    queryItems.append(URLQueryItem(name: name, value: ""))
                }
            }
        }
    }
    
    func removeQueryItemAction(name: String) -> () -> Void {
        return {
            withAnimation {
                if let index = queryItems.firstIndex(where: { $0.name == name }) {
                    queryItems.remove(at: index)
                }
            }
        }
    }
    
    func queryItemBinding(for name: String) -> Binding<String> {
        Binding(get: {
            queryItems.first(where: { $0.name == name })?.value ?? ""
        }, set: { newValue in
            if let index = queryItems.firstIndex(where: { $0.name == name }) {
                queryItems[index].value = newValue
            } else {
                queryItems.append(URLQueryItem(name: name, value: newValue))
            }
        })
    }
    
    func label(forQueryItemNamed name: String) -> some View {
        switch name {
        case "filter":
            return Label("Include Titles and Descriptions", systemImage: "line.horizontal.3.decrease.circle.fill")
        case "filter_title":
            return Label("Include Titles", systemImage: "line.horizontal.3.decrease.circle.fill")
        case "filter_description":
            return Label("Include Descriptions", systemImage: "line.horizontal.3.decrease.circle.fill")
        case "filter_author":
            return Label("Include Authors", systemImage: "person.crop.circle.fill.badge.checkmark")
        case "filter_time":
            return Label("Include Recent (Seconds)", systemImage: "clock.fill")
        
        case "filterout":
            return Label("Exclude Titles and Descriptions", systemImage: "line.horizontal.3.decrease.circle")
        case "filterout_title":
            return Label("Exclude Titles", systemImage: "line.horizontal.3.decrease.circle")
        case "filterout_description":
            return Label("Exclude Descriptions", systemImage: "line.horizontal.3.decrease.circle")
        case "filterout_author":
            return Label("Exclude Authors", systemImage: "person.crop.circle.badge.xmark")
        
        case "filter_case_sensitive":
            return Label("Case Sensitivity", systemImage: "textformat")
        case "limit":
            return Label("Limit Entry Count", systemImage: "number")
        default:
            return Label {
                Text(verbatim: name).foregroundColor(.secondary)
            } icon: {
                Image(systemName: "ellipsis")
            }
        }
    }
}

extension QueryEditor {
    static let filterInQueryItemNames: [String] = [
        "filter", "filter_title", "filter_description", "filter_author", "filter_time"
    ]
    
    static let filterOutQueryItemNames: [String] = [
        "filterout", "filterout_title", "filterout_description", "filterout_author"
    ]
    
    static let otherQueryItemNames: [String] = [
        "filter_case_sensitive",
        "limit"
    ]
}

struct QueryEditor_Previews: PreviewProvider {
    
    @State static var queryItems: [URLQueryItem] = [
        URLQueryItem(name: "filterout_description", value: "test"),
        URLQueryItem(name: "custom", value: "11111")
    ]
    
    static var previews: some View {
        ScrollView {
            QueryEditor(queryItems: $queryItems)
        }
    }
}
