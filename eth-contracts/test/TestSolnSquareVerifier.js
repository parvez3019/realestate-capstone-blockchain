const SolnSquareVerifier = artifacts.require('SolnSquareVerifier');
const SquareVerifier = artifacts.require('Verifier');

contract('SolnSquareVerifier', accounts => {

    const account1Address = accounts[0];
    const account2Address = accounts[1];
    const zProof = require('./proof.json');

    beforeEach(async function () {
        this.verifier = await SquareVerifier.new({from: account1Address});
        this.contract = await SolnSquareVerifier.new(this.verifier.address, {from: account1Address});
    })

    it('Test if a new solution can be added for contract - SolnSquareVerifier', async function () {
        const {proof: {a, b, c}, inputs: inputs} = zProof;
        let isEventEmitted = false;
        this.contract.contract.once('SolutionAdded', {}, function () {
            isEventEmitted = true;
        });

        await this.contract.addSolution(account2Address, 1, a, b, c, inputs);
        assert.equal(isEventEmitted, true, 'no_event_emitted');
    });

    it('Test if an ERC721 token can be minted for contract - SolnSquareVerifier', async function () {
        const {proof: {a, b, c}, inputs: inputs} = zProof;
        await this.contract.addSolution(account2Address, 1, a, b, c, inputs);
        let supplyBeforeVal = await this.contract.totalSupply.call();

        await this.contract.mint(account2Address, 1, {from: account1Address});
        let supplyAfterVal = await this.contract.totalSupply.call();

        let differenceInSupplyVal = supplyAfterVal.toNumber() - supplyBeforeVal.toNumber();

        assert.equal(differenceInSupplyVal, 1, "Invalid supply left");

        let isFailed = false;
        try {
            await this.contract.addSolution(account2Address, 1, a, b, c, inputs);
        } catch (e) {
            isFailed = true;
        }

        assert.equal(isFailed, true, "reused_solution");
    })
})