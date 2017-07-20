/// Slightly modified library, taken from https://github.com/ethereum/dapp-bin/blob/master/library/iterable_mapping.sol
/// @dev Models a uint -> uint mapping where it is possible to iterate over all keys. 
/// http://solidity.readthedocs.io/en/latest/types.html#mappings

library IterableMappings
{
  struct itmap
  {
    mapping(address => uint256) balances;
    KeyFlag[] keys;
    uint size;
  }
  struct balance { address adress; uint256 value; }
  struct KeyFlag { uint key; bool deleted; }
  function insert(itmap storage self, address key, uint256 value) returns (bool replaced)
  {
    uint keyIndex = self.data[key].keyIndex;
    self.data[key].value = value;
    if (keyIndex > 0)
      return true;
    else
    {
      keyIndex = self.keys.length++;
      self.data[key].keyIndex = keyIndex + 1;
      self.keys[keyIndex].key = key;
      self.size++;
      return false;
    }
  }
  function remove(itmap storage self, address key) returns (bool success)
  {
    uint keyIndex = self.data[key].keyIndex;
    if (keyIndex == 0)
      return false;
    delete self.data[key];
    self.keys[keyIndex - 1].deleted = true;
    self.size --;
  }
  function getValue(itmap storage self, address key) returns (uint256)
  {
    return self.data[key].value;
  }
  function setValue(itmap storage self, address key, uint256 _value) returns (bool)
  {
    if (self.data[key].keyIndex < 0) return false;
    self.data[key].value = _value;
    return true;
  }
  function contains(itmap storage self, uint key) returns (bool)
  {
    return self.data[key].keyIndex > 0;
  }
  function iterate_start(itmap storage self) returns (uint keyIndex)
  {
    return iterate_next(self, uint(-1));
  }
  function iterate_valid(itmap storage self, uint keyIndex) returns (bool)
  {
    return keyIndex < self.keys.length;
  }
  function iterate_next(itmap storage self, uint keyIndex) returns (uint r_keyIndex)
  {
    keyIndex++;
    while (keyIndex < self.keys.length && self.keys[keyIndex].deleted)
      keyIndex++;
    return keyIndex;
  }
  function iterate_get(itmap storage self, uint keyIndex) returns (address key, uint256 value)
  {
    key = self.keys[keyIndex].key;
    value = self.data[key].value;
  }
}
