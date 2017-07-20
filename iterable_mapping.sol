/// Slightly modified library, taken from https://github.com/ethereum/dapp-bin/blob/master/library/iterable_mapping.sol
/// nagor@academ.org
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
  struct balance { address adress; uint256 value; }
  struct KeyFlag { uint key; bool deleted; }
  
  function insert(itmap storage self, address key, uint256 value) returns (bool replaced) {
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
  
  function contains(itmap storage self, uint key) returns (bool) {
    return self.balances[key].keyIndex > 0;
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
  
  function iterate_get(itmap storage self, uint keyIndex) returns (address key, uint256 value) {
    key = self.keys[keyIndex].key;
    value = self.balances[key].value;
  }
}
