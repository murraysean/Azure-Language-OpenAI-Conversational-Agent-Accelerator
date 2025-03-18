// ========== main.bicep ========== //
targetScope = 'resourceGroup'

@description('GPT model deployment type.')
@allowed([
  'Standard'
  'GlobalStandard'
])
param gpt_deployment_type string = 'GlobalStandard'

@description('Name of GPT model to deploy.')
@allowed([
  'gpt-4o-mini'
  'gpt-4o'
  'gpt-4'
])
param gpt_model_name string = 'gpt-4o-mini'

@description('Capacity of GPT model deployment.')
param gpt_deployment_capacity int = 20

@description('Name of Embedding model to deploy.')
@allowed([
  'text-embedding-ada-002'
])
param embedding_model_name string = 'text-embedding-ada-002'

@description('Capacity of embedding model deployment.')
param embedding_deployment_capacity int = 20

var base_url = 'https://raw.githubusercontent.com/Azure-Samples/Azure-Language-OpenAI-Conversational-Agent-Accelerator/main/'
var clone_url = 'https://github.com/Azure-Samples/Azure-Language-OpenAI-Conversational-Agent-Accelerator.git'

// Deploy resources:
module container_registry 'resources/container_registry.bicep' = {
  name: 'deploy_container_registry'
}

module storage_account 'resources/storage_account.bicep' = {
  name: 'deploy_storage_account'
}

module openai_service 'resources/openai_service.bicep' = {
  name: 'deploy_openai_service'
  params: {
    gpt_model_name: gpt_model_name
    gpt_deployment_capacity: gpt_deployment_capacity
    embedding_model_name: embedding_model_name
    embedding_deployment_capacity: embedding_deployment_capacity
    gpt_deployment_type: gpt_deployment_type
  }
}

module search_service 'resources/search_service.bicep' = {
  name: 'deploy_search_service'
  params: {
    storage_account_name: storage_account.outputs.name
    openai_service_name: openai_service.outputs.name
  }
}

module language_service 'resources/language_service.bicep' = {
  name: 'deploy_language_service'
  params: {
    search_service_name: search_service.outputs.name
  }
}

module managed_identity 'resources/managed_identity.bicep' = {
  name: 'deploy_managed_identity'
  params: {
    container_registry_name: container_registry.outputs.name
    language_service_name: language_service.outputs.name
    openai_service_name: openai_service.outputs.name
    search_service_name: search_service.outputs.name
    storage_account_name: storage_account.outputs.name
  }
}

// Deploy scripts:
module language_setup 'scripts/language_setup_script.bicep' = {
  name: 'run_language_setup'
  params: {
    base_url: base_url
    language_endpoint: language_service.outputs.endpoint
    managed_identity_name: managed_identity.outputs.name
  }
}

module search_setup 'scripts/search_setup_script.bicep' = {
  name: 'run_search_setup'
  params: {
    base_url: base_url
    blob_container_name: storage_account.outputs.blob_container_name
    aoai_endpoint: openai_service.outputs.endpoint
    embedding_deployment_name: openai_service.outputs.embedding_deployment_name
    embedding_model_dimensions: openai_service.outputs.embedding_model_dimensions
    embedding_model_name: openai_service.outputs.embedding_model_name
    managed_identity_name: managed_identity.outputs.name
    search_endpoint: search_service.outputs.endpoint
    storage_account_connection_string: storage_account.outputs.connection_string
    storage_account_name: storage_account.outputs.name
  }
}

module registry_setup 'scripts/registry_setup_script.bicep' = {
  name: 'run_registry_setup'
  params: {
    acr_name: container_registry.outputs.name
    base_url: base_url
    clone_url: clone_url
    managed_identity_name: managed_identity.outputs.name
  }
}

// Deploy container app:
module container_app 'resources/container_app.bicep' = {
  name: 'deploy_container_app'
  params: {
    acr_name: container_registry.outputs.name
    aoai_deployment: openai_service.outputs.gpt_deployment_name
    aoai_endpoint: openai_service.outputs.endpoint
    clu_deployment_name: language_setup.outputs.clu_deployment_name
    clu_project_name: language_setup.outputs.clu_project_name
    cqa_deployment_name: language_setup.outputs.cqa_deployment_name
    cqa_project_name: language_setup.outputs.cqa_project_name
    image: registry_setup.outputs.image
    language_endpoint: language_service.outputs.endpoint
    managed_identity_name: managed_identity.outputs.name
    orchestration_deployment_name: language_setup.outputs.orchestration_deployment_name
    orchestration_project_name: language_setup.outputs.orchestration_project_name
    search_endpoint: search_service.outputs.endpoint
    search_index_name: search_setup.outputs.search_index_name
  }
}

output WEB_APP_URL string = container_app.outputs.fqdn
