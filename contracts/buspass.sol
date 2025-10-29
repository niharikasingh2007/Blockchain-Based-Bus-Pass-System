// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title BusPass
 * @dev Blockchain Based Bus Pass System
 *      Pay 0.05 ETH → Get 30-day unlimited bus pass
 */
contract BusPass {
    address public immutable authority;
    uint256 public constant PRICE = 0.05 ether;
    uint256 public constant VALIDITY = 30 days;

    struct Pass {
        address owner;
        uint256 startTime;
        uint256 expiryTime;
        bool active;
    }

    mapping(uint256 => Pass) public passes;
    mapping(address => uint256) public userToPass;
    uint256 public passCounter;

    event PassBought(uint256 indexed passId, address owner);
    event PassUsed(uint256 indexed passId, address user);
    event PassExpired(uint256 indexed passId);

    modifier onlyAuthority() {
        require(msg.sender == authority, "Only authority");
        _;
    }

    constructor() {
        authority = msg.sender;
    }

    // CORE 1: Buy Monthly Bus Pass
    function buyPass() external payable returns (uint256 passId) {
        require(msg.value == PRICE, "Send exactly 0.05 ETH");
        require(userToPass[msg.sender] == 0 || !passes[userToPass[msg.sender]].active, "Active pass exists");

        passId = ++passCounter;
        uint256 now = block.timestamp;

        passes[passId] = Pass({
            owner: msg.sender,
            startTime: now,
            expiryTime: now + VALIDITY,
            active: true
        });

        userToPass[msg.sender] = passId;
        emit PassBought(passId, msg.sender);
    }

    // CORE 2: Conductor Validates & Uses Pass
    function usePass(uint256 _passId) external onlyAuthority {
        Pass storage p = passes[_passId];
        require(p.active, "Pass not active");
        require(block.timestamp <= p.expiryTime, "Pass expired");

        emit PassUsed(_passId, p.owner);
    }

    // CORE 3: Expire Pass After 30 Days
    function expirePass(uint256 _passId) external {
        Pass storage p = passes[_passId];
        require(p.active, "Already expired");
        require(block.timestamp > p.expiryTime, "Still valid");

        p.active = false;
        emit PassExpired(_passId);
    }

    // View: Check if user has valid pass
    function hasValidPass(address user) external view returns (bool) {
        uint256 id = userToPass[user];
        if (id == 0) return false;
        Pass memory p = passes[id];
        return p.active && block.timestamp <= p.expiryTime;
    }

    // Withdraw earnings
    function withdraw() external {
        require(msg.sender == authority, "Only authority");
        payable(authority).transfer(address(this).balance);
    }
}
