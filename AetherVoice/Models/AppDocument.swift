import Foundation

struct AppDocument: Identifiable {
    var id: UUID
    var title: String
    var content: String
    var dateAdded: Date
    
    init(id: UUID = UUID(), title: String, content: String, dateAdded: Date = Date()) {
        self.id = id
        self.title = title
        self.content = content
        self.dateAdded = dateAdded
    }
}
