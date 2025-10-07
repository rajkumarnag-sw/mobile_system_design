import Foundation

// MARK: - Enums (from diagram)
enum PaymentStatus {
    case completed, failed, pending, unpaid, refunded
}

enum AccountStatus {
    case active, closed, canceled, blocklisted, none
}

enum TicketStatus {
    case issued, inUse, paid, validated, canceled, refunded
}

// MARK: - Value Types
struct Address: Hashable {
    var zipCode: Int
    var address: String
    var city: String
    var state: String
    var country: String
}

struct Person: Hashable {
    var name: String
    var streetAddress: String
    var city: String
    var state: String
    var zipcode: Int
    var country: String
}

// MARK: - Vehicle (abstract -> base class)
class Vehicle {
    let licenseNo: String
    fileprivate(set) var ticket: ParkingTicket?

    init(licenseNo: String) {
        self.licenseNo = licenseNo
    }

    func assignTicket(_ ticket: ParkingTicket) {
        self.ticket = ticket
    }
}

final class Car: Vehicle {}
final class Truck: Vehicle {}
final class Van: Vehicle {}
final class Motorcycle: Vehicle {}

// MARK: - ParkingSpot (abstract -> base class)
class ParkingSpot: Hashable {
    let id: Int
    private(set) var isFree: Bool = true
    private(set) weak var vehicle: Vehicle?

    init(id: Int) { self.id = id }

    @discardableResult
    func assignVehicle(_ vehicle: Vehicle) -> Bool {
        guard isFree else { return false }
        self.vehicle = vehicle
        self.isFree = false
        return true
    }

    @discardableResult
    func removeVehicle() -> Bool {
        guard !isFree else { return false }
        self.vehicle = nil
        self.isFree = true
        return true
    }

    // Hashable
    static func == (lhs: ParkingSpot, rhs: ParkingSpot) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

final class AccessibleSpot: ParkingSpot {}
final class CompactSpot: ParkingSpot {}
final class LargeSpot: ParkingSpot {}
final class MotorcycleSpot: ParkingSpot {}

// Optional extension from “Additional requirements”
final class ElectricSpot: ParkingSpot {
    var panel: ElectricPanel = ElectricPanel()
}

final class ElectricPanel {
    var paidForMinute: Int = 0
    var chargingStartTime: Date?

    @discardableResult
    func cancelCharging() -> Bool {
        chargingStartTime = nil
        paidForMinute = 0
        return true
    }
}

// MARK: - Accounts (abstract -> base + role subclass)
class Account {
    let userName: String
    private(set) var passwordHash: String
    var status: AccountStatus
    let person: Person

    init(userName: String, passwordHash: String, status: AccountStatus, person: Person) {
        self.userName = userName
        self.passwordHash = passwordHash
        self.status = status
        self.person = person
    }

    @discardableResult
    func resetPassword(newHash: String) -> Bool {
        guard status == .active else { return false }
        passwordHash = newHash
        return true
    }
}

final class Admin: Account {
    @discardableResult
    func addParkingSpot(floorName: String, spot: ParkingSpot) -> Bool {
        ParkingLot.shared.addParkingSpot(floorName: floorName, spot: spot)
    }

    @discardableResult
    func addDisplayBoard(floorName: String, displayBoard: DisplayBoard) -> Bool {
        ParkingLot.shared.addDisplayBoard(floorName: floorName, board: displayBoard)
    }

    @discardableResult
    func addEntrance(_ entrance: Entrance) -> Bool {
        ParkingLot.shared.addEntrance(entrance)
    }

    @discardableResult
    func addExit(_ exit: Exit) -> Bool {
        ParkingLot.shared.addExit(exit)
    }
}

// MARK: - DisplayBoard
final class DisplayBoard {
    let id: Int
    // spotType -> list of spots
    private(set) var parkingSpots: [String: [ParkingSpot]] = [:]

    init(id: Int) { self.id = id }

    func addParkingSpot(spotType: String, spots: [ParkingSpot]) {
        parkingSpots[spotType, default: []].append(contentsOf: spots)
    }

    func showFreeSlot() {
        // Stub: render to console / UI
        let lines = parkingSpots.map { type, spots in
            let freeCount = spots.filter { $0IsFree($0) }.count
            return "\(type): \(freeCount) free"
        }
        print("[DisplayBoard#\(id)] " + lines.joined(separator: " | "))
    }

