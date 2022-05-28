// define a variable to import the <Verifier> or <renamedVerifier> solidity contract generated by Zokrates
var SquareVerifier = artifacts.require('Verifier');

contract('SquareVerifier', accounts => {
    const account1 = accounts[0];
    // - use the contents from proof.json generated from zokrates steps
    const proof = require("./proof.json");

    beforeEach(async function () {
        this.contract = await SquareVerifier.new({from: account1});
    });

    // Test verification with correct proof
    it('Test verification with correct proof', async function () {

        const {proof: {a, b, c}, inputs: inputs} = proof;

        let result = await this.contract.verifyTx.call(a, b, c, inputs);
        assert.equal(result, true, "Proof incorrect");
    });

    // Test verification with incorrect proof
    it('Test verification with incorrect proof', async function () {
        const {proof: {a, b, c}} = proof;

        let result = await this.contract.verifyTx.call(a, b, c, [0, 0]);
        assert.equal(result, false, "Proof should not be correct");
    });
})