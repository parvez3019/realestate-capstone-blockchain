pragma solidity >=0.4.21 <0.6.0;

import "./ERC721Mintable.sol";
import "./verifier.sol";

contract SolnSquareVerifier is Verifier, GRToken {
    struct Solution {
        bool isAdded;
        bytes32 index;
        address userAddr;
        uint256 token_id;
    }

    mapping(uint256 => Solution) solutionsMap;
    mapping(bytes32 => bool) private existSolutionMap;
    
    event SolutionAdded(bytes32 key, address userAddr, uint256 token_id);

    function addSolution(
        address userAddr,
        uint256 token_id,
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[2] memory input
    ) public {
        bytes32 generatedKey = generateKey(a, b, c, input);
        require(!existSolutionMap[generatedKey], "solution_already_exists");
        bool isProofValid = verifyTx(a, b, c, input);
        require(isProofValid, "invalid_proof");

        Solution memory solutionObj = Solution({
            isAdded: true,
            index: generatedKey,
            userAddr: userAddr,
            token_id: token_id
        });

        solutionsMap[token_id] = solutionObj;
        existSolutionMap[generatedKey] = true;
        emit SolutionAdded(generatedKey, userAddr, token_id);
    }

    function generateKey(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[2] memory inputs
    ) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(a, b, c, inputs));
    }

    function mint(address to, uint256 token_id) public returns (bool) {
        return super.mint(to, token_id);
    }
}
