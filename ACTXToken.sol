// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable@5.0.0/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable@5.0.0/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable@5.0.0/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable@5.0.0/proxy/utils/UUPSUpgradeable.sol";

contract ACTXToken is Initializable, ERC20Upgradeable, AccessControlUpgradeable, UUPSUpgradeable {
    
    bytes32 public constant REWARD_MANAGER_ROLE = keccak256("REWARD_MANAGER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    uint256 public taxRateBasisPoints; 
    address public reservoirAddress;
    uint256 public constant MAX_SUPPLY = 100_000_000 * 10**18;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address defaultAdmin, address multiSigTreasury, address _reservoir) initializer public {
        __ERC20_init("ACT.X Token", "ACTX");
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(REWARD_MANAGER_ROLE, defaultAdmin);
        _grantRole(UPGRADER_ROLE, defaultAdmin);

        reservoirAddress = _reservoir;
        taxRateBasisPoints = 200; // 2% tax

        _mint(multiSigTreasury, MAX_SUPPLY);
    }

    // Na versão 5.0, usamos o hook _update para aplicar taxas
    function _update(address from, address to, uint256 value) internal virtual override {
        if (from != address(0) && to != address(0) && from != reservoirAddress) {
            uint256 tax = (value * taxRateBasisPoints) / 10000;
            uint256 amountAfterTax = value - tax;
            
            super._update(from, reservoirAddress, tax);
            super._update(from, to, amountAfterTax);
        } else {
            super._update(from, to, value);
        }
    }

    function distributeReward(address recipient, uint256 amount) external onlyRole(REWARD_MANAGER_ROLE) {
        // Transfere tokens do reservoir (piscina de recompensas) para o usuário
        _transfer(reservoirAddress, recipient, amount);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}
}
