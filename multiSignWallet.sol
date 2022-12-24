pragma solidity >=0.5.0 <0.6.0;

contract MultiSignWallet 
{
    
    event Deposit(address indexed sender , uint256 amount) ;   // deopsit event is fired when ether is transffered into this multsign wallets 
    event Submit(uint256 indexed txId); //when transaction is submitted and is waiting to be approved then this is fired and 
    event Approve(address indexed  owner , uint indexed txId); //appovral is done by the multisigners of the wallet
    event Revoke(address indexed owner , uint indexed txId);  //if they chmage there mind then they can revoke the transaction 
    event Execute(uint indexed txId) ;  //after sufficeient amount of approvals the transaction is executed 
   
    struct Transaction {
        address to ;    //where the transcation is executed 
        uint value ;    // amount of the ether send to the to address
        bytes data ;    // data send to the to address
        bool executed;  // after exectuin of the transcation it will turn into true
         }  
    address[] public owners;
    mapping (address => bool) public isOwner ; // if the address is the owner of multisign wallet then this mapping will turn true otherwise it will be false 
    uint public required;
    
    Transaction[] public transactions; 
    mapping(uint => mapping(address=>bool)) public approved  ; // transaction no  => address of owners => approved or not 
      
    modifier onlyOwner(){
        require(isOwner[msg.sender], "not owner ");
    _;}
    modifier txExists(uint _txId)
    {
    require(_txId < transactions.length, "tx does not exists");
    _;
    }
   
    modifier notApproved(uint _txId)
    {
        require(!apporved[_txId][msg.sender], "tx already approved ");
        _;
    }
   
    modifier notExectued(uint _txId)
    {
        require(!transactions[_txId].executed , "transaction is already executed");
    }
    


    constructor(address[] memory _owners , uint _required )
     {
        require(_owners.lenght > 0 , "owners required ") ;
        require (_required>0 && _required <= _owners.length, "invalid required no of owners") ;
        
        for (uint i ; i < _owners.length ; i++)
        {
            address owner = _owners[i] ;
            require(owner != address(0), "invalid owner");
            require(!isOwner[owner] , "onwer is not unique");

            isOwner[owner] = true ;  //listing of the address as owner 
            owners.push(owner) ;     //pushing the address inside the ownwers array 
        }
       required = _required;
    }
   

  receive( ) external payable {
    emit Deposit(msg.sender, msg.value);
  }
  function submit(address _to , uint _value , bytes calldata _data) external onlyowner
  {
     transactions.push(Transaction({    //inializing transaction by assigning the values 
         to:_to ;
         value:_value ;
         data :_data ;
         executed : false ; 
     }));
     emit Submit(transactions.length - 1 );        //index where the transaction is stored ; so txId is the element no 


  }
  function approve (uint _txId) external onlyOwner txExists(_txId) notApproved(_txId) notExecuted(_txId)
  {
       approved[_txId][msg.sender] = true ;
       emit Approve(msg.sender, _txId);

  }
   function _getApprovalCount(uint _txId) private view returns (uint count )
   {

   for (uint i ; i < owners.length ; i ++ )
   {
       if(approved[_txId][owners[i]]){     //if the owner is approving the transaction id then the count is increased
           count+=1;
       }


   }
   return count ; 
   }
   function execute(uint _txId) external txExists(_txId) notExecuted(_txId)             
   {
       require(_geApprovalCount(_txId)>= required , "approvals < required " ;
       Transactions storage transaction = transactions[_txId] ;            // stroing the data into transaction from the transactions array                        // an instance is created to store the 

       transaction.executed = true ;

       (bool success , ) = transaction.to.call{value:transaction.value}(transaction.data)
       require(success , "tx is not execueted");
       emit Execute(_txId);
    }
  function revoke (uint _txId ) external onlyOwner txExists(_txId) notExectued(_txId)  // if the owner dont want to approve the transaction now which he has already approved ; transaction shouldt be executed previosuly 
  {
      require(approved[_txId][msg.sender], " tx not approved");     // transaction should be approved firslty
      approved[_txId][msg.sender] = false ;                         //apprioval made false
      emit Revoke(msg.sender ,_txId) ;
   } 
}
