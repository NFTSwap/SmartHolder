//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// error Test();
// revert Test(type(uint8).max);

error InsufficientBalance(); // payable insufficient balance
error PayableInsufficientAmount(); // payable insufficient amount
error PayableAmountZero(); // aayable amount zero
error SendValueFail(); // send amount value fail
error PermissionDenied(); // permission denied
error PermissionDeniedForOnlyDAO(); // permission denied for only dao
error PermissionDeniedForMember(); // specific member no match
error CheckInterfaceNoMatch(bytes4 interfaceId);  // check interface or module no match
error AddressEmpty(); // address cannot be empty zero
error TokenIDEmpty(); // token Id cannot be empty zero
error PermissionDeniedInERC721(); // erc721 action permission denied
error TransferOfTokenIDThatIsNotOwnInERC721(); // transfer of token id that is not own in ERC721
error TokenIDNonExistentInERC721(); // nonexistent token id for ERC721
error TokenIDAlreadyMintedInERC721(); // token id already minted in ERC721
error ApprovalToOwnerInERC721(); // Cannot approve to owner
error ApproveAllToCallerInERC721(); // cannot approve all to caller or owner in ERC721
error NonERC721ReceiverImplementer(); // non ERC721 Receiver implementer
error OnlyOwnerAvailable(); // Only available to the owner
error NonContractAddress(); // non contract address
error AssetNonExistsInAssetShell(); // asset non exists
error NeedToUnlockAssetFirst(); // You need to unlock the asset first
error LockTokenIDEmptyInAssetShell(); // Lock cannot be empty in asset shell
error InsufficientVotesInMember(); // not votes power enough in member
error MemberNonExists(); // member non exists
error MemberAlreadyExists(); // member already exists
error MemberRequestJoinAlreadyExists(); // already exists member join request
error ProposalNonExistsInVotePool(); // proposal non exists
error ProposalAlreadyExistsInVotePool(); // proposal already exists
error ProposalDefaultLifespanLimitError(); // proposal lifespan not less than 12 hours
error CreateProposalVotePassEateLimitError(); // proposal vote pass rate not less than 50%
error CreateProposalLifespanLimitError(); // proposal lifespan not less than current setting lifespan days
error CreateProposalLoopTimeLimitError(); // Loop time must be greater than 1 minute
error VotesZero(); // votes cannot be zero
error ProposalClosed(); // proposal closed
error VotingMemberNoMatch();// Voting Membership Mismatch
error DuplicateVoteError(); // Cannot vote repeatedly
error VoteInsufficientVotes(); // vote insufficient votes
error VotingInProgress();
error ProposalNotPassed(); // Proposal was not passed

library Errors {}