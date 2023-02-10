pragma solidity 0.8.18;
// SPDX-License-Identifier: MIT

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract MyToken is IERC20 {

    /// @dev Address of contract Owner
    address contract_owner;

    /// @dev ERC20 metadata
    string private _name;
    string private _symbol;

    uint256 private _totalSupply = 10_000*10**18;
    uint256 private _circulatingSupply; /// @dev to make sure that more than _totalSupply doesn't get minted

    mapping(address => uint256) private _balances;
    mapping (address => mapping(address => uint256)) private _allowances;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        contract_owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == contract_owner, "Not Owner");
        _;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function decimals() public pure returns (uint256) {
        return 18;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function mint(address to, uint256 amount) public onlyOwner returns (bool) {
        require(_circulatingSupply + amount <= _totalSupply, "ERC20: Supply would be exceeded");
        _circulatingSupply += amount;
        _balances[to] += amount;
        emit Transfer(address(0), to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }
        emit Transfer(from, to, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        _allowances[owner][spender] = amount;
    }
    
    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        require(_allowances[owner][spender] >= amount, "ERC20: Not enough allowance");
        if (_allowances[owner][spender] != type(uint256).max) {
            _allowances[owner][spender] -= amount;
        }
        emit Approval(owner, spender, _allowances[owner][spender]);
    }

}