pragma solidity ^0.4.15;

import './IERC20Token.sol';

contract IENJToken is IERC20Token {
    function crowdfundAddress() public constant returns (address);
    function incentivisationFundAddress() public constant returns (address);
    function totalAllocated() public constant returns (uint256);
}

contract ENJAllocation {
    address public tokenAddress;
    IENJToken token;

    function ENJAllocation(address _tokenAddress){
        tokenAddress = _tokenAddress;
        token = IENJToken(tokenAddress);
    }

    function circulation() constant returns (uint256) {
        return token.totalAllocated() - token.balanceOf(token.incentivisationFundAddress());
    }
}
