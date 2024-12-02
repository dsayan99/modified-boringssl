import socket
import requests
import json

# Global variable to store the reference key ID
key_ref = ""

# Function to fetch data from the API using a key ID
def fetch_data_usingKeyID(key_id1):
    url = f"https://3.115.216.128/api/v1/keys/SAE_A/dec_keys?key_ID={key_id1}"
    response = requests.get(url, verify=False)  # Skipping SSL verification for demonstration purposes
    if response.status_code == 200:
        return response.text
    else:
        print(f"Failed to fetch data: {response.status_code}")
        return None

# Function to fetch data from the API for a new key
def fetch_data():
    url = "https://3.115.153.86/api/v1/keys/SAE_B/enc_keys?size=256"
    response = requests.get(url, verify=False)  # Skipping SSL verification for demonstration purposes
    if response.status_code == 200:
        return response.text
    else:
        print(f"Failed to fetch data: {response.status_code}")
        return None

# Function to parse JSON data
def parse_json(json_data):
    data = json.loads(json_data)
    key_id = data["keys"][0]["key_ID"]
    key = data["keys"][0]["key"]
    return key_id, key

# Function to handle client connections
def handle_client(client_socket, counter):
    global key_ref  # Use the global key_ref
    if counter % 2 == 0:
        data = fetch_data_usingKeyID(key_ref)
    else:
        data = fetch_data()
    if data:
        key_id, key = parse_json(data)
        #response = f"Key ID: {key_id}\nKey: {key}\n"
        response =f"{key}"
        if counter % 2 != 0:
            key_ref = key_id  # Update the global key_ref on odd counter
        client_socket.sendall(response.encode('utf-8'))
    
    client_socket.close()

def main():
    counter = 1
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.bind(('0.0.0.0', 8080))
    server_socket.listen(5)

    print("Server listening on port 8080")

    while True:
        client_socket, addr = server_socket.accept()
        print(f"Accepted connection from {addr}")
        handle_client(client_socket, counter)
        counter += 1

if __name__ == "__main__":
    main()

