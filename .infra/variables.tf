variable "kb_oss_collection_name" {
  type        = string
  description = "The name of the collection for the Knowledge Base Open Source Software (OSS) content."
}

variable "index_name" {
  type        = string
  description = "The name of the OpenSearch index"
}

variable "kb_model_id" {
  description = "The ID of the foundational model used by the knowledge base."
  type        = string
  default     = "amazon.titan-embed-text-v1"
}

variable "kb_name" {
  description = "The name of the knowledge base."
  type        = string
  default     = "sample"
}

variable "s3_bucket_name" {
  description = "The name of the S3 bucket where the knowledge base data is stored."
  type        = string
}
