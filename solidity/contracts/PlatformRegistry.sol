pragma solidity ^0.4.15;
import './TokenHolder.sol';
import './interfaces/IERC20Token.sol';

/**
    @dev The Platform Registry allows Trusted Platforms to register globally for linking wallets to their API
    A fee is charged for registering a platform on the registry
    Fees may be withdrawn by the registry owner using withdrawTokens
*/
contract PlatformRegistry is TokenHolder {

///////////////////////////////////////// VARIABLE INITIALIZATION /////////////////////////////////////////

    struct Platform {
        string url;
        string name;
        string description;
        address owner;
    }

    uint256 public lastFeeChanged = 0;              // Last timestamp the fee was updated
    uint256 public fee = 80000000000000000000;      // 80 ENJ fee, may be adjusted
    address public tokenAddress = 0x0;              // address of the Enjin Coin token
    IERC20Token enjinCoin;
    Platform[] platforms;

///////////////////////////////////////// EVENTS /////////////////////////////////////////

    event Registered(uint256 indexed id, string url, string name, string description, address owner);
    event Unregistered(uint256 indexed id, address owner);
    event Updated(uint256 indexed id);

///////////////////////////////////////// MODIFIERS /////////////////////////////////////////

    // Ensure 14 days have passed before allowing fee to be changed
    modifier feeTimeLock { if (lastFeeChanged != 0 && lastFeeChanged + (14 days) > now) return; _; }

    // Ensure new fee is within 10% of existing fee
    modifier feeAmountLimit(uint256 _fee) { if (_fee * 10 > fee * 11 || _fee * 10 < fee * 9) return; _; }

    // Only allow the Platform Owner/Creator to do something
    modifier onlyPlatformOwner(uint256 _id) { if (platforms[_id].owner != msg.sender) return; _; }

///////////////////////////////////////// OWNER FUNCTIONS /////////////////////////////////////////

    function setFee(uint256 _fee) ownerOnly feeTimeLock feeAmountLimit(_fee) {
        fee = _fee;
        lastFeeChanged = now;
    }

    function setToken(address _tokenAddress) validAddress(_tokenAddress) ownerOnly {
        enjinCoin = IERC20Token(_tokenAddress);
    }

///////////////////////////////////////// PUBLIC FUNCTIONS /////////////////////////////////////////

    function register(string _url, string _name, string _description) returns (bool) {
        require(enjinCoin.allowance(msg.sender, this) >= fee);

        // Transfer fee from registrant to registry contract
        enjinCoin.transferFrom(msg.sender, this, fee);

        platforms.push(Platform(_url, _name, _description, msg.sender));
        Registered(platforms.length - 1, _url, _name, _description, msg.sender);
        return true;
    }

    function unregister(uint256 _id) onlyPlatformOwner(_id) {
        Unregistered(_id, platforms[_id].owner);
        delete platforms[_id];
    }

    function setPlatformOwner(uint256 _id, address _newOwner) onlyPlatformOwner(_id) validAddress(_newOwner) {
        platforms[_id].owner = _newOwner;
        Updated(_id);
    }

    function setPlatformUrl(uint256 _id, string _url) onlyPlatformOwner(_id) {
        platforms[_id].url = _url;
        Updated(_id);
    }

    function setPlatformName(uint256 _id, string _name) onlyPlatformOwner(_id) {
        platforms[_id].name = _name;
        Updated(_id);
    }

    function setPlatformDescription(uint256 _id, string _description) onlyPlatformOwner(_id) {
        platforms[_id].description = _description;
        Updated(_id);
    }

///////////////////////////////////////// CONSTANT FUNCTIONS /////////////////////////////////////////

    function platformCount() constant returns (uint256) {
        return platforms.length;
    }

    function platform(uint256 _id) constant returns (string url, string name, string description, address owner) {
        var p = platforms[_id];
        url = p.url;
        name = p.name;
        description = p.description;
        owner = p.owner;
    }
}