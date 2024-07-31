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
import {IGranolaJar} from "src/interfaces/IGranolaJar.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {INounsToken} from "src/interfaces/INounsToken.sol";

contract GranolaJar is IGranolaJar, Initializable {
    address public nounsToken;
    address public granola;

    function initialize(address nounsToken_) external initializer {
        granola = msg.sender;
        nounsToken = nounsToken_;

        INounsToken(nounsToken_).setApprovalForAll(msg.sender, true);
    }

    function delegate(address delegatee) external {
        require(msg.sender == granola, "only granola");
        _delegate(delegatee);
    }

    function _delegate (address delegatee) internal {
        INounsToken(nounsToken).delegate(delegatee);
    }
}
