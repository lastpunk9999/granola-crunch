// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/**
 *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *
 */
import {INounsToken} from "src/interfaces/INounsToken.sol";
import {IGranolaJar} from "src/interfaces/IGranolaJar.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

contract GranolaDelegator {
    address public immutable nounsToken;
    address public immutable jarImplementation;
    mapping(uint256 tokenId => address owner) public ownerOf;

    constructor(address nounsToken_, address jarImplementation_) {
        nounsToken = nounsToken_;
        jarImplementation = jarImplementation_;
    }

    function depositAndDelegate(uint256[] calldata tokenIds, address delegatee) external {
        for (uint256 i; i < tokenIds.length; ++i) {
            address jar = getJar(tokenIds[i]);
            if (jar.code.length == 0) {
                Clones.cloneDeterministic(jarImplementation, salt(tokenIds[i]));
                IGranolaJar(jar).initialize(delegatee, nounsToken);
            } else {
                IGranolaJar(jar).delegate(delegatee);
            }
            ownerOf[tokenIds[i]] = msg.sender;
            INounsToken(nounsToken).transferFrom(msg.sender, jar, tokenIds[i]);
        }
    }

    function withdraw(uint256[] calldata tokenIds) external {
        for (uint256 i; i < tokenIds.length; ++i) {
            address jar = getJar(tokenIds[i]);
            require(ownerOf[tokenIds[i]] == msg.sender, "not owner");
            ownerOf[tokenIds[i]] = address(0);
            INounsToken(nounsToken).transferFrom(jar, msg.sender, tokenIds[i]);
        }
    }

    function delegate(uint256[] calldata tokenIds, address delegatee) external {
        for (uint256 i; i < tokenIds.length; ++i) {
            require(ownerOf[tokenIds[i]] == msg.sender, "not owner");
            address jar = Clones.predictDeterministicAddress(jarImplementation, salt(tokenIds[i]));
            IGranolaJar(jar).delegate(delegatee);
        }
    }

    function getJar(uint256 tokenId) public view returns (address) {
        return Clones.predictDeterministicAddress(jarImplementation, salt(tokenId));
    }

    function salt(uint256 tokenId) internal pure returns (bytes32) {
        return keccak256(abi.encode(tokenId));
    }
}
