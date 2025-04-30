s3sql() {
    bucket=$1
    file=$2
    sql=$3
    aws s3api select-object-content \
        --bucket $bucket \
        --file $file \
        --expression $sql \
        --expression-type SQL
        --input-serialization '{"Parquet": {}}' \
        --output-serialization '{"JSON": {}}' \
        /dev/stdout
}