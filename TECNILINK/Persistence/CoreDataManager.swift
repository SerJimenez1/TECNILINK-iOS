import CoreData
import Foundation

final class CoreDataManager {

    static let shared = CoreDataManager()

    private let container: NSPersistentContainer

    private init() {
        container = NSPersistentContainer(name: "TECNILINK")
        container.loadPersistentStores { _, error in
            if let error { fatalError("Core Data failed: \(error)") }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    var context: NSManagedObjectContext { container.viewContext }

    // MARK: - Create / Update

    func saveServicio(_ servicio: Servicio) {
        let request: NSFetchRequest<ServicioEntity> = ServicioEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", servicio.id)
        let entity = (try? context.fetch(request).first) ?? ServicioEntity(context: context)

        entity.id              = servicio.id
        entity.specialty       = servicio.specialty.rawValue
        entity.serviceDesc     = servicio.description
        entity.estimatedPrice  = servicio.estimatedPrice
        entity.scheduledDate   = servicio.scheduledDate
        entity.status          = servicio.status.rawValue
        entity.technicianId    = servicio.technicianId
        entity.userId          = servicio.userId
        entity.escrowStatus    = servicio.escrowStatus.rawValue
        entity.technicianName  = servicio.technicianName
        save()
    }

    // MARK: - Read

    func fetchServicios(for userId: String) -> [Servicio] {
        let request: NSFetchRequest<ServicioEntity> = ServicioEntity.fetchRequest()
        request.predicate     = NSPredicate(format: "userId == %@", userId)
        request.sortDescriptors = [NSSortDescriptor(key: "scheduledDate", ascending: false)]
        return (try? context.fetch(request))?.compactMap(mapToServicio) ?? []
    }

    func fetchAllServicios() -> [Servicio] {
        let request: NSFetchRequest<ServicioEntity> = ServicioEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "scheduledDate", ascending: false)]
        return (try? context.fetch(request))?.compactMap(mapToServicio) ?? []
    }

    // MARK: - Update status

    func updateStatus(id: String, status: ServiceStatus) {
        let request: NSFetchRequest<ServicioEntity> = ServicioEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        if let entity = try? context.fetch(request).first {
            entity.status = status.rawValue
            save()
        }
    }

    // MARK: - Delete

    func deleteServicio(id: String) {
        let request: NSFetchRequest<ServicioEntity> = ServicioEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        if let entity = try? context.fetch(request).first {
            context.delete(entity)
            save()
        }
    }

    // MARK: - Private

    private func save() {
        guard context.hasChanges else { return }
        do { try context.save() } catch { context.rollback() }
    }

    private func mapToServicio(_ e: ServicioEntity) -> Servicio? {
        guard
            let id        = e.id,
            let specRaw   = e.specialty,   let specialty = Specialty(rawValue: specRaw),
            let desc      = e.serviceDesc,
            let date      = e.scheduledDate,
            let statRaw   = e.status,      let status    = ServiceStatus(rawValue: statRaw),
            let techId    = e.technicianId,
            let uid       = e.userId,
            let escRaw    = e.escrowStatus, let escrow   = EscrowStatus(rawValue: escRaw)
        else { return nil }

        return Servicio(id: id, specialty: specialty, description: desc,
                        estimatedPrice: e.estimatedPrice, scheduledDate: date,
                        status: status, technicianId: techId, userId: uid,
                        technicianName: e.technicianName, escrowStatus: escrow)
    }
}
