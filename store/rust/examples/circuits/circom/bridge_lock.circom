pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/comparators.circom";
include "../node_modules/circomlib/circuits/poseidon.circom";

template BridgeLock() {
    signal input tokenAddress;
    signal input amount;
    signal input recipient;
    signal input lockTxHash;
    signal input merkleRoot;
    signal input merklePathElements[32];
    signal input merklePathIndices[32];
    signal output isValid;

    component tokenCheck = IsZero();
    tokenCheck.in <== tokenAddress;
    tokenCheck.out === 0;

    component amountCheck = IsZero();
    amountCheck.in <== amount;
    amountCheck.out === 0;

    component recipientCheck = IsZero();
    recipientCheck.in <== recipient;
    recipientCheck.out === 0;

    isValid <== 1;
}

component main = BridgeLock();
