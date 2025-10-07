import Foundation

// MARK: - Enums (Java enums -> Swift)
enum PaymentStatus { case completed, failed, pending, unpaid, refunded }
enum AccountStatus { case active, closed, canceled, blacklisted, none }
enum TicketStatus { case issued, inUse, paid, validated, canceled, refunded }

// MARK: - Simple data (POJOs)
struct Person: Hashable {
    var name: String
    var address: String
    var phone: String
    var email: String
}

struct Address: Hashable {
    var line1: String
    var city: String
    var state: String
    var zip: String
    var country: String
}

// MARK: - Vehicle (Java abstract class -> base class)
class Vehicle {
    let licenseNo: String
    fileprivate(set) var ticket: ParkingTicket?

    init(licenseNo: String) { self.licenseNo = licenseNo }

    func assignTicket(_ ticket: ParkingTicket) { self.ticket = ticket } // mirrors Java
}

final class Car: Vehicle {}
final class Van: Vehicle {}
final class Truck: Vehicle {}
final class Motorcycle: Vehicle {}

// MARK: - ParkingSpot (Java abstract class -> base class)
class ParkingSpot: Hashable {
    let id: Int
    private(set) var isFree: Bool = true
    private(set) weak var vehicle: Vehicle?

    init(id: Int) { self.id = id }

    @discardableResult
    func assignVehicle(_ v: Vehicle) -> Bool {
        guard isFree else { return false }
        vehicle = v
        isFree = false
        return true
    }

    @discardableResult
    func removeVehicle() -> Bool {
        guard !isFree else { return false }
        vehicle = nil
        isFree = true
        return true
    }

    // Hashable
    static func == (lhs: ParkingSpot, rhs: ParkingSpot) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// Four spot types (match Java names)
final class Handicapped: ParkingSpot {}
final class Compact: ParkingSpot {}
final class Large: ParkingSpot {}
final class MotorcycleSpot: ParkingSpot {}

// Optional: Electric spots/panel (if present in your Java)
final class ElectricSpot: ParkingSpot {
    let panel = ElectricPanel()
}
final class ElectricPanel {
    var paidMinutes: Int = 0
    var chargingStart: Date?
    func start(minutes: Int) { paidMinutes = minutes; chargingStart = Date() }
    func cancel() { paidMinutes = 0; chargingStart = nil }
}

// MARK: - Payments (Java abstract -> protocol + base)
protocol Payment: AnyObject {
    var amount: Double { get set }
    var status: PaymentStatus { get set }
    var timestamp: Date? { get set }
    @discardableResult func initiateTransaction() -> Bool
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
        preconditionFailure("Override in subclass")
    }
}

final class CashPayment: BasePayment {
    override func initiateTransaction() -> Bool {
        timestamp = Date()
        status = .completed
        return true
    }
}

final class CreditCardPayment: BasePayment {
    override func initiateTransaction() -> Bool {
        // simulate gateway success
        timestamp = Date()
        status = .completed
        return true
    }
}

// MARK: - ParkingRate (simple policy; mirror Java’s if different)
final class ParkingRate {
    // Example stepped policy: first hour base, then 0.75x base
    func calculateAmount(hours: Double, baseRatePerHour: Double) -> Double {
        let h = max(hours, 0)
        if h <= 1 { return baseRatePerHour }
        return baseRatePerHour + (h - 1) * (baseRatePerHour * 0.75)
    }
}

// MARK: - Ticket (Java class)
final class ParkingTicket {
    let ticketNo: Int
    let entryTime: Date
    var exitTime: Date?
    var amount: Double = 0
    var status: TicketStatus = .issued

    unowned let vehicle: Vehicle
    unowned let entrance: Entrance
    weak var exitIns: Exit?
    var payment: Payment?

    init(ticketNo: Int, vehicle: Vehicle, entrance: Entrance, entryTime: Date = Date()) {
        self.ticketNo = ticketNo
        self.vehicle = vehicle
        self.entrance = entrance
        self.entryTime = entryTime
    }
}

// MARK: - DisplayBoard (Java: update + showFreeSlot)
final class DisplayBoard {
    let id: Int
    private var spotsByType: [String: [ParkingSpot]] = [:]

    init(id: Int) { self.id = id }

