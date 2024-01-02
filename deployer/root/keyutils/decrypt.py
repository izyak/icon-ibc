import logging
import boto3
import subprocess
import json
import os
import shutil
import base64
import re
from botocore.exceptions import ClientError

region_name = "us-west-1"
kms_region_name = "us-east-1"

def read_ciphertext_blob(file_path):
    try:
        with open(file_path, "rb") as cipher_file:
            # Read the binary data from the file
            binary_data = cipher_file.read()
            original_content = eval(binary_data)
            return original_content
    except FileNotFoundError:
        logger.error("CIPHER_TEXT file not found at '%s'", file_path)
        return None


KEYID_TEXT_FILE = '/opt/deployer/root/keyutils/kms_id'
CIPHER_TEXT_FILE = "/opt/deployer/root/keyutils/.cipher_text"

CIPHER_TEXT = read_ciphertext_blob(CIPHER_TEXT_FILE)

logger = logging.getLogger(__name__)

# Read KEY ID
try:
    with open(KEYID_TEXT_FILE, "r") as f:
        KEY_ID = f.read()
except FileNotFoundError:
    logging.error("File not found at '%s'", KEYID_TEXT_FILE)

class KeyEncrypt:
    def __init__(self, kms_client):
        self.kms_client = kms_client

    def encrypt(self, key_id):
        text = input("Enter some text to encrypt: ")
        try:
            cipher_text = self.kms_client.encrypt(
                KeyId=key_id, Plaintext=text.encode())['CiphertextBlob']
        except ClientError as err:
            logger.error(
                "Couldn't encrypt text. Here's why: %s", err.response['Error']['Message'])
        else:
            print(f"Your ciphertext is: {cipher_text}")
            return cipher_text

    def decrypt(self, key_id, cipher_text):
        try:
            text = self.kms_client.decrypt(
                KeyId=key_id, CiphertextBlob=cipher_text)['Plaintext']
        except ClientError as err:
            logger.error(
                "Couldn't decrypt your ciphertext. Here's why: %s",
                err.response['Error']['Message'])
        else:
            plaintext_pass = f"{text.decode()}"
            return plaintext_pass



def change_permissions_to_600(directory):
    for filename in os.listdir(directory):
        file_path = os.path.join(directory, filename)
        if os.path.isfile(file_path):
            os.chmod(file_path, 0o600)


def key_decryption(kms_client):
    logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')

    if KEY_ID == '':
        print("A key is not found.")
        return

    key_encrypt = KeyEncrypt(kms_client)
    if CIPHER_TEXT is not None:
        return key_encrypt.decrypt(KEY_ID, CIPHER_TEXT)

def save_key_store_to_file(secret_name, key_store, directory):
    secret_name_file = secret_name.split('/')[-1]

    if 'archway' in secret_name:
        key_store_file_name = f"{secret_name_file}_private.key"
        key_store_file_path = os.path.join(directory, key_store_file_name)
        with open(key_store_file_path, "w") as key_store_file:
            key_store_file.write(key_store['key'])
    else:
        key_store_file_name = f"{secret_name_file}.json"
        key_store_file_path = os.path.join(directory, key_store_file_name)
        with open(key_store_file_path, "w") as key_store_file:
            json.dump(key_store, key_store_file, indent=4)

def extract_key_store_and_secret(secret_value):
    try:
        base64_data = secret_value.replace("\n", "")
        secret_data = json.loads(base64_data)
        if 'key' in secret_data:
            # If 'key' exists, treat it as 'key_store'
            key_store = {'key': base64.b64decode(secret_data['key']).decode('utf-8')}
            return key_store

        elif 'key_store' in secret_data:
            key_store = secret_data.get('key_store', {})
            return key_store

        elif 'secret' in secret_data:
            secret = secret_data.get('secret', '')
            return secret
        else:
            print("Error: Didnot found any key")
    except json.JSONDecodeError as e:
        print(f"Error decoding JSON data: {e}")
        return {}, ''


def decrypt_secret(encrypted_secret):
    try:
        password = key_decryption(boto3.client('kms', region_name=kms_region_name))
    except Exception:
        logging.exception("Something went wrong with the demo!")
    openssl_command = f'echo "{encrypted_secret}" | openssl enc -aes-256-cbc -a -d -salt -pbkdf2 -pass pass:{password} | base64 -d'
    decrypted_secret = subprocess.check_output(openssl_command, shell=True, stderr=subprocess.DEVNULL)
    return decrypted_secret.decode().strip()

