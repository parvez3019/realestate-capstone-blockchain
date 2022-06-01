pragma solidity ^0.5.0;

import 'openzeppelin-solidity/contracts/utils/Address.sol';
import 'openzeppelin-solidity/contracts/drafts/Counters.sol';
import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import 'openzeppelin-solidity/contracts/token/ERC721/IERC721Receiver.sol';
import "./Oraclize.sol";

contract Ownable {
    address private _ownerAddress;

    function owner() public view returns (address) {
        return _ownerAddress;
    }

    constructor() public {
        _ownerAddress = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == _ownerAddress, "you_are_not_authorized");
        _;
    }
    function transferOwnership(address newOwnerAddress) public onlyOwner {
        require(newOwnerAddress != address(0), "invalid_address");
        _ownerAddress = newOwnerAddress;
        emit TransferredOwnership(msg.sender, newOwnerAddress);
    }

    event TransferredOwnership(address indexed previousOwner, address indexed newOwnerAddress);
}

contract Pausable is Ownable {
    bool private _paused;

    function setPaused(bool state) public onlyOwner {
        require(_paused != state, "new_state_is_the_same_as_the_old_one");
        _paused = state;
        if (state) {
            emit Paused(msg.sender);
        } else {
            emit UnPaused(msg.sender);
        }
    }

    constructor() public {
        _paused = false;
    }
    modifier whenNotPaused() {
        require(!_paused, "currently_paused");
        _;
    }

    modifier paused() {
        require(_paused, "not_paused");
        _;
    }

    event Paused(address indexed account);
    event UnPaused(address indexed account);
}

contract ERC165 {
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
   
    mapping(bytes4 => bool) private _supportedInterfacesMap;

    constructor () internal {
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfacesMap[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff);
        _supportedInterfacesMap[interfaceId] = true;
    }
}

