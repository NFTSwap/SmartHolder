//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <=0.8.15;

// Module type
bytes4 constant Module_Type = 0x6b27a068; // bytes4(keccak256('initDepartment(address,string,address)'))
bytes4 constant AssetShell_Type = 0x43234e95; // bytes4(keccak256('initAssetShell(address,string,address,string)'))
bytes4 constant Asset_Type = 0x68ca456f; // bytes4(keccak256('initAsset(address,string,address,string)'))
bytes4 constant DAO_Type = 0xc7b55336; // bytes4(keccak256('initDAO(string,address,address,address,address,address,address)'))
bytes4 constant Ledger_Type = 0xf4c38e51; // bytes4(keccak256('initLedger(address,string,address)'))
bytes4 constant Member_Type = 0x23fc76b9; // bytes4(keccak256('initMember(address,string,address)'))
bytes4 constant VotePool_Type = 0x0ddf27bf; // bytes4(keccak256('initVotePool(address,string)'))

// Module indexed id
uint256 constant Module_DAO_ID = 0;
uint256 constant Module_MEMBER_ID = 1;
uint256 constant Module_LEDGER_ID = 2;
uint256 constant Module_ASSET_ID = 3;
uint256 constant Module_OPENSEA_First_ID = 4;
uint256 constant Module_OPENSEA_Second_ID = 5;

// Departments Change tag
uint256 constant Change_Tag_Common = 0;
uint256 constant Change_Tag_Description = 1;
uint256 constant Change_Tag_Operator = 2;
uint256 constant Change_Tag_Upgrade = 3;
uint256 constant Change_Tag_DAO_Mission = 4;
uint256 constant Change_Tag_DAO_Module = 5;

// Action
uint256 constant Action_Member_Create = 0x22a25870; // bytes4(keccak256('create(address,string memory,Info memory,uint256[] memory)'))
uint256 constant Action_VotePool_Create = 0xdc6b0b72; // bytes4(keccak256('create(Proposal memory)'))
uint256 constant Action_VotePool_Vote = 0x678ea396;  // bytes4(keccak256('vote(uint256,uint256,int256,bool)'))
uint256 constant Action_Asset_SafeMint = 0x59baef2a; // bytes4(keccak256('safeMint(address,uint256,string memory,bytes calldata)'))
uint256 constant Action_DAO_Settings = 0xd0a4ad96; // bytes4(keccak256('DAO::settings()'))
uint256 constant Action_DAO_SetModule = 0x5d29163; // bytes4(keccak256('setModule(uint256,address)'))