// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256); // 当前合约的total总量

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256); // 某个账户的当前余额

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool); // 把账户中的余额，由当前调用者发送到另一个账户中

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256); // 查询某一个账户对另一个账户的批准额度有多少

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool); // 批准函数，把我账户上的数量批准给另一个账户

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool); // amount数量的tokens，从sender发送到recipient，

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value); // 上述的transfer是写入函数，所以要加一个事件，通过Transfer事件，就可以查看token的流转

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value); // approve函数的事件，记录批准的流转
}

// 实现IERC20接口的合约 就是ERC20的标准的合约（不管里面的具体逻辑）
contract ERC20 is IERC20 {
    uint public totalSupply; // total总量，合约的供应总量
    mapping(address => uint) public balanceOf; // address地址对应的账户余额
    mapping(address => mapping(address => uint)) public allowance; // 一个账户对另一个账户的批准额度（批准账户 对 被批准账户 的批准额度）

    string public name = "Test"; // Token名称
    string public symbol = "TEST"; // Token缩写
    uint8 public decimals = 18; // Token精度，智能合约只能记录整数，1则后面有18个零

    // 合约的部署者一定数量的余额
    constructor(uint initialSupply) {
        totalSupply = initialSupply;
        balanceOf[msg.sender] = initialSupply;
    }

    // 转账amount to recipient接受者
    function transfer(address recipient, uint amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    // 批准spender消费者(被批准额度的账户)，amount金额的额度
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // 消息的发送者sender，当前函数的调用者 就是被批准额度的账户，它给recipient消费者发送amount的金额，扣的钱是扣在 批准额度账户上的，也就是sender消息发送者
    // 我给女盆友发钱，然后扣的钱是我爸的钱
    // 我爸   批准额度的账户，扣钱人，sender
    // 我     被批准额度的账户，发钱人，我发钱，但是不扣我自己的钱，扣我爸的钱，spender
    // 女盆友  收钱人，recipient
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        require(allowance[sender][msg.sender] >= amount, "Allowance exceeded");
        require(balanceOf[sender] >= amount, "Insufficient balance");
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    // 编译时会报错是因为重复定义了 Transfer 和 Approval 事件。这些事件已经在 IERC20 接口中声明，而 ERC20 合约继承了 IERC20，因此不需要再次在 ERC20 中定义它们
    // 转账事件
    // event Transfer(address indexed from, address indexed to, uint256 value);
    // 批准额度事件
    // event Approval(address indexed owner, address indexed spender, uint256 value);

    // 铸币函数，给一个账户增加余额，需要加上权限控制
    // （正常来说是通过constructor构造函数，给合约的部署者一定数量的余额）
    function mint(uint amount) external {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount); // 0地址，铸币方法
    }

    // 销毁函数
    function burn(uint amount) external {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount); // 0地址，铸币方法
    }
}