var ERC721MintableComplete = artifacts.require('GRToken');

contract('TestERC721Mintable', accounts => {
    const account1Address = accounts[0];
    const account2Address = accounts[1];
    const account3Address = accounts[2];
    const account4Address = accounts[3];

    describe('match erc721 spec', function () {
        beforeEach(async function () {
            this.contract = await ERC721MintableComplete.new({from: account1Address});

            await this.contract.mint(account1Address, 1, {from: account1Address});
            await this.contract.mint(account2Address, 2, {from: account1Address});
            await this.contract.mint(account3Address, 3, {from: account1Address});
            await this.contract.mint(account4Address, 4, {from: account1Address});
        });

        it('should return total supply', async function () {
            let totalSupply = await this.contract.totalSupply.call();
            
            assert.equal(totalSupply, 4, "incorrect_total_supply");
        });

        it('should get token balance', async function () {
            let actual_balance = await this.contract.balanceOf.call(account1Address);

            assert.equal(actual_balance.toNumber(), 1, "invalid_token_balance");
        });

        it('should return token uri', async function () {
            let tokenURI = await this.contract.tokenURI.call(1);

            assert.equal(
                tokenURI, "https://s3-us-west-2.amazonaws.com/udacity-blockchain/capstone/1",
                "invalid_token_uri"
            );
        });

        it('should transfer token from one owner to another', async function () {
            await this.contract.transferFrom(account1Address, account4Address, 1);
           
            let ownerAddr = await this.contract.ownerOf.call(1);
           
            assert.equal(ownerAddr, account4Address, "token_wasnt_transferred");
        });
    });

    describe('have ownership properties', function () {
        beforeEach(async function () {
            this.contract = await ERC721MintableComplete.new({from: account1Address});
        })

        it('should fail when minting when address is not contract owner', async function () {
            let isFailed = false;
            try {
                await this.contract.mint(account4Address, 5, {from: account2Address});
            } catch (e) {
                isFailed = true;
            }

            assert.equal(isFailed, true, "other_addresses_can_mint");
        });

        it('should return contract owner', async function () {
            let ownerAddr = await this.contract.owner.call({from: account1Address});

            assert.equal(ownerAddr, account1Address, "could_not_get_contract_owner");
        });

    });
})