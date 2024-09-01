// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RerollyerLST is ERC20, Ownable {
    // Total ETH staked in the pool
    uint256 public totalStakedETH;
    // Exchange rate of LST to ETH (starts at 1:1)
    uint256 public exchangeRate = 1 ether;

    constructor() ERC20("Relayer LST", "RLST") {}

    // Function to mint LST tokens in proportion to the deposited ETH
    function mint(address to, uint256 amountETH) external onlyOwner {
        uint256 amountLST = (amountETH * 1 ether) / exchangeRate;
        _mint(to, amountLST);
        totalStakedETH += amountETH;
    }

    // Function to redeem LST tokens for ETH
    function redeem(uint256 amountLST) external {
        require(balanceOf(msg.sender) >= amountLST, "Insufficient LST balance");

        uint256 amountETH = (amountLST * exchangeRate) / 1 ether;
        _burn(msg.sender, amountLST);

        require(
            address(this).balance >= amountETH,
            "Insufficient ETH in contract"
        );
        totalStakedETH -= amountETH;
        payable(msg.sender).transfer(amountETH);
    }

    // Function to update the exchange rate based on new rewards
    function updateExchangeRate(uint256 rewardsETH) external onlyOwner {
        require(totalStakedETH > 0, "No ETH staked");

        totalStakedETH += rewardsETH;
        exchangeRate = (totalStakedETH * 1 ether) / totalSupply();
    }

    // Fallback function to receive ETH
    receive() external payable {}
}
