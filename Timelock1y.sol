
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/governance/TimelockController.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TimelockPayout {
    
    TimelockController private timelock;
    address public immutable beneficiary;

    // Delay for the timelock
    uint256 public constant TIMELOCK_DELAY = 2700000;

    constructor(address _beneficiary) {
        require(_beneficiary != address(0), "Beneficiary address cannot be zero address");
        
        timelock = new TimelockController(TIMELOCK_DELAY, address(0), address(0));
        beneficiary = _beneficiary;
    }

    // Accept ETH deposits
    receive() external payable {}

    // Initiate release of ETH
    function initiateRelease() public {
        bytes memory data = abi.encodeWithSignature("release()");
        timelock.schedule(address(this), 0, data, bytes32(0), 0, 0);
    }

    // Execute release of ETH to beneficiary
    function release() external {
        require(address(this).balance > 0, "No funds to release");
        require(msg.sender == address(timelock), "Only the timelock can call this function");
        
        payable(beneficiary).transfer(address(this).balance);
    }

    // Anyone can execute the timelocked ETH release
    function executeRelease() public {
        bytes memory data = abi.encodeWithSignature("release()");
        timelock.execute(address(this), 0, data, bytes32(0), 0);
    }

    // Initiate release of any ERC20 token including PAPER
    function initiateTokenRelease(address tokenAddress) public {
        bytes memory data = abi.encodeWithSignature("releaseTokens(address)", tokenAddress);
        timelock.schedule(address(this), 0, data, bytes32(0), 0, 0);
    }

    // Execute release of tokens to beneficiary
    function releaseTokens(address tokenAddress) external {
        uint256 tokenBalance = IERC20(tokenAddress).balanceOf(address(this));
        require(tokenBalance > 0, "No tokens to release");
        require(msg.sender == address(timelock), "Only the timelock can call this function");

        IERC20(tokenAddress).transfer(beneficiary, tokenBalance);
    }

    // Anyone can execute the timelocked token release
    function executeTokenRelease(address tokenAddress) public {
        bytes memory data = abi.encodeWithSignature("releaseTokens(address)", tokenAddress);
        timelock.execute(address(this), 0, data, bytes32(0), 0);
    }
}
