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

    function initialize(address delegatee, address nounsToken_) external initializer {
        granola = msg.sender;
        nounsToken = nounsToken_;

        INounsToken(nounsToken_).setApprovalForAll(msg.sender, true);
        INounsToken(nounsToken_).delegate(delegatee);
    }

    function delegate(address delegatee) external {
        require(msg.sender == granola, "only granola");
        INounsToken(nounsToken).delegate(delegatee);
    }
}
