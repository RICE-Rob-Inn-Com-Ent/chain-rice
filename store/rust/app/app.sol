// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// ============================================================================
// Universal Multi-Chain Token System for ChainRice
// ============================================================================
// This contract provides full cross-chain compatibility for all blockchain networks
// - Universal tokens that work on EVM and ChainRice simultaneously
// - Gas abstraction (pay with CRICE instead of ETH)
// - Automatic bridge synchronization
// - Fee collection system
// - Support for all EVM chains and non-EVM chains via bridge
// ============================================================================

// ============================================================================
// Interfaces and Abstract Contracts
// ============================================================================
// This section contains reusable interfaces and abstract contracts
// used across all EVM contracts in the system.

// ============================================================================
// Interfaces
// ============================================================================

/**
 * @title AggregatorV3Interface
 * @notice Chainlink Price Feed Interface
 */
interface AggregatorV3Interface {
    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function version() external view returns (uint256);
    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

/**
 * @title IERC20
 * @notice Standard ERC20 Interface
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// ============================================================================
// Security - Abstract Contracts
// ============================================================================

/**
 * @title ReentrancyGuard
 * @notice Prevents reentrant calls to functions
 */
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

/**
 * @title Ownable
 * @notice Provides basic access control
 */
abstract contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// ============================================================================
// Contracts
// ============================================================================

// ============================================================================
// Universal Token - Cross-Chain Compatible ERC20
// ============================================================================

/**
 * @title UniversalToken
 * @notice ERC20 token that automatically syncs with ChainRice and other chains
 * @dev Fully cross-chain compatible - works on EVM and ChainRice simultaneously
 */
contract UniversalToken is IERC20, ReentrancyGuard {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    // ChainRice address mapping (EVM address -> ChainRice address)
    mapping(address => string) public chainRiceAddresses;
    mapping(string => address) public evmAddresses;

    // Cross-chain sync state
    mapping(bytes32 => bool) public syncedTransactions;
    address public bridgeContract;
    address public owner;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event CrossChainSync(
        address indexed evmAddress,
        string indexed chainRiceAddress,
        uint256 amount,
        string destinationChain
    );
    event BridgeContractUpdated(
        address indexed oldBridge,
        address indexed newBridge
    );

    modifier onlyBridge() {
        require(
            msg.sender == bridgeContract || msg.sender == owner,
            "UniversalToken: caller is not bridge or owner"
        );
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply,
        address _bridgeContract
    ) {
        require(
            bytes(_name).length > 0,
            "UniversalToken: name cannot be empty"
        );
        require(
            bytes(_symbol).length > 0,
            "UniversalToken: symbol cannot be empty"
        );
        require(
            _bridgeContract != address(0),
            "UniversalToken: bridge cannot be zero"
        );

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _initialSupply;
        bridgeContract = _bridgeContract;
        owner = msg.sender;

        balanceOf[msg.sender] = _initialSupply;
        emit Transfer(address(0), msg.sender, _initialSupply);
    }

    function transfer(
        address _to,
        uint256 _value
    ) public returns (bool success) {
        return _transfer(msg.sender, _to, _value);
    }

    function approve(
        address _spender,
        uint256 _value
    ) public returns (bool success) {
        require(
            _spender != address(0),
            "UniversalToken: approve to zero address"
        );
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(
            allowance[_from][msg.sender] >= _value,
            "UniversalToken: insufficient allowance"
        );
        allowance[_from][msg.sender] -= _value;
        return _transfer(_from, _to, _value);
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal returns (bool) {
        require(_to != address(0), "UniversalToken: transfer to zero address");
        require(
            balanceOf[_from] >= _value,
            "UniversalToken: insufficient balance"
        );

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @notice Link EVM address with ChainRice address for cross-chain sync
     */
    function linkChainRiceAddress(string memory _chainRiceAddress) external {
        require(
            bytes(_chainRiceAddress).length > 0,
            "UniversalToken: ChainRice address cannot be empty"
        );
        chainRiceAddresses[msg.sender] = _chainRiceAddress;
        evmAddresses[_chainRiceAddress] = msg.sender;
    }

    /**
     * @notice Sync tokens to ChainRice (called by bridge)
     */
    function syncToChainRice(
        address _from,
        string memory _toChainRiceAddress,
        uint256 _amount
    ) external onlyBridge {
        require(
            balanceOf[_from] >= _amount,
            "UniversalToken: insufficient balance for sync"
        );

        balanceOf[_from] -= _amount;
        totalSupply -= _amount; // Burn on EVM, mint on ChainRice

        bytes32 syncHash = keccak256(
            abi.encodePacked(
                _from,
                _toChainRiceAddress,
                _amount,
                block.timestamp
            )
        );
        syncedTransactions[syncHash] = true;

        emit CrossChainSync(_from, _toChainRiceAddress, _amount, "ChainRice");
    }

    /**
     * @notice Sync tokens from ChainRice to EVM (called by bridge)
     */
    function syncFromChainRice(
        address _to,
        uint256 _amount,
        string memory _proof
    ) external onlyBridge {
        bytes32 proofHash = keccak256(abi.encodePacked(_proof));
        require(
            !syncedTransactions[proofHash],
            "UniversalToken: proof already used"
        );

        syncedTransactions[proofHash] = true;
        balanceOf[_to] += _amount;
        totalSupply += _amount; // Mint on EVM

        emit Transfer(address(0), _to, _amount);
    }

    /**
     * @notice Update bridge contract address
     */
    function setBridgeContract(address _newBridge) external {
        require(msg.sender == owner, "UniversalToken: only owner");
        require(
            _newBridge != address(0),
            "UniversalToken: bridge cannot be zero"
        );
        address oldBridge = bridgeContract;
        bridgeContract = _newBridge;
        emit BridgeContractUpdated(oldBridge, _newBridge);
    }

    function increaseAllowance(
        address _spender,
        uint256 _addedValue
    ) public returns (bool) {
        require(
            _spender != address(0),
            "UniversalToken: approve to zero address"
        );
        allowance[msg.sender][_spender] += _addedValue;
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }

    function decreaseAllowance(
        address _spender,
        uint256 _subtractedValue
    ) public returns (bool) {
        require(
            _spender != address(0),
            "UniversalToken: approve to zero address"
        );
        require(
            allowance[msg.sender][_spender] >= _subtractedValue,
            "UniversalToken: decreased allowance below zero"
        );
        allowance[msg.sender][_spender] -= _subtractedValue;
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }
}

// ============================================================================
// Gas Paymaster - Pay with CRICE instead of ETH
// ============================================================================

/**
 * @title GasPaymaster
 * @notice Allows users to pay gas fees with CRICE token instead of native ETH
 * @dev Owner covers ETH costs, collects CRICE as payment
 */
contract GasPaymaster is Ownable, ReentrancyGuard {
    IERC20 public criceToken;
    uint256 public criceToEthRate; // CRICE per 1 ETH (with 18 decimals)
    uint256 public feePercentage; // Fee percentage (basis points, e.g., 100 = 1%)
    address public feeCollector;

    mapping(bytes32 => bool) public processedMetaTransactions;

    event GasPaidWithCRICE(
        address indexed user,
        uint256 criceAmount,
        uint256 ethAmount,
        bytes32 metaTxHash
    );
    event RateUpdated(uint256 oldRate, uint256 newRate);
    event FeePercentageUpdated(uint256 oldFee, uint256 newFee);

    constructor(
        address _criceToken,
        uint256 _initialRate,
        uint256 _feePercentage,
        address _feeCollector
    ) {
        require(
            _criceToken != address(0),
            "GasPaymaster: CRICE token cannot be zero"
        );
        require(
            _feeCollector != address(0),
            "GasPaymaster: fee collector cannot be zero"
        );
        require(
            _feePercentage <= 10000,
            "GasPaymaster: fee cannot exceed 100%"
        );

        criceToken = IERC20(_criceToken);
        criceToEthRate = _initialRate;
        feePercentage = _feePercentage;
        feeCollector = _feeCollector;
    }

    /**
     * @notice Calculate CRICE amount needed for gas payment
     */
    function calculateCRICEAmount(
        uint256 ethAmount
    ) public view returns (uint256) {
        uint256 criceAmount = (ethAmount * criceToEthRate) / 1 ether;
        uint256 fee = (criceAmount * feePercentage) / 10000;
        return criceAmount + fee;
    }

    /**
     * @notice Pay for gas with CRICE tokens
     * @param _to Destination address for the transaction
     * @param _data Transaction data
     * @param _criceAmount Amount of CRICE to pay
     */
    function payGasWithCRICE(
        address _to,
        bytes memory _data,
        uint256 _criceAmount
    ) external nonReentrant {
        require(_to != address(0), "GasPaymaster: destination cannot be zero");
        require(
            _criceAmount > 0,
            "GasPaymaster: CRICE amount must be greater than 0"
        );

        // Calculate required ETH (estimate gas)
        uint256 estimatedGas = gasleft();
        uint256 ethRequired = tx.gasprice * estimatedGas;
        uint256 requiredCRICE = calculateCRICEAmount(ethRequired);

        require(
            _criceAmount >= requiredCRICE,
            "GasPaymaster: insufficient CRICE amount"
        );

        // Transfer CRICE from user
        require(
            criceToken.transferFrom(msg.sender, address(this), _criceAmount),
            "GasPaymaster: CRICE transfer failed"
        );

        // Calculate fee
        uint256 fee = (_criceAmount * feePercentage) / 10000;

        // Send fee to fee collector
        if (fee > 0) {
            require(
                criceToken.transfer(feeCollector, fee),
                "GasPaymaster: fee transfer failed"
            );
        }

        // Execute transaction (owner covers ETH cost)
        bytes32 metaTxHash = keccak256(
            abi.encodePacked(msg.sender, _to, _data, block.timestamp)
        );
        require(
            !processedMetaTransactions[metaTxHash],
            "GasPaymaster: transaction already processed"
        );
        processedMetaTransactions[metaTxHash] = true;

        // Note: Actual transaction execution would be handled by relay server
        // This contract just handles the payment logic

        emit GasPaidWithCRICE(
            msg.sender,
            _criceAmount,
            ethRequired,
            metaTxHash
        );
    }

    /**
     * @notice Update CRICE to ETH exchange rate
     */
    function updateRate(uint256 _newRate) external onlyOwner {
        require(_newRate > 0, "GasPaymaster: rate must be greater than 0");
        uint256 oldRate = criceToEthRate;
        criceToEthRate = _newRate;
        emit RateUpdated(oldRate, _newRate);
    }

    /**
     * @notice Update fee percentage
     */
    function updateFeePercentage(
        uint256 _newFeePercentage
    ) external onlyOwner {
        require(
            _newFeePercentage <= 10000,
            "GasPaymaster: fee cannot exceed 100%"
        );
        uint256 oldFee = feePercentage;
        feePercentage = _newFeePercentage;
        emit FeePercentageUpdated(oldFee, _newFeePercentage);
    }

    /**
     * @notice Update fee collector address
     */
    function updateFeeCollector(address _newFeeCollector) external onlyOwner {
        require(
            _newFeeCollector != address(0),
            "GasPaymaster: fee collector cannot be zero"
        );
        feeCollector = _newFeeCollector;
    }

    /**
     * @notice Withdraw CRICE tokens (only owner)
     */
    function withdrawCRICE(uint256 _amount) external onlyOwner {
        require(
            criceToken.transfer(owner, _amount),
            "GasPaymaster: withdrawal failed"
        );
    }
}

// ============================================================================
// Auto Bridge - Automatic Cross-Chain Synchronization
// ============================================================================

/**
 * @title AutoBridge
 * @notice Automatically synchronizes tokens between EVM and ChainRice
 * @dev Handles automatic bridging for all supported chains
 */
contract AutoBridge is Ownable, ReentrancyGuard {
    mapping(address => bool) public supportedTokens;
    mapping(string => address) public chainRiceToEVM; // ChainRice denom -> EVM token address
    mapping(address => string) public evmToChainRice; // EVM token address -> ChainRice denom

    // Supported destination chains
    mapping(string => bool) public supportedChains;

    // Bridge fees
    mapping(string => uint256) public chainFees; // Chain name -> fee in CRICE

    event TokenRegistered(
        address indexed evmToken,
        string indexed chainRiceDenom,
        string[] supportedChains
    );
    event AutoBridgeExecuted(
        address indexed token,
        string sourceChain,
        string destinationChain,
        uint256 amount,
        address recipient
    );
    event ChainSupported(string indexed chain, bool supported);
    event ChainFeeUpdated(
        string indexed chain,
        uint256 oldFee,
        uint256 newFee
    );

    constructor() {
        // Initialize supported chains
        supportedChains["ethereum"] = true;
        supportedChains["polygon"] = true;
        supportedChains["bsc"] = true;
        supportedChains["avalanche"] = true;
        supportedChains["arbitrum"] = true;
        supportedChains["optimism"] = true;
        supportedChains["chainrice"] = true;
        supportedChains["bitcoin"] = true;
        supportedChains["solana"] = true;
        supportedChains["cardano"] = true;
        supportedChains["polkadot"] = true;
        supportedChains["near"] = true;
        supportedChains["algorand"] = true;
        supportedChains["tezos"] = true;
        supportedChains["tron"] = true;
        supportedChains["litecoin"] = true;
        supportedChains["dogecoin"] = true;
        supportedChains["stellar"] = true;
        supportedChains["ripple"] = true;
        supportedChains["ton"] = true;
        supportedChains["base"] = true;
        supportedChains["zksync"] = true;
        supportedChains["linea"] = true;
        supportedChains["scroll"] = true;
        supportedChains["mantle"] = true;
        supportedChains["sui"] = true;
        supportedChains["aptos"] = true;
        supportedChains["icp"] = true;
    }

    /**
     * @notice Register a token for cross-chain bridging
     */
    function registerToken(
        address _evmToken,
        string memory _chainRiceDenom,
        string[] memory _supportedChains
    ) external onlyOwner {
        require(_evmToken != address(0), "AutoBridge: token cannot be zero");
        require(
            bytes(_chainRiceDenom).length > 0,
            "AutoBridge: ChainRice denom cannot be empty"
        );

        supportedTokens[_evmToken] = true;
        chainRiceToEVM[_chainRiceDenom] = _evmToken;
        evmToChainRice[_evmToken] = _chainRiceDenom;

        emit TokenRegistered(_evmToken, _chainRiceDenom, _supportedChains);
    }

    /**
     * @notice Execute automatic bridge between chains
     */
    function bridge(
        address _token,
        string memory _destinationChain,
        uint256 _amount,
        string memory _recipientAddress
    ) external nonReentrant {
        require(supportedTokens[_token], "AutoBridge: token not supported");
        require(
            supportedChains[_destinationChain],
            "AutoBridge: destination chain not supported"
        );
        require(_amount > 0, "AutoBridge: amount must be greater than 0");
        require(
            bytes(_recipientAddress).length > 0,
            "AutoBridge: recipient address cannot be empty"
        );

        // Transfer tokens from user
        require(
            IERC20(_token).transferFrom(msg.sender, address(this), _amount),
            "AutoBridge: token transfer failed"
        );

        // Emit event for bridge relay to process
        emit AutoBridgeExecuted(
            _token,
            "evm",
            _destinationChain,
            _amount,
            msg.sender
        );

        // Note: Actual bridging is handled by off-chain relay (bridge.ts)
    }

    /**
     * @notice Add or remove supported chain
     */
    function setChainSupport(
        string memory _chain,
        bool _supported
    ) external onlyOwner {
        supportedChains[_chain] = _supported;
        emit ChainSupported(_chain, _supported);
    }

    /**
     * @notice Update bridge fee for a chain
     */
    function setChainFee(
        string memory _chain,
        uint256 _fee
    ) external onlyOwner {
        uint256 oldFee = chainFees[_chain];
        chainFees[_chain] = _fee;
        emit ChainFeeUpdated(_chain, oldFee, _fee);
    }

    /**
     * @notice Get bridge fee for a chain
     */
    function getChainFee(
        string memory _chain
    ) external view returns (uint256) {
        return chainFees[_chain];
    }
}

// ============================================================================
// Fee Collector - Collect All Transaction Fees
// ============================================================================

/**
 * @title FeeCollector
 * @notice Collects and manages all fees from cross-chain transactions
 * @dev Owner can withdraw collected fees
 */
contract FeeCollector is Ownable, ReentrancyGuard {
    mapping(address => uint256) public collectedFees; // Token address -> amount
    mapping(string => uint256) public chainFees; // Chain name -> amount in CRICE

    address public criceToken;

    event FeeCollected(address indexed token, uint256 amount, string source);
    event FeesWithdrawn(
        address indexed token,
        uint256 amount,
        address indexed recipient
    );

    constructor(address _criceToken) {
        require(
            _criceToken != address(0),
            "FeeCollector: CRICE token cannot be zero"
        );
        criceToken = _criceToken;
    }

    /**
     * @notice Collect fee in ERC20 token
     */
    function collectFee(address _token, uint256 _amount) external {
        require(_token != address(0), "FeeCollector: token cannot be zero");
        require(_amount > 0, "FeeCollector: amount must be greater than 0");

        require(
            IERC20(_token).transferFrom(msg.sender, address(this), _amount),
            "FeeCollector: fee transfer failed"
        );

        collectedFees[_token] += _amount;
        emit FeeCollected(_token, _amount, "erc20");
    }

    /**
     * @notice Collect fee in CRICE for specific chain
     */
    function collectChainFee(string memory _chain, uint256 _amount) external {
        require(
            bytes(_chain).length > 0,
            "FeeCollector: chain cannot be empty"
        );
        require(_amount > 0, "FeeCollector: amount must be greater than 0");

        require(
            IERC20(criceToken).transferFrom(
                msg.sender,
                address(this),
                _amount
            ),
            "FeeCollector: CRICE transfer failed"
        );

        chainFees[_chain] += _amount;
        emit FeeCollected(criceToken, _amount, _chain);
    }

    /**
     * @notice Withdraw collected fees
     */
    function withdrawFees(
        address _token,
        uint256 _amount
    ) external onlyOwner nonReentrant {
        require(_token != address(0), "FeeCollector: token cannot be zero");
        require(_amount > 0, "FeeCollector: amount must be greater than 0");
        require(
            collectedFees[_token] >= _amount,
            "FeeCollector: insufficient collected fees"
        );

        collectedFees[_token] -= _amount;
        require(
            IERC20(_token).transfer(owner, _amount),
            "FeeCollector: withdrawal failed"
        );

        emit FeesWithdrawn(_token, _amount, owner);
    }

    /**
     * @notice Withdraw chain fees in CRICE
     */
    function withdrawChainFees(
        string memory _chain,
        uint256 _amount
    ) external onlyOwner nonReentrant {
        require(
            bytes(_chain).length > 0,
            "FeeCollector: chain cannot be empty"
        );
        require(_amount > 0, "FeeCollector: amount must be greater than 0");
        require(
            chainFees[_chain] >= _amount,
            "FeeCollector: insufficient chain fees"
        );

        chainFees[_chain] -= _amount;
        require(
            IERC20(criceToken).transfer(owner, _amount),
            "FeeCollector: CRICE withdrawal failed"
        );

        emit FeesWithdrawn(criceToken, _amount, owner);
    }

    /**
     * @notice Get total collected fees for a token
     */
    function getCollectedFees(address _token) external view returns (uint256) {
        return collectedFees[_token];
    }

    /**
     * @notice Get total collected fees for a chain
     */
    function getChainFees(
        string memory _chain
    ) external view returns (uint256) {
        return chainFees[_chain];
    }
}

// ============================================================================
// Token Factory - Create Tokens on Multiple Chains Simultaneously
// ============================================================================

/**
 * @title TokenFactory
 * @notice Creates universal tokens on EVM and ChainRice simultaneously
 * @dev All tokens created are automatically cross-chain compatible
 */
contract TokenFactory is Ownable, ReentrancyGuard {
    address public bridgeContract;
    address public feeCollector;
    uint256 public creationFee; // Fee in CRICE for token creation

    mapping(address => TokenInfo) public tokens; // Token address -> info
    address[] public allTokens;

    struct TokenInfo {
        string name;
        string symbol;
        uint8 decimals;
        string chainRiceDenom;
        address creator;
        uint256 createdAt;
        string[] supportedChains;
    }

    event TokenCreated(
        address indexed token,
        string name,
        string symbol,
        string chainRiceDenom,
        address indexed creator,
        string[] supportedChains
    );
    event CreationFeeUpdated(uint256 oldFee, uint256 newFee);

    constructor(
        address _bridgeContract,
        address _feeCollector,
        uint256 _creationFee
    ) {
        require(
            _bridgeContract != address(0),
            "TokenFactory: bridge cannot be zero"
        );
        require(
            _feeCollector != address(0),
            "TokenFactory: fee collector cannot be zero"
        );

        bridgeContract = _bridgeContract;
        feeCollector = _feeCollector;
        creationFee = _creationFee;
    }

    /**
     * @notice Create a universal token on EVM and ChainRice
     */
    function createUniversalToken(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply,
        string memory _chainRiceDenom,
        string[] memory _supportedChains
    ) external nonReentrant returns (address) {
        require(bytes(_name).length > 0, "TokenFactory: name cannot be empty");
        require(
            bytes(_symbol).length > 0,
            "TokenFactory: symbol cannot be empty"
        );
        require(
            bytes(_chainRiceDenom).length > 0,
            "TokenFactory: ChainRice denom cannot be empty"
        );
        require(_decimals <= 18, "TokenFactory: decimals cannot exceed 18");

        // Collect creation fee (if fee token is set)
        if (creationFee > 0 && feeCollector != address(0)) {
            // Fee collection would be handled by bridge.ts
            // This is just the on-chain creation
        }

        // Deploy UniversalToken
        UniversalToken newToken = new UniversalToken(
            _name,
            _symbol,
            _decimals,
            _initialSupply,
            bridgeContract
        );

        address tokenAddress = address(newToken);

        // Store token info
        tokens[tokenAddress] = TokenInfo({
            name: _name,
            symbol: _symbol,
            decimals: _decimals,
            chainRiceDenom: _chainRiceDenom,
            creator: msg.sender,
            createdAt: block.timestamp,
            supportedChains: _supportedChains
        });

        allTokens.push(tokenAddress);

        emit TokenCreated(
            tokenAddress,
            _name,
            _symbol,
            _chainRiceDenom,
            msg.sender,
            _supportedChains
        );

        return tokenAddress;
    }

    /**
     * @notice Get all created tokens
     */
    function getAllTokens() external view returns (address[] memory) {
        return allTokens;
    }

    /**
     * @notice Get token count
     */
    function getTokenCount() external view returns (uint256) {
        return allTokens.length;
    }

    /**
     * @notice Update creation fee
     */
    function setCreationFee(uint256 _newFee) external onlyOwner {
        uint256 oldFee = creationFee;
        creationFee = _newFee;
        emit CreationFeeUpdated(oldFee, _newFee);
    }

    /**
     * @notice Update bridge contract
     */
    function setBridgeContract(address _newBridge) external onlyOwner {
        require(
            _newBridge != address(0),
            "TokenFactory: bridge cannot be zero"
        );
        bridgeContract = _newBridge;
    }

    /**
     * @notice Update fee collector
     */
    function setFeeCollector(address _newFeeCollector) external onlyOwner {
        require(
            _newFeeCollector != address(0),
            "TokenFactory: fee collector cannot be zero"
        );
        feeCollector = _newFeeCollector;
    }
}

// ============================================================================
// Bridge Lock (Enhanced)
// ============================================================================

/**
 * @title BridgeLock
 * @notice Locks tokens on EVM chain for cross-chain bridge
 * @dev Enhanced with multi-chain support
 */
contract BridgeLock is ReentrancyGuard, Ownable {
    mapping(address => mapping(string => uint256)) public lockedAmounts;
    mapping(uint256 => bool) public processedNonces;
    mapping(string => bool) public supportedDestinationChains;
    uint256 public nonce;

    event TokensLocked(
        address indexed token,
        uint256 amount,
        string recipient,
        string destinationChain,
        uint256 indexed nonce
    );
    event ChainSupportUpdated(string indexed chain, bool supported);

    constructor() {
        // Initialize supported chains
        supportedDestinationChains["chainrice"] = true;
        supportedDestinationChains["bitcoin"] = true;
        supportedDestinationChains["solana"] = true;
        supportedDestinationChains["cardano"] = true;
        supportedDestinationChains["polkadot"] = true;
        supportedDestinationChains["near"] = true;
        supportedDestinationChains["algorand"] = true;
        supportedDestinationChains["tezos"] = true;
        supportedDestinationChains["tron"] = true;
        supportedDestinationChains["litecoin"] = true;
        supportedDestinationChains["dogecoin"] = true;
        supportedDestinationChains["stellar"] = true;
        supportedDestinationChains["ripple"] = true;
    }

    function lock(
        address token,
        uint256 amount,
        string memory recipient,
        string memory destinationChain
    ) external nonReentrant {
        require(
            token != address(0),
            "BridgeLock: token address cannot be zero"
        );
        require(amount > 0, "BridgeLock: amount must be greater than 0");
        require(
            bytes(recipient).length > 0,
            "BridgeLock: recipient cannot be empty"
        );
        require(
            supportedDestinationChains[destinationChain],
            "BridgeLock: destination chain not supported"
        );

        (bool success, bytes memory returnData) = token.call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                msg.sender,
                address(this),
                amount
            )
        );
        require(success, "BridgeLock: token transfer failed");

        if (returnData.length > 0) {
            bool transferResult = abi.decode(returnData, (bool));
            require(
                transferResult,
                "BridgeLock: token transfer returned false"
            );
        }

        nonce++;
        lockedAmounts[token][recipient] += amount;

        emit TokensLocked(token, amount, recipient, destinationChain, nonce);
    }

    function getLockedAmount(
        address token,
        string memory recipient
    ) external view returns (uint256) {
        return lockedAmounts[token][recipient];
    }

    function getNonce() external view returns (uint256) {
        return nonce;
    }

    function isNonceProcessed(uint256 _nonce) external view returns (bool) {
        return processedNonces[_nonce];
    }

    function setChainSupport(
        string memory _chain,
        bool _supported
    ) external onlyOwner {
        supportedDestinationChains[_chain] = _supported;
        emit ChainSupportUpdated(_chain, _supported);
    }
}

// ============================================================================
// Bridge Unlock (Enhanced)
// ============================================================================

/**
 * @title BridgeUnlock
 * @notice Unlocks tokens on EVM chain after burn on other chains
 * @dev Enhanced with multi-chain support
 */
contract BridgeUnlock is ReentrancyGuard, Ownable {
    mapping(bytes32 => bool) public processedProofs;
    mapping(string => bool) public supportedSourceChains;

    event TokensUnlocked(
        address indexed token,
        uint256 amount,
        address indexed recipient,
        string sourceChain,
        bytes32 proof
    );
    event ChainSupportUpdated(string indexed chain, bool supported);

    constructor() {
        // Initialize supported chains
        supportedSourceChains["chainrice"] = true;
        supportedSourceChains["bitcoin"] = true;
        supportedSourceChains["solana"] = true;
        supportedSourceChains["cardano"] = true;
        supportedSourceChains["polkadot"] = true;
        supportedSourceChains["near"] = true;
        supportedSourceChains["algorand"] = true;
        supportedSourceChains["tezos"] = true;
        supportedSourceChains["tron"] = true;
        supportedSourceChains["litecoin"] = true;
        supportedSourceChains["dogecoin"] = true;
        supportedSourceChains["stellar"] = true;
        supportedSourceChains["ripple"] = true;
        supportedSourceChains["ton"] = true;
        supportedSourceChains["sui"] = true;
        supportedSourceChains["aptos"] = true;
        supportedSourceChains["icp"] = true;
    }

    function unlock(
        address token,
        uint256 amount,
        address recipient,
        string memory proof,
        string memory sourceChain
    ) external nonReentrant {
        require(
            token != address(0),
            "BridgeUnlock: token address cannot be zero"
        );
        require(
            recipient != address(0),
            "BridgeUnlock: recipient address cannot be zero"
        );
        require(amount > 0, "BridgeUnlock: amount must be greater than 0");
        require(
            bytes(proof).length > 0,
            "BridgeUnlock: proof cannot be empty"
        );
        require(
            supportedSourceChains[sourceChain],
            "BridgeUnlock: source chain not supported"
        );

        bytes32 proofHash = keccak256(abi.encodePacked(proof, sourceChain));
        require(
            !processedProofs[proofHash],
            "BridgeUnlock: proof already processed"
        );

        processedProofs[proofHash] = true;

        (bool success, bytes memory returnData) = token.call(
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                recipient,
                amount
            )
        );
        require(success, "BridgeUnlock: token transfer failed");

        if (returnData.length > 0) {
            bool transferResult = abi.decode(returnData, (bool));
            require(
                transferResult,
                "BridgeUnlock: token transfer returned false"
            );
        }

        emit TokensUnlocked(token, amount, recipient, sourceChain, proofHash);
    }