    private func $0IsFree(_ s: ParkingSpot) -> Bool { s.vehicle == nil }
}

// MARK: - Entrance / Exit
final class Entrance {
    let id: Int
    init(id: Int) { self.id = id }

    func getTicket(for vehicle: Vehicle) -> ParkingTicket {
        return ParkingLot.shared.issueTicket(vehicle: vehicle, entrance: self)
    }
}

final class Exit {
    let id: Int
    init(id: Int) { self.id = id }

    func validateTicket(_ ticket: ParkingTicket) -> Bool {
        guard ticket.status == .paid else { return false }
        ticket.exitIns = self
        ticket.status = .validated
        return true
    }
}

// MARK: - Payment (abstract -> protocol + base)
protocol Payment: AnyObject {
    var amount: Double { get set }
    var status: PaymentStatus { get set }
    var timestamp: Date? { get set }

    @discardableResult
    func initiateTransaction() -> Bool
}

class BasePayment: Payment {
    var amount: Double
    var status: PaymentStatus
    var timestamp: Date?

    init(amount: Double, status: PaymentStatus = .pending, timestamp: Date? = nil) {
        self.amount = amount
        self.status = status
        self.timestamp = timestamp
    }

    func initiateTransaction() -> Bool {
        fatalError("Subclasses must override")
    }
}

final class CashPayment: BasePayment {
    override func initiateTransaction() -> Bool {
        // Simulate success
        timestamp = Date()
        status = .completed
        return true
    }
}

final class CreditCardPayment: BasePayment {
    override func initiateTransaction() -> Bool {
        // Simulate external gateway
        timestamp = Date()
        status = .completed
        return true
    }
}

// MARK: - ParkingRate
final class ParkingRate {
    var hours: Double = 0
    var rate: Double = 0

    func calculate(hours: Double, baseRate: Double) -> Double {
        // Example policy: first hour at baseRate, then 0.75x base per additional hour
        let first = min(hours, 1.0) * baseRate
        let remain = max(hours - 1.0, 0)
        return first + remain * (baseRate * 0.75)
    }
}

// MARK: - ParkingTicket
final class ParkingTicket {
    let ticketNo: Int
    let entryTime: Date
    var exitTime: Date?
    var amount: Double = 0
    var status: TicketStatus = .issued

    unowned let vehicle: Vehicle
    var payment: Payment?
    unowned let entrance: Entrance
    weak var exitIns: Exit?

    init(ticketNo: Int, vehicle: Vehicle, entrance: Entrance, entryTime: Date = Date()) {
        self.ticketNo = ticketNo
        self.vehicle = vehicle
        self.entrance = entrance
        self.entryTime = entryTime
    }
}

// MARK: - ParkingFloor (from Additional requirements)
final class ParkingFloor {
    let name: String
    private(set) var spots: Set<ParkingSpot> = []
    private(set) var displayBoards: [DisplayBoard] = []

    init(name: String) { self.name = name }

    func updateDisplayBoard() {
        displayBoards.forEach { $0.showFreeSlot() }
    }

    func assignVehicleToSlot(_ vehicle: Vehicle, prefer type: (ParkingSpot) -> Bool) -> ParkingSpot? {
        guard let spot = spots.first(where: { $0.vehicle == nil && type($0) }) else { return nil }
        _ = spot.assignVehicle(vehicle)
        updateDisplayBoard()
        return spot
    }

    func addParkingSlot(_ spot: ParkingSpot) { spots.insert(spot) }
    func freeSlot(_ spot: ParkingSpot) { _ = spot.removeVehicle(); updateDisplayBoard() }

    func addDisplayBoard(_ board: DisplayBoard) { displayBoards.append(board) }
}

// MARK: - Factories
enum VehicleFactory {
    static func make(type: String, license: String) -> Vehicle {
        switch type.lowercased() {
        case "car": return Car(licenseNo: license)
        case "truck": return Truck(licenseNo: license)
        case "van": return Van(licenseNo: license)
        case "motorcycle": return Motorcycle(licenseNo: license)
        default: return Car(licenseNo: license) // sensible default
        }
    }
}

enum ParkingSpotFactory {
    static func make(type: String, id: Int) -> ParkingSpot {
        switch type.lowercased() {
        case "accessible": return AccessibleSpot(id: id)
        case "compact": return CompactSpot(id: id)
        case "large": return LargeSpot(id: id)
        case "motorcycle": return MotorcycleSpot(id: id)
        case "electric": return ElectricSpot(id: id)
        default: return CompactSpot(id: id)
        }
    }
}

enum PaymentFactory {
    static func make(method: String, amount: Double) -> Payment {
        switch method.lowercased() {
        case "cash": return CashPayment(amount: amount)
        case "card", "creditcard": return CreditCardPayment(amount: amount)
        default: return CashPayment(amount: amount)
        }
    }
}

// MARK: - ParkingLot (Singleton)
final class ParkingLot {
    static let shared = ParkingLot()

