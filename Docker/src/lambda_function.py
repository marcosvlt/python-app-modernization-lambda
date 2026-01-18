import json
import boto3
import os
from Docker.src.clean_data import clean_data

s3 = boto3.client("s3")

def lambda_handler(event, context):
    print(f"[DEBUG] Event received: {json.dumps(event)}")

    
    try:
        # S3 trigger sends events in Records array
        s3_record = event['Records'][0]['s3']
        bucket_input = s3_record['bucket']['name']
        csv_key = s3_record['object']['key']
        print(f"[DEBUG] Input bucket: {bucket_input}, CSV key: {csv_key}")
    except (KeyError, IndexError) as e:
        print(f"[ERROR] Failed to parse S3 event: {e}")
        return {"status": "error", "message": "Invalid S3 event structure"}


    bucket_output = os.environ["OUTPUT_BUCKET"]
    output_key = "resultado_fipe.json"
    print(f"[DEBUG] Output bucket: {bucket_output}, Output key: {output_key}")

    # Faz download do CSV
    tmp_csv = "/tmp/input.csv"
    print(f"[DEBUG] Downloading file from S3...")
    s3.download_file(bucket_input, csv_key, tmp_csv)
    print(f"[DEBUG] File downloaded successfully to {tmp_csv}")

    # Processa
    print(f"[DEBUG] Processing CSV file...")
    resultado = clean_data(tmp_csv)
    print(f"[DEBUG] Processing complete. Result keys: {list(resultado.keys())}")

    # Salva resultado JSON no S3
    print(f"[DEBUG] Uploading result to S3...")
    s3.put_object(
        Bucket=bucket_output,
        Key=output_key,
        Body=json.dumps(resultado, ensure_ascii=False, indent=2),
        ContentType="application/json"
    )
    print(f"[DEBUG] Upload complete")

    response = {"status": "ok", "output": f"s3://{bucket_output}/{output_key}"}
    print(f"[DEBUG] Response: {json.dumps(response)}")
    return response
