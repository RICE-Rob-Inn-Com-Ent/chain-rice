// Package main provides a bridge token lock circuit for gnark
package main

import (
	"github.com/consensys/gnark/frontend"
	"github.com/consensys/gnark/std/hash/sha2"
)

type BridgeLockCircuit struct {
	TokenAddress frontend.Variable `gnark:",public"`
	Amount       frontend.Variable `gnark:",public"`
	Recipient    frontend.Variable `gnark:",public"`
	LockTxHash   frontend.Variable
	MerkleProof  []frontend.Variable
	MerkleRoot   frontend.Variable
}

func (c *BridgeLockCircuit) Define(api frontend.API) error {
	api.AssertIsDifferent(c.TokenAddress, 0)
	api.AssertIsDifferent(c.Amount, 0)
	api.AssertIsDifferent(c.Recipient, 0)
	api.AssertIsDifferent(c.LockTxHash, 0)
	maxAmount := frontend.Variable("115792089237316195423570985008687907853269984665640564039457584007913129639935")
	api.AssertIsLessOrEqual(c.Amount, maxAmount)
	return nil
}
