pragma solidity ^0.4.24;

import "./SafeMath.sol";
import "./OwnerableContract.sol";

/**
 * @title ERC20Interface
 * @dev https: *github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
 contract ERC20Interface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address tokenOwner) public view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}


/**
 * @dev Contract function to receive approval and execute function in one call
 */
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is OwnerableContract {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyAdmins whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyAdmins whenPaused public {
    paused = false;
    emit Unpause();
  }
}

/**
 * @title 
 * @dev ERC20 Token, with the addition of symbol, name and decimals and an initial supply
 */
contract SignatureToken is ERC20Interface, Pausable {
    using SafeMath for uint256;

    string public symbol;
    string public  name;
    uint8 public decimals;
    string public version = "H0.1";
    
    uint256 totalSupply_;
    uint256  maxSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;


    /**
     * @dev Constructor
     */ 
    constructor(string _symbol, string _name, uint256 _initialAmount, uint256 _maxSupply) public {
        symbol = _symbol;
        name = _name;
        decimals = 18;
        totalSupply_ = _initialAmount * 10**uint(decimals);
        maxSupply = _maxSupply;
        balances[owner] = totalSupply_;
        
        emit Transfer(address(0), msg.sender, totalSupply_);
    }


    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address _tokenOwner) public view returns (uint256 balance) {
        return balances[_tokenOwner];
    }


    /**
     * Transfer the balance from token owner's account to `to` account
     * - Owner's account must have sufficient balance to transfer
     * - 0 value transfers are allowed
     */ 
    function transfer(address _to, uint256 _tokens) public whenNotPaused returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(_tokens);
        balances[_to] = balances[_to].add(_tokens);
        emit Transfer(msg.sender, _to, _tokens);
        return true;
    }


    /** 
     * Token owner can approve for `spender` to transferFrom(...) `tokens`
     * from the token owner's account
     *
     * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
     * recommends that there are no checks for the approval double-spend attack
     * as this should be implemented in user interfaces 
     */
    function approve(address _spender, uint256 _tokens) public whenNotPaused returns (bool success) {
        allowed[msg.sender][_spender] = _tokens;
        emit Approval(msg.sender, _spender, _tokens);
        return true;
    }


    /**
     * Transfer `tokens` from the `from` account to the `to` account
     * 
     * The calling account must already have sufficient tokens approve(...)-d
     * for spending from the `from` account and
     * - From account must have sufficient balance to transfer
     * - Spender must have sufficient allowance to transfer
     * - 0 value transfers are allowed
     */
    function transferFrom(address _from, address _to, uint256 _tokens) public whenNotPaused returns (bool success) {
        balances[_from] = balances[_from].sub(_tokens);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_tokens);
        balances[_to] = balances[_to].add(_tokens);
        emit Transfer(_from, _to, _tokens);
        return true;
    }


    /**
     * Returns the amount of tokens approved by the owner that can be
     * transferred to the spender's account
     */
    function allowance(address _tokenOwner, address _spender) public view returns (uint256 remaining) {
        return allowed[_tokenOwner][_spender];
    }


    /** 
     * Token owner can approve for `spender` to transferFrom(...) `tokens`
     * from the token owner's account. The `spender` contract function
     * `receiveApproval(...)` is then executed
     */
    function approveAndCall(address _spender, uint256 _tokens, bytes _data) public whenNotPaused returns (bool success) {
        allowed[msg.sender][_spender] = _tokens;
        emit Approval(msg.sender, _spender, _tokens);
        ApproveAndCallFallBack(_spender).receiveApproval(msg.sender, _tokens, this, _data);
        return true;
    }

    function mintToken(address _target, uint256 _mintedAmount) onlyAdmins whenNotPaused public {
        require(totalSupply_ <= maxSupply);
        balances[_target] = balances[_target].add(_mintedAmount);
        totalSupply_ = totalSupply_.add(_mintedAmount);
        emit Transfer(0, owner, _mintedAmount);
        emit Transfer(owner, _target, _mintedAmount);
    }

    /** 
     * Owner can transfer out any accidentally sent ERC20 tokens
     */
    function transferAnyERC20Token(address tokenAddress, uint256 tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}