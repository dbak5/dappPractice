//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

contract Hostel{
    address payable tenant;
    address payable landlord;
    uint public no_of_rooms = 0;
    uint public no_of_agreement = 0;
    uint public no_of_rent = 0;

    struct Room{
        uint roomid;
        uint agreementid;
        string roomname;
        string roomaddress;
        uint rent_per_month;
        uint securityDeposit;
        uint timestamp;
        bool vacant;
        address payable landlord;
        address payable currentTenant;
    }
    //map previous structure with a uint(named : roomid).
    mapping(uint => Room) public Room_by_No;

    struct RoomAgreement{
        uint roomid;
        uint agreementid;
        string Roomname;
        string RoomAddresss;
        uint rent_per_month;
        uint securityDeposit;
        uint lockInPeriod;
        uint timestamp;
        address payable tenantAddress;
        address payable landlordAddress;
    }
   
    mapping(uint => RoomAgreement) public RoomAgreement_by_No;

    struct Rent{
        uint rentno;
        uint roomid;
        uint agreementid;
        string Roomname;
        string RoomAddresss;
        uint rent_per_month;
        uint timestamp;
        address payable tenantAddress;
        address payable landlordAddress;
    }

    mapping(uint => Rent) public Rent_by_No;

    //The following will check if the message sender is the landlord.
    modifier onlyLandlord(uint _index) {
        require(msg.sender == Room_by_No[_index].landlord, "Only landlord can access this");
        _;
    }

    //The following will check if the message sender is anyone except the landlord.
    modifier notLandLord(uint _index) {
        require(msg.sender != Room_by_No[_index].landlord, "Only Tenant can access this");
        _;
    }

    //The following will check whether the room is vacant or not.
    modifier OnlyWhileVacant(uint _index){
        require(Room_by_No[_index].vacant == true, "Room is currently Occupied.");
        _;
    }

    //The following will check whether the tenant has enough Ether in his wallet to pay the rent.
    modifier enoughRent(uint _index) {
        require(msg.value >= uint(Room_by_No[_index].rent_per_month), "Not enough Ether in your wallet");
        _;
    }
    //The following will check whether the tenant has enough Ether in his wallet to pay a one-time security deposit and one month's rent in advance.
    modifier enoughAgreementfee(uint _index) {
        require(msg.value >= uint(uint(Room_by_No[_index].rent_per_month) + uint(Room_by_No[_index].securityDeposit)), "Not enough Ether in your wallet");
        _;
    }

    //The following will check whether the tenant's address is the same as who has signed the previous rental agreement.
    modifier sameTenant(uint _index) {
        require(msg.sender == Room_by_No[_index].currentTenant, "No previous agreement found with you & landlord");
        _;
    }

    //The following will check whether any time is left for the agreement to end.
    modifier AgreementTimesLeft(uint _index) {
        uint _AgreementNo = Room_by_No[_index].agreementid;
        uint time = RoomAgreement_by_No[_AgreementNo].timestamp + RoomAgreement_by_No[_AgreementNo].lockInPeriod;
        require(block.timestamp < time, "Agreement already Ended");
        _;
    }
    
    //The following will check whether 365 days have passed after the last agreement has been created.
    modifier AgreementTimesUp(uint _index) {
        uint _AgreementNo = Room_by_No[_index].agreementid;
        uint time = RoomAgreement_by_No[_AgreementNo].timestamp + RoomAgreement_by_No[_AgreementNo].lockInPeriod;
        require(block.timestamp > time, "Time is left for contract to end");
        _;
    }

    //The following will check whether 30 days have passed after the last rent payment.
    modifier RentTimesUp(uint _index) {
        uint time = Room_by_No[_index].timestamp + 30 days;
        require(block.timestamp >= time, "Time left to pay Rent");
        _;
    }

    //The following function will be used to add Rooms.
    function addRoom(
        string memory _roomname,
        string memory _roomaddress,
        uint _rentcost,
        uint  _securitydeposit) 
        public {
        require(msg.sender != address(0));
        no_of_rooms ++;
        bool _vacancy = true;
        Room_by_No[no_of_rooms] = Room(
            no_of_rooms,
            0,
            _roomname,
            _roomaddress,
            _rentcost,
            _securitydeposit,
            0,
            _vacancy,
            payable(msg.sender),
            payable(address(0))); 
    }

    //A function to sign the rental agreement for a hostel room between the landlord and a tenant.
    // will only execute if the user is Tenant, meaning that the user's address and the landlord's address don't match.
    // will only execute if the user has enough ether (payable 'ether') in their Ethereum wallet.(Enough ether means = one-time security deposit + 1st month's rent)
    // will only execute only if the said room is vacant and the tenant has enough ether in their wallet.
    function signAgreement(uint _index) public payable notLandLord(_index) enoughAgreementfee(_index) OnlyWhileVacant(_index) {
        require(msg.sender != address(0));
        address payable _landlord = Room_by_No[_index].landlord;
        uint totalfee = Room_by_No[_index].rent_per_month + Room_by_No[_index].securityDeposit;
        _landlord.transfer(totalfee);
        no_of_agreement++;
        Room_by_No[_index].currentTenant = payable(msg.sender);
        Room_by_No[_index].vacant = false;
        Room_by_No[_index].timestamp = block.timestamp;
        Room_by_No[_index].agreementid = no_of_agreement;
        RoomAgreement_by_No[no_of_agreement]=RoomAgreement(
            _index,
            no_of_agreement,
            Room_by_No[_index].roomname,
            Room_by_No[_index].roomaddress,
            Room_by_No[_index].rent_per_month,
            Room_by_No[_index].securityDeposit,
            365 days,
            block.timestamp,
            payable(msg.sender),
            _landlord);
        no_of_rent++;
        Rent_by_No[no_of_rent] = Rent(
            no_of_rent,
            _index,
            no_of_agreement,
            Room_by_No[_index].roomname,
            Room_by_No[_index].roomaddress,
            Room_by_No[_index].rent_per_month,
            block.timestamp,
            payable(msg.sender),
            _landlord);
    }

    // will only execute if the user's address and the landlord's address are the same.
    // will only execute if the tenant had signed that agreement more than a year ago.
function agreementCompleted(uint _index) public payable onlyLandlord(_index) AgreementTimesUp(_index){
    require(msg.sender != address(0));
    require(Room_by_No[_index].vacant == false, "Room is currently Occupied.");
    Room_by_No[_index].vacant = true;
    address payable _Tenant = Room_by_No[_index].currentTenant;
    uint _securitydeposit = Room_by_No[_index].securityDeposit;
    _Tenant.transfer(_securitydeposit);
}

    // will only execute if the user's address and the landlord's address are the same.
    // will only execute if the tenant had signed that agreement less than a year ago.
    function agreementTerminated(uint _index) public onlyLandlord(_index) AgreementTimesLeft(_index){
        require(msg.sender != address(0));
        Room_by_No[_index].vacant = true;
    }
}
