// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract EdTechToken is ERC20, ERC20Burnable, Ownable, ReentrancyGuard {
    uint256 public immutable maxSupply;
    uint256 public halvingPeriod = 365 days;
    uint256 public lastHalving;
    uint256 public rewardPerTask = 100 * 10**decimals();
    uint256 public stakingAPY = 10; // 10% APY
    
    struct Staker {
        uint256 stakedAmount;
        uint256 stakingStartTime;
        bool isStaking;
    }
    
    mapping(address => Staker) public stakers;
    mapping(address => uint256) public referralRewards;
    
    event TokensStaked(address indexed user, uint256 amount);
    event TokensUnstaked(address indexed user, uint256 amount);
    event TokensClaimed(address indexed user, uint256 amount);
    event TokensBurned(uint256 amount);
    event TaskCompleted(address indexed user, uint256 reward);
    
    // Updated constructor with proper initialization
    constructor() 
        ERC20("EdTechToken", "EDT") 
        Ownable(msg.sender) 
    {
        maxSupply = 100000000 * 10**decimals(); // 100 million tokens
        _mint(msg.sender, maxSupply / 10); // Mint 10% supply to owner
        lastHalving = block.timestamp;
    }
    
    function rewardForTaskCompletion(address student) external onlyOwner {
        require(totalSupply() + rewardPerTask <= maxSupply, "Max supply reached");
        _mint(student, rewardPerTask);
        emit TaskCompleted(student, rewardPerTask);
    }
    
    function halveReward() external onlyOwner {
        require(block.timestamp >= lastHalving + halvingPeriod, "Too early for halving");
        rewardPerTask /= 2;
        lastHalving = block.timestamp;
    }
    
    function stakeTokens(uint256 amount) external nonReentrant {
        require(balanceOf(msg.sender) >= amount, "Not enough balance");
        require(amount > 0, "Amount should be greater than 0");
        
        _transfer(msg.sender, address(this), amount);
        stakers[msg.sender] = Staker(amount, block.timestamp, true);
        
        emit TokensStaked(msg.sender, amount);
    }
    
    function unstakeTokens() external nonReentrant {
        Staker storage staker = stakers[msg.sender];
        require(staker.isStaking, "No tokens staked");
        
        uint256 duration = block.timestamp - staker.stakingStartTime;
        uint256 reward = (staker.stakedAmount * stakingAPY * duration) / (365 days * 100);
        uint256 totalAmount = staker.stakedAmount + reward;
        
        _mint(msg.sender, reward);
        _transfer(address(this), msg.sender, staker.stakedAmount);
        
        delete stakers[msg.sender];
        
        emit TokensUnstaked(msg.sender, totalAmount);
    }
    
    function rewardReferral(address referrer, address referee, uint256 amount) external onlyOwner {
        uint256 reward = amount / 10;
        require(totalSupply() + reward <= maxSupply, "Max supply reached");
        
        _mint(referrer, reward);
        referralRewards[referrer] += reward;
    }
    
    function burnTokens(uint256 amount) external onlyOwner {
        _burn(owner(), amount);
        emit TokensBurned(amount);
    }
}