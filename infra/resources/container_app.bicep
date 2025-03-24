@description('Location for all resources.')
param location string = resourceGroup().location

@description('Name of managed identity to use for Container Apps.')
param managed_identity_name string

// Language:
param language_endpoint string
param clu_project_name string = 'conv-assistant-clu'
param clu_model_name string = 'clu-m1'
param clu_deployment_name string = 'clu-m1-d1'
param clu_confidence_threshold string = '0.5'
param cqa_project_name string = 'conv-assistant-cqa'
param cqa_deployment_name string = 'production'
param cqa_confidence_threshold string = '0.5'
param orchestration_project_name string = 'conv-assistant-orch'
param orchestration_model_name string = 'orch-m1'
param orchestration_deployment_name string = 'orch-m1-d1'
param orchestration_confidence_threshold string = '0.5'
param pii_enabled string = 'true'
param pii_categories string = 'organization,person'
param pii_confidence_threshold string = '0.5'

// Search/AOAI:
param aoai_endpoint string
param aoai_deployment string
param embedding_deployment_name string
param embedding_model_name string
param embedding_model_dimensions int
param storage_account_name string
param storage_account_connection_string string
param blob_container_name string
param search_endpoint string
param search_index_name string = 'conv-assistant-manuals-idx'

@allowed([
  'BYPASS'
  'CLU'
  'CQA'
  'ORCHESTRATION'
  'FUNCTION_CALLING'
])
param router_type string = 'ORCHESTRATION'
param image string = 'mcr.microsoft.com/azure-cli:cbl-mariner2.0'
param port int = 7000
param repo_clone_url string

resource managed_identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: managed_identity_name
}

resource app_environment 'Microsoft.App/managedEnvironments@2024-10-02-preview' = {
  name: 'cae-${uniqueString(resourceGroup().id)}'
  location: location
  properties: {
    
  }
}

resource container_app 'Microsoft.App/containerApps@2024-10-02-preview' = {
  name: 'ca-conv-agent-app'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managed_identity.id}' : {}
    }
  }
  properties: {
    configuration: {
      identitySettings: [
        {
          identity: managed_identity.id
          lifecycle: 'All'
        }
      ]
      ingress: {
        external: true
        targetPort: port
      }
    }
    managedEnvironmentId: app_environment.id
    template: {
      scale: {
        maxReplicas: 1
        minReplicas: 1
      }
      containers: [
        {
          image: image
          imageType: 'ContainerImage'
          name: 'conv-agent-app'
          resources: {
            cpu: 1
            memory: '2Gi'
          }
          command: [
            '/bin/bash'
            '-c'
            'tdnf install -y git && git clone ${repo_clone_url} --single-branch repo_src && bash repo_src/infra/scripts/run_container_app.sh'
          ]
          env: [
            {
              name: 'AOAI_ENDPOINT'
              value: aoai_endpoint
            }
            {
              name: 'AOAI_DEPLOYMENT'
              value: aoai_deployment
            }
            {
              name: 'SEARCH_ENDPOINT'
              value: search_endpoint
            }
            {
              name: 'SEARCH_INDEX_NAME'
              value: search_index_name
            }
            {
              name: 'EMBEDDING_DEPLOYMENT_NAME'
              value: embedding_deployment_name
            }
            {
              name: 'EMBEDDING_MODEL_NAME'
              value: embedding_model_name
            }
            {
              name: 'EMBEDDING_MODEL_DIMENSIONS'
              value: string(embedding_model_dimensions)
            }
            {
              name: 'STORAGE_ACCOUNT_NAME'
              value: storage_account_name
            }
            {
              name: 'STORAGE_ACCOUNT_CONNECTION_STRING'
              value: storage_account_connection_string
            }
            {
              name: 'BLOB_CONTAINER_NAME'
              value: blob_container_name
            }
            {
              name: 'LANGUAGE_ENDPOINT'
              value: language_endpoint
            }
            {
              name: 'CLU_PROJECT_NAME'
              value: clu_project_name
            }
            {
              name: 'CLU_MODEL_NAME'
              value: clu_model_name
            }
            {
              name: 'CLU_DEPLOYMENT_NAME'
              value: clu_deployment_name
            }
            {
              name: 'CLU_CONFIDENCE_THRESHOLD'
              value: clu_confidence_threshold
            }
            {
              name: 'CQA_PROJECT_NAME'
              value: cqa_project_name
            }
            {
              name: 'CQA_DEPLOYMENT_NAME'
              value: cqa_deployment_name
            }
            {
              name: 'CQA_CONFIDENCE_THRESHOLD'
              value: cqa_confidence_threshold
            }
            {
              name: 'ORCHESTRATION_PROJECT_NAME'
              value: orchestration_project_name
            }
            {
              name: 'ORCHESTRATION_MODEL_NAME'
              value: orchestration_model_name
            }
            {
              name: 'ORCHESTRATION_DEPLOYMENT_NAME'
              value: orchestration_deployment_name
            }
            {
              name: 'ORCHESTRATION_CONFIDENCE_THRESHOLD'
              value: orchestration_confidence_threshold
            }
            {
              name: 'PII_ENABLED'
              value: pii_enabled
            }
            {
              name: 'PII_CATEGORIES'
              value: pii_categories
            }
            {
              name: 'PII_CONFIDENCE_THRESHOLD'
              value: pii_confidence_threshold
            }
            {
              name: 'ROUTER_TYPE'
              value: router_type
            }
          ]
        }
      ]
    }
  }
}

output fqdn string = container_app.properties.configuration.ingress.fqdn