    private(set) var id: Int = 1
    private(set) var name: String = "My Parking Lot"
    private(set) var address: Address = .init(zipCode: 0, address: "", city: "", state: "", country: "")
    let parkingRate = ParkingRate()

    private(set) var entrances: [String: Entrance] = [:]
    private(set) var exits: [String: Exit] = [:]
    private(set) var floors: [String: ParkingFloor] = [:]
    private(set) var tickets: [String: ParkingTicket] = [:]
    private(set) var displayBoards: [DisplayBoard] = []

    private var lastTicketNo: Int = 1000
    private var baseRatePerHour: Double = 50 // configurable policy

    private init() {}

    // Admin-facing composition helpers
    @discardableResult
    func addEntrance(_ e: Entrance) -> Bool {
        entrances["\(e.id)"] = e
        return true
    }

    @discardableResult
    func addExit(_ e: Exit) -> Bool {
        exits["\(e.id)"] = e
        return true
    }

    @discardableResult
    func addParkingSpot(floorName: String, spot: ParkingSpot) -> Bool {
        let floor = floors[floorName] ?? ParkingFloor(name: floorName)
        floor.addParkingSlot(spot)
        floors[floorName] = floor
        return true
    }

    @discardableResult
    func addDisplayBoard(floorName: String, board: DisplayBoard) -> Bool {
        let floor = floors[floorName] ?? ParkingFloor(name: floorName)
        floor.addDisplayBoard(board)
        floors[floorName] = floor
        displayBoards.append(board)
        return true
    }

    // Core workflows
    func getParkingTicket(for vehicle: Vehicle) -> ParkingTicket {
        // pick any entrance if not specified
        let entrance = entrances.values.first ?? Entrance(id: 1)
        if entrances.isEmpty { entrances["1"] = entrance }
        return issueTicket(vehicle: vehicle, entrance: entrance)
    }

    fileprivate func issueTicket(vehicle: Vehicle, entrance: Entrance) -> ParkingTicket {
        lastTicketNo += 1
        let ticket = ParkingTicket(ticketNo: lastTicketNo, vehicle: vehicle, entrance: entrance)
        vehicle.assignTicket(ticket)
        tickets["\(ticket.ticketNo)"] = ticket
        ticket.status = .inUse
        return ticket
    }

    func pay(ticket: ParkingTicket, method: String) -> Bool {
        let hours = max(Date().timeIntervalSince(ticket.entryTime) / 3600.0, 0.25)
        let amount = parkingRate.calculate(hours: hours, baseRate: baseRatePerHour)
        ticket.amount = amount

        let payment = PaymentFactory.make(method: method, amount: amount)
        guard payment.initiateTransaction() else { return false }

        ticket.payment = payment
        ticket.status = .paid
        return true
    }

    func isFull() -> Bool {
        // simple check: if every floor has all spots occupied
        guard !floors.isEmpty else { return false }
        return floors.values.allSatisfy { floor in
            floor.spots.allSatisfy { $0.vehicle != nil }
        }
    }
}

// MARK: - Example usage (optional)
/*
let admin = Admin(userName: "admin", passwordHash: "hash", status: .active,
                  person: .init(name: "Owner", streetAddress: "1", city: "X", state: "Y", zipcode: 0, country: "IN"))

admin.addEntrance(Entrance(id: 1))
admin.addExit(Exit(id: 1))
admin.addParkingSpot(floorName: "G", spot: CompactSpot(id: 101))
admin.addDisplayBoard(floorName: "G", displayBoard: DisplayBoard(id: 1))

let bike = Motorcycle(licenseNo: "MH-01-AB-1234")
let ticket = ParkingLot.shared.getParkingTicket(for: bike)
// ... later:
_ = ParkingLot.shared.pay(ticket: ticket, method: "card")
let ok = ParkingLot.shared.exits["1"]?.validateTicket(ticket) ?? false
print("Exit allowed:", ok)
*/