    function isProofProcessed(
        string memory proof,
        string memory sourceChain
    ) external view returns (bool) {
        bytes32 proofHash = keccak256(abi.encodePacked(proof, sourceChain));
        return processedProofs[proofHash];
    }

    function setChainSupport(
        string memory _chain,
        bool _supported
    ) external onlyOwner {
        supportedSourceChains[_chain] = _supported;
        emit ChainSupportUpdated(_chain, _supported);
    }

    function emergencyWithdraw(
        address token,
        uint256 amount,
        address to
    ) external onlyOwner {
        require(
            token != address(0),
            "BridgeUnlock: token address cannot be zero"
        );
        require(
            to != address(0),
            "BridgeUnlock: recipient address cannot be zero"
        );
        require(amount > 0, "BridgeUnlock: amount must be greater than 0");

        (bool success, bytes memory returnData) = token.call(
            abi.encodeWithSignature("transfer(address,uint256)", to, amount)
        );
        require(success, "BridgeUnlock: token transfer failed");

        if (returnData.length > 0) {
            bool transferResult = abi.decode(returnData, (bool));
            require(
                transferResult,
                "BridgeUnlock: token transfer returned false"
            );
        }
    }
}

// ============================================================================
// EVM Utilities (Enhanced)
// ============================================================================

