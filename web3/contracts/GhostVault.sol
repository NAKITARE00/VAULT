// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {ERC4626} from "@rari-capital/solmate/src/mixins/ERC4626.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IPriceOracle} from "@aave/core-v3/contracts/interfaces/IPriceOracle.sol";
import "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";

/**
 * @title GhostVault Contract
 * @dev Ghost Vaults are simple ERC4626 implementations. Managing deposit and withdrawal of assets using Aave lending pool. 
 * @dev GhostVault is currnetly deployed at "0x1157CFdd7Ea635c4a6f6E8a525B45EA58256160E" address on Mumbai testnet. 
 * @dev GhostVault 
 */
contract GhostVault is ERC4626 {
    address constant USDC_ADDRESS;
    address private AAVE_LENDING_POOL_ADDRESS; 
    address private PRICE_ORACLE;

    mapping(address => uint256) public balances;
    IPool private lendingPool;
    IPriceOracle private priceOracle;

    struct Asset{
        address owner;
        uint256 amount;
    }

    mapping (address => Asset) public assets;

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLE
    //////////////////////////////////////////////////////////////*/

    constructor(
        ERC20 _token,
        string memory _name,
        string memory _symbol,
        address _poolProvider,
        address _usdcAddress
    ) ERC4626(_token, _name, _symbol) {
        IPoolAddressesProvider provider = IPoolAddressesProvider(_poolProvider);
        USDC_ADDRESS = _usdcAddress;
        AAVE_LENDING_POOL_ADDRESS = provider.getPool();
        lendingPool = IPool(AAVE_LENDING_POOL_ADDRESS);
        priceOracle = IPriceOracle(PRICE_ORACLE);
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev Deposit assets into the GhostVault and mint corresponding shares.
     * @param assets The amount of assets to deposit.
     * @param receiver The address to receive the minted shares.
     * @return shares The number of shares minted.
     */
    function deposit(uint256 assets, address receiver) public virtual override returns (uint256 shares) {
        asset.transferFrom(msg.sender, address(this), assets);
        Asset storage asset;
        asset.owner = receiver;
        asset.amount = assets;
        assets[receiver] = asset;
        _mint(receiver, shares);
        emit Deposit(msg.sender, receiver, assets, shares);
         // Approve lending pool to use tokens from this smart contract
        asset.approve(AAVE_LENDING_POOL_ADDRESS, assets);
        // Deposit tokens to the Aave lending pool
        lendingPool.supply(address(asset), assets, address(this), 0);
    }

    /**
     * @dev Withdraw assets from the GhostVault and burn corresponding shares.
     * @param assets The amount of assets to withdraw.
     * @param receiver The address to receive the withdrawn assets.
     * @param owner The owner of the shares being burned.
     * @return shares The number of shares burned.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual override returns (uint256 shares) {
        Asset storage asset = assets[owner];
        shares = previewWithdraw(assets);
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender];
            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }
        lendingPool.withdraw(address(asset), assets, msg.sender);
        _burn(owner, shares);
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
        asset.transferFrom(address(this), receiver, assets);
        asset.amount = asset.amount - assets;
    }

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Get the total assets held by the GhostVault.
     * @return The total amount of assets held.
     */
    function totalAssets() public view virtual override returns (uint256) {
        return asset.balanceOf(address(this));
    }

    /**
     * @dev Convert the given amount of assets to shares.
     * @param assets The amount of assets to convert.
     * @return The number of shares corresponding to the given assets.
     */
    function convertToShares(uint256 assets) public view virtual override returns (uint256) {
        uint256 supply = assets;
        return supply;
    }

    /**
     * @dev Convert the given number of shares to assets.
     * @param shares The number of shares to convert.
     * @return The amount of assets corresponding to the given shares.
     */
    function convertToAssets(uint256 shares) public view virtual override returns (uint256) {
        uint256 supply = shares;
        return supply;
    }

    /**
     * @dev Preview the number of shares that will be minted for the given amount of assets.
     * @param assets The amount of assets to deposit.
     * @return The number of shares that will be minted.
     */
    function previewDeposit(uint256 assets) public view virtual override returns (uint256) {
        return convertToShares(assets);
    }

    /**
     * @dev Preview the number of shares that will be burned for the given amount of assets to withdraw.
     * @param assets The amount of assets to withdraw.
     * @return The number of shares that will be burned.
     */
    function previewWithdraw(uint256 assets) public view virtual override returns (uint256) {
        uint256 supply = assets;
        return supply;
    }

    /**
     * @dev Preview the amount of assets that will be redeemed for the given number of shares.
     * @param shares The number of shares to redeem.
     * @return The amount of assets that will be redeemed.
     */
    function previewRedeem(uint256 shares) public view virtual override returns (uint256) {
        return convertToAssets(shares);
    }

    /*//////////////////////////////////////////////////////////////
                            HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Get the price of the asset held by the GhostVault.
     * @return The price of the asset.
     */
    function getAssetPrice( ) public view  returns (uint256) {
        return priceOracle.getAssetPrice(USDC_ADDRESS);
    }

    function getAsset() public view returns (uint256) {
        Asset memory asset = assets[msg.sender];
        return asset.amount;
    }        
}