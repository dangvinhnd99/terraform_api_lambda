
provider "aws" {
  region = "us-east-1"
}
# cap quyen truy cap vao S3 de read file
#tao IAM role va cho phep lambda su dung IAM role đó.
resource "aws_iam_role" "hello_lambda_exec" {
  name = "vinh-lambda"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}


# đính kèm role vào 1 loạt các policies ( ít nhất cần cái polocy: AWSLambdaBasicExecutionRole)
resource "aws_iam_role_policy_attachment" "hello_lambda_policy" {
  role       = aws_iam_role.hello_lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# tạo lambda function
resource "aws_lambda_function" "hello" {
  function_name = "hello"
  filename = "hello.zip"

// s3_bucket = aws_s3_bucket.lambda_bucket.id   // chỉ định bộ chứa nơi ta lưu trữ tất cả lambda 
  // s3_key    = aws_s3_object.lambda_hello.key   // key trỏ đến file zip có function

  runtime = "nodejs18.x"      //chọn runtime nodejs
  handler = "function.handler"  //file name function

  source_code_hash = data.archive_file.lambda_hello.output_base64sha256   // để triển khia lại chức năng nếu bạn thay đổi bất kì cái gì trong source code

  role = aws_iam_role.hello_lambda_exec.arn
}
# tạo cloudwatch để debug cho dễ. Nó sẽ lưu lại tất cả console.log và lỗi trong hàm. Thời gian lưu ở đây là 14 ngày
resource "aws_cloudwatch_log_group" "hello" {
  name = "/aws/lambda/${aws_lambda_function.hello.function_name}"

  retention_in_days = 1
}


//đóng gói file lambda dưới dạng zip (phát triển nội bộ thì dc, còn CICD thì nên xem xét lại)
data "archive_file" "lambda_hello" {
  type = "zip"

  source_dir  = "hello"
  output_path = "hello.zip"
}


#lấy file zip này và tải nó lên S3
# resource "aws_s3_object" "lambda_hello" {
#   bucket = aws_s3_bucket.lambda_bucket.id

#   key    = "hello.zip"
#   source = data.archive_file.lambda_hello.output_path

#   etag = filemd5(data.archive_file.lambda_hello.output_path)  // etag: kích hoạt cập nhật khi giá trị thay đổi, nếu file >16MB, nó sẽ ko chạy dc
# }