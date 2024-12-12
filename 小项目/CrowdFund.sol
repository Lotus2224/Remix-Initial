// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./IERC20.sol";

// 众筹合约
contract CrowdFund {

    // 众筹活动
    struct Campaign {
        address creator; // 创建者
        uint goal;
        uint pledged; // 众筹总金额
        uint32 startAt;
        uint32 endAt;
        bool claimed; // 判断筹款是否有被创建者领取
    }

    IERC20 public immutable token; // 一个众筹对应一个token
    uint public count; // 众筹活动计数器
    mapping(uint => Campaign) public campaigns; // 众筹活动映射，一个众筹活动Id 对应 一个众筹活动
    mapping(uint => mapping(address => uint)) public pledgedAmount; // 参与众筹活动的映射，众筹活动Id => 参与众筹活动的用户 => 参与众筹活动的金额

    constructor(address _token) {
        token = IERC20(_token);
    }

    event Launch(uint id, address indexed creator, uint goal, uint32 startAt, uint32 endAt); // 开始众筹
    event Cancel(uint id); // 众筹创建者可以在众筹开始之前取消众筹
    event Pledge(uint indexed id, address indexed caller, uint amount); // 其他人可以参与众筹，给出自己参与众筹的金额
    event Unpledge(uint indexed id, address indexed caller, uint amount); // 其他人可以取消众筹，拿回自己参与众筹的金额
    event Claim(uint id); // 达到众筹要求
    event Refund(uint id, address indexed caller, uint amount); // 没有达到众筹要求，参与众筹的参与者可以领取回自己的众筹金额

    // 开始众筹（众筹目标，开始时间，结束时间）
    function launch(uint _goal, uint32 _startAt, uint32 _endAt) external {
        require(_startAt >= block.timestamp, "start at < now");
        require(_endAt >= _startAt, "end at < start at");
        require(_endAt <= block.timestamp + 90 days, "end at > max duration");

        count += 1;
        campaigns[count] = Campaign({
            creator: msg.sender,
            goal: _goal,
            pledged: 0,
            startAt: _startAt,
            endAt: _endAt,
            claimed: false
        });

        emit Launch(count, msg.sender, _goal, _startAt, _endAt);
    }

    // 众筹创建者可以在众筹开始之前取消众筹
    function cancel(uint _id) external {
        Campaign memory campaign = campaigns[_id];
        require(campaign.creator == msg.sender, "no creator"); // 是众筹创建者
        require(block.timestamp < campaign.startAt, "started"); // 众筹还没开始

        delete campaigns[_id];
        emit Cancel(_id);
    }

    // 其他人可以参与众筹，给出自己参与众筹的金额
    function pledge(uint _id, uint _amount) external {
        Campaign memory campaign = campaigns[_id];
        require(block.timestamp >= campaign.startAt, "not started"); // 众筹开始了
        require(block.timestamp <= campaign.endAt, "ended"); // 众筹还没结束

        campaign.pledged += _amount;
        pledgedAmount[_id][msg.sender] += _amount;
        token.transferFrom(msg.sender, address(this), _amount);
        emit Pledge(_id, msg.sender, _amount);
    }

    // 其他人可以取消众筹，拿回自己参与众筹的金额
    function unpledge(uint _id, uint _amount) external {
        Campaign memory campaign = campaigns[_id];
        require(block.timestamp <= campaign.endAt, "ended"); // 众筹还没结束
        require(!campaign.claimed, "claimed"); // 存款还没被创建者领取
        require(pledgedAmount[_id][msg.sender] >= _amount, "pledged < amount"); // 存款人的存款金额大于等于取款值

        campaign.pledged -= _amount;
        pledgedAmount[_id][msg.sender] -= _amount;
        token.transfer(msg.sender, _amount);
        emit Unpledge(_id, msg.sender, _amount);
    }

    // 达到众筹要求
    function claim(uint _id) external {
        Campaign memory campaign = campaigns[_id];
        require(campaign.creator == msg.sender, "not creator"); // 是众筹合约的创建者
        require(block.timestamp > campaign.endAt, "not ended"); // 众筹结束了
        require(campaign.pledged >= campaign.goal, "pledged < goal"); // 众筹总金额大于等于目标值
        require(!campaign.claimed, "claimed");

        campaign.claimed = true;
        token.transfer(campaign.creator, campaign.pledged);
        emit Claim(_id);
    }

    // 没有达到众筹要求，参与众筹的参与者可以领取回自己的众筹金额
    function refund(uint _id) external {
        Campaign memory campaign = campaigns[_id];
        require(block.timestamp > campaign.endAt, "not ended"); // 众筹结束了
        require(campaign.pledged < campaign.goal, "pledged >= goal"); // 众筹总金额小于目标值

        uint bal = pledgedAmount[_id][msg.sender];
        pledgedAmount[_id][msg.sender] = 0;
        token.transfer(msg.sender, bal);
        emit Refund(_id, msg.sender, bal);
    }
}