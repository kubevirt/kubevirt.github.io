#!/bin/bash

declare -A DEFAULTS
DEFAULTS[DEMO_SCRIPT_ROOT]=~/kubevirt.github.io/_includes/scriptlets/lab1
DEFAULTS[TEST_USER]=centos
DEFAULTS[KEY_FILE]=~/.ssh/aws-kubevirt-demos.pem

# ============================================================================
# PROCESS ARGUMENTS AND INPUTS
# ============================================================================
OPTSPEC="dhnvH:K:R:U:"

function parse_arguments() {
    while getopts "${OPTSPEC}" opt ; do
        case ${opt} in
            d) DEBUG=true
               ;;

            h) HELP=true
               ;;

            H) TEST_HOST=${OPTARG}
               ;;
            
            K) KEY_FILE=${OPTARG}
               ;;

            R) DEMO_SCRIPT_ROOT=${OPTARG}
               ;;

            n) NOOP=true
               ;;

            v) VERBOSE=true
               ;;
            
            U) TEST_USERNAME=${OPTARG}
               ;;
        esac
    done
}

function apply_defaults() {
    for KEY in ${!DEFAULTS[@]} ; do
        eval "$KEY=\${${KEY}:=${DEFAULTS[$KEY]}}"
    done
}

# Find all files in the listed directory and sort them by name numerically
function scriptlets() {
    local script_root=$1
    find ${script_root} -maxdepth 1 -type f | xargs -I{} basename {} | sort -n
}

function test_file() {
    local stimulus_file=$1
    local script_root=$2

    ls ${script_root}/test/${stimulus_file}
}

# ============================================================================
# MAIN
# ============================================================================
parse_arguments $*
apply_defaults

echo "running demo at ${DEMO_SCRIPT_ROOT} on ${TEST_HOST}"
echo
echo "--------"
ssh -o StrictHostKeyChecking=no ${TEST_USER}@${TEST_HOST} cat /etc/motd
echo "--------"
echo

ssh ${TEST_USER}@${TEST_HOST} mkdir -p test

for SCRIPTLET in $(scriptlets ${DEMO_SCRIPT_ROOT}) ; do
    
    echo Testing ${SCRIPTLET}
    echo Test file: $(test_file ${SCRIPTLET} ${DEMO_SCRIPT_ROOT})


    scp ${DEMO_SCRIPT_ROOT}/${SCRIPTLET} ${TEST_USER}@${TEST_HOST}:
    
    scp ${DEMO_SCRIPT_ROOT}/test/${SCRIPTLET} ${TEST_USER}@${TEST_HOST}:test
    
    ssh ${TEST_USER}@${TEST_HOST} sh test/${SCRIPTLET} before || exit $?

    [ $? -eq 127 ] && echo SKIP && break

    ssh ${TEST_USER}@${TEST_HOST} sh -x test/${SCRIPTLET} execute || exit $?
    ssh ${TEST_USER}@${TEST_HOST} sh test/${SCRIPTLET} after || exit $?
done

# ssh ${TEST_USER}@${TEST_HOST} rm -rf  [[:digit:]][[:digit:]]_*.sh
ssh ${TEST_USER}@${TEST_HOST} rm -rf  test



