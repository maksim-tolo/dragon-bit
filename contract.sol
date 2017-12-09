pragma solidity ^0.4.19;

contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}

contract ERC721 {
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

contract DragonBase is Ownable {
    event Birth(address owner, uint256 dragonId);
    event Transfer(address from, address to, uint256 tokenId);

    struct Dragon {
      // uint256 genes; TODO
      // string name; TODO
      uint8 attack;
      uint8 defence;
      uint8 color;
      uint8 bodyType;
      uint8 eyesType;
      uint8 mouthType;
      uint8 hornsType;
      uint8 wingsType;
      uint16 health;
      uint16 price;
    }

    Dragon[] dragons;

    mapping (uint256 => address) public dragonIndexToOwner;
    mapping (address => uint256) ownershipTokenCount;
    mapping (uint256 => address) public dragonIndexToApproved;

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        ownershipTokenCount[_to]++;
        dragonIndexToOwner[_tokenId] = _to;

        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            delete dragonIndexToApproved[_tokenId];
        }

        Transfer(_from, _to, _tokenId);
    }
}

contract ERC721Metadata {
    function getMetadata(uint256 _tokenId, string) public view returns (bytes32[4] buffer, uint256 count) {
        if (_tokenId == 1) {
            buffer[0] = "Hello World! :D";
            count = 15;
        } else if (_tokenId == 2) {
            buffer[0] = "I would definitely choose a medi";
            buffer[1] = "um length string.";
            count = 49;
        } else if (_tokenId == 3) {
            buffer[0] = "Lorem ipsum dolor sit amet, mi e";
            buffer[1] = "st accumsan dapibus augue lorem,";
            buffer[2] = " tristique vestibulum id, libero";
            buffer[3] = " suscipit varius sapien aliquam.";
            count = 128;
        }
    }
}