def get_wallets(wallet_names, region_name, directory):

    if os.path.exists(directory):
        shutil.rmtree(directory)

    os.makedirs(directory)

    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )


    for wallet in wallet_names:
        try:
            get_secret_value_response = client.get_secret_value(
                SecretId=wallet
            )
        except ClientError as e:
            # Handle exceptions if necessary
            print(f"Error fetching secret {wallet}: {e}")
            continue

        secret_value = get_secret_value_response['SecretString']
        decrypted_secret = decrypt_secret(secret_value)
        key_store = extract_key_store_and_secret(decrypted_secret)

        save_key_store_to_file(wallet, key_store, directory)


def get_secrets(secret_names, region_name, directory):

    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )

    secrets = {}

    for secret_name in secret_names:
        try:
            get_secret_value_response = client.get_secret_value(
                SecretId=secret_name
            )
        except ClientError as e:
            # Handle exceptions if necessary
            print(f"Error fetching secret {secret_name}: {e}")
            continue

        secret_value = get_secret_value_response['SecretString']
        decrypted_secret = decrypt_secret(secret_value)
        secret = extract_key_store_and_secret(decrypted_secret)

        parts = secret_name.split('/')
        name = '_'.join(parts[1:])
        secrets[name] = secret


    secrets_file_path = os.path.join(directory, 'secrets.json')
    with open(secrets_file_path, "w") as secrets_file:
        json.dump(secrets, secrets_file, indent=4)

    change_permissions_to_600(directory)

def get_secret_names(starting_string):
    client = boto3.client('secretsmanager', region_name=region_name)
    secrets = client.list_secrets()
    secret_names = [secret['Name'] for secret in secrets['SecretList'] if secret['Name'].startswith(starting_string)]
    return secret_names


def load_archway_wallet(directory):
    try:
        # Load passwords from secrets.json
        secrets_file_path = os.path.join(directory, "secrets.json")
        with open(secrets_file_path, "r") as secrets_file:
            passwords = json.load(secrets_file)


        key_files = [file for file in os.listdir(directory) if file.endswith(".key")]

        for key_file in key_files:
            # Extract wallet name from key file name
            wallet_name = os.path.splitext(key_file)[0]

            # Check if the wallet name has a corresponding password in secrets.json
            parts = key_file.replace("private", "")
            wallet_name = parts.split('.')[0]
            pass_key = f"archway_{wallet_name}secret"
            pass_key = re.sub(r"_+$", "", pass_key)
            wallet_name = re.sub(r"_+$", "", wallet_name)

            password = passwords.get(pass_key, "")


            if password:
                # Define the command to execute
                command = f'echo "{password}" | archwayd keys import {wallet_name} {directory}/{key_file} --keyring-backend test'
                command_inj = f'echo "{password}" | injectived keys import {wallet_name} {directory}/{key_file} --keyring-backend test'
                command_ntrn = f'echo "{password}" | injectived keys import {wallet_name} {directory}/{key_file} --keyring-backend test'

                # Execute the command using subprocess
                subprocess.run(command, shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                subprocess.run(command_inj, shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                subprocess.run(command_ntrn, shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                print(f"Wallet '{wallet_name}' imported successfully.")
            else:
                print(f"Skipping import for '{wallet_name}' due to missing password in secrets.json.")
    except subprocess.CalledProcessError as e:
        print(f"Error importing wallet: {e}")
    except Exception as e:
        print(f"An error occurred: {e}")



if __name__ == '__main__':
    secret_names = get_secret_names('mainnet')
    wallet_names = [
        "mainnet/icon/ibc_wallet",
        "mainnet/icon/xcall_wallet",
        "mainnet/archway/ibc_wallet",
        "mainnet/archway/xcall_wallet"
    ]
    secret_names = [
        "mainnet/icon/ibc_wallet_secret",
        "mainnet/icon/xcall_wallet_secret",
        "mainnet/archway/ibc_wallet_secret",
        "mainnet/archway/xcall_wallet_secret"
    ]
    save_directory = "/opt/deployer/root/keystore"
    get_wallets(wallet_names, region_name, save_directory)
    get_secrets(secret_names, region_name, save_directory)
    load_archway_wallet(save_directory)
