## set env vars

export GOOGLE_CLOUD_PROJECT=foo-bar #change-me

export MIG_NAME=discriminat-foo #change-me
export MIG_EXPECTED_SIZE=3 #change-me
export MIG_REGION=europe-west6 #change-me

## env vars done

# this script exists because of the following outstanding issues on gcp, where maxUnavailable cannot be set to 1
# https://issuetracker.google.com/issues/201753226
# https://issuetracker.google.com/issues/243973366

## script follows

CURRENT_SIZE=$(gcloud --format json compute instance-groups managed describe --region $MIG_REGION $MIG_NAME | jq .targetSize)

if [ $CURRENT_SIZE -ne $MIG_EXPECTED_SIZE ]; then
  echo -e "\nCURRENT SIZE $CURRENT_SIZE does not match MIG EXPECTED SIZE $MIG_EXPECTED_SIZE\n\nexiting\n" 1>&2
  kill -INT $$
fi

echo "EXPECTED and CURRENT SIZE: $MIG_EXPECTED_SIZE"

echo -e "\nPROGRESS 0/$MIG_EXPECTED_SIZE\n"
gcloud compute instance-groups managed wait-until $MIG_NAME --stable --region $MIG_REGION

for i in $(seq 1 $MIG_EXPECTED_SIZE); do
  gcloud compute instance-groups managed resize $MIG_NAME --size $(($MIG_EXPECTED_SIZE - 1)) --region $MIG_REGION 1> /dev/null
  echo -e "\nPROGRESS $(($i-1)).25/$MIG_EXPECTED_SIZE\n"
  gcloud compute instance-groups managed wait-until $MIG_NAME --stable --region $MIG_REGION
  echo -e "\nPROGRESS $(($i-1)).5/$MIG_EXPECTED_SIZE\n"
  gcloud compute instance-groups managed resize $MIG_NAME --size $MIG_EXPECTED_SIZE --region $MIG_REGION 1> /dev/null
  echo -e "\nPROGRESS $(($i-1)).75/$MIG_EXPECTED_SIZE\n"
  gcloud compute instance-groups managed wait-until $MIG_NAME --stable --region $MIG_REGION
  echo -e "\nPROGRESS $i/$MIG_EXPECTED_SIZE\n"
done

echo "FINAL SIZE: $(gcloud --format json compute instance-groups managed describe --region $MIG_REGION $MIG_NAME | jq .targetSize)"

## script done
