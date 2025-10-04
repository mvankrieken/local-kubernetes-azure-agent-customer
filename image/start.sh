#!/bin/bash
set -e

# Check manatory variables
if [ -z "${VSTS_AGENT_INPUT_URL}" ]; then
  echo 1>&2 "error: missing VSTS_AGENT_INPUT_URL environment variable"
  exit 1
fi

if [ -z "${VSTS_AGENT_INPUT_TOKEN}" ]; then
  echo 1>&2 "error: missing VSTS_AGENT_INPUT_TOKEN environment variable"
  exit 1
fi

if [ -z "${VSTS_AGENT_INPUT_POOL}" ]; then
  echo 1>&2 "error: missing VSTS_AGENT_INPUT_POOL environment variable"
  exit 1
fi

# Make dir if needed
if [ -n "${VSTS_AGENT_INPUT_WORK}" ]; then
  mkdir -p "${VSTS_AGENT_INPUT_WORK}"
fi

cleanup() {
  trap "" EXIT

  if [ -e ./config.sh ]; then
    print_header "Cleanup. Removing Azure Pipelines agent..."

    # If the agent has some running jobs, the configuration removal process will fail.
    # So, give it some time to finish the job.
    while true; do
      ./config.sh remove --unattended --auth "PAT" && break

      echo "Retrying in 30 seconds..."
      sleep 30
    done
  fi
}

print_header() {
  lightcyan="\033[1;36m"
  nocolor="\033[0m"
  echo -e "\n${lightcyan}$1${nocolor}\n"
}

# Let the agent ignore the token env variables
export VSO_AGENT_IGNORE="VSTS_AGENT_INPUT_TOKEN,PATH"

print_header "1. Determining matching Azure Pipelines agent..."

AZP_AGENT_PACKAGES=$(curl -LsS \
    -u "user:${VSTS_AGENT_INPUT_TOKEN}" \
    -H "Accept:application/json;" \
    "${VSTS_AGENT_INPUT_URL}/_apis/distributedtask/packages/agent?platform=${TARGETARCH}&top=1")

AZP_AGENT_PACKAGE_LATEST_URL=$(echo "${AZP_AGENT_PACKAGES}" | jq -r ".value[0].downloadUrl")

if [ -z "${AZP_AGENT_PACKAGE_LATEST_URL}" -o "${AZP_AGENT_PACKAGE_LATEST_URL}" == "null" ]; then
  echo 1>&2 "error: could not determine a matching Azure Pipelines agent"
  echo 1>&2 "check that account "${VSTS_AGENT_INPUT_URL}" is correct and the token is valid for that account"
  exit 1
fi

print_header "2. Downloading and extracting Azure Pipelines agent from ${AZP_AGENT_PACKAGE_LATEST_URL}..."

curl -LsS "${AZP_AGENT_PACKAGE_LATEST_URL}" | tar -xz & wait $!

source ./env.sh

print_header "3. Configuring Azure Pipelines agent..."
./config.sh --unattended \
  --agent "${VSTS_AGENT_INPUT_AGENT:-$(hostname)}" \
  --auth "PAT" \
  --replace \
  --acceptTeeEula & wait $!

print_header "4. Running Azure Pipelines agent..."
chmod +x ./run.sh

# To be aware of TERM and INT signals call ./run.sh
# Running it with the --once flag at the end will shut down the agent after the build is executed
pid=
trap 'cleanup; [[ $pid ]] && kill $pid; exit' EXIT
./run.sh "$@" & pid=$!
wait
pid=