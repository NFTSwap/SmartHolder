//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

// error Test();
// revert Test(type(uint8).max);

error InsufficientBalance(); // 0xf4d678b8 payable insufficient balance
error PayableInsufficientAmount(); // 0x5bdb36f8 payable insufficient amount
error PayableAmountZero(); // 0x41a5bd5c payable amount zero
error SendValueFail(); // 0x9993a422 send amount value fail
error PermissionDenied(); // 0x1e092104 permission denied
error PermissionDeniedForOnlyDAO(); // 0xda002518 permission denied for only dao
error PermissionDeniedForMember(); // 0x7832bbc1 specific member no match
error CheckInterfaceNoMatch(bytes4 interfaceId);  // 0x2aae78ef check interface or module no match
error AddressEmpty(); // 0x5bb7a723 address cannot be empty zero
error TokenIDEmpty(); // 0x94e69af8 token Id cannot be empty zero
error PermissionDeniedInERC721(); // 0xd3a32745 erc721 action permission denied
error TransferOfTokenIDThatIsNotOwnInERC721(); // 0x11307032 transfer of token id that is not own in ERC721
error TokenIDNonExistentInERC721(); // 0x5449cd45 nonexistent token id for ERC721
error TokenIDAlreadyMintedInERC721(); // 0x082c3a4f token id already minted in ERC721
error ApprovalToOwnerInERC721(); // 0x65f090f7 Cannot approve to owner
error ApproveAllToCallerInERC721(); // 0x19095a8c cannot approve all to caller or owner in ERC721
error NonERC721ReceiverImplementer(); // 0x85d5821e non ERC721 Receiver implementer
error OnlyOwnerAvailable(); // 0x399c7579 Only available to the owner
error NonContractAddress(); // 0x4aa4cf51 non contract address
error AssetNonExistsInAssetShell(); // 0x54ac7492 asset non exists
error NeedToUnlockAssetFirst(); // 0xf31df50e You need to unlock the asset first
error LockTokenIDEmptyInAssetShell(); // 0x21c67f49 Lock cannot be empty in asset shell
error LockTokenIDPreviousOwnerEmptyInAssetShell(); // 0x21c67f49 Lock previous owner cannot be empty in asset shell
error InsufficientVotesInMember(); // 0x252f4a32 not votes power enough in member
error MemberNonExists(); // 0x7f5c5df9 member non exists
error MemberAlreadyExists(); // 0xe0150952 member already exists
error MemberRequestJoinAlreadyExists(); // 0xa1ee8585 already exists member join request
error ProposalNonExistsInVotePool(); // 0xf0f63e9e proposal non exists
error ProposalAlreadyExistsInVotePool(); // 0xec297468 proposal already exists
error ProposalDefaultLifespanLimitError(); // 0x420e832e proposal lifespan not less than 12 hours
error CreateProposalVotePassEateLimitError(); // 0xeda2bb99 proposal vote pass rate not less than 50%
error CreateProposalLifespanLimitError(); // 0xc0c4b93d proposal lifespan not less than current setting lifespan days
error CreateProposalLoopTimeLimitError(); // 0x0d67e9dd Loop time must be greater than 1 minute
error VotesZero(); // 0xdd3b8d8f votes cannot be zero
error ProposalClosed(); // 0x1446e503 proposal closed
error VotingMemberNoMatch(); // 0x22dd3c54 Voting Membership Mismatch
error DuplicateVoteError(); // 0x29a56ece Cannot vote repeatedly
error VoteInsufficientVotes(); // 0xaccf9793 vote insufficient votes
error VotingInProgress(); // 0x1182db35 voting in progress
error ProposalNotPassed(); // 0xc8c93ba3 Proposal was not passed
error MethodNotImplemented(); // 0x29749743 method not implemented
error MaximumSupplyLimitInShare(); // 0x9b4cee83 Exceeding the maximum supply limit
error TokenIDMustEvenNumberInAsset(); // 0x5a708f03 token id must be an even number
error NoPermissionToMintNFTs1155(); // 0x292c3a85 No permission to mint NFTs
error TokenIDAlreadyExistsInAsset(); // 0x8791d6ee token id already exists
error AmountMinimumLimit(); // 0xf76273e9 amount minimum limit

library Errors {}