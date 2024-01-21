// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IERC20} from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol";

contract IronVault {
    address payable owner;

    IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;
    IPool public immutable POOL;

    address private immutable linkAddress =
        0x779877A7B0D9E8603169DdbD7836e478b4624789;
    IERC20 private link;
    address asset;
    address GHO = 0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f;

    constructor(address _addressProvider, address _tokenAddress) {
        ADDRESSES_PROVIDER = IPoolAddressesProvider(_addressProvider);
        POOL = IPool(ADDRESSES_PROVIDER.getPool());
        owner = payable(msg.sender);
        link = IERC20(linkAddress);
        asset = _tokenAddress;
    }

    function deposit(uint256 _amount) external {
        uint256 amount = _amount;
        address onBehalfOf = address(this);
        uint16 referralCode = 0;
        POOL.supply(asset, amount, onBehalfOf, referralCode);
    }

    function withdraw(uint256 _amount)
        external
        returns (uint256)
    {
        uint256 amount = _amount;
        address to = address(this);
        return POOL.withdraw(asset, amount, to);
    }

    function requestLoan(uint256 _amount) public {
        POOL.borrow(
            address(GHO),
            _amount,
            2,
            0,
            address(this)
        );
    }
    function getAccountData(address _userAddress)
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        )
    {
        return POOL.getUserAccountData(_userAddress);
    }

    function approveLINK(uint256 _amount, address _poolContractAddress)
        external
        returns (bool)
    {
        return link.approve(_poolContractAddress, _amount);
    }

    function allowanceLINK(address _poolContractAddress)
        external
        view
        returns (uint256)
    {
        return link.allowance(address(this), _poolContractAddress);
    }

    function getBalance() external view returns (uint256) {
        return IERC20(asset).balanceOf(address(this));
    }

    function withdraw() external onlyOwner {
        IERC20 token = IERC20(asset);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner can call this function"
        );
        _;
    }

    receive() external payable {}
}