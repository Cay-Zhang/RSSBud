//
//  QueryEditor.swift
//  RSSBud
//
//  Created by Cay Zhang on 2020/8/21.
//

import SwiftUI

struct QueryEditor: View {
    @Binding var queryItems: [URLQueryItem]
    var scrollViewProxy: ScrollViewProxy? = nil
    @FocusState var focusedQueryItemName: String?

    @Environment(\.customOpenURLAction) var openURL
    
    var body: some View {
        LazyVStack(spacing: 16) {
            HStack(spacing: 16) {
                Button("RSSHub Parameters Help", systemImage: "text.book.closed.fill", withAnimation: .default) {
                    openURL(URLComponents(string: "https://docs.rsshub.app/parameter.html")!)
                }
                addParameterMenu
            }.buttonStyle(CayButtonStyle(wideContainerWithBackgroundColor: Color(uiColor: .secondarySystemBackground)))
            .menuStyle(CayMenuStyle())
            
            ForEach(queryItems, id: \.name) { item in
                GroupBox(label:
                    HStack {
                        label(forQueryItemNamed: item.name)
                        Spacer()
                        Button(action: removeQueryItemAction(name: item.name)) {
                            Image(systemName: "trash.fill")
                        }
                    }
                ) { groupBoxContent(forQueryItem: item) }
                .id(item.name)
                .contextMenu {
                    Button(action: removeQueryItemAction(name: item.name)) {
                        Label("Delete", systemImage: "trash.fill")
                    }
                }
            }
        }.onChange(of: focusedQueryItemName) { name in
            if let name {
                Task { @MainActor in
                    try await Task.sleep(nanoseconds: 150_000_000)  // 0.15s
                    withAnimation(BottomBar.transitionAnimation.speed(2)) {
                        scrollViewProxy?.scrollTo(name)
                    }
                }
            }
        }
    }
    
    var addParameterMenu: some View {
        Menu {
            let currentQueryItemNames = queryItems.map(\.name)
            
            Menu {
                ForEach(QueryEditor.filterInQueryItemNames, id: \.self) { name in
                    Button(action: addQueryItemAction(name: name)) {
                        label(forQueryItemNamed: name)
                    }.environment(\.isEnabled, !currentQueryItemNames.contains(name))
                }
            } label: { Label("Include...", systemImage: "line.horizontal.3.decrease.circle.fill") }
            
            Menu {
                ForEach(QueryEditor.filterOutQueryItemNames, id: \.self) { name in
                    Button(action: addQueryItemAction(name: name)) {
                        label(forQueryItemNamed: name)
                    }.environment(\.isEnabled, !currentQueryItemNames.contains(name))
                }
            } label: { Label("Exclude...", systemImage: "line.horizontal.3.decrease.circle") }
            
            ForEach(QueryEditor.otherQueryItemNames, id: \.self) { name in
                Button(action: addQueryItemAction(name: name)) {
                    label(forQueryItemNamed: name)
                }.environment(\.isEnabled, !currentQueryItemNames.contains(name))
            }
        } label: {
            Label("RSSHub Parameters Add", systemImage: "plus")
                .modifier(WideButtonContainerModifier(backgroundColor: Color(uiColor: .secondarySystemBackground)))
        }
    }
    
