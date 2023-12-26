import CoreData
import Foundation

class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "CloudReader")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
    }

    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    func saveDocument(_ appDocument: AppDocument) {
        let newDocument = Document(context: container.viewContext)
        newDocument.id = appDocument.id
        newDocument.title = appDocument.title
        newDocument.content = appDocument.content
        newDocument.dateAdded = appDocument.dateAdded

        do {
            try container.viewContext.save()
        } catch {
            // Handle the error appropriately
            print("Failed to save document: \(error)")
        }
    }

    func fetchDocuments() -> [AppDocument] {
        let fetchRequest: NSFetchRequest<Document> = Document.fetchRequest()

        do {
            let documentEntities = try container.viewContext.fetch(fetchRequest)
            return documentEntities.map { AppDocument(id: $0.id!, title: $0.title!, content: $0.content!, dateAdded: $0.dateAdded!) }
        } catch {
            // Handle the error appropriately
            print("Failed to fetch documents: \(error)")
            return []
        }
    }
}
