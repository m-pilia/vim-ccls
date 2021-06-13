#!/usr/bin/env bash

set -xeuo pipefail

# Profiling file (no profiling if empty)
profile_file=
profile_prefix=''
if [ $# -gt 0 ] && [ "$1" == "--profile" ]; then
    profile_prefix='profile_file'
fi

docker_image=martinopilia/vim-ccls:1

echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin

if ! docker inspect --type=image "${docker_image}" >/dev/null 2>&1 ; then
    if ! docker pull "${docker_image}" ; then
        docker build -t "${docker_image}" .
        docker image push docker.io/${docker_image} || echo "Docker push failed"
    fi
fi

vim_binaries=$(docker run --rm "${docker_image}" ls /vim-build/bin \
             | grep -E '^(neo)?vim' )

set +e
exit_status=0

# Run tests
for vim in ${vim_binaries} ; do
    for test_suite in ./test/*.vader ; do
        test_name=$(basename "${test_suite}" | cut -d'.' -f1)

        # Collect profiling data if an output file name is provided
        if [ "${profile_prefix}" != '' ]; then
            profile_file="${profile_prefix}_${vim}_${test_name}"
        fi

        find test -name '*.swp' -delete

        docker run \
            --rm \
            -a stderr \
            -e VADER_OUTPUT_FILE=/dev/stderr \
            -e VIM_PROFILE_FILE="${profile_file}" \
            -v "$PWD:/testplugin" \
            -v "$PWD/test:/home"\
            -w /testplugin \
            "${docker_image}" \
                "/vim-build/bin/${vim}" -u test/vimrc "+Vader! ${test_suite}" 2>&1

        # shellcheck disable=SC2181
        if [ "$?" -ne 0 ]; then
            exit_status=1
        fi
    done
done

# Run vint
docker run \
    --rm \
    -a stdout \
    -v "$PWD:/testplugin" \
    -v "$PWD/test:/home"\
    -w /testplugin \
    "${docker_image}" \
        find . -type f -name '*.vim' -exec vint -s '{}' + 2>&1

# shellcheck disable=SC2181
if [ "$?" -ne 0 ]; then
    exit_status=1
fi

# Lint Dockerfile
docker run \
    --rm \
    -i \
    -v "$(pwd)":/mnt \
    -w /mnt \
    'hadolint/hadolint:v1.17.2' \
    hadolint Dockerfile

# shellcheck disable=SC2181
if [ "$?" -ne 0 ]; then
    exit_status=1
fi

# Validate Codecov configuration
curl --data-binary @.codecov.yml https://codecov.io/validate | tee codecov_validation
head -n 1 codecov_validation | grep 'Valid!'

# shellcheck disable=SC2181
if [ "$?" -ne 0 ]; then
    exit_status=1
fi

exit ${exit_status}
