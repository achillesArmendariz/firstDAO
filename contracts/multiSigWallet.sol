// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.9.0;
pragma abicoder v2;

//Multi-sig Wallet
//Creator: Achilles Armendariz

contract myContract{

    //owners should be able to vote to delete a request transfer so that it doesn't congest system

    //I should create another sturct and be specific with the funcding is, example on solididty.lang
    //for structs

    //this contract should also practice inheritance where I see fit.

    address creator;
    uint approvalCountReq;
    uint transactionNumber;
    // keep track of the numver of created
    //transfer requests

    mapping(address => bool) isOwner; //Verify that the client address is owner
    mapping(address =>uint) balance; //Keep track of the balances of each address interacting w/ SC

    //made double mapping so you can query for only
    //approved transcations
    //mapping(uint => mapping(bool=> Transfers)) transactionRequests;
    //Transfers[] public transfersNotApproved;

    //in these two mappings, I decided to use a state variable as the key
    //value for the map, to eliminate ambigous transaction id's

    //keep track of who's beeb approved that can
    //approve
    mapping(address => mapping(uint=> bool)) approvals;
    mapping(uint => Transfers) transactions;
    //decided to get rid of mapping because only approvers
    //should be able to approve, select indiv, in a array of struct

    //creating a constructor that initializes the states of
    //the SC once it's deployed onto mainnet

    event transferRequestCreated(uint _id, uint _amount, address initiator, address recipient);
    event approvalReceived(uint id, uint approvals, address approver);
    event transferApproved(uint id);

    constructor(){
        isOwner[msg.sender]=true;
        creator = msg.sender;
    }

    /*
    creating an object, or "Struct", that can recieve a payable
    address, with a stated value that they'd like to send to said
    address. Once this new transfer object is created we'll initiate
    approvals to 0 and transaction number to the last one avaible.
    */
    struct Transfers{
        address payable payTo;
        uint value;
        uint approvalAccumulated;
        bool sent;
        uint _transactionNumber;
        address creator;

}

    /*
    function that runs before my actual function, this will allow me
    to reduce some redundant code that i'd like to see it multiple functions.

    this onlyOwner requires that before function is used, you're one of the
    privileged to use it.
    */
    modifier onlyOwner{
       require(isOwner[msg.sender] == true, "you're now allowed to use this function");
        _;
   }

    //Only the creator of the smart contract who launced it onto mainnet
    //can add more owners. These owner's can approve transaction requests.
    function addOwner(address member)public{
        require(msg.sender == creator, "You're not the creator of this contract");
        isOwner[member]=true;
        approvalCountReq+=1;

    }
    function NumOfOwners()public view returns(uint){
        uint NumOwners;
        NumOwners = approvalCountReq+1;
        return NumOwners;
    }
    //This function will allow anyone to deposit money,
    //it doesn't matter if you're a owner or a creator, anyone.
    function deposit()public payable returns(uint){
        balance[msg.sender] += msg.value;
        return balance[msg.sender];
    }

    //This function will only be something that is viewable
    // the client wants balance of they're account
    function getMyBalance() public view returns(uint){
        return balance[msg.sender];
    }

    function getSCBalance() onlyOwner public view returns(uint){
        return address(this).balance;
    }

    //To be determined if this creates what I want to create and
    // make sure that we are creating a new transaction memory for
    //each new request.
    function createTransferReq(address payable sendTo, uint valueToSend)public returns(uint){
        require(balance[msg.sender]>=1, "You're not a contributing member of our society");
        require(address(this).balance >= valueToSend, "Amount requested too large");
       // transactionRequests[transactionNumber][false] = Transfers memory transaction;

        //this is a mapping storage allocation


        //thinking about creating a new Transfer object that stored
        //in a state variable array of Transfer. This would keep track
        //of non-approved transactions left, while map has entire record.
        //I'd do this because it's each to return an array and pop items
        //I'm personally thinking that thse two storage type need to mirror
        // each other indices. And have the necessary require().
        //transfersNotApproved.push(Transfers(sendTo, valueToSend, 0, transactionNumber, msg.sender));
        Transfers storage newRequest = transactions[transactionNumber];
        newRequest.payTo = sendTo;
        newRequest.value = valueToSend;
        newRequest.approvalAccumulated=0;
        newRequest.sent = false;
        newRequest._transactionNumber = transactionNumber;
        newRequest.creator = msg.sender;

        emit transferRequestCreated(newRequest._transactionNumber, newRequest.value, newRequest.creator, newRequest.payTo);
        uint oldTxNum = transactionNumber;
        transactionNumber +=1;

        return oldTxNum;
    }

    function approveRequest(uint id)public onlyOwner {
    require(approvals[msg.sender][id] == false, "You've already approved this transaction");
    require(transactions[id].sent ==false, "This transactions has already been sent");
      approvals[msg.sender][id] = true;
      emit approvalReceived(id, transactions[id].approvalAccumulated, msg.sender);
      transactions[id].approvalAccumulated += 1;
      if(transactions[id].approvalAccumulated == approvalCountReq){

          sendMoney(id);
          emit transferApproved(id);
          //print out a message like "the dao has sent he money and now has ..remaining"
      }
    }

    function sendMoney(uint id)private{
        require(address(this).balance >= transactions[id].value, "We don't have enough to Transfer money :/");
        transactions[id].sent = true;
        transactions[id].payTo.transfer(transactions[id].value);

    }

    function getNonApprovedTransactions()public view onlyOwner returns(Transfers[] memory){
        Transfers[] memory nonApproved = new Transfers[](transactionNumber);
        for(uint i = 0; i<transactionNumber; i++){
            if(transactions[i].sent == false){
                nonApproved[i]=Transfers(transactions[i].payTo, transactions[i].value, transactions[i].approvalAccumulated,
                transactions[i].sent, transactions[i]._transactionNumber, transactions[i].creator);
            }
        }

        return nonApproved;

   }





}
