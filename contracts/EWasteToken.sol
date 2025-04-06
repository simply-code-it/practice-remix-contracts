// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract EWasteToken is ERC20, AccessControl {
    // Roles
    bytes32 public constant COLLECTOR_ROLE = keccak256("COLLECTOR_ROLE");
    bytes32 public constant RECYCLER_ROLE = keccak256("RECYCLER_ROLE");
    bytes32 public constant DISMANTLER_ROLE = keccak256("DISMANTLER_ROLE");
    bytes32 public constant REPAIRER_ROLE = keccak256("REPAIRER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Reward Structure
    uint256 public constant BASE_DISPOSAL_REWARD = 10 ether;
    uint256 public constant BASE_COLLECTION_REWARD = 5 ether;
    uint256 public constant BASE_RECYCLING_REWARD = 7 ether;
    uint256 public constant BASE_REPAIR_REWARD = 8 ether;
    uint256 public constant BASE_DISMANTLE_REWARD = 6 ether;
    uint256 public constant PER_ITEM_REWARD = 1 ether;
    uint256 public constant PER_GRAM_REWARD = 0.01 ether;

    struct WasteItem {
        uint256 id;
        address creator;
        string itemType;
        uint256 weight;
        uint256 quantity;
        Status status;
        address currentHandler;
        bool isRepairable;
    }

    enum Status { 
        CREATED, 
        COLLECTED, 
        REPAIRABLE,
        REPAIRED,
        RECYCLED, 
        DISMANTLED, 
        RESOLD 
    }

    mapping(uint256 => WasteItem) public wasteItems;
    uint256 public itemCounter;

    // Status-Specific Events (One per status)
    event ItemCreated(uint256 indexed id, address indexed creator, uint256 quantity, uint256 weight);
    event ItemCollected(uint256 indexed id, address indexed collector, uint256 reward);
    event ItemMarkedRepairable(uint256 indexed id, address indexed collector);
    event ItemRepaired(uint256 indexed id, address indexed repairer, uint256 reward);
    event ItemRecycled(uint256 indexed id, address indexed recycler, uint256 reward);
    event ItemDismantled(uint256 indexed id, address indexed dismantler, uint256 reward);
    event ItemResold(uint256 indexed id, address indexed seller);

    // Reward Calculation Event
    event RewardCalculated(
        uint256 indexed id,
        Status status,
        uint256 baseReward,
        uint256 quantityBonus,
        uint256 weightBonus,
        uint256 totalReward
    );

    constructor() ERC20("EWasteToken", "EWT") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _mint(msg.sender, 10_000_000 * 10**decimals());
    }

    function createItem(
        string memory _itemType,
        uint256 _weight,
        uint256 _quantity,
        bool _isRepairable
    ) external {
        require(_quantity > 0 && _weight > 0, "Invalid input");
        
        uint256 newId = itemCounter++;
        wasteItems[newId] = WasteItem({
            id: newId,
            creator: msg.sender,
            itemType: _itemType,
            weight: _weight,
            quantity: _quantity,
            status: Status.CREATED,
            currentHandler: msg.sender,
            isRepairable: _isRepairable
        });

        // uint256 reward = _calculateAndMintReward(newId, Status.CREATED);
        emit ItemCreated(newId, msg.sender, _quantity, _weight);
    }

    function collectItem(uint256 _id) external onlyRole(COLLECTOR_ROLE) {
        require(wasteItems[_id].status == Status.CREATED, "Invalid status");
        wasteItems[_id].status = Status.COLLECTED;
        wasteItems[_id].currentHandler = msg.sender;
        
        uint256 reward = _calculateAndMintReward(_id, Status.COLLECTED);
        emit ItemCollected(_id, msg.sender, reward);
    }

    function markAsRepairable(uint256 _id) external onlyRole(COLLECTOR_ROLE) {
        require(wasteItems[_id].status == Status.COLLECTED, "Invalid status");
        require(wasteItems[_id].isRepairable, "Item not repairable");
        
        wasteItems[_id].status = Status.REPAIRABLE;
        emit ItemMarkedRepairable(_id, msg.sender);
    }

    function repairItem(uint256 _id) external onlyRole(REPAIRER_ROLE) {
        require(wasteItems[_id].status == Status.REPAIRABLE, "Invalid status");
        
        wasteItems[_id].status = Status.REPAIRED;
        wasteItems[_id].currentHandler = msg.sender;
        
        uint256 reward = _calculateAndMintReward(_id, Status.REPAIRED);
        emit ItemRepaired(_id, msg.sender, reward);
    }

    function recycleItem(uint256 _id) external onlyRole(RECYCLER_ROLE) {
        require(
            wasteItems[_id].status == Status.COLLECTED || 
            wasteItems[_id].status == Status.REPAIRED,
            "Invalid status"
        );
        
        wasteItems[_id].status = Status.RECYCLED;
        wasteItems[_id].currentHandler = msg.sender;
        
        uint256 reward = _calculateAndMintReward(_id, Status.RECYCLED);
        emit ItemRecycled(_id, msg.sender, reward);
    }

    function dismantleItem(uint256 _id) external onlyRole(DISMANTLER_ROLE) {
        require(wasteItems[_id].status == Status.RECYCLED, "Invalid status");
        
        wasteItems[_id].status = Status.DISMANTLED;
        wasteItems[_id].currentHandler = msg.sender;
        
        uint256 reward = _calculateAndMintReward(_id, Status.DISMANTLED);
        emit ItemDismantled(_id, msg.sender, reward);
    }

    function resellItem(uint256 _id) external {
        require(wasteItems[_id].status == Status.DISMANTLED, "Invalid status");
        require(wasteItems[_id].currentHandler == msg.sender, "Not owner");
        
        wasteItems[_id].status = Status.RESOLD;
        emit ItemResold(_id, msg.sender);
    }

    // Internal reward calculation and minting
    function _calculateAndMintReward(uint256 _id, Status _status) internal returns (uint256) {
        (uint256 base, uint256 qBonus, uint256 wBonus) = _getRewardComponents(_id, _status);
        uint256 totalReward = base + qBonus + wBonus;
        
        _mint(msg.sender, totalReward);
        
        emit RewardCalculated(
            _id,
            _status,
            base,
            qBonus,
            wBonus,
            totalReward
        );
        
        return totalReward;
    }

    function _getRewardComponents(uint256 _id, Status _status) internal view returns (
        uint256 baseReward,
        uint256 quantityBonus,
        uint256 weightBonus
    ) {
        WasteItem memory item = wasteItems[_id];
        
        if (_status == Status.CREATED) {
            baseReward = BASE_DISPOSAL_REWARD;
        } else if (_status == Status.COLLECTED) {
            baseReward = BASE_COLLECTION_REWARD;
        } else if (_status == Status.REPAIRED) {
            baseReward = BASE_REPAIR_REWARD;
        } else if (_status == Status.RECYCLED) {
            baseReward = BASE_RECYCLING_REWARD;
        } else if (_status == Status.DISMANTLED) {
            baseReward = BASE_DISMANTLE_REWARD;
        }

        quantityBonus = PER_ITEM_REWARD * item.quantity;
        
        // Apply multipliers for certain statuses
        if (_status == Status.REPAIRED) {
            quantityBonus *= 2; // Double reward for repair
        } else if (_status == Status.RECYCLED) {
            weightBonus = (PER_GRAM_REWARD * item.weight) * 2;
        } else if (_status == Status.DISMANTLED) {
            weightBonus = (PER_GRAM_REWARD * item.weight) * 3;
        } else {
            weightBonus = PER_GRAM_REWARD * item.weight;
        }
    }

    // Admin functions
    function addRole(address _account, bytes32 _role) external onlyRole(ADMIN_ROLE) {
        grantRole(_role, _account);
    }

    function mintTokens(address _to, uint256 _amount) external onlyRole(ADMIN_ROLE) {
        _mint(_to, _amount);
    }
}