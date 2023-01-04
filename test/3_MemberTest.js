
const { assert } = require('chai');
const App = require('./app');
const Member = artifacts.require('Member.sol');

contract('Member', ([from]) => {
	let app, member;
	before(async () =>{
		app = await App.create();
		member = await Member.at(await app.DAO.member());
	});

	context("Settings", () => {

		it('create()', async () => {
			await member.create(
				from,
				'https://upload.jianshu.io/users/upload_avatars/7936206/11941ca0-442d-4d7c-a300-a81f4206fd87.JPG?imageMogr2/auto-orient/strip|imageView2/1/w/120/h/120',
				{
					id: 1,
					name: 'Test 1',
					description: 'Test 1 Desc',
					avatar: 'https://upload.jianshu.io/users/upload_avatars/7936206/11941ca0-442d-4d7c-a300-a81f4206fd87.JPG?imageMogr2/auto-orient/strip|imageView2/1/w/120/h/120',
					votes: 3,
				}, [0xdc6b0b72, 0x678ea396]);
		});

		it('createFrom() 1', async () => {
			await member.createFrom(
				from,
				2,
				'https://avatars.githubusercontent.com/u/1221969?v=4',
				[0xdc6b0b72, 0x678ea396],
				1,
				'Test 2',
				'Test 2 Desc',
				'https://avatars.githubusercontent.com/u/1221969?v=4'
			);
		});

		it('createFrom() 2', async () => {
			await member.createFrom(
				from,
				3,
				'https://avatars.githubusercontent.com/u/1221969?v=4',
				[0xdc6b0b72, 0x678ea396],
				1,
				'Test 3',
				'Test 3 Desc',
				'https://avatars.githubusercontent.com/u/1221969?v=4'
			);
		});

		it('setMemberInfo()', async () => {
			await member.setMemberInfo(1, 'Test 1 Change', 'Test 1 Desc Change', '');
		});

		it('setExecutor()', async () => {
			await member.setExecutor(2);
		});

		it('addPermissions()', async () => {
			await member.addPermissions([2], [0x59baef2a,0xd0a4ad96]);
		});

		it('removePermissions()', async () => {
			await member.removePermissions([2], [0xd0a4ad96]);
		});

		it('addVotes()', async () => {
			await member.addVotes(2, 1); // votes 2
		});

		it('transferVotes()', async () => {
			// 1 votes = 2
			// 2 votes = 3
			await member.transferVotes(1, 2, 1);
		});

		it('remove()', async () => {
			await member.remove(3);
		});

	});

	context("Gettings", () => {

		it('votes() get total', async () => {
			// votes 1 + 2 + 3
			assert(await member.votes() == 6);
		});

		it('getMemberInfo()', async () => {
			let info = await member.getMemberInfo(1);
			assert(info.votes == 2, 'info.votes == 2');
			assert(info.name == 'Test 1 Change', 'info.name == Test 1 Change');
		});

		it('indexAt()', async () => {
			assert((await member.indexAt(1)).id == 1);
		});

		it('isApprovedOrOwner()', async () => {
			assert(await member.isApprovedOrOwner(from, 1));
		});

		it('total()', async () => {
			assert(await member.total() == 3);
		});

		it('executor()', async () => {
			assert(await member.executor() == 2);
		});

		it('isPermission()', async () => {
			assert(await member.isPermission(from, 0xdc6b0b72/*Action_VotePool_Create*/));
		});

		it('isPermissionFrom()', async () => {
			assert(!await member.isPermissionFrom(1, 0x22a25870/*Action_Member_Create*/));
		});

	});

});