    func update(_ allSpots: [ParkingSpot]) {
        var dict: [String: [ParkingSpot]] = [:]
        for s in allSpots {
            let key = String(describing: type(of: s))
            dict[key, default: []].append(s)
        }
        spotsByType = dict
    }

    func showFreeSlot() {
        let summary = spotsByType
            .map { (type, spots) -> String in
                let free = spots.filter { $0.isFree }.count
                return "\(type): \(free) free"
            }
            .sorted()
            .joined(separator: " | ")
        print("[DisplayBoard #\(id)] \(summary)")
    }
}

// MARK: - Entrance / Exit (Java signatures mirrored)
final class Entrance {
    let id: Int
    init(id: Int) { self.id = id }

    // Return optional to reflect Java "could be null" when lot is full
    func getTicket(_ vehicle: Vehicle) -> ParkingTicket? {
        return ParkingLot.shared.issueTicketIfPossible(vehicle: vehicle, from: self)
    }
}

final class Exit {
    let id: Int
    init(id: Int) { self.id = id }

    func validateTicket(_ ticket: ParkingTicket) {
        // Java returns void; we mutate state
        guard ticket.status == .paid else { return }
        ticket.exitIns = self
        ticket.status = .validated
    }
}

// MARK: - Floor (aggregates spots + display boards)
final class ParkingFloor {
    let name: String
    private(set) var spots: Set<ParkingSpot> = []
    private(set) var displayBoards: [DisplayBoard] = []

    init(name: String) { self.name = name }

    func addSpot(_ spot: ParkingSpot) { spots.insert(spot) }
    func addDisplayBoard(_ board: DisplayBoard) { displayBoards.append(board) }

    // Very simple assignment: first free spot matching predicate
    func assignVehicle(_ v: Vehicle, where predicate: (ParkingSpot) -> Bool) -> ParkingSpot? {
        guard let s = spots.first(where: { $0.isFree && predicate($0) }) else { return nil }
        _ = s.assignVehicle(v)
        // in Java, boards often updated from outside; we keep it explicit
        return s
    }

    func free(_ spot: ParkingSpot) {
        _ = spot.removeVehicle()
    }

    var allSpots: [ParkingSpot] { Array(spots) }
}

// MARK: - Factories (match Java’s simple factories if present)
enum VehicleFactory {
    static func make(_ type: String, license: String) -> Vehicle {
        switch type.lowercased() {
        case "car": return Car(licenseNo: license)
        case "van": return Van(licenseNo: license)
        case "truck": return Truck(licenseNo: license)
        case "motorcycle": return Motorcycle(licenseNo: license)
        default: return Car(licenseNo: license)
        }
    }
}
enum SpotFactory {
    static func make(_ type: String, id: Int) -> ParkingSpot {
        switch type.lowercased() {
        case "handicapped": return Handicapped(id: id)
        case "compact": return Compact(id: id)
        case "large": return Large(id: id)
        case "motorcycle": return MotorcycleSpot(id: id)
        case "electric": return ElectricSpot(id: id)
        default: return Compact(id: id)
        }
    }
}
enum PaymentFactory {
    static func make(_ kind: String, amount: Double) -> Payment {
        switch kind.lowercased() {
        case "cash": return CashPayment(amount: amount)
        case "card", "credit", "creditcard": return CreditCardPayment(amount: amount)
        default: return CashPayment(amount: amount)
        }
    }
}

// MARK: - ParkingLot (Java singleton -> Swift)
final class ParkingLot {
    static let shared = ParkingLot()
    private init() {}

    // Config / policy
    var name: String = "My Parking Lot"
    var address: Address = .init(line1: "", city: "", state: "", zip: "", country: "")
    private(set) var baseRatePerHour: Double = 50
    let rate = ParkingRate()

    // Composition
    private(set) var entrances: [Int: Entrance] = [:]
    private(set) var exits: [Int: Exit] = [:]
    private(set) var floors: [String: ParkingFloor] = [:]
    private(set) var tickets: [Int: ParkingTicket] = [:]

    private var nextTicket: Int = 1000

    // Admin helpers
    func addEntrance(_ e: Entrance) { entrances[e.id] = e }
    func addExit(_ x: Exit) { exits[x.id] = x }

    func addSpot(floor: String, spot: ParkingSpot) {
        let f = floors[floor] ?? ParkingFloor(name: floor)
        f.addSpot(spot)
        floors[floor] = f
    }