/**
 * @title EVMUtils
 * @notice Utility functions for EVM chain communication
 */
contract EVMUtils {
    function getBalance(address token) external view returns (uint256) {
        if (token == address(0)) {
            return address(this).balance;
        }
        return IERC20(token).balanceOf(address(this));
    }

    function getAccountBalance(
        address token,
        address account
    ) external view returns (uint256) {
        if (token == address(0)) {
            return account.balance;
        }
        return IERC20(token).balanceOf(account);
    }

    function isContract(address addr) external view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function getChainId() external view returns (uint256) {
        return block.chainid;
    }

    function getBlockTimestamp() external view returns (uint256) {
        return block.timestamp;
    }

    function getBlockNumber() external view returns (uint256) {
        return block.number;
    }

    function getBlockHash(
        uint256 blockNumber
    ) external view returns (bytes32) {
        return blockhash(blockNumber);
    }

    function getMsgSender() external view returns (address) {
        return msg.sender;
    }

    function getMsgValue() external payable returns (uint256) {
        return msg.value;
    }
}

// ============================================================================
// Price Feed Consumer (Kept from original)
// ============================================================================

/**
 * @title PriceFeedConsumer
 * @notice Consumer contract for Chainlink Price Feeds
 * @dev Fully reusable - all price feed addresses via constructor
 */
