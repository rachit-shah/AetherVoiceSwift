import SwiftUI

struct URLInputSheet: View {
    @Binding var isPresented: Bool
    @State private var urlStrings: [String] = [""]
    var fetchContent: ([String]) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                ScrollView {
                    ForEach(0..<urlStrings.count, id: \.self) { index in
                        HStack {
                            TextField("http://example.com", text: $urlStrings[index])
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .disableAutocorrection(true)
                                .padding(.horizontal)
                            
                            if urlStrings.count > 1 {
                                Button(action: {
                                    urlStrings.remove(at: index)
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
                
                HStack(spacing: 20) {
                    Button(action: {
                        urlStrings.append("")
                    }) {
                        Image(systemName: "plus.circle.fill")
                        .padding(.horizontal, 16)
                    }
                    .background(Color.green)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    
                    Button(action: {
                        fetchContent(urlStrings.filter { !$0.isEmpty })
                        isPresented = false
                    }) {
                        Image(systemName: "checkmark.circle.fill")
                        .padding(.horizontal, 16)
                    }
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Enter URLs")
            #if os(iOS)
            .navigationBarItems(trailing: Button(action: {
                isPresented = false
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(.gray)
            })
            #endif
        }
    }
}
