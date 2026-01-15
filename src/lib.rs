use alloy::primitives::{address, Address};
use alloy::sol;
use blueprint_sdk::runner::config::BlueprintEnvironment;
use blueprint_sdk::macros::context::KeystoreContext;
use blueprint_sdk::evm::extract::BlockEvents;
use blueprint_sdk::extract::Context;
use serde::{Deserialize, Serialize};
use std::sync::LazyLock;

sol!(
    #[allow(missing_docs)]
    #[sol(rpc)]
    #[derive(Debug, Serialize, Deserialize)]
    TangleServiceManager,
    "contracts/out/TangleServiceManager.sol/TangleServiceManager.json"
);

pub static SERVICE_MANAGER_ADDRESS: LazyLock<Address> = LazyLock::new(|| {
    std::env::var("SERVICE_MANAGER_ADDRESS")
        .map(|addr| addr.parse().expect("Invalid SERVICE_MANAGER_ADDRESS"))
        .unwrap_or_else(|_| address!("0000000000000000000000000000000000000000"))
});

/// The context for the blueprint, containing configuration and any shared state.
#[derive(Clone, KeystoreContext)]
pub struct ExampleContext {
    #[config]
    pub env: BlueprintEnvironment,
}

/// Returns "Hello, {who}!"
///
/// This job is triggered by `OperatorRegisteredToAVS` events from the TangleServiceManager contract.
/// It extracts the operator address from the event and returns a greeting.
#[blueprint_sdk::macros::debug_job]
pub async fn say_hello(
    Context(_ctx): Context<ExampleContext>,
    BlockEvents(events): BlockEvents,
) -> Result<(), std::convert::Infallible> {
    use alloy::sol_types::SolEvent;

    // Filter for OperatorRegisteredToAVS events
    let registration_events = events.iter().filter_map(|log| {
        TangleServiceManager::OperatorRegisteredToAVS::decode_log(&log.inner)
            .map(|event| event.data)
            .ok()
    });

    for event in registration_events {
        let who = event.operator;
        blueprint_sdk::info!("Hello, {}!", who);
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn context_can_be_created() {
        let env = BlueprintEnvironment::default();
        let _context = ExampleContext { env };
    }
}
