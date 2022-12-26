//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <=0.8.15;

/*
	* bytes4(keccak256('initDepartment(address,string,address)')) == 0x36c6362d
	*/
bytes4 constant Department_Type = 0x36c6362d;
/*
	* bytes4(keccak256('initAssetShell(address,string,address,string)')) == 0x711cc62c
	*/
bytes4 constant AssetShell_Type = 0x43234e95;
/*
	* bytes4(keccak256('initAsset(address,string,address,string)')) == 0xb6f00dcf
	*/
bytes4 constant Asset_Type = 0x68ca456f;
/*
	* bytes4(keccak256('initDAO(string,address,address,address,address,address,address)')) == 0xc7b55336
	*/
bytes4 constant DAO_Type = 0xc7b55336;
/*
	* bytes4(keccak256('initLedger(address,string,address)')) == 0xf4c38e51
	*/
bytes4 constant Ledger_Type = 0xf4c38e51;
/*
	* bytes4(keccak256('initMember(address,string,address)')) == 0x23fc76b9
	*/
bytes4 constant Member_Type = 0x23fc76b9;
/*
	* bytes4(keccak256('initVotePool(address,string)')) == 0x0ddf27bf
	*/
bytes4 constant VotePool_Type = 0x0ddf27bf;

// Departments indexed
uint256 constant Departments_DAO_ID = 0;
uint256 constant Departments_MEMBER_ID = 1;
uint256 constant Departments_LEDGER_ID = 2;
uint256 constant Departments_ASSET_ID = 3;
uint256 constant Departments_OPENSEA_First_ID = 4;
uint256 constant Departments_OPENSEA_Second_ID = 5;

// Departments Change tag
uint256 constant Change_Tag_Common = 0;
uint256 constant Change_Tag_Description = 1;
uint256 constant Change_Tag_Operator = 2;
uint256 constant Change_Tag_Upgrade = 3;
uint256 constant Change_Tag_DAO_Mission = 4;
uint256 constant Change_Tag_DAO_Department = 5;
