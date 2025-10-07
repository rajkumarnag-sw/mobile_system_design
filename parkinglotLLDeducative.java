// educative.io

// Enumerations for status tracking in the system
enum PaymentStatus { COMPLETED, FAILED, PENDING, UNPAID, REFUNDED }
enum AccountStatus { ACTIVE, CLOSED, CANCELED, BLACKLISTED, NONE }
enum TicketStatus { ISSUED, IN_USE, PAID, VALIDATED, CANCELED, REFUNDED }

// Custom data type for personal and address information
class Person {
    private String name;
    private String address;
    private String phone;
    private String email;
}

class Address {
    private int zipCode;
    private String street;
    private String city;
    private String state;
    private String country;
}


// Abstract base class for parking spots
abstract class ParkingSpot {
    private int id;
    private boolean isFree;
    private Vehicle vehicle; // Association: Each spot can be assigned to one vehicle

    public abstract boolean assignVehicle(Vehicle vehicle);

    public boolean removeVehicle() {
        // Logic to remove vehicle from spot and mark as free
        return true;
    }
}

// Four types of parking spots as subclasses
class Handicapped extends ParkingSpot {
    public boolean assignVehicle(Vehicle vehicle) { /* ... */ return true; }
}

class Compact extends ParkingSpot {
    public boolean assignVehicle(Vehicle vehicle) { /* ... */ return true; }
}

class Large extends ParkingSpot {
    public boolean assignVehicle(Vehicle vehicle) { /* ... */ return true; }
}

class MotorcycleSpot extends ParkingSpot {
    public boolean assignVehicle(Vehicle vehicle) { /* ... */ return true; }
}

abstract class Vehicle {
    private String licenseNo;
    private ParkingTicket ticket; // Association: Each vehicle has a ticket

    public abstract void assignTicket(ParkingTicket ticket);
}

class Car extends Vehicle {
    public void assignTicket(ParkingTicket ticket) { /* ... */ }
}
class Van extends Vehicle {
    public void assignTicket(ParkingTicket ticket) { /* ... */ }
}
class Truck extends Vehicle {
    public void assignTicket(ParkingTicket ticket) { /* ... */ }
}
class Motorcycle extends Vehicle {
    public void assignTicket(ParkingTicket ticket) { /* ... */ }
}
abstract class Account {
    private String userName;
    private String password;
    private Person person;
    private AccountStatus status;

    public abstract boolean resetPassword();
}

class Admin extends Account {
    public boolean addParkingSpot(ParkingSpot spot) { /* ... */ return true; }
    public boolean addDisplayBoard(DisplayBoard board) { /* ... */ return true; }
    public boolean addEntrance(Entrance entrance) { /* ... */ return true; }
    public boolean addExit(Exit exit) { /* ... */ return true; }

    public boolean resetPassword() { /* ... */ return true; }
}

class DisplayBoard {
    private int id;
    private Map<String, List<ParkingSpot>> parkingSpots;

    public DisplayBoard(int id) { /* ... */ }
    public void addParkingSpot(String spotType, List<ParkingSpot> spots) { /* ... */ }
    public void showFreeSlot() { /* ... */ }
}

class ParkingRate {
    private double hours;
    private double rate;

    public double calculate(double duration, Vehicle vehicle, ParkingSpot spot) {
        // Pricing logic can use duration, vehicle type, spot type, etc.
        return 0.0;
    }
}

class Entrance {
    private int id;
    public ParkingTicket getTicket(Vehicle vehicle) { /* ... */ return null; }
}

class Exit {
    private int id;
    public void validateTicket(ParkingTicket ticket) { /* ... */ }
}

class ParkingTicket {
    private int ticketNo;
    private Date entryTime;
    private Date exitTime;
    private double amount;
    private TicketStatus status;

    private Vehicle vehicle;
    private Payment payment; // Composition: Ticket owns Payment
    private Entrance entrance;
    private Exit exitIns;
}


abstract class Payment {
    private double amount;
    private PaymentStatus status;
    private Date timestamp;

    public abstract boolean initiateTransaction();
}

class Cash extends Payment {
    public boolean initiateTransaction() { /* ... */ return true; }
}

class CreditCard extends Payment {
    public boolean initiateTransaction() { /* ... */ return true; }
}


class ParkingLot {
    private int id;
    private String name;
    private Address address;
    private ParkingRate parkingRate;

