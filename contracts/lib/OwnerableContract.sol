pragma solidity ^0.4.24;


contract OwnerableContract{
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    
    mapping (address => bool) public admins;

    constructor () public { 
        owner = msg.sender; 
        addAdmin(owner);
    }    
  
    /* Modifiers */
    // This contract only defines a modifier but does not use
    // it: it will be used in derived contracts.
    // The function body is inserted where the special symbol
    // `_;` in the definition of a modifier appears.
    // This means that if the owner calls this function, the
    // function is executed and otherwise, an exception is
    // thrown.
    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }
    modifier onlyAdmins() {
        require(
            admins[msg.sender],
            "Only admin can call this function."
        );
        _;
    }    
    
    /* Owner */
    function setOwner (address _owner) onlyOwner() public {
        owner = _owner;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    function addAdmin (address _admin) onlyOwner public {
        admins[_admin] = true;
    }

    function removeAdmin (address _admin) onlyOwner public {
        delete admins[_admin];
    }  
    
    /* Withdraw */
    function withdrawAll () onlyAdmins public {
        msg.sender.transfer(address(this).balance);
    }

    function withdrawAmount (uint256 _amount) onlyAdmins public {
        msg.sender.transfer(_amount);
    }  
}