contract DragonOwnership is DragonBase, ERC721 {
    string public constant name = "DragonBit";
    string public constant symbol = "DB";
    ERC721Metadata public erc721Metadata;

    bytes4 constant InterfaceSignature_ERC165 =
        bytes4(keccak256('supportsInterface(bytes4)'));

    bytes4 constant InterfaceSignature_ERC721 =
        bytes4(keccak256('name()')) ^
        bytes4(keccak256('symbol()')) ^
        bytes4(keccak256('totalSupply()')) ^
        bytes4(keccak256('balanceOf(address)')) ^
        bytes4(keccak256('ownerOf(uint256)')) ^
        bytes4(keccak256('approve(address,uint256)')) ^
        bytes4(keccak256('transfer(address,uint256)')) ^
        bytes4(keccak256('transferFrom(address,address,uint256)')) ^
        bytes4(keccak256('tokensOfOwner(address)')) ^
        bytes4(keccak256('tokenMetadata(uint256,string)'));

    function supportsInterface(bytes4 _interfaceID) external view returns (bool)
    {
        return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
    }

    function setMetadataAddress(address _contractAddress) public onlyOwner {
        erc721Metadata = ERC721Metadata(_contractAddress);
    }

    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return dragonIndexToOwner[_tokenId] == _claimant;
    }

    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return dragonIndexToApproved[_tokenId] == _claimant;
    }

    function _approve(uint256 _tokenId, address _approved) internal {
        dragonIndexToApproved[_tokenId] = _approved;
    }

    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

    function transfer(
        address _to,
        uint256 _tokenId
    )
        external
    {
        require(_to != address(0));
        require(_to != address(this));
        require(_owns(msg.sender, _tokenId));
        _transfer(msg.sender, _to, _tokenId);
    }

    function approve(
        address _to,
        uint256 _tokenId
    )
        external
    {
        require(_owns(msg.sender, _tokenId));
        _approve(_tokenId, _to);
        Approval(msg.sender, _to, _tokenId);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        external
    {
        require(_to != address(0));
        require(_to != address(this));
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));
        _transfer(_from, _to, _tokenId);
    }

    function totalSupply() public view returns (uint) {
        return dragons.length;
    }

    function ownerOf(uint256 _tokenId)
        external
        view
        returns (address owner)
    {
        owner = dragonIndexToOwner[_tokenId];

        require(owner != address(0));
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalDragons = totalSupply();
            uint256 resultIndex = 0;
            uint256 dragonId;

            for (dragonId = 0; dragonId <= totalDragons; dragonId++) {
                if (dragonIndexToOwner[dragonId] == _owner) {
                    result[resultIndex] = dragonId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    function _memcpy(uint _dest, uint _src, uint _len) private view {
        // Copy word-length chunks while possible
        for(; _len >= 32; _len -= 32) {
            assembly {
                mstore(_dest, mload(_src))
            }
            _dest += 32;
            _src += 32;
        }

        // Copy remaining bytes
        uint256 mask = 256 ** (32 - _len) - 1;
        assembly {
            let srcpart := and(mload(_src), not(mask))
            let destpart := and(mload(_dest), mask)
            mstore(_dest, or(destpart, srcpart))
        }
    }

    function _toString(bytes32[4] _rawBytes, uint256 _stringLength) private view returns (string) {
        var outputString = new string(_stringLength);
        uint256 outputPtr;
        uint256 bytesPtr;

        assembly {
            outputPtr := add(outputString, 32)
            bytesPtr := _rawBytes
        }

        _memcpy(outputPtr, bytesPtr, _stringLength);

        return outputString;
    }

    function tokenMetadata(uint256 _tokenId, string _preferredTransport) external view returns (string infoUrl) {
        require(erc721Metadata != address(0));
        bytes32[4] memory buffer;
        uint256 count;
        (buffer, count) = erc721Metadata.getMetadata(_tokenId, _preferredTransport);

        return _toString(buffer, count);
    }
}

contract DragonCore is DragonOwnership {
    function getDragon(uint256 _id)
        external
        view
        returns (
          uint8 attack,
          uint8 defence,
          uint8 color,
          uint8 bodyType,
          uint8 eyesType,
          uint8 mouthType,
          uint8 hornsType,
          uint8 wingsType,
          uint16 health,
          uint16 price
    ) {
        Dragon storage d = dragons[_id];

        attack = d.attack;
        defence = d.defence;
        color = d.color;
        bodyType = d.bodyType;
        eyesType = d.eyesType;
        mouthType = d.mouthType;
        hornsType = d.hornsType;
        wingsType = d.wingsType;
        health = d.health;
        price = d.price;
    }

    function createDragon(
        uint8 _attack,
        uint8 _defence,
        uint8 _color,
        uint8 _bodyType,
        uint8 _eyesType,
        uint8 _mouthType,
        uint8 _hornsType,
        uint8 _wingsType,
        uint16 _health,
        uint16 _price,
        address _owner
      ) external onlyOwner returns (uint) {
        Dragon memory _dragon = Dragon({
          attack: _attack,
          defence: _defence,
          color: _color,
          bodyType: _bodyType,
          eyesType: _eyesType,
          mouthType: _mouthType,
          hornsType: _hornsType,
          wingsType: _wingsType,
          health: _health,
          price: _price
        });

        uint256 newDragonId = dragons.push(_dragon) - 1;

        require(newDragonId == uint256(uint32(newDragonId)));

        return newDragonId;
    }

    function buyDragon(uint256 _id) payable {
      Dragon storage d = dragons[_id];
      owner = dragonIndexToOwner[_id];

      require(owner == address(0));
      require(msg.value > d.price);

      Birth(msg.sender, _id);

      _transfer(0, msg.sender, _id);
    }

    function withdrawBalance() external onlyOwner {
        uint256 balance = this.balance;
        owner.transfer(balance);
    }
}

contract Random {
  uint64 _seed = 0;

  // return a pseudo random number between lower and upper bounds
  // given the number of previous blocks it should hash.
  function random(uint64 upper) public returns (uint64 randomNumber) {
    _seed = uint64(keccak256(keccak256(block.blockhash(block.number), _seed), now));

    return _seed % upper;
  }
}

contract DragonFight is DragonCore, Random {

    event Fight(uint256 _ownerDragonId,
                uint256 _opponentDragonId,
                bool firstAttack,
                bool secondAttack);

    function fight(uint256 _ownerDragonId, uint256 _opponentDragonId) external returns(
        bool firstAttack,
        bool secondAttack
      ) {
        require(_owns(msg.sender, _ownerDragonId));
        require(!_owns(msg.sender, _ownerDragonId));

        Dragon memory ownerDragon = dragons[_ownerDragonId];
        Dragon memory opponentDragon = dragons[_opponentDragonId];

        bool randomAttackResult = _randomAttack(ownerDragon.attack, opponentDragon.defence);
        bool randomAttack2Result = _randomAttack(ownerDragon.defence, opponentDragon.attack);

        Fight(_ownerDragonId, _opponentDragonId, randomAttackResult, randomAttack2Result);

        return (randomAttackResult, randomAttack2Result);
    }

    function _randomAttack(uint8 _ownerDragonAmount, uint8 _opponentDragonAmount) private
    returns(bool result) {
        uint64 ownerValue = random(uint64(_ownerDragonAmount));
        uint64 opponentValue = random(uint64(_opponentDragonAmount));

        return ownerValue > opponentValue;
    }
}

contract DragonTest is DragonFight {
    
    function createTestData() public onlyOwner {
        Dragon memory _dragon = Dragon({
          attack: 1,
          defence: 2,
          color: 3,
          bodyType: 4,
          eyesType: 5,
          mouthType: 6,
          hornsType: 7,
          wingsType: 8,
          health: 9,
          price: 1
        });

        uint256 newDragonId = dragons.push(_dragon) - 1;
        
        _transfer(0, msg.sender, newDragonId);
    }
}