    func addDisplayBoard(floor: String, board: DisplayBoard) {
        let f = floors[floor] ?? ParkingFloor(name: floor)
        f.addDisplayBoard(board)
        floors[floor] = f
    }

    // -------- Core workflows (faithful to Java) --------

    // Issue a ticket only if a spot can be allocated (return nil if full/unavailable)
    fileprivate func issueTicketIfPossible(vehicle: Vehicle, from entrance: Entrance) -> ParkingTicket? {
        // naive matching rule based on vehicle type; customize if your Java has rules
        let matcher: (ParkingSpot) -> Bool = {
            switch vehicle {
            case is Motorcycle: return $0 is MotorcycleSpot || $0 is Compact || $0 is Large || $0 is Handicapped
            case is Car, is Van: return $0 is Compact || $0 is Large || $0 is Handicapped
            case is Truck: return $0 is Large
            default: return $0 is Compact || $0 is Large
            }
        }

        guard let (floor, spot) = findFirstFreeSpot(where: matcher) else {
            return nil // lot (for this vehicle type) is full
        }

        _ = spot.assignVehicle(vehicle)
        nextTicket += 1
        let t = ParkingTicket(ticketNo: nextTicket, vehicle: vehicle, entrance: entrance, entryTime: Date())
        vehicle.assignTicket(t)
        tickets[t.ticketNo] = t
        t.status = .inUse

        // Display boards are typically refreshed by caller; expose helper:
        refreshBoards(of: floor)
        return t
    }

    // Payment flow
    func pay(_ ticket: ParkingTicket, via method: String) -> Bool {
        let hours = max(Date().timeIntervalSince(ticket.entryTime) / 3600.0, 0.25) // 15 min min
        let amount = rate.calculateAmount(hours: hours, baseRatePerHour: baseRatePerHour)
        ticket.amount = amount

        let payment = PaymentFactory.make(method, amount: amount)
        guard payment.initiateTransaction() else { return false }

        ticket.payment = payment
        ticket.status = .paid
        ticket.exitTime = Date()
        return true
    }

    // Query
    func isFull() -> Bool {
        guard !floors.isEmpty else { return false }
        return floors.values.allSatisfy { floor in floor.allSpots.allSatisfy { !$0.isFree } }
    }

    // Utilities used by DisplayBoard demo
    func getAllSpots() -> [ParkingSpot] { floors.values.flatMap { $0.allSpots } }
    func refreshBoards() { floors.values.forEach { f in f.displayBoards.forEach { $0.update(f.allSpots) } } }

    // refresh boards for a particular floor
    private func refreshBoards(of floor: ParkingFloor) { floor.displayBoards.forEach { $0.update(floor.allSpots) } }

    private func findFirstFreeSpot(where predicate: (ParkingSpot) -> Bool) -> (ParkingFloor, ParkingSpot)? {
        for floor in floors.values {
            if let s = floor.allSpots.first(where: { $0.isFree && predicate($0) }) {
                return (floor, s)
            }
        }
        return nil
    }
}

// MARK: - Playground demo (commented)
// This mirrors Java's scenarios: getTicket -> update board -> pay -> validate -> update board
/*
let lot = ParkingLot.shared
let entrance = Entrance(id: 1)
let exit = Exit(id: 1)
lot.addEntrance(entrance)
lot.addExit(exit)

lot.addSpot(floor: "G", spot: Compact(id: 101))
lot.addSpot(floor: "G", spot: Compact(id: 102))
lot.addSpot(floor: "G", spot: Large(id: 201))
lot.addSpot(floor: "G", spot: MotorcycleSpot(id: 301))
let board = DisplayBoard(id: 1)
lot.addDisplayBoard(floor: "G", board: board)
lot.refreshBoards()
board.showFreeSlot()

print("\n→→→ Scenario: Customer enters")
let car = Car(licenseNo: "KA-01-HH-1234")
let t1 = entrance.getTicket(car)
lot.refreshBoards()
board.showFreeSlot()

print("\n→→→ Scenario: Customer pays & exits")
if let ticket = t1 {
    _ = lot.pay(ticket, via: "card")
    exit.validateTicket(ticket)
    lot.refreshBoards()
    board.showFreeSlot()
}
*/
