use {{project-name | snake_case}} as blueprint;
use blueprint::{ExampleContext, SERVICE_MANAGER_ADDRESS};
use alloy::primitives::Address;
use blueprint_sdk::evm::producer::{PollingConfig, PollingProducer};
use blueprint_sdk::evm::util::get_provider_http;
use blueprint_sdk::runner::BlueprintRunner;
use blueprint_sdk::runner::config::BlueprintEnvironment;
use blueprint_sdk::runner::eigenlayer::ecdsa::EigenlayerECDSAConfig;
use blueprint_sdk::{Router, info};
use std::sync::Arc;
use std::time::Duration;

#[tokio::main]
async fn main() -> Result<(), blueprint_sdk::Error> {
    // Initialize logging
    let filter = tracing_subscriber::EnvFilter::new("info");
    let _ = tracing_subscriber::fmt()
        .with_env_filter(filter)
        .with_target(true)
        .try_init();

    // Load the blueprint environment from CLI args and environment variables
    let env = BlueprintEnvironment::load()?;

    // Create your service context
    // Here you can pass any configuration or context that your service needs.
    let context = ExampleContext {
        env: env.clone(),
    };

    // Get the provider for EVM interactions
    let provider = Arc::new(get_provider_http(env.http_rpc_endpoint.clone()));

    // Create a polling producer to listen for events on the service manager contract
    let producer = PollingProducer::new(
        provider.clone(),
        PollingConfig::default().poll_interval(Duration::from_secs(1)),
    )
    .await
    .map_err(|e| blueprint_sdk::Error::Other(e.to_string()))?;

    info!("Starting the event watcher for service manager at {}...", *SERVICE_MANAGER_ADDRESS);

    // Configure EigenLayer ECDSA operator
    // - delegation_approver: Address::ZERO for tests; use wallet address in production
    let delegation_approver_address = Address::ZERO;
    let eigen_config = EigenlayerECDSAConfig::new(delegation_approver_address);

    // Build and run the blueprint runner
    BlueprintRunner::builder(eigen_config, env)
        .router(
            Router::new()
                .always(blueprint::say_hello)
                .with_context(context),
        )
        .producer(producer)
        .with_shutdown_handler(async {
            blueprint_sdk::info!("Shutting down blueprint service");
        })
        .run()
        .await?;

    info!("Exiting...");
    Ok(())
}