    @ViewBuilder func groupBoxContent(forQueryItem item: URLQueryItem) -> some View {
        let queryItemValueBinding = queryItemBinding(for: item.name)
        
        switch item.name {
        case "filter_time":
            TextField("Time Interval", text: queryItemValueBinding)
                .keyboardType(.decimalPad)
                .focused($focusedQueryItemName, equals: item.name)
        case "mode":
            Toggle("Enabled", isOn: Binding(get: {
                queryItemValueBinding.wrappedValue == "fulltext"
            }, set: { newValue in
                queryItemValueBinding.wrappedValue = newValue ? "fulltext" : ""
            }))
        case "opencc":
            TextField("OpenCC Configuration", text: queryItemValueBinding)
                .focused($focusedQueryItemName, equals: item.name)
        case "filter_case_sensitive":
            Toggle("Sensitive", isOn: Binding(get: {
                queryItemValueBinding.wrappedValue != "false"
            }, set: { newValue in
                queryItemValueBinding.wrappedValue = newValue.description
            }))
        case "limit":
            TextField("Max Entry Count", text: queryItemValueBinding)
                .keyboardType(.numberPad)
                .focused($focusedQueryItemName, equals: item.name)
        case "tgiv":
            TextField("Template Hash", text: queryItemValueBinding)
                .disableAutocorrection(true)
                .autocapitalization(.none)
                .focused($focusedQueryItemName, equals: item.name)
        case "scihub":
            Toggle("Enabled", isOn: Binding(get: {
                !queryItemValueBinding.wrappedValue.isEmpty
            }, set: { newValue in
                queryItemValueBinding.wrappedValue = newValue ? "true" : ""
            }))
        case _ where item.name.starts(with: "filter"):
            TextField("Regular Expression", text: queryItemValueBinding)
                .focused($focusedQueryItemName, equals: item.name)
        default:
            TextField("Value", text: queryItemValueBinding)
                .focused($focusedQueryItemName, equals: item.name)
        }
    }
    
    func addQueryItemAction(name: String) -> () -> Void {
        return {
            withAnimation {
                if !queryItems.contains(where: { $0.name == name }) {
                    queryItems.append(URLQueryItem(name: name, value: QueryEditor.defaultValue(forQueryItemNamed: name)))
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
            return Label("filter", systemImage: "line.horizontal.3.decrease.circle.fill")
        case "filter_title":
            return Label("filter_title", systemImage: "line.horizontal.3.decrease.circle.fill")
        case "filter_description":
            return Label("filter_description", systemImage: "line.horizontal.3.decrease.circle.fill")
        case "filter_author":
            return Label("filter_author", systemImage: "person.crop.circle.fill.badge.checkmark")
        case "filter_time":
            return Label("filter_time", systemImage: "clock.fill")
        
        case "filterout":
            return Label("filterout", systemImage: "line.horizontal.3.decrease.circle")
        case "filterout_title":
            return Label("filterout_title", systemImage: "line.horizontal.3.decrease.circle")
        case "filterout_description":
            return Label("filterout_description", systemImage: "line.horizontal.3.decrease.circle")
        case "filterout_author":
            return Label("filterout_author", systemImage: "person.crop.circle.badge.xmark")
        
        case "mode":
            return Label("mode", systemImage: "doc.text.fill.viewfinder")
        case "opencc":
            return Label("opencc", systemImage: "arrow.2.squarepath")
        case "filter_case_sensitive":
            return Label("filter_case_sensitive", systemImage: "textformat")
        case "limit":
            return Label("limit", systemImage: "number")
        case "tgiv":
            return Label("tgiv", systemImage: "paperplane.fill")
        case "scihub":
            return Label("scihub", systemImage: "books.vertical.fill")
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
        "mode",
        "opencc",
        "filter_case_sensitive",
        "limit",
        "tgiv",
        "scihub"
    ]
}

extension QueryEditor {
    static let customDefaultValues: [String : String] = [
        "mode" : "fulltext",
        "opencc" : "s2t",
        "filter_case_sensitive" : "true",
        "limit" : "10",
        "scihub" : "true"
    ]
    
    static func defaultValue(forQueryItemNamed name: String) -> String {
        customDefaultValues[name, default: ""]
    }
}

struct QueryEditor_Previews: PreviewProvider {
    
    @State static var queryItems: [URLQueryItem] = [
        URLQueryItem(name: "filterout_description", value: "test"),
        URLQueryItem(name: "custom", value: "11111")
    ]
    
    static var previews: some View {
        NavigationView {
            ScrollView {
                QueryEditor(queryItems: $queryItems)
                    .padding(.horizontal, 16)
            }.navigationTitle("Query Editor")
        }
    }
}
