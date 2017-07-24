pragma solidity ^0.4.10;

contract ERC20 {
    function totalSupply() constant returns (uint supply);
    function balanceOf(address who) constant returns (uint value);
    function allowance(address owner, address spender) constant returns (uint _allowance);

    function transfer(address to, uint value) returns (bool ok);
    function transferFrom(address from, address to, uint value) returns (bool ok);
    function approve(address spender, uint value) returns (bool ok);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract snkCoin is ERC20{
	uint initialSupply;
	string name;
	string symbol;
	uint currentPrice;
	address snkFoundation;
	string[] questions;
	uint voteStartDate;
	uint daysAfter;
	IterableBalances.itmap balances;
	mapping (address => mapping (address => uint256)) allowed;
	mapping (address => uint256) approvedDividends;
	voteUtils.itmap answers;
	mapping (address => uint) donators;
	
	modifier onlyOwner{
    if (msg.sender == snkFoundation) {
		  _;
		}
	}

	modifier tokenHolder{
		if (IterableBalances.containsKey(balances, msg.sender)) {
		  _;
		}
	}
	
	modifier costs(uint _amount) {
    
        if (msg.value >= _amount)
            {
                _;
            }
    }

	function totalSupply() constant returns (uint256) {
		return initialSupply;
    }

	function balanceOf(address src) constant returns (uint256) {
		return IterableBalances.getValue(balances,src);
    }

	function allowance(address owner, address spender) constant returns (uint256) {
		return allowed[owner][spender];
    }

	function transfer(address to, uint value) returns (bool) {
		if (IterableBalances.getValue(balances,msg.sender) >= value && value > 0) {
			IterableBalances.setValue(balances,msg.sender, IterableBalances.getValue(balances,msg.sender)- value);
			IterableBalances.setValue(balances,to, IterableBalances.getValue(balances,to) + value);
			
			Transfer(msg.sender, to, value);
        
			return true;
		} else 
			return false;
    }

	function transferFrom(address from, address to, uint256 value) returns (bool success) {
		if (IterableBalances.getValue(balances,from) >= value && allowed[from][msg.sender] >= value && value > 0) {
		  IterableBalances.setValue(balances,to, IterableBalances.getValue(balances,to) + value);
		  IterableBalances.setValue(balances,from, IterableBalances.getValue(balances,from) - value);
		  allowed[from][msg.sender] -= value;
		  Transfer(from, to, value);
		  return true;
		} else 
		  return false;
	 }

	function approve(address spender, uint value) returns (bool ok) {
		if ((value != 0) && (allowed[msg.sender][spender] != 0)) throw;
		allowed[msg.sender][spender] = value;
		Approval(msg.sender, spender, value);
		return true;
	}

	function snkCoin(uint supply, string _name, string _symbol, uint _initialPrice) {
        snkFoundation = msg.sender;		
		initialSupply = supply;
		currentPrice = _initialPrice;
		name = _name;
		symbol = _symbol;
    }

	function setCurrentPrice (uint _price) onlyOwner{
		currentPrice = _price;
	}

	function donate() payable{
		donators[msg.sender] = msg.value;
		//thank you!!  
	}

	function buySnkCoins() payable costs(currentPrice) {
		if (msg.value<currentPrice) throw; 
		uint numberOfSnkCoinsToSend = msg.value/currentPrice;
		if (IterableBalances.getValue(balances,this)<numberOfSnkCoinsToSend) throw;
		transfer(msg.sender, numberOfSnkCoinsToSend);
	}

	function approveDividends (uint totalDividendsAmount) onlyOwner{
		uint256 dividendsPerToken = totalDividendsAmount / initialSupply; 

		for (var i = IterableBalances.iterate_start(balances); IterableBalances.iterate_valid(balances, i); i = IterableBalances.iterate_next(balances, i))
			{
				var (tokenHolder, value) = IterableBalances.iterate_get(balances, i);
				approvedDividends[tokenHolder] = value * dividendsPerToken;
			}
	}

	function transferAllDividends() onlyOwner{
	
		for (var i = IterableBalances.iterate_start(balances); IterableBalances.iterate_valid(balances, i); i = IterableBalances.iterate_next(balances, i))
			{
				var (tokenHolder, value) = IterableBalances.iterate_get(balances, i);
				var _value = value;
				_value++;
				if (approvedDividends[tokenHolder] != 0)
				{
					tokenHolder.transfer(approvedDividends[tokenHolder]);
					approvedDividends[tokenHolder] = 0;
				}
			}
	}

	function setVoteStartDate(uint _daysAfter) onlyOwner{
		daysAfter = _daysAfter;
		voteStartDate = now;
	}

	function vote(bool[] _answers) tokenHolder{
		if (now <= voteStartDate + daysAfter * 1 days) {
				voteUtils.setValue(answers,msg.sender,_answers);
			}
	}
}

/// Slightly modified library, taken from https://github.com/ethereum/dapp-bin/blob/master/library/iterable_mapping.sol
/// nagor[at]academ.org
/// @dev Models a uint -> uint mapping where it is possible to iterate over all keys. 
/// http://solidity.readthedocs.io/en/latest/types.html#mappings

library voteUtils
{
  struct itmap {
    mapping(address => IndexValue) votes;
    KeyFlag[] keys;
    uint size;
  }
  
  struct IndexValue { uint keyIndex; bool[] value; }
  struct KeyFlag { address key; bool deleted; }
  
  function insert(itmap storage self, address key, bool[] value) returns (bool replaced) {
    uint keyIndex = self.votes[key].keyIndex;
    self.votes[key].value = value;
    if (keyIndex > 0)
      return true;
    else {
      keyIndex = self.keys.length++;
      self.votes[key].keyIndex = keyIndex + 1;
      self.keys[keyIndex].key = key;
      self.size++;
      return false;
    }
  }
  
  function remove(itmap storage self, address key) returns (bool success) {
    uint keyIndex = self.votes[key].keyIndex;
    if (keyIndex == 0)
      return false;
    delete self.votes[key];
    self.keys[keyIndex - 1].deleted = true;
    self.size --;
  }
  
  function getValue(itmap storage self, address key) returns (bool[]) {
    return self.votes[key].value;
  }
  
  function setValue(itmap storage self, address key, bool[] _value) returns (bool) {
    if (self.votes[key].keyIndex < 0) return false;
    self.votes[key].value = _value;
    return true;
  }

  function iterate_start(itmap storage self) returns (uint keyIndex) {
    return iterate_next(self, uint(-1));
  }
  function iterate_valid(itmap storage self, uint keyIndex) returns (bool) {
    return keyIndex < self.keys.length;
  }
  
  function iterate_next(itmap storage self, uint keyIndex) returns (uint r_keyIndex) {
    keyIndex++;
    while (keyIndex < self.keys.length && self.keys[keyIndex].deleted)
      keyIndex++;
    return keyIndex;
  }
  
  function iterate_get(itmap storage self, uint keyIndex) returns (address key, bool[] value) {
    key = self.keys[keyIndex].key;
    value = self.votes[key].value;
  }
}

/// Slightly modified library, taken from https://github.com/ethereum/dapp-bin/blob/master/library/iterable_mapping.sol
/// nagor[at]academ.org
/// @dev Models a uint -> uint mapping where it is possible to iterate over all keys. 
/// http://solidity.readthedocs.io/en/latest/types.html#mappings

library IterableBalances
{
  struct itmap {
    mapping(address => IndexValue) balances;
    KeyFlag[] keys;
    uint size;
  }
  
  struct IndexValue { uint keyIndex; uint value; }
  struct KeyFlag { address key; bool deleted; }
  
  function insert(itmap storage self, address key, uint value) returns (bool replaced) {
    uint keyIndex = self.balances[key].keyIndex;
    self.balances[key].value = value;
    if (keyIndex > 0)
      return true;
    else {
      keyIndex = self.keys.length++;
      self.balances[key].keyIndex = keyIndex + 1;
      self.keys[keyIndex].key = key;
      self.size++;
      return false;
    }
  }
  
  function remove(itmap storage self, address key) returns (bool success) {
    uint keyIndex = self.balances[key].keyIndex;
    if (keyIndex == 0)
      return false;
    delete self.balances[key];
    self.keys[keyIndex - 1].deleted = true;
    self.size --;
  }
  
  function getValue(itmap storage self, address key) returns (uint256) {
    return self.balances[key].value;
  }
  
  function setValue(itmap storage self, address key, uint256 _value) returns (bool) {
    if (self.balances[key].keyIndex < 0) return false;
    self.balances[key].value = _value;
    return true;
  }
  
  function containsKey(itmap storage self, address key) returns (bool) {
    return self.balances[key].value > 0;
  }
  
  function iterate_start(itmap storage self) returns (uint keyIndex) {
    return iterate_next(self, uint(-1));
  }
  function iterate_valid(itmap storage self, uint keyIndex) returns (bool) {
    return keyIndex < self.keys.length;
  }
  
  function iterate_next(itmap storage self, uint keyIndex) returns (uint r_keyIndex) {
    keyIndex++;
    while (keyIndex < self.keys.length && self.keys[keyIndex].deleted)
      keyIndex++;
    return keyIndex;
  }
  
  function iterate_get(itmap storage self, uint keyIndex) returns (address key, uint value) {
    key = self.keys[keyIndex].key;
    value = self.balances[key].value;
  }
}
