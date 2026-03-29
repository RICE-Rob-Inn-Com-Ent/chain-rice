//! Trusted setup — circuit-specific Groth16 parameter generation (`ProvingKey`, `VerifyingKey`).

use ark_crypto_primitives::snark::CircuitSpecificSetupSNARK;
use ark_ec::pairing::Pairing;
use ark_groth16::{Groth16, ProvingKey, VerifyingKey};
use ark_std::rand::{CryptoRng, RngCore};

use crate::circuit::MulCircuit;
use crate::error::SetupError;

// [ ] https://docs.rs/ark-groth16/ — ark-serialize
// [ ] trusted setup load RICE_ZK_TRUSTED_SETUP_PATH; pk/vk paths; ceremony hash RICE_ZK_CEREMONY_HASH; never prod-generate inline

/// Run Groth16 setup for the template [`MulCircuit`](crate::circuit::MulCircuit).
pub fn trusted_setup<E: Pairing, R: RngCore + CryptoRng>(
    rng: &mut R,
) -> Result<(ProvingKey<E>, VerifyingKey<E>), SetupError> {
    let (pk, vk) = Groth16::<E>::setup(MulCircuit::<E::ScalarField>::for_setup(), rng)?;
    Ok((pk, vk))
}
