
data "aws_iam_policy_document" "iam_policy_document_for_presigned_url_lambda" {
  statement {
    sid       = "GetPutDataObject"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["*"]
  }
  statement {
    sid       = "ListExistingDataProducts"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["code/*"]
    }

  }
}