contract PriceFeedConsumer {
    AggregatorV3Interface public ethUsdPriceFeed;
    AggregatorV3Interface public btcUsdPriceFeed;
    AggregatorV3Interface public linkUsdPriceFeed;

    constructor(
        address _ethUsdPriceFeed,
        address _btcUsdPriceFeed,
        address _linkUsdPriceFeed
    ) {
        require(
            _ethUsdPriceFeed != address(0),
            "PriceFeed: ETH price feed cannot be zero"
        );
        require(
            _btcUsdPriceFeed != address(0),
            "PriceFeed: BTC price feed cannot be zero"
        );
        require(
            _linkUsdPriceFeed != address(0),
            "PriceFeed: LINK price feed cannot be zero"
        );

        ethUsdPriceFeed = AggregatorV3Interface(_ethUsdPriceFeed);
        btcUsdPriceFeed = AggregatorV3Interface(_btcUsdPriceFeed);
        linkUsdPriceFeed = AggregatorV3Interface(_linkUsdPriceFeed);
    }

    function getLatestETHPrice() public view returns (int256) {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        return price;
    }

    function getLatestBTCPrice() public view returns (int256) {
        (, int256 price, , , ) = btcUsdPriceFeed.latestRoundData();
        return price;
    }

    function getLatestLINKPrice() public view returns (int256) {
        (, int256 price, , , ) = linkUsdPriceFeed.latestRoundData();
        return price;
    }

    function getDecimals() public view returns (uint8) {
        return ethUsdPriceFeed.decimals();
    }

    function getHistoricalETHPrice(
        uint80 roundId
    ) public view returns (int256) {
        (, int256 price, , , ) = ethUsdPriceFeed.getRoundData(roundId);
        return price;
    }

    function getHistoricalBTCPrice(
        uint80 roundId
    ) public view returns (int256) {
        (, int256 price, , , ) = btcUsdPriceFeed.getRoundData(roundId);
        return price;
    }

    function getHistoricalLINKPrice(
        uint80 roundId
    ) public view returns (int256) {
        (, int256 price, , , ) = linkUsdPriceFeed.getRoundData(roundId);
        return price;
    }

    function convertETHToUSD(
        uint256 amountInWei
    ) public view returns (uint256) {
        int256 price = getLatestETHPrice();
        require(price > 0, "PriceFeed: invalid price");

        uint8 decimals = getDecimals();
        uint256 priceWith18Decimals = uint256(price) * 10 ** (18 - decimals);

        return (amountInWei * priceWith18Decimals) / 1 ether;
    }

    function convertBTCToUSD(
        uint256 amountInSatoshi
    ) public view returns (uint256) {
        int256 price = getLatestBTCPrice();
        require(price > 0, "PriceFeed: invalid price");

        uint8 decimals = getDecimals();
        uint256 priceWith18Decimals = uint256(price) * 10 ** (18 - decimals);

        return (amountInSatoshi * priceWith18Decimals) / 1e8;
    }

    function convertLINKToUSD(
        uint256 amountInWei
    ) public view returns (uint256) {
        int256 price = getLatestLINKPrice();
        require(price > 0, "PriceFeed: invalid price");

        uint8 decimals = getDecimals();
        uint256 priceWith18Decimals = uint256(price) * 10 ** (18 - decimals);

        return (amountInWei * priceWith18Decimals) / 1 ether;
    }

    function getLatestETHRoundData()
        public
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return ethUsdPriceFeed.latestRoundData();
    }

    function getLatestBTCRoundData()
        public
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return btcUsdPriceFeed.latestRoundData();
    }

    function getLatestLINKRoundData()
        public
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return linkUsdPriceFeed.latestRoundData();
    }
}
