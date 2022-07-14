
const { expect, assert } = require("chai");
const { createApp } = require("./app");

contract('DAO', (accounts) => {
	var user = accounts[0];

	before(async () => {
		this.app = await createApp(user);
	});

	context("a", () => {

		before(async () => {
			// debugger
			// console.log();
		});

		it("aa", async () => {
			// debugger
		})
	});

});