// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ElectronicWasteTracking {
    
    enum WasteStatus { Created, Collected, Sorted, Processed, Sold, Completed }
    enum WasteCategory { Undefined, Repairable, SecondHand, Refining, Landfill }

    struct Waste {
        uint256 id;
        address payable user;  // Waste Owner
        address collector;
        address recycler;
        address buyer; // Second-hand market, Refinery, Manufacturer, Landfill
        WasteStatus status;
        WasteCategory category;
        string metadata;
        uint256 timestamp;
        uint256 price;  // Payment amount for waste collection
        uint256 resalePrice; // Price for selling after recycling
        bool paid;  // Payment status for collection
        bool sold;  // Payment status for resale
    }

    mapping(uint256 => Waste) public wasteRegistry;
    uint256 public wasteCounter;

    event WasteCreated(uint256 indexed id, address indexed user, string metadata);
    event WasteCollected(uint256 indexed id, address indexed collector, uint256 price);
    event WasteSorted(uint256 indexed id, WasteCategory category);
    event WasteProcessed(uint256 indexed id, WasteStatus status);
    event WasteSold(uint256 indexed id, address indexed buyer, uint256 resalePrice);
    event PaymentMade(address indexed to, uint256 amount);

    modifier onlyUser(uint256 _id) {
        require(wasteRegistry[_id].user == msg.sender, "Not authorized!");
        _;
    }

    modifier onlyCollector(uint256 _id) {
        require(wasteRegistry[_id].collector == msg.sender, "Not authorized!");
        _;
    }

    modifier onlyRecycler(uint256 _id) {
        require(wasteRegistry[_id].recycler == msg.sender, "Not authorized!");
        _;
    }

    modifier onlyBuyer(uint256 _id) {
        require(wasteRegistry[_id].buyer == msg.sender, "Not authorized!");
        _;
    }

    // 🟢 Submit waste (User)
    function submitWaste(string memory _metadata, uint256 _price) external {
        wasteCounter++;
        wasteRegistry[wasteCounter] = Waste({
            id: wasteCounter,
            user: payable(msg.sender),
            collector: address(0),
            recycler: address(0),
            buyer: address(0),
            status: WasteStatus.Created,
            category: WasteCategory.Undefined,
            metadata: _metadata,
            timestamp: block.timestamp,
            price: _price,
            resalePrice: 0,
            paid: false,
            sold: false
        });

        emit WasteCreated(wasteCounter, msg.sender, _metadata);
    }

    // 🟢 Assign collector (User)
    function assignCollector(uint256 _id, address _collector) external onlyUser(_id) {
        require(wasteRegistry[_id].collector == address(0), "Collector already assigned!");
        wasteRegistry[_id].collector = _collector;
    }

    // 🟢 Collector collects waste and pays user
    function markCollected(uint256 _id) external payable onlyCollector(_id) {
        Waste storage waste = wasteRegistry[_id];
        require(waste.status == WasteStatus.Created, "Invalid status!");
        require(msg.value == waste.price, "Incorrect payment!");

        waste.user.transfer(msg.value); // Transfer payment immediately
        waste.status = WasteStatus.Collected;
        waste.paid = true;

        emit PaymentMade(waste.user, msg.value);
        emit WasteCollected(_id, msg.sender, msg.value);
    }

    // 🟢 Assign recycler (Collector)
    function assignRecycler(uint256 _id, address _recycler) external onlyCollector(_id) {
        require(wasteRegistry[_id].recycler == address(0), "Recycler already assigned!");
        wasteRegistry[_id].recycler = _recycler;
    }

    // 🟢 Recycler sorts waste
    function categorizeWaste(uint256 _id, WasteCategory _category) external onlyRecycler(_id) {
        require(wasteRegistry[_id].status == WasteStatus.Collected, "Invalid status!");
        wasteRegistry[_id].category = _category;
        wasteRegistry[_id].status = WasteStatus.Sorted;

        emit WasteSorted(_id, _category);
    }

    // 🟢 Recycler processes waste
    function markProcessed(uint256 _id) external onlyRecycler(_id) {
        require(wasteRegistry[_id].status == WasteStatus.Sorted, "Not sorted yet!");

        wasteRegistry[_id].status = WasteStatus.Processed;
        emit WasteProcessed(_id, WasteStatus.Processed);
    }

    // 🟢 Assign Buyer (Recycler sets resale price)
    function assignBuyer(uint256 _id, address _buyer, uint256 _resalePrice) external onlyRecycler(_id) {
        require(wasteRegistry[_id].status == WasteStatus.Processed, "Not processed yet!");
        require(wasteRegistry[_id].buyer == address(0), "Buyer already assigned!");

        wasteRegistry[_id].buyer = _buyer;
        wasteRegistry[_id].resalePrice = _resalePrice;
    }

    // 🟢 Buyer purchases waste (e.g., Second-hand market, Refinery, Manufacturer, Landfill)
    function purchaseWaste(uint256 _id) external payable onlyBuyer(_id) {
        Waste storage waste = wasteRegistry[_id];
        require(waste.status == WasteStatus.Processed, "Waste not available for sale!");
        require(msg.value == waste.resalePrice, "Incorrect payment!");

        payable(waste.recycler).transfer(msg.value); // Transfer payment to recycler
        waste.status = WasteStatus.Sold;
        waste.sold = true;

        emit PaymentMade(waste.recycler, msg.value);
        emit WasteSold(_id, msg.sender, msg.value);
    }

    // 🔍 Get waste details
    function getWaste(uint256 _id) external view returns (Waste memory) {
        return wasteRegistry[_id];
    }
}
