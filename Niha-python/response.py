import itertools
import enchant

# Initialize the English dictionary
d = enchant.Dict("en_US")

# Function to generate non-vocabulary combinations
def generate_non_words(length):
    alphabet = 'abcdefghijklmnopqrstuvwxyz'
    all_combinations = [''.join(p) for p in itertools.product(alphabet, repeat=length)]
    non_words = [word for word in all_combinations if not d.check(word)]
    return non_words

# Example usage for 3-letter combinations
non_words_3 = generate_non_words(3)
print(non_words_3)
