// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IPriceOracle} from "@aave/core-v3/contracts/interfaces/IPriceOracle.sol";
import "@openzeppelin/contracts/interfaces/IERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract IronVault is ERC4626 {
     address private constant POOL_ADDRESS_PROVIDER = 0xeb7A892BB04A8f836bDEeBbf60897A7Af1Bf5d7F;
    address constant USDC_ADDRESS = 0xe9DcE89B076BA6107Bb64EF30678efec11939234;
    address private AAVE_LENDING_POOL_ADDRESS; 
    address private PRICE_ORACLE;

     IERC20 public immutable stc;
    mapping(address => uint256) public balances;
    IPool private lendingPool;
    IPriceOracle private priceOracle;

    struct Token{
        address owner;
        uint256 amount;
    }

    mapping (address => Token) public tokens;
    address payable public owner;
    uint256 public entryFeeBasisPoints;

    constructor(
        ERC20 _token,
        uint256 _entryFeeBasisPoints
    ) ERC4626(_token) ERC20("Iron Vault Token", "IVT"){
        IPoolAddressesProvider provider = IPoolAddressesProvider(POOL_ADDRESS_PROVIDER);
        AAVE_LENDING_POOL_ADDRESS = provider.getPool();
        lendingPool = IPool(AAVE_LENDING_POOL_ADDRESS);
        priceOracle = IPriceOracle(PRICE_ORACLE);
        entryFeeBasisPoints = _entryFeeBasisPoints;
        owner = payable(msg.sender);
        stc = _token;
    }

    function deposit(uint256 assets, address receiver) public virtual override returns (uint256 shares) {
        stc.transferFrom(msg.sender, address(this), assets);
        Token storage token = tokens[receiver];
        token.owner = receiver;
        token.amount = assets;
        _mint(receiver, shares);
        stc.approve(AAVE_LENDING_POOL_ADDRESS, assets);
        lendingPool.supply(address(stc), assets, address(this), 0);
    }

   function withdraw(
        uint256 assets,
        address receiver,
        address _owner
    ) public virtual override returns (uint256 shares) {
        shares = previewWithdraw(assets);
        lendingPool.withdraw(address(stc), assets, msg.sender);
        _burn(_owner, shares);
        stc.transferFrom(address(this), receiver, assets);
    }

    function borrow(uint256 amount) external {
        address[] memory assets = new address[](1);
        assets[0] = address(stc);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        uint256[] memory modes = new uint256[](1);
        modes[0] = 0; // 0 means "No debt swap" - you can customize this based on your needs

        address onBehalfOf = address(this);
        bytes memory params = ""; // You can include custom parameters if needed

        lendingPool.flashLoan(
            address(this),
            assets,
            amounts,
            modes,
            onBehalfOf,
            params,
            0 // referralCode, set to 0 for no referral
        );
    }

    function repay(uint256 amount) external {
        stc.transferFrom(msg.sender, address(this), amount);
        stc.approve(AAVE_LENDING_POOL_ADDRESS, amount);
        lendingPool.repay(address(stc), amount, 2, address(this));
    }

 
    function totalAssets() public view virtual override returns (uint256) {
        return stc.balanceOf(address(this));
    }

    function convertToShares(uint256 assets) public view virtual override returns (uint256) {
        uint256 supply = assets;
        return supply;
    }

    function convertToAssets(uint256 shares) public view virtual override returns (uint256) {
        uint256 supply = shares;
        return supply;
    }

    function previewDeposit(uint256 assets) public view virtual override returns (uint256) {
        return convertToShares(assets);
    }

    function previewWithdraw(uint256 assets) public view virtual override returns (uint256) {
        uint256 supply = assets;
        return supply;
    }

    function previewRedeem(uint256 shares) public view virtual override returns (uint256) {
        return convertToAssets(shares);
    }

    function getAssetPrice() public view  returns (uint256) {
        return priceOracle.getAssetPrice(USDC_ADDRESS);
    }

    function getAsset(address _owner) public view returns (uint256) {
        Token memory token = tokens[_owner];
        return token.amount;
    }       
}