#!/usr/bin/env bash

# template: https://sharats.me/posts/shell-script-best-practices/

set -o errexit
set -o nounset
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then
    set -o xtrace
fi

if [[ "${1-}" =~ ^-*h(elp)?$ ]]; then
    echo "Usage: ./$(basename "$0")"
    exit
fi

cd "$(dirname "$0")"

print_step_message() {
    echo "*************** $1 ..."
}

print_done() {
    echo "*************** Done"
}

main() {
    # TODO: variables should be passed from the caller
    TERRAFORM_CONTAINER_NAME="terraform_for_localstack_test"
    LOCALSTACK_CONTAINER_NAME="localstackmaintest"
    LOCALSTACK_PORT=4567

    TEMPDIR=$(mktemp -d)
    echo "Created tempdir: $TEMPDIR"
    trap 'rm -rf $TEMPDIR' ERR
    # copy files inside terraform
    # create tar to preserve the tree structure
    print_step_message "Copying tf files on terraform"
    # ./**/*.tf does not match with root level tf files (for some reason)
    (cd ../src/main/resources/terraform && tar -czf "$TEMPDIR/tf_tree.tar.gz" $(find . -path './**.tf'))
    docker cp "$TEMPDIR/tf_tree.tar.gz" "$TERRAFORM_CONTAINER_NAME:/app/tf_tree.tar.gz"

    docker exec "$TERRAFORM_CONTAINER_NAME" sh -c "tar -xzf tf_tree.tar.gz && rm tf_tree.tar.gz"
    print_done

    # I don't need to copy the zip distribution in the terraform and localstack
    # containers because lambda hot-reloading is enabled

    # terraform apply
    print_step_message "Terraform applying"
    docker exec "$TERRAFORM_CONTAINER_NAME" terraform init
    docker exec "$TERRAFORM_CONTAINER_NAME" terraform apply \
        -auto-approve \
        -var="admin_lambda_dist_bucket_key=$(pwd)/../build/hot-reload" \
        -var="authorizer_lambda_dist_bucket_key=$(pwd)/../build/hot-reload"
    print_done

    print_step_message "Cleanup"
    rm -rf "$TEMPDIR"
    print_done
}

main "$@"