pragma solidity ^0.5.11;

// ----------------------------------------------------------------------------
// 'Xclusive Coin' token contract
//
// Deployed to : 0x887C2B36D83c9F5C1e9d850D9d53CCF40FBF8d0f
// Symbol      : Xclusive
// Name        : 0 Xclusive Token
// Total supply: 100000000
// Decimals    : 2
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function transfer(address to, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);

}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract XclusiveToken is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    address manager;
    address payable[] public validate;
    address[] public admins;
    mapping(address => bool) denied;
    mapping(address => uint) voteCountAccept;
    mapping(address => uint) voteCountReject;
    mapping(address => uint) balances;
    mapping(address => bool) isValidated;
    mapping(address => bool) isAdmin;
    mapping(address => mapping(address => bool)) didVote;
    mapping(string => address) post;
    mapping(address => mapping(string => bool)) didVotePost;
    mapping(string => uint) voteCountAcceptPost;
    mapping(string => uint) voteCountRejectPost;
    mapping(string => bool) isValidatedPost;
    
    uint noOfAdmins;
    event becameAdmin(address indexed add);

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        noOfAdmins = 0;
        symbol = "Xclusive";
        name = "0 Xclusive Token";
        manager = msg.sender;
        decimals = 2;
        _totalSupply = 1000000000;
        balances[0x887C2B36D83c9F5C1e9d850D9d53CCF40FBF8d0f] = _totalSupply;
        emit Transfer(address(0), 0x887C2B36D83c9F5C1e9d850D9d53CCF40FBF8d0f, _totalSupply);
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    
    //TODO: GIVE CURRENCY WHEN VALIDATE COMPLETE for posts and new users
    //Pay to Post

    function consensusAccept(address applicationAddress) public {
         //After voting consensus
        isValidated[applicationAddress] = true;
        admins.push(applicationAddress);
        noOfAdmins = safeAdd(noOfAdmins,1);
        isAdmin[applicationAddress] = true;
        transferFrom(manager,applicationAddress,5000);
    }
    
    function consensusReject(address applicationAddress) public {
        isValidated[applicationAddress] = true;
        denied[applicationAddress] = true;
        isAdmin[applicationAddress] = false;
    }
    function viewConsensusStatus()  view public returns (string memory) {
        require(isAdmin[msg.sender] == false);
        require(denied[msg.sender] == false,"You have been previously denied");
        require(isValidated[msg.sender] == false);
        return "Pending approval";
    }
    function acceptUser(address applicationAddress) public {
        require(msg.sender != applicationAddress);
        require(isValidated[applicationAddress] == false);
        require(denied[applicationAddress] == false);
        require(didVote[applicationAddress][msg.sender] == false);
        voteCountAccept[applicationAddress] = safeAdd(voteCountAccept[applicationAddress],1);
        didVote[applicationAddress][msg.sender] = true;
        transferFrom(manager,msg.sender,250);
        require((noOfAdmins/2) < voteCountAccept[applicationAddress]);
        emit becameAdmin(applicationAddress);
        consensusAccept(applicationAddress);
        
    }
    function rejectUser (address applicationAddress) public {
        require(msg.sender != applicationAddress);
        require(isValidated[applicationAddress] == false);
        require(denied[applicationAddress] == false);
        require(didVote[applicationAddress][msg.sender] == false);
        voteCountReject[applicationAddress] = safeAdd(voteCountReject[applicationAddress],1);
        didVote[applicationAddress][msg.sender] = true;
        transferFrom(manager,msg.sender,250);
        require((noOfAdmins/2) < voteCountReject[applicationAddress]);
        consensusReject(applicationAddress);
    }
    function signUp() public {
        //Transfer an initial 100 tokens to this dude to begin with.
        require(denied[msg.sender] == false,"You have been previously denied");
        require(msg.sender != manager);
        require(noOfAdmins < 100,"Xclusive is currenly full. Try again after a while");
        voteCountAccept[msg.sender] = 0;
        voteCountReject[msg.sender] = 0;
        isValidated[msg.sender] = false;
        validate.push(msg.sender);
        
    }

    function addVotablePost(string memory postID) public {
        transferFrom(msg.sender,manager,5);
        post[postID] = msg.sender;
    }
    function postAccept(string memory postID) public {
        //Give token at the end
        require(post[postID] != msg.sender);
        require(isValidatedPost[postID] != true);
        require(didVotePost[msg.sender][postID] != true);
        require(isAdmin[msg.sender] == true);
        voteCountAcceptPost[postID] = safeAdd(voteCountAcceptPost[postID],1);
        didVotePost[msg.sender][postID] = true;
        transferFrom(manager,msg.sender,150);
        require(voteCountAcceptPost[postID] > (noOfAdmins/2));
        consensusAcceptPost(postID);
    }


    function postReject(string memory postID) public {
        //Give Token
        require(post[postID] != msg.sender);
        require(didVotePost[msg.sender][postID] != true);
        require(isValidatedPost[postID] != true);
        require(isAdmin[msg.sender] == true);
        voteCountRejectPost[postID] = safeAdd(voteCountRejectPost[postID],1);
        didVotePost[msg.sender][postID] = true;
        transferFrom(manager,msg.sender,150);
        require(voteCountRejectPost[postID] > (noOfAdmins/2));
        consensusRejectPost(postID);
    }

    function consensusAcceptPost(string memory postID) private  returns(string memory){

        isValidatedPost[postID] = true;
        return "Accepted :)";
    }
    function consensusRejectPost(string memory postID) private  returns(string memory){
        isValidatedPost[postID] = true;
        return "Rejected :(";
    }
    
    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to to account
    // - Owner's account must have sufficient balance to transfer
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        require(to != manager);
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer tokens from the from account to the to account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the from account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }



    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    function () payable external {
        revert();
    }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}