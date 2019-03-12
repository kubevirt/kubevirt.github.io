#!/usr/bin/env python
"""
This program runs a series of single CLI steps, testing the state before and
after each step. It reports failure if:

1) A step's result state test is true before execution
2) A step returns a non-zero status value
3) A step's result state test is not true after execution
4) An asynchronous step result state is not met before a timeout expires
5) An interactive step does not respond correctly to the send/expect conditions

Each test is described by a specification file provided at runtime.
The specification file describes the test steps
"""

from __future__ import print_function

import argparse
import logging
import os
import pexpect
import re
import subprocess
import sys
import time
import yaml

# ----------------------------------------------------------------------------
# UTILITY FUNCTIONS
# ---------------------------------------------------------------------------

def process_cli():
    """Process the CLI arguments and return an options structure"""
    
    parser = argparse.ArgumentParser()

    parser.add_argument("-d", "--debug", action="store_true", default=False,
                        help="Print information useful to a script debugger")

    parser.add_argument("-t", "--test-dir", required=True,
                        help="The location of the test to run")
    
    parser.add_argument("-s", "--single-step", type=int,
                        help="A single step to run", default=0)

    parser.add_argument("-c", "--clean", action="store_true", dest='clean', default=True,
                        help="clean up after test run")

    parser.add_argument("--no-clean", action="store_false", dest='clean',
                        help="do not clean up after test run")

    opts = parser.parse_args()
    return opts


# ----------------------------------------------------------------------------
# TESTING FUNCTIONS
# ----------------------------------------------------------------------------

def run_step(t, opts):
    """Run a single step from a test spec"""

    logging.debug("step number: {}".format(t['step']))

    cmd = open(os.path.join(opts.test_dir, t['filename'])).readlines()[0]

    
    logging.debug("command: {}".format(cmd))

    result = None
    
    if "expect" in t.keys():
        result = interactive_step(t, opts.test_dir)

    if "test" in t.keys():
        result = side_effect_step(t, opts.test_dir)

    if "wait_for" in t.keys():
        result = wait_for_step(t)

    return result


def side_effect_step(t, test_dir):
    """Run a test step"""
    shell = t['shell'] if 'shell' in t.keys() else "sh"
                               
    # pre check
    if "test" in t.keys() and t['test'] != False:
        precheck_ok = False
        status = 0
        try: 
            output = subprocess.check_output([t['test']], shell=True, stderr=subprocess.STDOUT)
        except subprocess.CalledProcessError as e:
            # test should fail before step execution
            logging.debug("precheck status for {}: {}".format(t['name'], e.returncode))
            precheck_ok = True
            status = e.returncode

        if not precheck_ok:
            logging.error("PRE CHECK FOR {} FAILED: STATUS: {}".format(t['name'], status))
            return False

    logging.debug("Step '{}' - executing {}".format(t['name'], t['filename']))
    try:
        output = subprocess.check_output([shell, os.path.join(test_dir, t['filename'])], stderr=subprocess.STDOUT)
        
    except subprocess.CalledProcessError as e:
        logging.error("Step '{}' failed: status: {} - output\n{}".format(t['name'], e.returncode. e.output))
        return False

    logging.debug("Step '{}': output:\n{}".format(t['name'], output))

    # post check
    if "test" in t.keys() and t['test'] != False:
        try: 
            output = subprocess.check_output([t['test']], shell=True, stderr=subprocess.STDOUT)
        except subprocess.CalledProcessError as e:
            logging.error("POST CHECK FOR {} FAILED: STATUS: {}".format(t['name'], e.returncode))
            return False

    return True


def interactive_step(t, test_dir):
    """Execute an interactive demo step"""
    
    logging.info("Expect step: '{}'".format(t['name']))

    cmd = open(os.path.join(test_dir, t['filename'])).read()
    
    child = pexpect.spawn(cmd)

    status = True

    for action in t['expect']:

        for tries in range(0, action['tries']):
            logging.debug("try: {}".format(tries))

            child.send(action['send'])
            try:
                child.expect(action['expect'], action['timeout'])
            except pexpect.TIMEOUT:
                continue # go to top of loop

            break # didn't time out, so we're done
                            
    child.terminate()
    return status


def wait_for_step(t):
    """ """
    logging.info("Step '{}': waiting for {}".format(t['name'], t['wait_for']['poll']))

    tries = 0
    success_pattern = re.compile(t['wait_for']['match'])
    output = ""

    logging.debug("Step '{}': poll command: {}".format(t['name'], t['wait_for']['poll']))
    
    while tries < t['wait_for']['tries']:
        logging.debug("Step '{}': tries: {}. trying poll command: '{}'".format(t['name'], tries, t['wait_for']['poll']))
        try:
            output = subprocess.check_output(t['wait_for']['poll'], stderr=subprocess.STDOUT, shell=True)
        except subprocess.CalledProcessError as exit_status:
            logging.debug("Step '{}': error running check - status: {}\n  output:\n{}".format(t['name'], exit_status.returncode, exit_status.output))
            output = exit_status.output

        logging.debug("Step '{}': tries: {}. output:\n{}".format(t['name'], tries, output))

        if success_pattern.match(output):
            logging.info("Step '{}': success after {} tries".format(t['name'], tries))
            success = True
            return True
            
        tries += 1
        time.sleep(t['wait_for']['rate'])

    logging.error("Step '{}': fail after {} tries".format(t['name'], tries))
    return False

def cleanup(script):
    for line in script:
        logging.debug("Cleanup Line: \n{}".format(line.split()))
        subprocess.check_call(line.split())
    
# ===========================================================================
# MAIN
# ===========================================================================

if __name__ == "__main__":

    opts = process_cli()

    if opts.debug:
        logging.basicConfig(level=logging.DEBUG, stream=sys.stdout)
    else:
        logging.basicConfig(level=logging.INFO, stream=sys.stdout)

    # Read the demo test spec into a test spec structure
    spec = yaml.load(open(os.path.join(opts.test_dir, "test_spec.yaml")))    

    #
    # Execute a single specified step or the complete sequence from start to end
    #
    logging.info("Demo Test '{}': BEGIN".format(spec['test']['name']))
    if opts.single_step > 0:
        status = run_step(spec['test']['steps'][opts.single_step-1], opts)
    else:
        for step in spec['test']['steps']:
            status = run_step(step, opts)
            if status == False:
                break

    logging.info("Demo Test '{}': END".format(spec['test']['name']))
    if status == True:
        logging.info("Demo Test '{}': PASS".format(spec['test']['name']))
    else:
        logging.error("Demo Test '{}' FAIL".format(spec['test']['name']))
        
    if opts.clean and 'cleanup' in spec['test']:
        cleanup(spec['test']['cleanup'])

    if status == True:
        sys.exit(0)
    else:
        sys.exit(1)
