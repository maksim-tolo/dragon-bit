pragma solidity ^0.4.19;

contract Ownable {
  address public contractOwner;

  function Ownable() {
    contractOwner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == contractOwner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      contractOwner = newOwner;
    }
  }
}

contract Random {
  uint64 _seed = 0;

  // return a pseudo random number between lower and upper bounds
  // given the number of previous blocks it should hash.
  function random(uint64 upper, uint8 step) public returns (uint64 randomNumber) {
    _seed = uint64(keccak256(keccak256(block.blockhash(block.number - step), _seed), now));

    return _seed % upper;
  }
}

contract ERC721 {
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address tokenOwner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address tokenOwner, address approved, uint256 tokenId);

    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

contract DragonBase is Ownable, Random {
    event Birth(address tokenOwner, uint256 dragonId);
    event Transfer(address from, address to, uint256 tokenId);

    struct Skills {
      uint256 intelligence;
      uint256 strength;
      uint256 stamina;
      uint256 agility;
    }

    struct Appearance {
      string color;
      string wingsColor;
      uint8 bodyType;
      uint8 eyesType;
      uint8 mouthType;
      uint8 hornsType;
    }

    struct Stats {
      uint256 wins;
      uint256 losses;
    }

    struct Dragon {
      string name;

      Appearance appearance;
      Skills skills;
      Stats stats;

      uint256 health;
      uint256 price;
    }

    Dragon[] dragons;

    uint256 dragonsOnSaleCount = 0;

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

    function _initSkills(uint32 level) internal returns (Skills) {
      uint64 points = level * 2;
      uint8 index;
      uint64 skill;
      uint256 _intelligence = 1;
      uint256 _strength = 1;
      uint256 _stamina = 1;
      uint256 _agility = 1;

      for (index = 0; index < points && index < 256; index++) {
          skill = random(4, index + 1);

          if (skill == 0) {
            _intelligence++;
          } else if (skill == 1) {
            _strength++;
          } else if (skill == 2) {
            _stamina++;
          } else if (skill == 3) {
            _agility++;
          }
      }

      Skills memory _skils = Skills({
        intelligence: _intelligence,
        strength: _strength,
        stamina: _stamina,
        agility: _agility
      });

      return _skils;
    }

    function _getHealth(uint256 stamina) internal returns (uint256) {
       uint8 _baseHealth = 10;

       return stamina * 2 + _baseHealth;
    }

    function _getPrice(uint32 level) internal returns (uint256) {
       uint256 basePrice = 1000000000000000; // 0.001 eth

       return basePrice * level;
    }

    function _createDragon (
        uint32 _level,
        string _color,
        string _wingsColor,
        uint8 _bodyType,
        uint8 _eyesType,
        uint8 _mouthType,
        uint8 _hornsType
      ) internal returns (uint) {
        Skills memory _skills = _initSkills(_level);
        Stats memory _stats = Stats({
          wins: 0,
          losses: 0
        });
        Appearance memory _appearance = Appearance({
          color: _color,
          wingsColor: _wingsColor,
          bodyType: _bodyType,
          eyesType: _eyesType,
          mouthType: _mouthType,
          hornsType: _hornsType
        });

        uint256 _health = _getHealth(_skills.stamina);
        uint256 _price = _getPrice(_level);

        Dragon memory _dragon = Dragon({
          name: '',
          stats: _stats,
          skills: _skills,
          appearance: _appearance,
          health: _health,
          price: _price
        });

        uint256 newDragonId = dragons.push(_dragon) - 1;

        require(newDragonId == uint256(uint32(newDragonId)));

        dragonsOnSaleCount++;

        return newDragonId;
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
        returns (address tokenOwner)
    {
        tokenOwner = dragonIndexToOwner[_tokenId];

        require(tokenOwner != address(0));
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalDragons = totalSupply();
            uint256 resultIndex = 0;
            uint256 dragonId;

            for (dragonId = 0; dragonId < totalDragons; dragonId++) {
                if (_owns(_owner, dragonId)) {
                    result[resultIndex] = dragonId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    function tokensOnSale() external view returns(uint256[] availableTokens) {
        if (dragonsOnSaleCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](dragonsOnSaleCount);
            uint256 totalDragons = totalSupply();
            uint256 resultIndex = 0;
            uint256 dragonId;

            for (dragonId = 0; dragonId < totalDragons; dragonId++) {
                if (_owns(address(0), dragonId)) {
                    result[resultIndex] = dragonId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    function tokensForFight() external view returns(uint256[] availableTokens) {
        uint256 dragonsForFightCount = dragons.length - dragonsOnSaleCount - ownershipTokenCount[msg.sender];

        if (dragonsForFightCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](dragonsForFightCount);
            uint256 totalDragons = totalSupply();
            uint256 resultIndex = 0;
            uint256 dragonId;

            for (dragonId = 0; dragonId < totalDragons; dragonId++) {
                if (!_owns(address(0), dragonId) && !_owns(address(msg.sender), dragonId)) {
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
          string name,
          string color,
          string wingsColor,
          uint8 bodyType,
          uint8 eyesType,
          uint8 mouthType,
          uint8 hornsType,
          uint256 price,
          uint256 wins,
          uint256 losses,
          uint256 health
    ) {
        Dragon storage d = dragons[_id];

        return (
          d.name,
          d.appearance.color,
          d.appearance.wingsColor,
          d.appearance.bodyType,
          d.appearance.eyesType,
          d.appearance.mouthType,
          d.appearance.hornsType,
          d.price,
          d.stats.wins,
          d.stats.losses,
          d.health
        );
    }

    function getDragonSkills(uint256 _id)
        external
        view
        returns (
          uint256 intelligence,
          uint256 strength,
          uint256 stamina,
          uint256 agility
    ) {
        Dragon storage d = dragons[_id];

        return (
          d.skills.intelligence,
          d.skills.strength,
          d.skills.stamina,
          d.skills.agility
        );
    }

    function createDragon(
        uint32 _level,
        string _color,
        string _wingsColor,
        uint8 _bodyType,
        uint8 _eyesType,
        uint8 _mouthType,
        uint8 _hornsType
      ) external onlyOwner returns (uint) {
        return _createDragon(
          _level,
          _color,
          _wingsColor,
          _bodyType,
          _eyesType,
          _mouthType,
          _hornsType
        );
    }

    function buyDragon(uint256 _id, string name) payable {
      Dragon storage d = dragons[_id];
      address dragonOwner = dragonIndexToOwner[_id];

      require(dragonOwner == address(0));
      require(msg.value >= d.price);

      d.name = name;

      Birth(msg.sender, _id);

      dragonsOnSaleCount--;

      _transfer(0, msg.sender, _id);
    }

    function withdrawBalance() external onlyOwner {
        uint256 balance = this.balance;
        contractOwner.transfer(balance);
    }
}

contract DragonFight is DragonCore {

    event Fight(uint256 _winner, uint256 _loser);

    function fight(uint256 _ownerDragonId, uint256 _opponentDragonId) external returns(
        uint256 _winner
      ) {
        require(_owns(msg.sender, _ownerDragonId));
        require(!_owns(msg.sender, _opponentDragonId));
        require(!_owns(address(0), _opponentDragonId));

        Dragon memory ownerDragon = dragons[_ownerDragonId];
        Dragon memory opponentDragon = dragons[_opponentDragonId];

        uint256 hitNumber = 0;
        uint256 ownerAttack = 0;
        uint256 opponentAttack = 0;
        uint256 ownerHealth = ownerDragon.health;
        uint256 opponentHealth = opponentDragon.health;

        while (ownerHealth > opponentAttack && opponentHealth > ownerAttack) {
          opponentHealth -= ownerAttack;
          ownerHealth -= opponentAttack;

          ownerAttack = _randomAttack(
            ownerDragon.skills,
            opponentDragon.skills,
            uint8(hitNumber + 1)
          );

          hitNumber++;

          opponentAttack = _randomAttack(
            opponentDragon.skills,
            ownerDragon.skills,
            uint8(hitNumber + 1)
          );

          hitNumber++;
        }

        if (opponentHealth <= ownerAttack) {
          ownerDragon.stats.wins++;
          opponentDragon.stats.losses++;

          Fight(_ownerDragonId, _opponentDragonId);

          return _ownerDragonId;
        } else {
          ownerDragon.stats.losses++;
          opponentDragon.stats.wins++;

          Fight(_opponentDragonId, _ownerDragonId);

          return _opponentDragonId;
        }
    }

    function _randomAttack(Skills _attackingDragonSkills, Skills _defensibleDragonSkills, uint8 _step) private
    returns(uint256 damage) {
        uint64 range = 100;
        uint256 criticalHitChance = 5 + _attackingDragonSkills.intelligence;
        uint256 escapeHitChance = 5 + _defensibleDragonSkills.agility;
        uint256 attackPower = _attackingDragonSkills.strength;

        uint64 criticalHit = random(range, _step);
        uint64 escapeHit = random(range, _step + 1);

        if (escapeHit < escapeHitChance) {
          return 0;
        } else if (criticalHit < criticalHitChance) {
          return 2 * attackPower;
        } else {
          return attackPower;
        }
    }
}

contract DragonTest is DragonFight {
    function createTestData() public onlyOwner {
        uint newDragon1Id = _createDragon(1, '#F7CD41', '#0397D8', 1, 1, 1, 1);
        _transfer(0, msg.sender, newDragon1Id);
        dragons[newDragon1Id].name = 'Adam';
        dragonsOnSaleCount--;

        uint newDragon2Id = _createDragon(1, '#DE19A1', '#D82782', 1, 2, 2, 3);
        _transfer(0, msg.sender, newDragon2Id);
        dragons[newDragon2Id].name = 'Eva';
        dragonsOnSaleCount--;

        _createDragon(1, '#FF003C', '#88C100', 1, 3, 2, 2);
        _createDragon(1, '#AAFF00', '#AA00FF', 1, 2, 1, 3);
    }
}