    private Map<String, Entrance> entrances;
    private Map<String, Exit> exits;
    private Map<Integer, ParkingSpot> spots;
    private Map<String, ParkingTicket> tickets;
    private List<DisplayBoard> displayBoards;

    // Singleton implementation
    private static ParkingLot parkingLot = null;
    private ParkingLot() { /* ... */ }
    public static ParkingLot getInstance() {
        if (parkingLot == null) { parkingLot = new ParkingLot(); }
        return parkingLot;
    }

    public boolean addEntrance(Entrance entrance) { /* ... */ return true; }
    public boolean addExit(Exit exit) { /* ... */ return true; }
    public boolean addParkingSpot(ParkingSpot spot) { /* ... */ return true; }
    public boolean addDisplayBoard(DisplayBoard board) { /* ... */ return true; }

    public ParkingTicket getParkingTicket(Vehicle vehicle) { /* ... */ return null; }
    public boolean isFull(ParkingSpot spotType) { /* ... */ return false; }
}


public class Driver {
    public static void main(String[] args) throws InterruptedException {
        // -------------- SYSTEM INITIALIZATION --------------
        System.out.println("\n====================== PARKING LOT SYSTEM DEMO ======================\n");

        ParkingLot lot = ParkingLot.getInstance();
        lot.addSpot(new Handicapped(1));
        lot.addSpot(new Compact(2));
        lot.addSpot(new Large(3));
        lot.addSpot(new MotorcycleSpot(4));

        DisplayBoard board = new DisplayBoard(1);
        lot.addDisplayBoard(board);

        Entrance entrance = new Entrance(1);
        Exit exit = new Exit(1);

        // ----------------- SCENARIO 1: CUSTOMER ENTERS, PARKS -----------------
        System.out.println("\n→→→ SCENARIO 1: Customer enters and parks a car\n");

        Vehicle car = new Car("KA-01-HH-1234");
        System.out.println("-> Car " + car.getLicenseNo() + " arrives at entrance");
        ParkingTicket ticket1 = entrance.getTicket(car);

        System.out.println("-> Updating display board after parking:");
        board.update(lot.getAllSpots());
        board.showFreeSlot();

        // ----------------- SCENARIO 2: CUSTOMER EXITS AND PAYS -----------------
        System.out.println("\n→→→ SCENARIO 2: Customer exits and pays\n");

        System.out.println("-> Car " + car.getLicenseNo() + " proceeds to exit panel");
        Thread.sleep(1500); // Simulate parking duration (1.5 sec)
        exit.validateTicket(ticket1);

        System.out.println("-> Updating display board after exit:");
        board.update(lot.getAllSpots());
        board.showFreeSlot();

        // --------- SCENARIO 3: FILLING LOT AND REJECTING ENTRY IF FULL ---------
        System.out.println("\n→→→ SCENARIO 3: Multiple customers attempt to enter; lot may become full\n");

        // Vehicles arriving
        Vehicle van = new Van("KA-01-HH-9999");
        Vehicle motorcycle = new Motorcycle("KA-02-XX-3333");
        Vehicle truck = new Truck("KA-04-AA-9998");
        Vehicle car2 = new Car("DL-09-YY-1234");

        System.out.println("-> Van " + van.getLicenseNo() + " arrives at entrance");
        ParkingTicket ticket2 = entrance.getTicket(van);

        System.out.println("-> Motorcycle " + motorcycle.getLicenseNo() + " arrives at entrance");
        ParkingTicket ticket3 = entrance.getTicket(motorcycle);

        System.out.println("-> Truck " + truck.getLicenseNo() + " arrives at entrance");
        ParkingTicket ticket4 = entrance.getTicket(truck);

        System.out.println("-> Car " + car2.getLicenseNo() + " arrives at entrance");
        ParkingTicket ticket5 = entrance.getTicket(car2);

        System.out.println("-> Updating display board after several parkings:");
        board.update(lot.getAllSpots());
        board.showFreeSlot();

        // Try to park another car (lot may now be full)
        Vehicle car3 = new Car("UP-01-CC-1001");
        System.out.println("-> Car " + car3.getLicenseNo() + " attempts to park (should be denied if lot is full):");
        ParkingTicket ticket6 = entrance.getTicket(car3);

        board.update(lot.getAllSpots());
        board.showFreeSlot();

        System.out.println("\n====================== END OF DEMONSTRATION ======================\n");
    }
}