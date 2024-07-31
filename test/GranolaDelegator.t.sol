// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {GranolaDelegator} from "src/GranolaDelegator.sol";
import {GranolaJar} from "src/GranolaJar.sol";
import {ERC721Votes} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Votes.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract ApprovedTransfersState is Test {
    GranolaDelegator granola;
    NounsMock nounsToken;
    uint256[] tokenIds;
    address nouner = makeAddr("nouner");
    address delegate1 = makeAddr("delegate1");
    address delegate2 = makeAddr("delegate2");

    function setUp() public virtual {
        nounsToken = new NounsMock();
        address jarImplementation = address(new GranolaJar());
        granola = new GranolaDelegator(address(nounsToken), jarImplementation);

        nounsToken.mint(nouner, 1);
        nounsToken.mint(nouner, 2);
        nounsToken.mint(nouner, 3);

        vm.prank(nouner);
        nounsToken.setApprovalForAll(address(granola), true);
    }
}

contract ApprovedTransfersStateTest is ApprovedTransfersState {
    function test_delegatesToTwoAddresses() public {
        vm.startPrank(nouner);

        tokenIds = [1, 2];
        granola.depositAndDelegate(tokenIds, delegate1);

        tokenIds = [3];
        granola.depositAndDelegate(tokenIds, delegate2);

        assertEq(nounsToken.getVotes(delegate1), 2);
        assertEq(nounsToken.getVotes(delegate2), 1);
    }
}

contract DepositedState is ApprovedTransfersState {
    function setUp() public override {
        super.setUp();
        vm.startPrank(nouner);

        tokenIds = [1, 2];
        granola.depositAndDelegate(tokenIds, delegate1);

        tokenIds = [3];
        granola.depositAndDelegate(tokenIds, delegate2);
    }
}

contract DepositedStateTest is DepositedState {
    function test_withdraw() public {
        vm.startPrank(nouner);
        tokenIds = [1, 3];
        granola.withdraw(tokenIds);

        assertEq(nounsToken.ownerOf(1), nouner);
        assertNotEq(nounsToken.ownerOf(2), nouner);
        assertEq(nounsToken.ownerOf(3), nouner);
    }

    function test_nonOwnerCantWithdraw() public {
        vm.startPrank(makeAddr("rando"));
        tokenIds = [1, 3];
        vm.expectRevert("not owner");
        granola.withdraw(tokenIds);
    }

    function test_changeDelegate() public {
        vm.startPrank(nouner);
        tokenIds = [3];
        granola.delegate(tokenIds, delegate1);

        assertEq(nounsToken.getVotes(delegate1), 3);
        assertEq(nounsToken.getVotes(delegate2), 0);
    }

    function test_nonOwnerCanDelegate() public {
        vm.startPrank(makeAddr("rando"));
        tokenIds = [3];
        vm.expectRevert("not owner");
        granola.delegate(tokenIds, delegate1);
    }

    function test_nonGranolaCantCallDelegateOnJar() public {
        vm.startPrank(makeAddr("rando"));
        address jar = granola.getJar(1);

        vm.expectRevert("only granola");
        GranolaJar(jar).delegate(address(5));
    }

    function test_nounsCanBeTransferredAndRedeposited() public {
        vm.startPrank(nouner);
        tokenIds = [1, 3];
        granola.withdraw(tokenIds);

        tokenIds = [1];
        nounsToken.setApprovalForAll(address(granola), true);
        granola.depositAndDelegate(tokenIds, delegate2);

        nounsToken.transferFrom(nouner, delegate1, 3);

        vm.startPrank(delegate1);
        tokenIds = [3];
        nounsToken.setApprovalForAll(address(granola), true);
        granola.depositAndDelegate(tokenIds, delegate2);
    }
}

contract NounsMock is ERC721Votes {
    constructor() ERC721("nouns mock", "NOUNSMOCK") EIP712("nouns mock", "1") {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }
}
