use blueprint_sdk::alloy::primitives::{address, Address};
use blueprint_sdk::alloy::rpc::types::Log;
use blueprint_sdk::alloy::sol;
use blueprint_sdk::config::GadgetConfiguration;
use blueprint_sdk::event_listeners::evm::EvmContractEventListener;
use blueprint_sdk::job;
use blueprint_sdk::macros::load_abi;
use blueprint_sdk::std::convert::Infallible;
use blueprint_sdk::std::sync::LazyLock;
use serde::{Deserialize, Serialize};

type ProcessorError =
    blueprint_sdk::event_listeners::core::Error<blueprint_sdk::event_listeners::evm::error::Error>;

sol!(
    #[allow(missing_docs)]
    #[sol(rpc)]
    #[derive(Debug, Serialize, Deserialize)]
    TangleServiceManager,
    "contracts/out/TangleServiceManager.sol/TangleServiceManager.json"
);

load_abi!(
    TANGLE_SERVICE_MANAGER_ABI_STRING,
    "contracts/out/TangleServiceManager.sol/TangleServiceManager.json"
);

pub static SERVICE_MANAGER_ADDRESS: LazyLock<Address> = LazyLock::new(|| {
    std::env::var("SERVICE_MANAGER_ADDRESS")
        .map(|addr| addr.parse().expect("Invalid SERVICE_MANAGER_ADDRESS"))
        .unwrap_or_else(|_| address!("0000000000000000000000000000000000000000"))
});

#[derive(Clone)]
pub struct ExampleContext {
    pub config: GadgetConfiguration,
}

/// Returns "Hello, {who}!"
#[job(
    id = 0,
    params(who),
    event_listener(
        listener = EvmContractEventListener<TangleServiceManager::OperatorRegisteredToAVS>,
        instance = TangleServiceManager,
        abi = TANGLE_SERVICE_MANAGER_ABI_STRING,
        pre_processor = example_pre_processor,
    ),
)]
pub fn say_hello(context: ExampleContext, who: String) -> Result<String, Infallible> {
    Ok(format!("Hello, {who}!"))
}

/// Example pre-processor for handling inbound events
async fn example_pre_processor(
    (_event, log): (TangleServiceManager::OperatorRegisteredToAVS, Log),
) -> Result<Option<(String,)>, ProcessorError> {
    let who = log.address();
    Ok(Some((who.to_string(),)))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_works() {
        let config = GadgetConfiguration::default();
        let context = ExampleContext { config };
        let result = say_hello(context, "Alice".into()).unwrap();
        assert_eq!(result, "Hello, Alice!");
    }
}
