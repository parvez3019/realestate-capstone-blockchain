var ERC721MintableComplete = artifacts.require('GRToken');

contract('TestERC721Mintable', accounts => {

    const account1 = accounts[0];
    const account2 = accounts[1];
    const account3 = accounts[2];
    const account4 = accounts[3];

    describe('match erc721 spec', function () {
        beforeEach(async function () {
            this.contract = await ERC721MintableComplete.new({from: account1});

            // mint multiple tokens
            await this.contract.mint(account1, 1, {from: account1});
            await this.contract.mint(account2, 2, {from: account1});
            await this.contract.mint(account3, 3, {from: account1});
            await this.contract.mint(account4, 4, {from: account1});
        });

        it('should return total supply', async function () {
            let totalSupply = await this.contract.totalSupply.call();
            assert.equal(totalSupply, 4, "Incorrect total supply");
        });

        it('should get token balance', async function () {
            let balance = await this.contract.balanceOf.call(account1);

            assert.equal(balance.toNumber(), 1, "Invalid token balance");
        });

        // token uri should be complete i.e: https://s3-us-west-2.amazonaws.com/udacity-blockchain/capstone/1
        it('should return token uri', async function () {
            let tokenURI = await this.contract.tokenURI.call(1);

            assert.equal(
                tokenURI, "https://s3-us-west-2.amazonaws.com/udacity-blockchain/capstone/1",
                "Invalid token URI"
            );
        });

        it('should transfer token from one owner to another', async function () {
            await this.contract.transferFrom(account1, account4, 1);
            let owner = await this.contract.ownerOf.call(1);
            assert.equal(owner, account4, "Token wasn't transferred");
        });
    });

    describe('have ownership properties', function () {
        beforeEach(async function () {
            this.contract = await ERC721MintableComplete.new({from: account1});
        })

        it('should fail when minting when address is not contract owner', async function () {
            let failed = false;
            try {
                await this.contract.mint(account4, 5, {from: account2});
            } catch (e) {
                failed = true;
            }

            assert.equal(failed, true, "Other addresses can mint");
        });

        it('should return contract owner', async function () {
            let owner = await this.contract.owner.call({from: account1});

            assert.equal(owner, account1, "Could not get contract owner");
        });

    });
})