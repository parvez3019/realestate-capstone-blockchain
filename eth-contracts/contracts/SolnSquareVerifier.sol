pragma solidity >=0.4.21 <0.6.0;

// define a contract call to the zokrates generated solidity contract <Verifier> or <renamedVerifier>
import "./ERC721Mintable.sol";
import "./verifier.sol";


// define another contract named SolnSquareVerifier that inherits from your ERC721Mintable class
contract SolnSquareVerifier is Verifier, GRToken {

    // define a solutions struct that can hold an index & an address
    struct Solution {
        bool added;
        bytes32 index;
        address user;
        uint256 tokenId;
    }

    // define an array of the above struct
    mapping(uint256 => Solution) solutions;

    // define a mapping to store unique solutions submitted
    mapping(bytes32 => bool) private existSolution;

    // Create an event to emit when a solution is added
    event SolutionAdded(bytes32 key, address user, uint256 tokenId);

    //  Create a function to add the solutions to the array and emit the event
    //  This will just limit the ability for a user to mint a token unless they have actually verified that they own that token
    function addSolution(address user, uint256 tokenId, uint[2] memory a, uint[2][2] memory b, uint[2] memory c, uint[2] memory input) public {
        // Create unique key for the arguments
        bytes32 key = generateKey(a, b, c, input);

        // Check whether the solution is already used
        require(!existSolution[key], "Solution already exists");

        // Verification to check if a token is valid using zokrates (verifier.sol)
        bool isValidProof = verifyTx(a, b, c, input);
        require(isValidProof, "Invalid proof");

        // Add solutions mappings and set existSolution to be true
        Solution memory solution = Solution({added : true, index : key, user : user, tokenId : tokenId});
        solutions[tokenId] = solution;
        existSolution[key] = true;
        emit SolutionAdded(key, user, tokenId);
    }

    function generateKey(uint[2] memory a, uint[2][2] memory b, uint[2] memory c, uint[2] memory inputs) view internal returns (bytes32) {
        return keccak256(abi.encodePacked(a, b, c, inputs));
    }

    //  - make sure the solution is unique (has not been used before)
    //  - make sure you handle metadata as well as tokenSupply
    function mint(address to, uint256 tokenId) public returns (bool){
        return super.mint(to, tokenId);
    }
}