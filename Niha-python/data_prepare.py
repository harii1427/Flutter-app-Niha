import pandas as pd
import random
import os

# Function to generate unnatural commands
def generate_unnatural_commands(command):
    words = command.split()
    unnatural_commands = []
    for _ in range(5):  # Generate 5 unnatural commands as an example
        random.shuffle(words)
        unnatural_command = " ".join(words)
        unnatural_commands.append(unnatural_command)
    return unnatural_commands

# Function to continuously take user input and store in CSV
def main():
    # Check if CSV file exists
    if os.path.exists('commands_responses.csv'):
        df = pd.read_csv('commands_responses.csv')
    else:
        df = pd.DataFrame(columns=['command', 'response'])

    while True:
        input_command = input("Enter a command (or type 'exit' to quit): ")
        if input_command.lower() == 'exit':
            break
        response = input("Enter the response: ")

        # Generate unnatural commands
        unnatural_commands = generate_unnatural_commands(input_command)

        # Append new data to DataFrame
        new_data = {'command': [input_command] + unnatural_commands, 'response': [response] * (len(unnatural_commands) + 1)}
        df = pd.concat([df, pd.DataFrame(new_data)], ignore_index=True)

        # Save DataFrame to CSV
        df.to_csv('commands_responses.csv', index=False)
        print("Data saved to CSV file.")

if __name__ == "__main__":
    main()