contract ERC721 is Pausable, ERC165 {

    event Transfer(address indexed from, address indexed toAddress, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed isApproved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool isApproved);

    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    mapping(uint256 => address) private _tokenOwnerMap;
    mapping(uint256 => address) private _tokenApprovalsMap;
    mapping(address => Counters.Counter) private _ownedTokensCountMap;
    mapping(address => mapping(address => bool)) private _operatorApprovalsMap;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    constructor () public {
        _registerInterface(_INTERFACE_ID_ERC721);
    }

    function balanceOf(address ownerAddr) public view returns (uint256) {
        return _ownedTokensCountMap[ownerAddr].current();
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        return _tokenOwnerMap[tokenId];
    }

    function approve(address toAddress, uint256 tokenId) public {
        require(toAddress != msg.sender, "you_can_transfer_your_token_to_yourself");
        require(this.ownerOf(tokenId) == msg.sender, "you_are_not_the_owner_of_this_token");
        _tokenApprovalsMap[tokenId] = toAddress;
        emit Approval(_tokenOwnerMap[tokenId], toAddress, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        return _tokenApprovalsMap[tokenId];
    }

    function setApprovalForAll(address toAddress, bool isApproved) public {
        require(toAddress != msg.sender);
        _operatorApprovalsMap[msg.sender][toAddress] = isApproved;
        emit ApprovalForAll(msg.sender, toAddress, isApproved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovalsMap[owner][operator];
    }

    function transferFrom(address from, address toAddress, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId));

        _transferFrom(from, toAddress, tokenId);
    }

    function safeTransferFrom(address from, address toAddress, uint256 tokenId) public {
        safeTransferFrom(from, toAddress, tokenId, "");
    }

    function safeTransferFrom(address from, address toAddress, uint256 tokenId, bytes memory _data) public {
        transferFrom(from, toAddress, tokenId);
        require(_checkOnERC721Received(from, toAddress, tokenId, _data));
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwnerMap[tokenId];
        return owner != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _mint(address toAddress, uint256 tokenId) internal {
        if (_exists(tokenId) || toAddress == address(0)) revert();
        _tokenOwnerMap[tokenId] = toAddress;
        _ownedTokensCountMap[toAddress].increment();
        emit Transfer(address(0), toAddress, tokenId);
    }

    function _transferFrom(address from, address toAddress, uint256 tokenId) internal {
        require(from == ownerOf(tokenId), "unauthorized");
        require(toAddress != address(0), "invalid_address");
        _clearApproval(tokenId);
        _ownedTokensCountMap[from].decrement();
        _ownedTokensCountMap[toAddress].increment();
        _tokenOwnerMap[tokenId] = toAddress;

        emit Transfer(from, toAddress, tokenId);
    }

    function _checkOnERC721Received(address from, address toAddress, uint256 tokenId, bytes memory _data)
    internal returns (bool) {
        if (!toAddress.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(toAddress).onERC721Received(msg.sender, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovalsMap[tokenId] != address(0)) {
            _tokenApprovalsMap[tokenId] = address(0);
        }
    }
}

contract ERC721Enumerable is ERC165, ERC721 {
    mapping(address => uint256[]) private _ownedTokensMap;
    mapping(uint256 => uint256) private _ownedTokensIndexMap;
    uint256[] private _allTokens;

    mapping(uint256 => uint256) private _allTokensIndexMap;

    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
    constructor () public {
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner));
        return _ownedTokensMap[owner][index];
    }

    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply());
        return _allTokens[index];
    }

    function _transferFrom(address from, address toAddress, uint256 tokenId) internal {
        super._transferFrom(from, toAddress, tokenId);

        _removeTokenFromOwnerEnumeration(from, tokenId);

        _addTokenToOwnerEnumeration(toAddress, tokenId);
    }

    function _mint(address toAddress, uint256 tokenId) internal {
        super._mint(toAddress, tokenId);

        _addTokenToOwnerEnumeration(toAddress, tokenId);

        _addTokenToAllTokensEnumeration(tokenId);
    }

    function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
        return _ownedTokensMap[owner];
    }

    function _addTokenToOwnerEnumeration(address toAddress, uint256 tokenId) private {
        _ownedTokensIndexMap[tokenId] = _ownedTokensMap[toAddress].length;
        _ownedTokensMap[toAddress].push(tokenId);
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndexMap[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        uint256 lastTokenIndex = _ownedTokensMap[from].length.sub(1);
        uint256 tokenIndex = _ownedTokensIndexMap[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokensMap[from][lastTokenIndex];

            _ownedTokensMap[from][tokenIndex] = lastTokenId;
            _ownedTokensIndexMap[lastTokenId] = tokenIndex;
        }

        _ownedTokensMap[from].length--;
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        uint256 lastTokenIndex = _allTokens.length.sub(1);
        uint256 tokenIndex = _allTokensIndexMap[tokenId];

        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId;
        _allTokensIndexMap[lastTokenId] = tokenIndex;

        _allTokens.length--;
        _allTokensIndexMap[tokenId] = 0;
    }
}

contract ERC721Metadata is ERC721Enumerable, usingOraclize {

    string private _name;
    string private _symbol;
    string private _baseTokenURI;

    mapping(uint256 => string) private _tokenURIs;

    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    constructor (string memory name, string memory symbol, string memory baseTokenURI) public {
        _name = name;
        _symbol = symbol;
        _baseTokenURI = baseTokenURI;

        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function baseTokenURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId));
        return _tokenURIs[tokenId];
    }


    function _setTokenURI(uint256 tokenId) internal {
        require(_exists(tokenId), "Token does not exist");
        _tokenURIs[tokenId] = strConcat(_baseTokenURI, uint2str(tokenId));
    }
}

contract GRToken is ERC721Metadata("Great Token", "GRT", "https://s3-us-west-2.amazonaws.com/udacity-blockchain/capstone/") {
    function mint(address toAddress, uint256 tokenId) public onlyOwner returns (bool) {
        _mint(toAddress, tokenId);
        _setTokenURI(tokenId);

        return true;
    }
}
