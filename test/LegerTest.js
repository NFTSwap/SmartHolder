const { createAPP, help } = require("./app.js");
const { BN, balance, expectRevert } = require("@openzeppelin/test-helpers");

const ZERO_ADDRESS = "0x" + "0".repeat(40);
const { expect } = require("chai")

contract('Ledger', (accounts) => {

    var app;
    var user = accounts[0];
    before(async () => {
        app = await createAPP(accounts[1]);
    })

    it("balance is zero if account is empty", async () => {
        const balanceNow = await app.ledger.balanceOf(ZERO_ADDRESS);
        // expect(balance).to.be.bignumber.equal("0");
        assert.equal(balanceNow.valueOf(), 0);
    })

    context("Mint and Burn", () => {

        mintTest = async function (miner, amount) {
            const ledger = app.ledger;

            const beforeBalance = (await ledger.balanceOf(miner)).toNumber();
            const beofreTotal = (await ledger.totalSupply()).toNumber();

            await ledger.deposit({ from: miner, value: amount })
            assert.equal(
                (await ledger.balanceOf(miner)).toNumber(),
                beforeBalance + amount
            );
            assert.equal(
                (await ledger.totalSupply()).toNumber(),
                beofreTotal + amount
            );
        }

        burnTest = async function (user, amount) {
            const ledger = app.ledger;
            const ethers = await balance.current(user)
            const beforeBalance = (await ledger.balanceOf(user)).toNumber();
            const beofreTotal = (await ledger.totalSupply()).toNumber();

            var result = await ledger.withdraw(user, amount, { from: user })

            assert.equal(
                (await ledger.balanceOf(user)).toNumber(),
                beforeBalance - amount
            );
            assert.equal(
                (await ledger.totalSupply()).toNumber(),
                beofreTotal - amount
            );

            assert.equal(
                (await balance.current(user)).toString(),
                ethers.add(new BN(amount.toString())).sub(await help.getTxFee(result.tx)).toString(),
            )
        }

        it("should be mint ethers", async () => {
            await mintTest(accounts[0], 1);
            await mintTest(accounts[1], 0);
            await mintTest(accounts[2], 3);
            await mintTest(accounts[3], 5);
            await mintTest(accounts[3], 6);
        })

        it("burn give amount", async () => {
            var user = accounts[1];
            await app.ledger.deposit({ from: user, value: 1000 })
            await burnTest(user, 100);
            await burnTest(user, 10);
            await burnTest(user, 90);
        })
    })

    context("lock", () => {

        var subledger;
        before(async () => {
            const SubLedgerMock = artifacts.require("SubLedgerMock")
            subledger = await SubLedgerMock.new(app.ledger.address);

            var admin = await app.ledger.owner();
            await app.ledger.addNewSubLedger(subledger.address, { from: admin });

            // send ethers to subleager
            var goodman = accounts[2]
            await app.ledger.deposit({ from: goodman, value: 1e10 })
            await app.ledger.transfer(subledger.address, 1e10, { from: goodman })

        })

        it("should be show release balance", async () => {

            var user = accounts[4]

            var balance = await app.ledger.balanceOf(user)

            for (var i = 0; i < 3; i++) {
                var amount = new BN(i.toString())
                await subledger.setRelease(user, amount)
                expect(
                    await app.ledger.balanceOf(user)
                ).to.bignumber.equal(
                    balance.add(amount)
                )
            }
        })

        it("should be auto release when can be released", async () => {


            var amount = new BN("1111")
            await subledger.setRelease(user, amount)

            //transfer it
            var b = accounts[3]
            var b_balance = await app.ledger.balanceOf(b)
            var user_balance = await app.ledger.balanceOf(user)
            var subledger_balance = await app.ledger.balanceOf(subledger.address)

            var sends = new BN("1000");
            // send 1000 to `b`
            await app.ledger.transfer(b, sends, { from: user })

            // b.blance +=1000
            expect(
                await app.ledger.balanceOf(b)
            ).to.bignumber.equal(b_balance.add(sends))
            // user.balance -= 1000
            expect(
                await app.ledger.balanceOf(user)
            ).to.bignumber.equal(user_balance.sub(sends))

            //release 1111 from subleager to user
            expect(
                await app.ledger.balanceOf(subledger.address)
            ).to.bignumber.equal(
                subledger_balance.sub(amount)
            )
        })


        it("should be unlock when can be unlocked", async () => {

            // set unlock
            var user = accounts[4]

            console.log("v:", (await app.ledger.balanceOf(user)) / 1)
            for (var i = 1; i < 5; i++) {
                await subledger.lock(user, i, { from: accounts[2], value: i * 2 })
            }
            //set unlock
            var balance = await app.ledger.balanceOf(user)
            await subledger.setLockStatus(user, 1, false)
            await subledger.setLockStatus(user, 3, false)
            await subledger.setLockStatus(user, 4, false)
            let unlocked = new BN((1 * 2 + 3 * 2 + 4 * 2).toString())//16

            expect(
                await app.ledger.balanceOf(user)
            ).to.bignumber.equal(
                balance.add(unlocked),
                "expect balance+=unlocked"
            )
            // can transfer unlocked to other
            var user_balance = await app.ledger.balanceOf(user)
            var subledger_balance = await app.ledger.balanceOf(subledger.address)

            var sends = new BN("2");
            var b = accounts[3]
            var b_balance = await app.ledger.balanceOf(b)
            // send 2 to `b`
            await app.ledger.transfer(b, sends, { from: user })

            expect(
                await app.ledger.balanceOf(b)
            ).to.bignumber.equal(
                b_balance.add(sends), "expect b.balance +=2")

            expect(
                await app.ledger.balanceOf(user)
            ).to.bignumber.equal(
                user_balance.sub(sends), "expect user.blanace -=2")

            //  TODO: why?
            // expect(
            //     await app.ledger.balanceOf(subledger.address)
            // ).to.bignumber.equal(
            //     subledger_balance.sub(unlocked),
            //     "expect unlocked ethers from subledager"
            // )
        })

    })



});