resource "aws_iam_role" "bedrock_kb_sample_kb" {
  name = "AmazonBedrockExecutionRoleForKnowledgeBase_${var.kb_name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = local.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:${local.partition}:bedrock:${local.region}:${local.account_id}:knowledge-base/*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "bedrock_kb_sample_kb_model" {
  name = "AmazonBedrockFoundationModelPolicyForKnowledgeBase_${var.kb_name}"
  role = aws_iam_role.bedrock_kb_sample_kb.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "bedrock:InvokeModel"
        Effect   = "Allow"
        Resource = data.aws_bedrock_foundation_model.kb.model_arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "bedrock_kb_sample_kb_s3" {
  name = "AmazonBedrockS3PolicyForKnowledgeBase_${var.kb_name}"
  role = aws_iam_role.bedrock_kb_sample_kb.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "S3ListGetPutObjectStatement"
        Action   = ["s3:List*", "s3:Get*", "s3:PutObject"]
        Effect   = "Allow"
        Resource = ["${local.s3_bucket_arn}/*"]
        Condition = {
          StringEquals = {
            "aws:PrincipalAccount" = local.account_id
          }
      } },
      {
        Sid      = "KMSPermissions"
        Action   = ["kms:*"]
        Effect   = "Allow"
        Resource = ["*"]
      }
    ]
  })
}

#custom model policy
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["bedrock.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
  }
}

resource "aws_iam_role" "bedrock_custom_role" {
  name_prefix         = "BedrockCM-"
  description         = "Role for Bedrock Custom Models customization jobs"
  assume_role_policy  = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy" "bedrock_custom_oss_policy" {
  name = "AmazonBedrockOSSPolicyForKnowledgeBase_${var.kb_name}"
  role = aws_iam_role.bedrock_custom_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["aoss:*"]
        Effect   = "Allow"
        Resource = [aws_opensearchserverless_collection.sample_kb.arn]
      }
    ]
  })
}

resource "time_sleep" "iam_consistency_delay" {
  create_duration = "120s"
  depends_on      = [aws_iam_role_policy.bedrock_kb_sample_kb_model]
}

resource "aws_opensearchserverless_access_policy" "sample_kb" {
  name = var.kb_oss_collection_name
  type = "data"
  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "index"
          Resource = [
            "index/${var.kb_oss_collection_name}/*"
          ]
          Permission = [
            "aoss:CreateIndex",
            "aoss:DeleteIndex", # Required for Terraform
            "aoss:DescribeIndex",
            "aoss:ReadDocument",
            "aoss:UpdateIndex",
            "aoss:WriteDocument"
          ]
        },
        {
          ResourceType = "collection"
          Resource = [
            "collection/${var.kb_oss_collection_name}"
          ]
          Permission = [
            "aoss:CreateCollectionItems",
            "aoss:DescribeCollectionItems",
            "aoss:UpdateCollectionItems"
          ]
        }
      ],
      Principal = [
        aws_iam_role.bedrock_custom_role.arn,
        data.aws_caller_identity.this.arn  
      ]
    }
  ])
}

resource "aws_opensearchserverless_security_policy" "sample_kb_encryption" {
  name = var.kb_oss_collection_name
  type = "encryption"
  policy = jsonencode({
    Rules = [
      {
        Resource = [
          "collection/${var.kb_oss_collection_name}"
        ]
        ResourceType = "collection"
      }
    ],
    AWSOwnedKey = true
  })
}

resource "aws_opensearchserverless_security_policy" "sample_kb_network" {
  name = var.kb_oss_collection_name
  type = "network"
  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "collection"
          Resource = [
            "collection/${var.kb_oss_collection_name}"
          ]
        },
        {
          ResourceType = "dashboard"
          Resource = [
            "collection/${var.kb_oss_collection_name}"
          ]
        }
      ]
      AllowFromPublic = true
    }
  ])
}

resource "aws_opensearchserverless_collection" "sample_kb" {
  name = var.kb_oss_collection_name
  type = "VECTORSEARCH"
  depends_on = [
    aws_opensearchserverless_access_policy.sample_kb,
    aws_opensearchserverless_security_policy.sample_kb_encryption,
    aws_opensearchserverless_security_policy.sample_kb_network
  ]
}

provider "opensearch" {
  url         = aws_opensearchserverless_collection.sample_kb.collection_endpoint
  healthcheck = false
}

resource "time_sleep" "wait_before_index_creation" {
  depends_on      = [aws_opensearchserverless_collection.sample_kb]
  create_duration = "60s" # Wait for 60 seconds before creating the index
}

resource "opensearch_index" "sample_kb" {
  name                           = var.index_name
  number_of_shards               = "2"
  number_of_replicas             = "0"
  index_knn                      = true
  index_knn_algo_param_ef_search = "512"
  mappings                       = <<-EOF
    {
      "properties": {
        "bedrock-knowledge-base-default-vector": {
          "type": "knn_vector",
          "dimension": 1536,
          "method": {
            "name": "hnsw",
            "engine": "faiss",
            "parameters": {
              "m": 16,
              "ef_construction": 512
            },
            "space_type": "l2"
          }
        },
        "AMAZON_BEDROCK_METADATA": {
          "type": "text",
          "index": "false"
        },
        "AMAZON_BEDROCK_TEXT_CHUNK": {
          "type": "text",
          "index": "true"
        }
      }
    }
  EOF
  force_destroy                  = true
  depends_on                     = [time_sleep.wait_before_index_creation]
}

resource "aws_bedrockagent_knowledge_base" "sample_kb" {
  name     = var.kb_name
  role_arn = aws_iam_role.bedrock_custom_role.arn
  knowledge_base_configuration {
    vector_knowledge_base_configuration {
      embedding_model_arn = data.aws_bedrock_foundation_model.kb.model_arn
    }
    type = "VECTOR"
  }
  storage_configuration {
    type = "OPENSEARCH_SERVERLESS"
    opensearch_serverless_configuration {
      collection_arn    = aws_opensearchserverless_collection.sample_kb.arn
      vector_index_name = opensearch_index.sample_kb.name
      field_mapping {
        vector_field   = "bedrock-knowledge-base-default-vector"
        text_field     = "AMAZON_BEDROCK_TEXT_CHUNK"
        metadata_field = "AMAZON_BEDROCK_METADATA"
      }
    }
  }
  depends_on = [time_sleep.iam_consistency_delay, aws_iam_role_policy.bedrock_kb_sample_kb_model]
}

resource "aws_bedrockagent_data_source" "sample_kb" {
  knowledge_base_id = aws_bedrockagent_knowledge_base.sample_kb.id
  name              = "${var.kb_name}DataSource"
  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn = local.s3_bucket_arn
    }
  }
}