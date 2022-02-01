#!/usr/bin/env python

import argparse
import subprocess
import configparser
import json
import sys

# defualt global values
MFA_DEVICE_SERIAL_ARN="arn:aws:iam::546776815214:mfa/vali"
# default 36 hours
SESSION_DURATION = "129600"
# default aws credentials file
AWS_CREDS_FILE = "/home/ec2-user/.aws/credentials"


def command_args():
    # arguments parser
    parser = argparse.ArgumentParser(description="AWS MFA Authentication tool")

    # read the token number
    parser.add_argument("TOKEN_NUMBER", help="MFA token number", nargs=1, type=int)

    # read session duration
    parser.add_argument("--duration", help="Session duration", nargs='?', type=int)

    # read credential file
    parser.add_argument("--credential-file", help="AWS credential file", nargs='?')

    # read credential file
    parser.add_argument("--mfa-device-arn", help="MFA device serial number or ARN", nargs='?')

    return parser.parse_args()



def executor(command):

    # get the sts token credentials
    # TODO: fetch full path dynamically
    # TODO: add try except and catch errors
    proc = subprocess.Popen(
        command,
        shell = True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        universal_newlines=True
    )

    try:
        output, errors = proc.communicate()
        return output, errors
    except Exception as error:
        sys.exit(error)


def update_credential_file(output, file):

    output = json.loads(output)

    config = configparser.ConfigParser()
    config.read(file)

    if "mfa" not in config.sections():
        config.add_section("mfa")

    # update credentials file with mfa profile
    config["mfa"]["aws_access_key_id"] = output["Credentials"]["AccessKeyId"]
    config["mfa"]["aws_secret_access_key"] = output["Credentials"]["SecretAccessKey"]
    config["mfa"]["aws_session_token"] = output["Credentials"]["SessionToken"]

    with open(file, 'w') as configfile:
        config.write(configfile)


def main():

    global MFA_DEVICE_SERIAL_ARN, SESSION_DURATION, AWS_CREDS_FILE

    command = [
        "aws sts get-session-token"
    ]

    # update command with TOKEN_NUMBER
    command.append(str(command_args().TOKEN_NUMBER[0]))

    # update MFA_ARN
    if command_args().mfa_device_arn:
        MFA_DEVICE_SERIAL_ARN = command_args().mfa_device_arn

    # update SESSION_DURATION
    if command_args().duration:
        SESSION_DURATION = command_args().duration

    # update AWS_CREDS_FILE
    if command_args().credential_file:
        AWS_CREDS_FILE = command_args().credential_file


    # update command
    command.append(f"--serial-number {MFA_DEVICE_SERIAL_ARN}")
    command.append(f"--duration-seconds {SESSION_DURATION}")

    output = executor(command)

    if output[0]:
        update_credential_file(output[0], AWS_CREDS_FILE)
    else:
        print(output[1])


if __name__ == '__main__':
    main()