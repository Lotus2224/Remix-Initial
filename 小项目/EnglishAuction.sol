// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./IERC721.sol";

// 英式拍卖
contract EnglishAuction {
    IERC721 public immutable nft;
    uint public  immutable nftId;

    address payable public immutable seller; // 卖方
    uint32 public endAt; // 结束时间
    bool public started; // 拍卖是否开始
    bool public ended; // 拍卖是否结束

    address public highestBidder; // 最高出价者地址
    uint public highestBid; // 最高出价
    mapping(address => uint) public bids; // 除了最高出价之外的，每个人的历史累积最高出价之和

    constructor(address _nft, uint _nftId, uint _startingBid) {
        nft = IERC721(_nft);
        nftId = _nftId;
        seller = payable(msg.sender);
        highestBid = _startingBid;
    }

    event Start(); // 开始拍卖
    event Bid(address indexed sender, uint amount); // 出价
    event Withdraw(address indexed bidder, uint amount); // 撤销，取款
    event End(address highestBidder, uint amount); // 结束拍卖
    // Tips：End事件只会在拍卖结束时触发一次。这是因为拍卖的生命周期是有限的，一旦结束，整个拍卖过程已经完成。所以，highestBidder只是一次性的记录最高出价者。由于事件的触发仅发生一次，没有必要频繁地查询此事件，因此不会造成检索效率的问题。不需要为单次触发事件增加额外的索引开销。因此，不加索引是一个节省资源和gas费用的合理做法。

    // 开始拍卖
    function strat() external {
        require(msg.sender == seller, "not seller");
        require(!started, "started");
        started = true;
        endAt = uint32(block.timestamp + 60); // 结束时间在拍卖开始后的60秒
        // endAt = uint32(block.timestamp + 7 days); // 结束时间在拍卖开始后的7天
        nft.transferFrom(seller, address(this), nftId);
        emit Start();
    }

    // 出价
    function bid() external payable {
        require(started, "not started");
        require(block.timestamp < endAt, "ended");
        require(msg.value > highestBid, "value < highest bid");
        
        if (highestBidder != address(0)) {
            bids[highestBidder] += highestBid;
        }

        highestBid = msg.value;
        highestBidder = msg.sender;

        emit Bid(msg.sender, msg.value);
    }

    // 撤销，取款
    function withdraw() external {
        uint bal = bids[msg.sender]; // 结余
        bids[msg.sender] = 0;
        payable(msg.sender).transfer(bal);
        emit Withdraw(msg.sender, bal);
    }

    // 结束拍卖
    function end() external {
        require(started, "not started");
        require(!ended, "ended");
        require(block.timestamp >= endAt, "not ended"); // 当前时间需要大于结束时间
        ended = true;
        if (highestBidder != address(0)) {
            nft.transferFrom(address(this), highestBidder, nftId); // 给最高出价者货物nftId，将合约中保存的nftId发送到最高出价者地址中
            seller.transfer(highestBid); // 给卖方钱，把合约中的主币发送到销售者的地址上
        } else {
            nft.transferFrom(address(this), seller, nftId); // 把nftId从当前合约的地址 发送到 销售者的地址上
        }
        emit End(highestBidder, highestBid);
    }
}